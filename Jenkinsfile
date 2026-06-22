pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'vibha5552/patient-portal'
        IMAGE_TAG = "${BUILD_NUMBER}"
        LATEST_TAG = 'latest'
        DOCKER_CREDENTIALS = 'dockerhub_creds'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Git Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/vibha555/patient-portal.git'
                    ]]
                ])
            }
        }

        stage('Docker Build Image') {
            steps {
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:${LATEST_TAG}
                '''
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:${LATEST_TAG}
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed. Images pushed: ${DOCKER_IMAGE}:${IMAGE_TAG} and ${DOCKER_IMAGE}:${LATEST_TAG}"
        }
        failure {
            echo 'Pipeline failed. Check stage logs for details.'
        }
        always {
            sh '''
                docker rmi ${DOCKER_IMAGE}:${IMAGE_TAG} || true
                docker rmi ${DOCKER_IMAGE}:${LATEST_TAG} || true
            '''
            cleanWs(deleteDirs: true, disableDeferredWipeout: true)
        }
    }
}