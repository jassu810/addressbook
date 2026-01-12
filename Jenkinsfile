pipeline {
    agent any

    tools {
        maven 'mymaven'
    }

    parameters {
        string(name: 'Env', defaultValue: 'Test', description: 'Environment to deploy')
        booleanParam(name: 'executeTests', defaultValue: true, description: 'Run unit tests')
        choice(name: 'APPVERSION', choices: ['1.1', '1.2', '1.3'], description: 'Select application version')
    }

    environment {
        BUILD_SERVER = 'ec2-user@172.31.6.105'
        IMAGE_NAME = 'jassu810/java-mvn-privaterepos:$BUILD_NUMBER'
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

        stage('Build docker image ') {
            steps {
                sshagent(['slave2']) {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'password', usernameVariable: 'username')]) {
                    echo "Packaging the code version ${params.APPVERSION}"

                    sh """
                        scp -o StrictHostKeyChecking=no server-script.sh \
                        ${BUILD_SERVER}:/home/ec2-user/
                    """

                    sh """
                        ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} \
                        'bash /home/ec2-user/server-script.sh ${IMAGE_NAME}'
                    """
                    sh "ssh -o ${BUILD_SERVER} sudo docker login -u ${usename} -p ${password}"
                    sh  "ssh -o ${BUILD_SERVER} sudo docker push $(IMAGE_NAME}"
                }
            }
        }
    }
}
