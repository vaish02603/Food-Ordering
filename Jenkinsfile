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
                        echo "Static HTML website — no build needed"
                        ls -la
                    '''
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                container('dind') {
                    script {
                        try {
                            withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                                sh '''
                                    echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
                                '''
                            }
                        } catch (all) {
                            echo 'dockerhub-creds not found. Trying DH_USER/DH_PASS env fallback.'
                            sh '''
                                if [ -n "$DH_USER" ] && [ -n "$DH_PASS" ]; then \
                                  echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin; \
                                else \
                                  echo "Skipping Docker Hub login: no creds available. Pulls may be rate limited."; \
                                fi
                            '''
                        }
                    }
                }
            }
        }

        stage('Login to Nexus Registry (pre-build)') {
            steps {
                container('dind') {
                    script {
                        try {
                            withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                                sh '''
                                    docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 \
                                      -u $NEXUS_USER -p $NEXUS_PASS
                                '''
                            }
                        } catch (all) {
                            echo 'nexus-creds not found. Trying NEXUS_USER/NEXUS_PASS env fallback.'
                            sh '''
                                if [ -n "$NEXUS_USER" ] && [ -n "$NEXUS_PASS" ]; then \
                                  docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 -u "$NEXUS_USER" -p "$NEXUS_PASS"; \
                                else \
                                  echo "Skipping Nexus login: no creds available. Ensure hosted repo allows anonymous pull or add credentials."; \
                                fi
                            '''
                        }
                    }
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
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=2401048-food \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000 \
                              -Dsonar.token=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Login to Nexus Registry') {
            steps {
                container('dind') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh '''
                            docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 \
                              -u $NEXUS_USER -p $NEXUS_PASS
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
                        kubectl create namespace 2401048 || true
                        kubectl get ns
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        ls -la k8s

                        kubectl apply -f k8s/deployment.yaml -n 2401048
                        kubectl apply -f k8s/service.yaml -n 2401048

                        kubectl rollout status deployment/food-ordering-deployment -n 2401048
                    '''
                }
            }
        }

        stage('Debug Pods') {
            steps {
                container('kubectl') {
                    sh '''
                        echo "Listing pods:"
                        kubectl get pods -n 2401048

                        echo "Describing pod:"
                        POD=$(kubectl get pods -n 2401048 -o jsonpath="{.items[0].metadata.name}")
                        kubectl describe pod $POD -n 2401048 | head -n 300
                    '''
                }
            }
        }

    }
}
