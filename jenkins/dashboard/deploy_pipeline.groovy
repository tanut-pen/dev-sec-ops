pipelineJob('devops-dashboard-pipeline') {
  description('Builds and deploys the custom DevOps Dashboard. It builds the Docker image, pushes it to Harbor, updates the image tag in Kustomize manifests, commits the tag change back to Git, and syncs Argo CD.')

  logRotator {
    numToKeep(10)
  }

  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('https://github.com/tanut-pen/dev-sec-ops.git')
            credentials('tanut-pen')
          }
          branch('*/main')
        }
      }
      scriptPath('jenkins/dashboard/Jenkinsfile')
      lightweight(true)
    }
  }
}
