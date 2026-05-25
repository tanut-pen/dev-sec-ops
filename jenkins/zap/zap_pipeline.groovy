pipelineJob('zap-scan-pipeline') {
  description('OWASP ZAP DAST scan pipeline. Enter a target URL, choose a scan mode (baseline / full / api / all), and get HTML + JSON reports. Optionally imports findings into DefectDojo.')

  logRotator {
    numToKeep(10)
  }

  parameters {
    stringParam('TARGET_URL', '', 'Full URL of the target to scan (e.g. https://example.com). For API mode this should be the OpenAPI/Swagger spec URL.')
    choiceParam('ZAP_MODE', ['baseline', 'full', 'api', 'all'],
      'baseline = passive/fast | full = active attack | api = OpenAPI spec scan | all = run all three')
    stringParam('CONTEXT_FILE', '', '(Optional) Path or URL to a ZAP context (.context) file for authenticated scans. Leave empty to skip.')
    booleanParam('IMPORT_TO_DEFECTDOJO', false, 'Upload the ZAP JSON report to DefectDojo after the scan')
    stringParam('DEFECTDOJO_ENGAGEMENT_ID', '1', 'DefectDojo engagement ID to import findings into (only used when IMPORT_TO_DEFECTDOJO is true)')
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
      scriptPath('jenkins/zap/Jenkinsfile')
      lightweight(true)
    }
  }
}
