pipeline {
    agent {
        label 'PS'
    }
    options {
        timeout(time: 5, unit: 'MINUTES')
    }
    stages {
        stage('Build') {
            steps {
                powershell 'Write-Output "building stuff"'
            }
        }
        stage('Test') {
            steps {
                powershell 'if ((invoke-pester ./test -passThru).FailedCount -ne 0) {exit -1} else {exit 0}'
            }
        }
        stage('Deploy') {
            when {
                branch 'production'
            }
            steps {
                powershell 'Write-Output "Package module and upload to powershell gallery etc."'
            }
        }
    }
    post {
        success {
            powershell 'Write-Ouptput "Something to do post success"'
        }
    }
}