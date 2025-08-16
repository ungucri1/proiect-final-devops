pipeline {
	agent any


	environment {
		IMAGE_NAME = 'ungucri0103/monitor'
		IMAGE_TAG = 'latest'
		TARGET_HOST = '192.168.1.195'
		TARGET_USER = 'ansibleuser'
		REPO_URL 	= 'https://github.com/ungucri1/proiect-final-devops.git'
	}


	stages {
		stage('lint bash') {
			steps {
				sh 'bash -n app/monitor/monitor.sh' 
				
			}
		}


		stage('build & push pe target') {
			steps {
				withCredentials([
					usernamePassword(credentialsId: 'parola-dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS'),
					sshUserPrivateKey(credentialsId: 'target-ssh', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
				])  {
					script {
						def privateKeyText = readFile(file: "${SSH_KEY}")
						def remote = [
							name: 'target',
							host: "${TARGET_HOST}",
							user: "${SSH_USER}",
							allowAnyHosts: true,
							identity: privateKeyText
						]

						sshCommand remote: remote, command: "rm -rf ~/ci-build || true"
						sshCommand remote: remote, command: "git clone ${REPO_URL} ~/ci-build"

						sshCommand remote: remote, command: "cd ~/ci-build && docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f app/monitor/Dockerfile ."

						sshCommand remote: remote, command: "echo '${DH_PASS}' | docker login -u '${DH_USER}' --password-stdin"
						sshCommand remote: remote, command: "docker push ${IMAGE_NAME}:${IMAGE_TAG}"

					}
				}
			}
		}
	}
}