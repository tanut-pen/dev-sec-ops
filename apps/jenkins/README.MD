Example Secret

apiVersion: v1
kind: Secret
metadata:
  name: mcp-jenkins-secret
  namespace: jenkins
  labels:
    app.kubernetes.io/name: mcp-jenkins
    app.kubernetes.io/component: mcp-server
type: Opaque
stringData:
  JENKINS_USERNAME: {}
  JENKINS_PASSWORD: {}
