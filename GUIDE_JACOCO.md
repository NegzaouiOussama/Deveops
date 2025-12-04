# Guide : Configuration JaCoCo pour la Couverture de Code

## Objectif

Ajouter le plugin JaCoCo pour mesurer la couverture de code et l'intégrer avec SonarQube.

## Modifications Effectuées

### 1. Plugin JaCoCo dans pom.xml ✅

Le plugin JaCoCo a été ajouté dans la section `<plugins>` :

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <id>prepare-agent</id>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### 2. Test Unitaire Créé ✅

Un test unitaire complet pour `StudentService` a été créé :
- **Fichier** : `src/test/java/tn/esprit/studentmanagement/services/StudentServiceTest.java`
- **Tests** :
  - `testGetAllStudents()` : Teste la récupération de tous les étudiants
  - `testGetStudentById_Found()` : Teste la récupération d'un étudiant existant
  - `testGetStudentById_NotFound()` : Teste la récupération d'un étudiant inexistant
  - `testSaveStudent()` : Teste la sauvegarde d'un étudiant
  - `testDeleteStudent()` : Teste la suppression d'un étudiant

### 3. Jenkinsfile Mis à Jour ✅

- Stage **Test** : Utilise `mvn clean test` pour générer le rapport JaCoCo
- Stage **MVN SONARQUBE** : Configure le chemin du rapport JaCoCo pour SonarQube

### 4. sonar-project.properties Mis à Jour ✅

Ajout de la configuration pour le rapport JaCoCo :
```properties
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

## Comment Ça Fonctionne

1. **Lors de `mvn test`** :
   - JaCoCo instrumente le code Java
   - Les tests s'exécutent
   - JaCoCo collecte les données de couverture
   - Le rapport est généré dans `target/site/jacoco/jacoco.xml`

2. **Lors de `mvn sonar:sonar`** :
   - SonarQube lit le rapport JaCoCo
   - La couverture de code est affichée dans SonarQube

## Vérification

### 1. Exécuter les Tests Localement

```bash
mvn clean test
```

### 2. Voir le Rapport JaCoCo

Le rapport HTML est généré dans : `target/site/jacoco/index.html`

Ouvrez ce fichier dans votre navigateur pour voir :
- **Coverage** : Pourcentage de code couvert
- **Missed Instructions** : Instructions non couvertes
- **Covered Instructions** : Instructions couvertes

### 3. Vérifier dans SonarQube

Après avoir lancé le pipeline Jenkins :
1. Allez sur : http://localhost:9000/dashboard?id=tn.esprit:student-management
2. Vérifiez la section **Coverage**
3. La couverture devrait être **> 0%**

## Résultats Attendus

Après l'exécution du pipeline :
- ✅ **Coverage** : > 0% (au lieu de 0.0%)
- ✅ **Tests** : 6 tests (1 test existant + 5 nouveaux tests)
- ✅ **Rapport JaCoCo** : Généré dans `target/site/jacoco/`

## Commandes Utiles

### Générer le Rapport JaCoCo

```bash
mvn clean test jacoco:report
```

### Voir le Rapport HTML

```bash
# Sur Windows
start target/site/jacoco/index.html

# Sur Linux/Mac
xdg-open target/site/jacoco/index.html
```

### Vérifier la Couverture

```bash
mvn test jacoco:check
```

## Prochaines Étapes

1. **Relancer le Pipeline Jenkins**
2. **Vérifier dans SonarQube** que la couverture est > 0%
3. **Développer d'autres tests unitaires** pour augmenter la couverture
4. **Corriger les issues** détectées par SonarQube

## Notes Importantes

- Le rapport JaCoCo est généré **après** l'exécution des tests
- SonarQube lit automatiquement le rapport si le chemin est correct
- La couverture inclut les lignes de code exécutées pendant les tests
- Les getters/setters générés par Lombok ne sont pas comptés dans la couverture

