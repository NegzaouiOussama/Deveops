# Script Jenkins Pipeline Final avec SonarQube

## Script Complet à Copier dans Jenkins

Copiez ce script dans le champ "Script" de votre job Jenkins :

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven3'
    }
    
    environment {
        MAVEN_HOME = "${tool 'Maven3'}"
        PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
        SONAR_HOST_URL = "http://172.29.114.102:9000"
        SONAR_TOKEN = "sqa_53a643aea3ccdbcedef2c73df0428a1d8397d01e"
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
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('MVN SONARQUBE') {
            steps {
                script {
                    sh """
                        mvn sonar:sonar \\
                            -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                            -Dsonar.login=${env.SONAR_TOKEN}
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline réussi avec succès!'
            echo "SonarQube Dashboard: ${env.SONAR_HOST_URL}/dashboard?id=tn.esprit:student-management"
        }
        failure {
            echo 'Pipeline a échoué!'
        }
    }
}
```

## Configuration

### Token SonarQube

- **Type** : Global Analysis Token
- **Nom** : jenkins-global
- **Token** : `sqa_53a643aea3ccdbcedef2c73df0428a1d8397d01e`
- **Avantage** : Peut analyser tous les projets dans SonarQube

### Projet SonarQube

- **Project key** : `tn.esprit:student-management`
- **Display name** : Student Management
- **URL** : http://localhost:9000/dashboard?id=tn.esprit:student-management

## Vérification

1. **Relancez le Pipeline Jenkins**
2. **Vérifiez dans SonarQube** : http://localhost:9000/projects
3. **Cliquez sur "Student Management"** pour voir les résultats

## Résultats Attendus

Après l'exécution, vous verrez dans SonarQube :
- **Bugs** détectés
- **Vulnerabilities** de sécurité
- **Code Smells**
- **Coverage** (couverture de code)
- **Duplications**

## Notes Importantes

- Le token global peut analyser tous les projets
- Le projet "Student Management" doit exister dans SonarQube
- L'IP `172.29.114.102` est l'IP de votre WSL (vérifiez avec `wsl hostname -I`)

