# Script Jenkins Docker - Version Finale Corrigée

## Script Corrigé (Sans erreur de substitution)

Copiez ce script dans Jenkins :

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven3'
    }
    
    environment {
        MAVEN_HOME = "${tool 'Maven3'}"
        PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
        DOCKER_IMAGE_NAME = "student-management"
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/NegzaouiOussama/Deveops.git'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} .
                        docker tag ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ${env.DOCKER_IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Run Docker Container') {
            steps {
                script {
                    def imageName = env.DOCKER_IMAGE_NAME
                    def imageTag = env.DOCKER_IMAGE_TAG
                    
                    sh "docker stop ${imageName}-container || true"
                    sh "docker rm ${imageName}-container || true"
                    
                    sh '''
                        docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=0000 \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    '''
                    
                    sh 'sleep 10'
                    
                    sh """
                        docker run -d --name ${imageName}-container \\
                            --link student-mysql:mysql \\
                            -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb?createDatabaseIfNotExist=true \\
                            -e SPRING_DATASOURCE_USERNAME=root \\
                            -e SPRING_DATASOURCE_PASSWORD=0000 \\
                            -p 8089:8089 \\
                            ${imageName}:${imageTag}
                    """
                }
            }
        }
        
        stage('Verify Container') {
            steps {
                script {
                    def imageName = env.DOCKER_IMAGE_NAME
                    sh 'sleep 15'
                    sh "docker ps | grep ${imageName}-container || true"
                    sh "docker logs --tail 50 ${imageName}-container || true"
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
            echo "Image Docker: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
            echo "Application: http://localhost:8089/student"
        }
        failure {
            echo 'Pipeline a échoué!'
            script {
                sh "docker logs ${env.DOCKER_IMAGE_NAME}-container || true"
            }
        }
    }
}
```

## Changements Principaux

1. **Variables locales** : Utilisation de `def imageName = env.DOCKER_IMAGE_NAME` pour éviter les erreurs de substitution
2. **Mot de passe MySQL** : Changé de `rootpassword` à `0000`
3. **Gestion d'erreurs** : Ajout de `|| true` pour éviter les échecs si les conteneurs n'existent pas

## Alternative : Script Simplifié

Si vous préférez une version plus simple :

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven3'
    }
    
    environment {
        MAVEN_HOME = "${tool 'Maven3'}"
        PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/NegzaouiOussama/Deveops.git'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t student-management:${BUILD_NUMBER} .'
                sh 'docker tag student-management:${BUILD_NUMBER} student-management:latest'
            }
        }
        
        stage('Run Docker Container') {
            steps {
                script {
                    sh 'docker stop student-management-container || true'
                    sh 'docker rm student-management-container || true'
                    
                    sh '''
                        docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=0000 \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    '''
                    
                    sh 'sleep 10'
                    
                    sh '''
                        docker run -d --name student-management-container \\
                            --link student-mysql:mysql \\
                            -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb?createDatabaseIfNotExist=true \\
                            -e SPRING_DATASOURCE_USERNAME=root \\
                            -e SPRING_DATASOURCE_PASSWORD=0000 \\
                            -p 8089:8089 \\
                            student-management:latest
                    '''
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            cleanWs()
        }
        success {
            echo 'Pipeline réussi avec succès!'
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Configuration MySQL

- **Mot de passe root** : `0000` (comme spécifié)
- **Base de données** : `studentdb`
- **Port** : `3306`

Le script devrait maintenant fonctionner sans erreur de substitution !

