pipeline {
	agent any


	environment {
		DOCKERHUB_USER = 'ungucri0103'
		DOCKERHUB_PASS =  credentials('parola-dockerhub')
		IMAGE_NAME = 'ungucri0103/monitor-script'
	}


	stages {
		stage('build docker image') {
			steps {
				script {
					sh 'docker build -t $IMAGE_NAME . -f Dockerfile.monitor' 
				}
			}
		}


		stage('push to dockerhub') {
			steps {
				script {
					sh 'echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin'
					sh 'docker push $IMAGE_NAME'
				}
			}
		}
	}
}