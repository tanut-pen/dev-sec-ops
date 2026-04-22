# Jenkins Seed Job Configuration

This directory contains the seed job and Job DSL scripts for bootstrapping Jenkins pipeline jobs.

## Files

### seed-job.groovy
Groovy initialization script that creates the seed job during Jenkins startup. This script:
- Creates a freestyle job named `seed-job`
- Configures Git SCM to fetch job definitions from the repository
- Sets up Job DSL builder to dynamically create jobs from `jobs.groovy`
- Is automatically executed via `jenkins-values.yaml` `initScripts`

### jobs.groovy
Job DSL script that defines Jenkins pipeline jobs:
- **demo-pipeline**: Basic pipeline job with Git triggers
- **security-scan**: Security scanning pipeline (SAST, dependencies, DAST)
- **deploy-to-k8s**: Kubernetes deployment pipeline

## How It Works

1. **Initialization**: When Jenkins starts, the `seed-init` groovy script from `jenkins-values.yaml` runs
2. **Seed Job Creation**: The seed job is created and configured to watch for Job DSL files
3. **Job Generation**: The seed job builds, clones the repository, and executes `jobs.groovy`
4. **Job Provisioning**: All jobs defined in `jobs.groovy` are created in Jenkins

## Adding New Jobs

To add a new job:

1. Edit `jobs.groovy` and add a new `pipelineJob()` or `job()` block
2. Commit and push the changes
3. Run the seed job manually or let it trigger automatically
4. The new job will be created automatically

### Example: Adding a Simple Job

```groovy
pipelineJob('my-new-job') {
    description('My new job created by seed')
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    stages {
                        stage('Hello') {
                            steps {
                                echo 'Hello from my job!'
                            }
                        }
                    }
                }
            ''')
            sandbox(true)
        }
    }
}
```

## Configuration in jenkins-values.yaml

The seed job initialization is configured in `jenkins-values.yaml` under:
```yaml
controller:
  installPlugins:
    - job-dsl:1.90  # Required for Job DSL support
  
  initScripts:
    seed-init: |
      # Groovy script that creates the seed job
```

## Useful References

- [Job DSL Plugin Documentation](https://jenkinsci.github.io/job-dsl-plugin/)
- [Job DSL API Reference](https://jenkinsci.github.io/job-dsl-plugin/1.80/)
- [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)

## Troubleshooting

**Seed job not creating jobs?**
- Check Jenkins logs: `kubectl logs -f <jenkins-pod> -n jenkins`
- Verify Job DSL plugin is installed: Manage Jenkins → Plugin Manager
- Run the seed job manually and check console output

**Jobs created but not updated?**
- By default, removed jobs are deleted. Use `removedJobAction: 'DISABLE'` to disable instead
- Set `ignoreExisting: false` to overwrite existing job configurations

**Script Approval Issues?**
- Jenkins may require script approval for certain Groovy operations
- Go to Manage Jenkins → Script Approval to approve scripts
- Or disable the Script Security plugin (not recommended for production)
