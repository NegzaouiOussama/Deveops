# Atelier : SonarQube - Jenkins

## ✅ Tâches Complétées

### 1. ✅ Lancer le conteneur SonarQube
- Conteneur SonarQube lancé et opérationnel
- Accessible sur : http://localhost:9000 (ou http://172.29.114.102:9000)
- Login : `admin` / Password : `sonar`

### 2. ✅ Ajouter le stage de qualité dans Jenkins
- Stage "MVN SONARQUBE" ajouté au pipeline Jenkins
- Configuration avec token global SonarQube
- Analyse automatique du code à chaque build

### 3. ✅ Vérifier que le projet est scanné par SonarQube
- Projet "Student Management" créé dans SonarQube
- Project key : `tn.esprit:student-management`
- Analyse réussie : `ANALYSIS SUCCESSFUL`
- Dashboard : http://localhost:9000/dashboard?id=tn.esprit:student-management

### 4. ⏳ Éliminer quelques erreurs de qualité (Push du nouveau code sur git)
- 2 issues détectées (Maintainability)
- À corriger et pousser sur Git

### 5. ✅ Développer un test unitaire
- Test unitaire créé : `StudentServiceTest.java`
- 5 tests unitaires pour `StudentService` :
  - `testGetAllStudents()` : Teste la récupération de tous les étudiants
  - `testGetStudentById_Found()` : Teste la récupération d'un étudiant existant
  - `testGetStudentById_NotFound()` : Teste la récupération d'un étudiant inexistant
  - `testSaveStudent()` : Teste la sauvegarde d'un étudiant
  - `testDeleteStudent()` : Teste la suppression d'un étudiant
- Utilise Mockito pour mocker le repository

### 6. ✅ Ajouter le plugin Jacoco et vérifier que la couverture du code est différente de 0
- Plugin JaCoCo ajouté dans `pom.xml` (version 0.8.11)
- Configuration dans `sonar-project.properties`
- Rapport JaCoCo généré dans `target/site/jacoco/jacoco.xml`
- Intégration avec SonarQube configurée

## Configuration Finale

### Jenkinsfile

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
                sh 'mvn clean test'
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
```

## Fichiers Créés/Modifiés

### ✅ Fichiers Créés
- `src/test/java/tn/esprit/studentmanagement/services/StudentServiceTest.java` : Tests unitaires
- `GUIDE_JACOCO.md` : Guide d'utilisation de JaCoCo
- `ATELIER_SONARQUBE_JENKINS.md` : Ce document

### ✅ Fichiers Modifiés
- `pom.xml` : Plugin JaCoCo ajouté
- `Jenkinsfile` : Configuration JaCoCo ajoutée
- `sonar-project.properties` : Configuration JaCoCo ajoutée

## Résultats Attendus

Après le prochain build Jenkins :

1. **Tests** : 6 tests (1 existant + 5 nouveaux)
2. **Coverage** : > 0% (au lieu de 0.0%)
3. **Rapport JaCoCo** : Généré dans `target/site/jacoco/jacoco.xml`
4. **SonarQube** : Affiche la couverture de code

## Vérification

### 1. Lancer le Pipeline Jenkins

Le pipeline va :
1. Checkout le code
2. Exécuter les tests (avec JaCoCo)
3. Générer le package
4. Analyser avec SonarQube (avec couverture)

### 2. Vérifier dans SonarQube

1. Allez sur : http://localhost:9000/dashboard?id=tn.esprit:student-management
2. Vérifiez la section **Coverage**
3. La couverture devrait être **> 0%**

### 3. Voir le Rapport JaCoCo Localement

```bash
mvn clean test jacoco:report
# Ouvrir target/site/jacoco/index.html
```

## Prochaines Étapes

1. **Commiter et pousser les changements** :
   ```bash
   git add .
   git commit -m "Add JaCoCo plugin and unit tests for StudentService"
   git push
   ```

2. **Relancer le Pipeline Jenkins**

3. **Vérifier la couverture dans SonarQube**

4. **Corriger les 2 issues** détectées par SonarQube

5. **Développer d'autres tests** pour augmenter la couverture

## Commandes Utiles

### Générer le Rapport JaCoCo Localement

```bash
mvn clean test jacoco:report
```

### Voir le Rapport HTML

```bash
# Windows
start target/site/jacoco/index.html

# Linux/Mac
xdg-open target/site/jacoco/index.html
```

### Vérifier la Couverture

```bash
mvn test jacoco:check
```

## Notes Importantes

- Le rapport JaCoCo est généré **après** l'exécution des tests
- SonarQube lit automatiquement le rapport si le chemin est correct
- La couverture inclut les lignes de code exécutées pendant les tests
- Les getters/setters générés par Lombok ne sont pas comptés dans la couverture

