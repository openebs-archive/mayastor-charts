#!/usr/bin/env groovy

def mainBranches() {
    return BRANCH_NAME == "develop" || BRANCH_NAME.startsWith("release/");
}

// TODO: Use multiple choices
helm_test = true
run_tests = params.run_tests

// Will skip steps for cases when we don't want to build
if (currentBuild.getBuildCauses('jenkins.branch.BranchIndexingCause') && mainBranches()) {
    print "INFO: Branch Indexing, skip tests and push the new images."
    run_tests = false
}

// Only schedule regular builds on main branches, so we don't need to guard against it
String cron_schedule = mainBranches() ? "0 2 * * *" : ""

pipeline {
  agent none
  options {
    timeout(time: 2, unit: 'HOURS')
  }
  parameters {
    booleanParam(defaultValue: true, name: 'run_tests')
  }
  triggers {
    cron(cron_schedule)
  }

  stages {
    stage('init') {
      agent { label 'nixos-mayastor' }
      steps {
        step([
          $class: 'GitHubSetCommitStatusBuilder',
          contextSource: [
            $class: 'ManuallyEnteredCommitContextSource',
            context: 'continuous-integration/jenkins/branch'
          ],
          statusMessage: [ content: 'Pipeline started' ]
        ])
      }
    }
    stage('chart publish test') {
      when {
        expression { helm_test == true }
      }
      agent { label 'nixos-mayastor' }
      steps {
        sh 'printenv'
        sh 'nix-shell --pure --run "./scripts/helm/test-publish-chart-yaml.sh" ./shell.nix'
      }
    }
  }

  // The main motivation for post block is that if all stages were skipped
  // (which happens when running cron job and branch != develop) then we don't
  // want to set commit status in github (jenkins will implicitly set it to
  // success).
  post {
    always {
      node(null) {
        script {
          // If no tests were run then we should neither be updating commit
          // status in github nor send any slack messages
          if (currentBuild.result != null) {
            step([
              $class            : 'GitHubCommitStatusSetter',
              errorHandlers     : [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
              contextSource     : [
                $class : 'ManuallyEnteredCommitContextSource',
                context: 'continuous-integration/jenkins/branch'
              ],
              statusResultSource: [
                $class : 'ConditionalStatusResultSource',
                results: [
                  [$class: 'AnyBuildResult', message: 'Pipeline result', state: currentBuild.getResult()]
                ]
              ]
            ])
          }
        }
      }
    }
  }
}
