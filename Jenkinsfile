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

        stage('Prepare Static Website') {
            steps {
                container('node') {
                    sh '''
                        echo "No build required — static HTML website"
                        echo "Listing project files..."
                        ls -la
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('dind') {
                    sh '''
                        sleep 10
                        docker build -t food-ordering:latest .
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=2401048-food\
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
                        docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 \
                          -u admin -p Changeme@2025
                    '''
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                container('dind') {
                    sh '''
                        docker tag food-ordering:latest nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401048/food-ordering:v1
                        docker push nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085/2401048/food-ordering:v1
                    '''
                }
            }
        }

        stage('Create Namespace') {
    steps {
        container('kubectl') {
            sh '''
                echo "Creating namespace 2401048 if not exists..."
                kubectl create namespace 2401048 || echo "Namespace already exists"
                kubectl get ns
            '''
        }
    }
}


        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        set -x
                        ls -la
                        ls -la k8s

                        kubectl apply -f k8s/deployment.yaml -n 2401048
                        kubectl apply -f k8s/service.yaml -n 2401048

                        kubectl get all -n 2401048
                        kubectl rollout status deployment/food-ordering-deployment -n 2401048
                    '''
                }
            }
        }

        stage('Debug Pods') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "[DEBUG] Listing Pods..."
                        kubectl get pods -n 2401048

                        echo "[DEBUG] Describing Pods..."
                        kubectl describe pods -n 2401048 | head -n 200
                    '''
                }
            }
        }
    }
}
