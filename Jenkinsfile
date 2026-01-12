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
        BUILD_SERVER  = 'ec2-user@172.31.6.105'
        DEPLOY_SERVER = 'ec2-user@172.31.5.217'
        IMAGE_NAME    = "jassu810/java-mvn-privaterepos:${BUILD_NUMBER}"
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
                echo 'Running code coverage'
                sh 'mvn verify'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                sshagent(['slave2']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker-hub',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {

                        sh """
                            scp -o StrictHostKeyChecking=no server-script.sh \
                            ${BUILD_SERVER}:/home/ec2-user/
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} \
                            "bash /home/ec2-user/server-script.sh ${IMAGE_NAME}"
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} \
                            "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} \
                            "docker push ${IMAGE_NAME}"
                        """
                    }
                }
            }
        }

        stage('Deploy Docker Image') {
            steps {
                sshagent(['slave2']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker-hub',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {

                        sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} sudo yum install docker -y"
                        sh "ssh  ${DEPLOY_SERVER} sudo service docker start"
                        sh "ssh  ${DEPLOY_SERVER} sudo docker login -u ${username} -p ${password}"
                        sh "ssh  ${DEPLOY_SERVER} sudo docker run -itd -P ${IMAGE_NAME}"
                    }
                }
            }
        }
    }
}
