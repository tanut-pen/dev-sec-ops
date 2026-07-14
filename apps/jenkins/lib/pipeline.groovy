def call() {
    pipeline {
        agent {
            kubernetes {
                yamlFile 'apps/jenkins/demo/pod.yaml'
            }
        }

        options {
            disableConcurrentBuilds()
            timeout(time: 45, unit: 'MINUTES')
            timestamps()
        }

        environment {
            REPO_URL    = 'https://github.com/tanut-pen/vulnerability-application.git'
            REPO_BRANCH = 'main'

            APP_NAME        = 'vulnerability-application'
            IMAGE_TAG       = "${params.IMAGE_TAG?.trim() ? params.IMAGE_TAG : env.IMAGE_TAG_OVERRIDE ?: env.BUILD_NUMBER}"
            REGISTRY_URL     = 'harbor.tpinf.xyz'
            REGISTRY_PROJECT = 'lab'
            IMAGE_NAME       = "${REGISTRY_URL}/${REGISTRY_PROJECT}/${APP_NAME}:${IMAGE_TAG}"

            SONAR_ORGANIZATION = 'tanut-pen'
            SONARQUBE_URL      = 'https://sonarcloud.io'
            SONARQUBE_ENV      = 'sonarqube'
            SONAR_PROJECT_KEY  = 'tanut-pen_vulnerability-application'
            SONAR_PROJECT_NAME = 'vulnerability-application'

            HARBOR_CREDENTIALS_ID     = 'harbor-credentials'
            DEFECTDOJO_URL            = 'https://defectdojo.tpinf.xyz'
            DEFECTDOJO_ENGAGEMENT_NAME = 'Test'
            DEFECTDOJO_PRODUCT_NAME    = 'vulnerability-application'
            // NOTE: DEFECTDOJO_API_TOKEN intentionally NOT bound here anymore.
            // It's injected only inside the specific steps that call the DefectDojo API,
            // via withCredentials(), so it isn't exposed as a plaintext env var to every
            // container in the pipeline (golang, sonar, docker-cli, trivy, etc).
        }

        stages {

            stage('Clone Repository') {
                steps {
                    deleteDir()
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${env.REPO_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: env.REPO_URL,
                            credentialsId: 'git-token'
                        ]]
                    ])
                    // Using Jenkins' native checkout with credentialsId instead of an
                    // inline https://user:token@... URL avoids the token being written
                    // in plaintext to .git/config or echoed in git error output.
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
                        script {
                            // Distinguish "no test files" (exit code 0, message on stdout)
                            // from an actual test failure (non-zero exit). Previously both
                            // were swallowed by `|| echo ...`, which hid real failures.
                            def result = sh(script: 'go test ./... 2>&1 | tee test-output.log; exit ${PIPESTATUS[0]:-$?}',
                                            returnStatus: true)
                            if (result != 0) {
                                error("go test failed with exit code ${result}. See test-output.log")
                            }
                        }
                    }
                }
            }

            stage('SCA - Go Vulnerability Check') {
                steps {
                    container('golang') {
                        sh '''
                            go install golang.org/x/vuln/cmd/govulncheck@latest
                            govulncheck ./... || echo "govulncheck reported findings (non-blocking, no gate configured)"
                        '''
                    }
                }
            }

            stage('Sonar & Build (Parallel)') {
                parallel {
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
                                        sonar-report \
                                            --sonarurl="${SONARQUBE_URL}" \
                                            --sonartoken="${SONAR_TOKEN}" \
                                            --sonarorganization="${SONAR_ORGANIZATION}" \
                                            --sonarcomponent="${SONAR_PROJECT_KEY}" \
                                            --project="${SONAR_PROJECT_NAME}" \
                                            --application="${APP_NAME}" \
                                            --release="${BUILD_NUMBER}" \
                                            --branch="${REPO_BRANCH}" \
                                            --output=sonar-report.html
                                    '''
                                }
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
                }
            }

            stage('Import SonarQube to DefectDojo') {
                steps {
                    container('curl') {
                        withCredentials([string(credentialsId: 'defectdojo-api-token', variable: 'DEFECTDOJO_API_TOKEN')]) {
                            script {
                                importToDefectDojo(
                                    scanType: 'SonarQube Scan detailed',
                                    reportFile: 'sonar-report.html',
                                    minimumSeverity: 'Info'
                                )
                            }
                        }
                    }
                }
            }

            // Scan now runs BEFORE push (was previously parallel with it), so the
            // report reflects the exact image that ends up in Harbor and the scan
            // has fully completed before anything is published. No gate is enforced
            // per current requirements -- this only fixes ordering/visibility, not
            // build-blocking behavior.
            stage('Vulnerability Scan (Trivy)') {
                steps {
                    container('trivy') {
                        sh """
                            trivy image --format template --template '@/contrib/html.tpl' \
                                --output trivy-report.html --severity HIGH,CRITICAL ${IMAGE_NAME}
                            trivy image --format json \
                                --output trivy-report.json --severity HIGH,CRITICAL ${IMAGE_NAME}
                        """
                    }
                }
            }

            stage('Import Trivy Scan to DefectDojo') {
                steps {
                    container('curl') {
                        withCredentials([string(credentialsId: 'defectdojo-api-token', variable: 'DEFECTDOJO_API_TOKEN')]) {
                            script {
                                importToDefectDojo(
                                    scanType: 'Trivy Scan',
                                    reportFile: 'trivy-report.json',
                                    minimumSeverity: 'Low'
                                )
                            }
                        }
                    }
                }
            }

            stage('Push Image to Harbor') {
                steps {
                    container('docker-cli') {
                        withCredentials([usernamePassword(
                            credentialsId: "${env.HARBOR_CREDENTIALS_ID}",
                            usernameVariable: 'HARBOR_USER',
                            passwordVariable: 'HARBOR_PASS'
                        )]) {
                            sh """
                                echo "\${HARBOR_PASS}" | docker login ${REGISTRY_URL} -u "\${HARBOR_USER}" --password-stdin
                                docker push ${IMAGE_NAME}
                                docker logout ${REGISTRY_URL}
                            """
                        }
                    }
                }
            }
        }

        post {
            always {
                archiveArtifacts artifacts: 'trivy-report.json,trivy-report.html,sonar-report.html,test-output.log',
                                  allowEmptyArchive: true
            }
        }
    }
}

// Shared helper so both DefectDojo imports use identical, response-checked logic
// instead of duplicated curl blocks that only echo the HTTP status without acting on it.
def importToDefectDojo(Map cfg) {
    sh """
        set -e
        RESPONSE=\$(curl -sS --connect-timeout 10 -m 60 \\
            -X POST "\${DEFECTDOJO_URL}/api/v2/import-scan/" \\
            -H "Authorization: Token \${DEFECTDOJO_API_TOKEN}" \\
            -H "Accept: application/json" \\
            -F "scan_type=${cfg.scanType}" \\
            -F "file=@${cfg.reportFile}" \\
            -F "engagement_name=\${DEFECTDOJO_ENGAGEMENT_NAME}" \\
            -F "product_name=\${DEFECTDOJO_PRODUCT_NAME}" \\
            -F "product_type_name=Research and Development" \\
            -F "auto_create_context=true" \\
            -F "active=true" \\
            -F "verified=false" \\
            -F "close_old_findings=false" \\
            -F "scan_date=\$(date +%F)" \\
            -F "minimum_severity=${cfg.minimumSeverity}" \\
            -w "\\nHTTP_STATUS:%{http_code}")

        echo "=== DEFECTDOJO IMPORT RESPONSE (${cfg.scanType}) ==="
        echo "\$RESPONSE"

        HTTP_CODE=\$(echo "\$RESPONSE" | grep -o 'HTTP_STATUS:[0-9]*' | cut -d: -f2)
        if [ -z "\$HTTP_CODE" ] || [ "\$HTTP_CODE" -ge 400 ]; then
            echo "ERROR: DefectDojo import failed for ${cfg.scanType} (HTTP \$HTTP_CODE)"
            exit 1
        fi
    """
}

return this