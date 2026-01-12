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
                sh 'mvn clean compile'
            }
        }

        stage('Unit Test') {
            when {
                expression { params.executeTests }
            }
            steps {
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
                sh 'mvn pmd:pmd'
            }
        }

        stage('Coverage') {
            steps {
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
                        sh '''
                        scp -o StrictHostKeyChecking=no server-script.sh ${BUILD_SERVER}:/home/ec2-user/

                        ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} << 'EOF'
                          sudo systemctl start docker || true
                          echo "$DOCKER_PASS" | sudo docker login -u "$DOCKER_USER" --password-stdin
                          bash /home/ec2-user/server-script.sh ${IMAGE_NAME}
                          sudo docker push ${IMAGE_NAME}
                        EOF
                        '''
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
                        sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} << 'EOF'
                          sudo systemctl start docker || true
                          echo "$DOCKER_PASS" | sudo docker login -u "$DOCKER_USER" --password-stdin
                          sudo docker stop app || true
                          sudo docker rm app || true
                          sudo docker run -d --name app -p 8080:8080 ${IMAGE_NAME}
                        EOF
                        '''
                    }
                }
            }
        }
    }
}
