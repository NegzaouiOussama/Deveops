# Solution : JaCoCo et SonarQube - Problème Résolu

## Problème Identifié

Dans les logs du pipeline, on peut voir :
```
[INFO] Sensor JaCoCo XML Report Importer [jacoco]
[INFO] 'sonar.coverage.jacoco.xmlReportPaths' is not defined. Using default locations: target/site/jacoco/jacoco.xml
[INFO] No report imported, no coverage information will be imported by JaCoCo XML Report Importer
```

**Cause** : Le rapport JaCoCo n'était pas disponible lors de l'analyse SonarQube car :
1. Le stage "Test" génère le rapport JaCoCo
2. Le stage "Package" fait `mvn clean package`, ce qui supprime le répertoire `target` et donc le rapport
3. Le stage "SonarQube" ne trouve pas le rapport car il a été supprimé

## Solution Appliquée

### 1. Ordre des Stages Modifié ✅

L'ordre des stages a été réorganisé :

1. **Checkout** : Récupération du code
2. **Test** : Exécution des tests avec JaCoCo (`mvn clean test`)
3. **Generate JaCoCo Report** : Génération du rapport JaCoCo (`mvn jacoco:report`)
4. **Package** : Build du JAR (`mvn package -DskipTests` - **sans `clean`**)
5. **MVN SONARQUBE** : Analyse avec SonarQube

### 2. Modifications dans Jenkinsfile

#### Avant :
```groovy
stage('Test') {
    steps {
        sh 'mvn clean test'
    }
}

stage('Package') {
    steps {
        sh 'mvn clean package -DskipTests'  // ❌ Supprime le rapport JaCoCo
    }
}

stage('MVN SONARQUBE') {
    // ❌ Rapport JaCoCo introuvable
}
```

#### Après :
```groovy
stage('Test') {
    steps {
        sh 'mvn clean test'  // Génère jacoco.exec
    }
}

stage('Generate JaCoCo Report') {
    steps {
        sh 'mvn jacoco:report'  // ✅ Génère target/site/jacoco/jacoco.xml
    }
}

stage('Package') {
    steps {
        sh 'mvn package -DskipTests'  // ✅ Sans 'clean' pour préserver le rapport
    }
}

stage('MVN SONARQUBE') {
    steps {
        sh """
            mvn sonar:sonar \\
                -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                -Dsonar.login=${env.SONAR_TOKEN} \\
                -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
        """
    }
}
```

## Comment Ça Fonctionne Maintenant

1. **Stage Test** :
   - Exécute `mvn clean test`
   - JaCoCo instrumente le code et collecte les données
   - Les données sont sauvegardées dans `target/jacoco.exec`

2. **Stage Generate JaCoCo Report** :
   - Exécute `mvn jacoco:report`
   - Lit `target/jacoco.exec`
   - Génère le rapport XML dans `target/site/jacoco/jacoco.xml`

3. **Stage Package** :
   - Exécute `mvn package -DskipTests` (sans `clean`)
   - Le rapport JaCoCo est préservé

4. **Stage SonarQube** :
   - Lit le rapport JaCoCo depuis `target/site/jacoco/jacoco.xml`
   - Affiche la couverture de code dans SonarQube

## Résultats Attendus

Après le prochain build :

✅ **Coverage** : > 0% dans SonarQube
✅ **Rapport JaCoCo** : Généré et disponible
✅ **Tests** : 6 tests (1 existant + 5 nouveaux)

## Vérification

1. **Relancer le Pipeline Jenkins**

2. **Vérifier dans les Logs** :
   ```
   [INFO] Sensor JaCoCo XML Report Importer [jacoco]
   [INFO] Importing 1 report(s)
   [INFO] Coverage information was loaded from 1 file
   ```

3. **Vérifier dans SonarQube** :
   - Allez sur : http://172.29.114.102:9000/dashboard?id=tn.esprit:student-management
   - Vérifiez la section **Coverage**
   - La couverture devrait être **> 0%**

## Notes Importantes

- Le stage "Test" fait `clean` pour un environnement propre
- Le stage "Package" ne fait **pas** `clean` pour préserver le rapport JaCoCo
- Le rapport JaCoCo est généré **après** les tests mais **avant** SonarQube
- Le fichier `target/jacoco.exec` contient les données brutes de couverture
- Le fichier `target/site/jacoco/jacoco.xml` est le rapport XML lisible par SonarQube

