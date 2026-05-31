pipelineJob('redbus-deploy') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('<GIT_REPO_URL>')
            credentials('<GIT_CREDENTIALS_ID>')
          }
          branches('*/main')
          extensions()
        }
      }
      scriptPath('Jenkinsfile')
    }
  }
  triggers {
    scm('H/5 * * * *')
  }
  description('Pipeline to build, push, and deploy Redbus app to EKS using Jenkinsfile in repository')
}
