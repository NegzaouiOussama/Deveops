# Solution Rapide : Erreur SonarQube

## Problème Actuel

L'erreur indique que le projet `tn.esprit:student-management` n'existe pas dans SonarQube ou que le token n'a pas les permissions.

## Solution 1 : Créer le Projet dans SonarQube (Recommandé)

### Étapes :

1. **Ouvrez SonarQube** : http://localhost:9000
2. **Connectez-vous** : `admin` / `admin` (puis changez à `sonar`)
3. **Créez le Projet** :
   - Cliquez sur **Projects** (menu en haut)
   - Cliquez sur **Create Project** (bouton en haut à droite)
   - Choisissez **Manually**
   - **Project key** : `tn.esprit:student-management`
   - **Display name** : `Student Management`
   - Cliquez sur **Set Up**

4. **Relancez le Pipeline Jenkins**

## Solution 2 : Utiliser un Token Global (Plus Simple)

Le token actuel est de type "Project" et lié à "Deveops". Créez un token global qui peut analyser tous les projets :

### Étapes :

1. **Dans SonarQube** : http://localhost:9000
2. **My Account** (icône utilisateur en haut à droite) → **Security**
3. **Generate Tokens** :
   - **Name** : `jenkins-global`
   - **Type** : **Global Analysis Token** (ou laissez "User Token")
   - **Generate**
4. **Copiez le nouveau token**
5. **Mettez à jour le Jenkinsfile** avec le nouveau token
6. **Relancez le Pipeline**

## Solution 3 : Utiliser le Projet "Deveops" Existant

Si vous voulez utiliser le projet "Deveops" qui existe déjà :

### Option A : Modifier sonar-project.properties

Changez la clé du projet dans `sonar-project.properties` :

```properties
sonar.projectKey=Deveops
```

### Option B : Passer la clé en paramètre Maven

Modifiez le stage SonarQube dans le Jenkinsfile :

```groovy
stage('MVN SONARQUBE') {
    steps {
        script {
            sh """
                mvn sonar:sonar \\
                    -Dsonar.host.url=${env.SONAR_HOST_URL} \\
                    -Dsonar.login=${env.SONAR_TOKEN} \\
                    -Dsonar.projectKey=Deveops
            """
        }
    }
}
```

## Recommandation

**Solution 2 (Token Global)** est la plus simple et flexible :
- Un seul token pour tous les projets
- Pas besoin de créer des projets manuellement
- Fonctionne pour tous les projets futurs

## Vérification

Après avoir appliqué une solution :

1. **Relancez le Pipeline Jenkins**
2. **Vérifiez dans SonarQube** : http://localhost:9000/projects
3. **Les résultats de l'analyse** apparaîtront dans SonarQube

