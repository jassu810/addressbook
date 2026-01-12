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
                echo 'Running code coverage verification'
                sh 'mvn verify'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                sshagent(['slave2']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker-hub',
                            usernameVariable: 'USERNAME',
                            passwordVariable: 'PASSWORD'
                        )
                    ]) {

                        echo "Packaging the code version ${params.APPVERSION}"

                        sh """
                            scp -o StrictHostKeyChecking=no server-script.sh ${BUILD_SERVER}:/home/ec2-user/
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} \
                            "bash /home/ec2-user/server-script.sh ${IMAGE_NAME}"
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} \
                            "sudo docker login -u ${USERNAME} -p ${PASSWORD}"
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} \
                            "sudo docker push ${IMAGE_NAME}"
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
                            usernameVariable: 'USERNAME',
                            passwordVariable: 'PASSWORD'
                        )
                    ]) {

                        sh """
                            ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} \
                            "sudo yum install -y docker && sudo systemctl start docker"
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} \
                            "sudo docker login -u ${USERNAME} -p ${PASSWORD}"
                        """

                        sh """
                            ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} \
                            "sudo docker run -itd -P ${IMAGE_NAME}"
                        """
                    }
                }
            }
        }
    }
}
