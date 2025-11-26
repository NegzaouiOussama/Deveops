# Vérification de la Configuration Docker pour Jenkins

## ✅ Configuration Appliquée

Vous avez :
1. ✅ Ajouté Jenkins au groupe docker : `sudo usermod -aG docker jenkins`
2. ✅ Redémarré Jenkins : `sudo systemctl restart jenkins`

## Vérification

### 1. Vérifier que Jenkins est dans le groupe docker

```bash
groups jenkins
```

Vous devriez voir `docker` dans la liste des groupes.

### 2. Tester Docker en tant que Jenkins

```bash
sudo su - jenkins -s /bin/bash
docker ps
```

Si ça fonctionne sans erreur, la configuration est correcte !

### 3. Vérifier les permissions du socket Docker

```bash
ls -la /var/run/docker.sock
```

Le groupe devrait être `docker` et les permissions `rw-rw----`.

## Script Jenkins Mis à Jour (SANS sudo)

Maintenant que Jenkins est dans le groupe docker, utilisez ce script :

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
                    sh 'docker stop ${env.DOCKER_IMAGE_NAME}-container || true'
                    sh 'docker rm ${env.DOCKER_IMAGE_NAME}-container || true'
                    
                    sh '''
                        docker run -d --name student-mysql \\
                            -e MYSQL_ROOT_PASSWORD=rootpassword \\
                            -e MYSQL_DATABASE=studentdb \\
                            -p 3306:3306 \\
                            mysql:8.0 || true
                    '''
                    
                    sh 'sleep 10'
                    
                    sh """
                        docker run -d --name ${env.DOCKER_IMAGE_NAME}-container \\
                            --link student-mysql:mysql \\
                            -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb?createDatabaseIfNotExist=true \\
                            -e SPRING_DATASOURCE_USERNAME=root \\
                            -e SPRING_DATASOURCE_PASSWORD=rootpassword \\
                            -p 8089:8089 \\
                            ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                    """
                }
            }
        }
        
        stage('Verify Container') {
            steps {
                script {
                    sh 'sleep 15'
                    sh """
                        docker ps | grep ${env.DOCKER_IMAGE_NAME}-container
                        docker logs --tail 50 ${env.DOCKER_IMAGE_NAME}-container
                    """
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
                sh 'docker logs ${env.DOCKER_IMAGE_NAME}-container || true'
            }
        }
    }
}
```

## Notes Importantes

1. **Plus besoin de sudo** : Toutes les commandes `docker` fonctionnent directement
2. **Plus besoin de mot de passe** : Jenkins peut utiliser Docker sans authentification
3. **Plus sécurisé** : Pas de mot de passe en clair dans le script

## Si ça ne fonctionne toujours pas

### Option 1 : Vérifier que Jenkins a bien les nouveaux groupes

Parfois, il faut se déconnecter/reconnecter pour que les nouveaux groupes soient pris en compte. Redémarrez Jenkins :

```bash
sudo systemctl restart jenkins
```

### Option 2 : Vérifier les permissions du socket Docker

```bash
sudo chmod 666 /var/run/docker.sock
# OU mieux :
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock
```

### Option 3 : Vérifier que le groupe docker existe

```bash
getent group docker
```

Vous devriez voir quelque chose comme : `docker:x:999:jenkins`

## Test Rapide

Pour tester rapidement si Jenkins peut utiliser Docker :

```bash
sudo -u jenkins docker ps
```

Si cette commande fonctionne, alors le script Jenkins fonctionnera aussi !

