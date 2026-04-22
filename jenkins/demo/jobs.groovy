// Job DSL Script - Defines jobs to be created by the seed job
// Reference: https://jenkinsci.github.io/job-dsl-plugin/

def gitRepo = 'https://github.com/Iceza5k/dev-sec-ops.git'
def gitBranch = 'main'
def gitCredentials = ''

// Example: Create a basic pipeline job
pipelineJob('demo-pipeline') {
    description('Demo pipeline job created by seed job')
    
    parameters {
        string(
            name: 'BRANCH',
            defaultValue: gitBranch,
            description: 'Git branch to build'
        )
        string(
            name: 'BUILD_ENV',
            defaultValue: 'dev',
            description: 'Build environment (dev/staging/prod)'
        )
    }
    
    triggers {
        // Trigger on GitHub push
        githubPush()
        
        // Poll SCM every 15 minutes as fallback
        pollSCM('H/15 * * * *')
    }
    
    definition {
        cps {
            script(readFileFromWorkspace('jenkins/Jenkinsfile'))
            sandbox(true)
        }
    }
    
    properties {
        // Keep last 10 builds
        buildDiscarder {
            strategy {
                logRotator {
                    daysToKeepStr('7')
                    numToKeepStr('10')
                    artifactDaysToKeepStr('')
                    artifactNumToKeepStr('')
                }
            }
        }
    }
}

// Example: Create a security scanning job
pipelineJob('security-scan') {
    description('Security scanning pipeline - SAST, DAST, dependency check')
    
    parameters {
        choice(
            name: 'SCAN_TYPE',
            choices: ['full', 'quick', 'dependency-only'],
            description: 'Type of security scan to run'
        )
    }
    
    triggers {
        // Run daily at 2 AM UTC
        cron('0 2 * * *')
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    options {
                        timestamps()
                        timeout(time: 1, unit: 'HOURS')
                        buildDiscarder(logRotator(numToKeepStr: '10'))
                    }
                    
                    stages {
                        stage('Checkout') {
                            steps {
                                checkout scm
                            }
                        }
                        
                        stage('SAST - SonarQube') {
                            steps {
                                script {
                                    if (params.SCAN_TYPE == 'full' || params.SCAN_TYPE == 'quick') {
                                        echo 'Running SonarQube SAST analysis...'
                                        // sonarQube integration here
                                    }
                                }
                            }
                        }
                        
                        stage('Dependency Check') {
                            steps {
                                script {
                                    if (params.SCAN_TYPE == 'full' || params.SCAN_TYPE == 'dependency-only') {
                                        echo 'Running dependency vulnerability check...'
                                        // dependency-check integration here
                                    }
                                }
                            }
                        }
                        
                        stage('Report') {
                            steps {
                                echo 'Generating security report...'
                                // Report aggregation
                            }
                        }
                    }
                    
                    post {
                        always {
                            echo 'Security scan completed'
                        }
                        failure {
                            echo 'Security scan failed!'
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }
}

// Example: Create a deployment job
pipelineJob('deploy-to-k8s') {
    description('Deploy application to Kubernetes cluster')
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image tag to deploy'
        )
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    options {
                        timestamps()
                        buildDiscarder(logRotator(numToKeepStr: '10'))
                    }
                    
                    stages {
                        stage('Validate') {
                            steps {
                                echo "Validating deployment to ${params.ENVIRONMENT}"
                            }
                        }
                        
                        stage('Deploy') {
                            steps {
                                echo "Deploying image ${params.IMAGE_TAG} to ${params.ENVIRONMENT}"
                                // kubectl apply -f deployment.yaml
                            }
                        }
                        
                        stage('Verify') {
                            steps {
                                echo "Verifying deployment..."
                                // kubectl rollout status
                            }
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }
}

println("Job DSL completed: Created demo-pipeline, security-scan, and deploy-to-k8s jobs")
