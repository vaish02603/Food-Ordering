pipeline {
    agent {
        kubernetes {
            yaml """
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
    args:
      - "--storage-driver=overlay2"
      - "--insecure-registry=nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""

  volumes:
  - name: kubeconfig-secret
    secret:
      secretName: kubeconfig-secret
"""
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
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DH_USER',
                        passwordVariable: 'DH_PASS'
                    )]) {
                        sh '''
                            echo "Waiting for Docker daemon to be ready..."

                            # Try for ~60 seconds
                            for i in $(seq 1 30); do
                              if docker info >/dev/null 2>&1; then
                                echo "Docker daemon is ready"
                                break
                              fi
                              echo "Docker not ready yet, retrying in 2s... ($i/30)"
                              sleep 2
                            done

                            # Final check – if still not ready, fail clearly
                            if ! docker info >/dev/null 2>&1; then
                              echo "Docker daemon is still not reachable. Failing build."
                              exit 1
                            fi

                            echo "Logging in to Docker Hub to avoid rate limits..."
                            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin

                            echo "Building Docker image..."
                            docker build -t food-ordering:latest .
                        '''
                    }
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
                    withCredentials([usernamePassword(
                        credentialsId: 'nexus-docker-creds',
                        usernameVariable: 'REG_USER',
                        passwordVariable: 'REG_PASS'
                    )]) {
                        sh '''
                            echo "$REG_PASS" | docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 \
                              -u "$REG_USER" --password-stdin
                        '''
                    }
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

                        kubectl get all -n 2401086
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