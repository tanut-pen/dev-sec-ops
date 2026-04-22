// Seed Job - Creates and manages Jenkins pipeline jobs from code
// This groovy script initializes the seed job that dynamically generates other jobs

import jenkins.model.Jenkins
import hudson.model.FreeStyleProject
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import hudson.util.Secret

// Define seed job configuration
def seedJobName = "seed-job"
def seedJobDescription = "Seed job for bootstrapping CI/CD pipeline"
def gitRepo = "https://github.com/Iceza5k/dev-sec-ops.git"
def jobsPath = "jenkins/demo"
def branch = "HEAD"

// Get Jenkins instance
Jenkins jenkins = Jenkins.getInstance()

// Check if seed job already exists
def existingSeedJob = jenkins.getItemByFullName(seedJobName)

if (existingSeedJob == null) {
    println("Creating seed job: ${seedJobName}")
    
    // Create a new freestyle job
    def seedJob = jenkins.createProject(FreeStyleProject.class, seedJobName)
    seedJob.setDescription(seedJobDescription)
    
    // Configure SCM (Git)
    def scm = new hudson.plugins.git.GitSCM(
        [new hudson.plugins.git.UserRemoteConfig(gitRepo)],
        [new hudson.plugins.git.BranchSpec(branch)],
        false,
        [],
        null,
        null,
        []
    )
    seedJob.setScm(scm)
    
    // Configure Job DSL Builder
    def jobDslBuilder = new javaposse.jobdsl.plugin.ExecuteDslScripts(
        targets: "${jobsPath}/*.groovy",
        usingScriptText: false,
        sandbox: true,
        ignoreExisting: false,
        ignoreFailures: false,
        unstableOnDeprecation: false,
        unstableOnWarning: true,
        removedJobAction: 'DELETE',
        removedViewAction: 'DELETE',
        removedConfigFilesAction: 'DELETE',
        lookupStrategy: 'JENKINS_ROOT'
    )
    
    seedJob.getBuildersList().add(jobDslBuilder)
    
    // Save the job
    seedJob.save()
    println("Seed job '${seedJobName}' created successfully")
} else {
    println("Seed job '${seedJobName}' already exists, skipping creation")
}

println("Seed job initialization complete")
