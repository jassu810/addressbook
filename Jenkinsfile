pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
    }

    parameters {
        string(name: 'Env', defaultValue: 'Test', description: 'Environment to deploy')
        booleanParam(name: 'executeTests', defaultValue: true, description: 'Run unit tests')
        choice(name: 'APPVERSION', choices: ['1.1', '1.2', '1.3'], description: 'Select application version')
    }

    stages {

        stage('Compile') {
            steps {
                echo "Compiling code in ${params.Env} environment"
                sh 'mvn clean compile'
            }
        }

        stage('Unit Test') {
            when {
                expression { params.executeTests }
            }
            steps {
                echo "Running unit tests in ${params.Env} environment"
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Code Review') {
            steps {
                echo 'Running PMD code analysis'
                sh 'mvn pmd:pmd'
            }
        }

        stage('Coverage') {
            steps {
                echo 'Running code coverage verification'
                sh 'mvn verify'
            }
        }
    }
}
