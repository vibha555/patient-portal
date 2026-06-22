pipeline {
    agent any

    environment {
        CI = 'true'
        PROJECT_DIR = '.'
        DOCKER_IMAGE = 'vibha5552/patient-portal'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    stages {

        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Detect Project Directory') {
            steps {
                script {
                    if (fileExists('package.json')) {
                        env.PROJECT_DIR = '.'
                    } else if (fileExists('patient-portal/package.json')) {
                        env.PROJECT_DIR = 'patient-portal'
                    } else {
                        error('Could not find patient-portal package.json.')
                    }

                    echo "Using project directory: ${env.PROJECT_DIR}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh '''
                        node --version
                        npm --version

                        if [ -f package-lock.json ]; then
                            npm ci
                        else
                            npm install
                        fi
                    '''
                }
            }
        }

        stage('Lint') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh 'npm run lint'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh 'npm run test:coverage'
                }
            }
        }

        stage('Build') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh 'npm run build'
                }
            }
        }

        stage('Archive Build Artifacts') {
            steps {
                archiveArtifacts artifacts: "${env.PROJECT_DIR}/dist/**",
                                  fingerprint: true
            }
        }

        stage('Build Docker Image') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    sh '''
                        docker build -t $DOCKER_IMAGE:$IMAGE_TAG .
                        docker tag $DOCKER_IMAGE:$IMAGE_TAG $DOCKER_IMAGE:latest
                    '''
                }
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    docker push $DOCKER_IMAGE:$IMAGE_TAG
                    docker push $DOCKER_IMAGE:latest
                '''
            }
        }
    }

    post {
        success {
            echo 'Patient Portal pipeline completed successfully.'
        }

        failure {
            echo 'Patient Portal pipeline failed.'
        }

        always {
            sh '''
                docker rmi $DOCKER_IMAGE:$IMAGE_TAG || true
                docker rmi $DOCKER_IMAGE:latest || true
            '''
            cleanWs(deleteDirs: true, disableDeferredWipeout: true)
        }
    }
}