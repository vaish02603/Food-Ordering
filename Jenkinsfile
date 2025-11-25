pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:

  - name: node
    image: node:18
    command: ['cat']
    tty: true

  - name: sonar-scanner
    image: sonarsource/sonar-scanner-cli
    command: ['cat']
    tty: true

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
    securityContext:
      runAsUser: 0
      readOnlyRootFilesystem: false
    env:
    - name: KUBECONFIG
      value: /kube/config
    volumeMounts:
    - name: kubeconfig-secret
      mountPath: /kube/config
      subPath: kubeconfig

  - name: dind
    image: docker:dind
    args: ["--storage-driver=overlay2", "--insecure-registry=nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"]
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""

  volumes:
  - name: kubeconfig-secret
    secret:
      secretName: kubeconfig-secret
'''
        }
    }

    stages {

        stage('Prepare Static Files') {
            steps {
                container('node') {
                    sh '''
                        echo "Static Website — No build required."
                        echo "Displaying project files:"
                        ls -la
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('dind') {
                    sh '''
                        echo "Waiting for Docker daemon..."
                        sleep 10

                        echo "Building Docker image for static website..."
                        docker build -t recipe-finder:latest .
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=2401048-food \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000 \
                            -Dsonar.login=sqp_e5eafae11fc3f0cf3bd677e0763b65e45bd69a6d
                    '''
                }
            }
        }

        stage('Login to Nexus Registry') {
            steps {
                container('dind') {
                    sh '''
                        echo "Logging into Nexus Registry..."
                        docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 -u admin -p Changeme@2025
                    '''
                }
            }
        }

        stage('Push to Nexus') {
            steps {
                container('dind') {
                    sh '''
                        echo "Tagging Docker image..."
                        docker tag food-ordering:latest nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401048/food-ordering:v1

                        echo "Pushing image to Nexus..."
                        docker push nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401048/food-ordering:v1
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "Deploying to Kubernetes Namespace: 2401048"

                        kubectl apply -f k8s/deployment.yaml -n 2401048
                        kubectl apply -f k8s/service.yaml -n 2401048

                        kubectl get all -n 2401048

                        kubectl rollout status deployment/food-ordering-deployment -n 2401048
                    '''
                }
            }
        }
    }
}
