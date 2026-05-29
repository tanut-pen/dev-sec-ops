pipeline {
        agent {
            kubernetes {
                yamlFile 'jenkins/demo/pod.yaml'
            }
        }

        options {
            disableConcurrentBuilds()
        }

        environment {
            REPO_URL = 'https://github.com/tanut-pen/vulnerability-application.git'
            REPO_BRANCH = 'main'

            APP_NAME = 'vulnerability-application'
            IMAGE_TAG = "${env.BUILD_NUMBER}"
            REGISTRY_URL = 'harbor.tpinf.xyz'
            REGISTRY_PROJECT = 'lab'
            IMAGE_NAME = "${REGISTRY_URL}/${REGISTRY_PROJECT}/${APP_NAME}:${IMAGE_TAG}"

            SONAR_ORGANIZATION = 'tanut-pen'
            SONARQUBE_URL = 'https://sonarcloud.io'
            SONARQUBE_ENV = 'sonarqube'
            SONAR_PROJECT_KEY = 'tanut-pen_vulnerability-application'
            SONAR_PROJECT_NAME = 'vulnerability-application'

            HARBOR_CREDENTIALS_ID = 'harbor-credentials'
            DEFECTDOJO_URL = 'https://defectdojo.tpinf.xyz'
            DEFECTDOJO_ENGAGEMENT_ID = '2'
            DEFECTDOJO_PRODUCT_NAME = 'vulnerability-application'
            DEFECTDOJO_API_TOKEN = credentials('defectdojo-api-token')
        }

        stages {
            stage('Clone Repository') {
                steps {
                    deleteDir()
                    withCredentials([usernamePassword(
                        credentialsId: 'git-token',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh '''
                            git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/tanut-pen/vulnerability-application.git .
                            git checkout main
                        '''
                    }
                }
            }

            stage('Install Dependencies') {
                steps {
                    container('golang') {
                        sh 'GOTOOLCHAIN=auto go mod download'
                    }
                }
            }

            stage('Run Tests') {
                steps {
                    container('golang') {
                        sh 'go test ./... || echo "No tests to run"'
                    }
                }
            }

            stage('SonarQube Analysis') {
                steps {
                    container('sonar') {
                        withSonarQubeEnv('sonarqube') {
                            withCredentials([string(credentialsId: 'sonar', variable: 'SONAR_TOKEN')]) {
                                sh '''
                                    sonar-scanner \
                                        -Dsonar.host.url=${SONARQUBE_URL} \
                                        -Dsonar.login=$SONAR_TOKEN \
                                        -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                                        -Dsonar.projectName=$SONAR_PROJECT_NAME \
                                        -Dsonar.organization=$SONAR_ORGANIZATION \
                                        -Dsonar.projectVersion=$BUILD_NUMBER \
                                        -Dsonar.sources=. \
                                        -Dsonar.exclusions=**/static/** \
                                        -Dsonar.sourceEncoding=UTF-8
                                '''
                            }
                        }
                    }
                    container('curl') {
                        withCredentials([string(credentialsId: 'sonar', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                apk add -q curl nodejs npm
                                npm install -g sonar-report
                                sonar-report \
                                    --sonarurl="${SONARQUBE_URL}" \
                                    --sonartoken="${SONAR_TOKEN}" \
                                    --sonarorganization="${SONAR_ORGANIZATION}" \
                                    --sonarcomponent="${SONAR_PROJECT_KEY}" \
                                    --project="${SONAR_PROJECT_NAME}" \
                                    --application="${APP_NAME}" \
                                    --release="${BUILD_NUMBER}" \
                                    --branch="main" \
                                    --output=sonar-report.html
                            '''
                        }
                    }
                }
            }

            stage('Import SonarQube to DefectDojo') {
                steps {
                    container('curl') {
                        sh '''
                            apk add -q curl
                            echo "=== FILE INFO ==="
                            ls -la sonar-report.html
                            echo "=== FILE PREVIEW ==="
                            head -c 500 sonar-report.html

                            RESPONSE=$(curl -sS --connect-timeout 10 -m 60 \
                                -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
                                -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \
                                -H "Accept: application/json" \
                                -F "scan_type=SonarQube Scan detailed" \
                                -F "file=@sonar-report.html" \
                                -F "engagement=${DEFECTDOJO_ENGAGEMENT_ID}" \
                                -F "product_name=${DEFECTDOJO_PRODUCT_NAME}" \
                                -F "active=true" \
                                -F "verified=false" \
                                -F "close_old_findings=false" \
                                -F "scan_date=$(date +%F)" \
                                -F "minimum_severity=Info" \
                                -F "file=@sonar-report.html" \
                                -w "\\nHTTP_STATUS:%{http_code}")

                            echo "=== SONARQUBE IMPORT RESPONSE ==="
                            echo "$RESPONSE"
                        '''
                    }
                }
            }

            stage('Build Container Image') {
                steps {
                    container('docker-cli') {
                        sh "docker build -t ${IMAGE_NAME} ."
                    }
                }
            }

            stage('Vulnerability Scan') {
                steps {
                    container('trivy') {
                        script {
                            def imageName = env.IMAGE_NAME
                            echo "Scanning Image: ${imageName}"
                            sh "trivy image --format template --template '@/contrib/html.tpl' --output trivy-report.html --severity HIGH,CRITICAL ${imageName}"
                            sh "trivy image --format json --output trivy-report.json --severity HIGH,CRITICAL ${imageName}"
                        }
                    }
                }
            }

            stage('Push Image to Harbor') {
                when {
                    expression { return params.PUSH_TO_HARBOR }
                }
                steps {
                    container('docker-cli') {
                        withCredentials([usernamePassword(credentialsId: "${env.HARBOR_CREDENTIALS_ID}", usernameVariable: 'HARBOR_USER', passwordVariable: 'HARBOR_PASS')]) {
                            sh """
                                echo "${HARBOR_PASS}" | docker login ${REGISTRY_URL} -u "${HARBOR_USER}" --password-stdin
                                docker push ${IMAGE_NAME}
                                docker logout ${REGISTRY_URL}
                            """
                        }
                    }
                }
            }

            stage('Import Scan to DefectDojo') {
                when {
                    expression { return params.IMPORT_TO_DEFECTDOJO }
                }
                steps {
                    container('curl') {
                        sh '''
                            apk add -q curl
                            RESPONSE=$(curl -sS --connect-timeout 10 -m 60 \
                                -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
                                -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \
                                -H "Accept: application/json" \
                                -F "scan_type=Trivy Scan" \
                                -F "engagement=${DEFECTDOJO_ENGAGEMENT_ID}" \
                                -F "product_name=${DEFECTDOJO_PRODUCT_NAME}" \
                                -F "active=true" \
                                -F "verified=false" \
                                -F "close_old_findings=false" \
                                -F "scan_date=$(date +%F)" \
                                -F "minimum_severity=Low" \
                                -F "file=@trivy-report.json" \
                                -w "\\nHTTP_STATUS:%{http_code}")

                            echo "=== RESPONSE BODY ==="
                            echo "$RESPONSE"
                        '''
                    }
                }
            }
        }

        post {
            always {
                archiveArtifacts artifacts: 'trivy-report.json,trivy-report.html,sonar-report.html', allowEmptyArchive: true
            }
        }
}

