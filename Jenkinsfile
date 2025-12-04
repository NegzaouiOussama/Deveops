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
                sh 'mvn clean test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    // Sauvegarder le fichier jacoco.exec pour le rapport
                    sh 'test -f target/jacoco.exec && echo "JaCoCo execution data saved" || echo "No JaCoCo execution data"'
                }
            }
        }
        
        stage('Generate JaCoCo Report') {
            steps {
                sh 'mvn jacoco:report'
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
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
                            -Dsonar.login=${env.SONAR_TOKEN} \\
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
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
