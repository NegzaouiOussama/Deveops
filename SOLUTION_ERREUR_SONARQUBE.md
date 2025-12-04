# Solution : Erreur SonarQube "You're not authorized to analyze this project"

## Problème

L'erreur indique :
```
You're not authorized to analyze this project or the project doesn't exist on SonarQube and you're not authorized to create it.
```

## Causes Possibles

1. **Le projet n'existe pas dans SonarQube** avec la clé `tn.esprit:student-management`
2. **Le token est de type "Project"** et est lié à un autre projet (Deveops)
3. **Le token n'a pas les permissions** pour créer ou analyser le projet

## Solutions

### Solution 1 : Créer le Projet dans SonarQube (Recommandé)

1. **Accéder à SonarQube** :
   - URL : http://localhost:9000 (ou http://172.29.114.102:9000)
   - Login : `admin` / Password : `sonar`

2. **Créer le Projet** :
   - Allez dans **Projects** → **Create Project**
   - Choisissez **Manually**
   - **Project key** : `tn.esprit:student-management`
   - **Display name** : `Student Management`
   - Cliquez sur **Set Up**

3. **Vérifier le Token** :
   - Le token actuel est de type "Project" et lié à "Deveops"
   - **Option A** : Utiliser un token global (Global Analysis Token)
   - **Option B** : Créer un nouveau token pour le projet "Student Management"

### Solution 2 : Utiliser un Token Global

1. **Créer un Token Global** :
   - Dans SonarQube : **My Account** → **Security**
   - **Generate Tokens** → **Type** : Sélectionnez **Global Analysis Token**
   - **Name** : `jenkins-global`
   - **Generate** et copiez le token

2. **Mettre à jour le Jenkinsfile** :
   ```groovy
   environment {
       SONAR_TOKEN = "votre-nouveau-token-global"
   }
   ```

### Solution 3 : Utiliser le Projet "Deveops" Existant

Si vous voulez utiliser le projet "Deveops" qui existe déjà :

1. **Mettre à jour sonar-project.properties** :
   ```properties
   sonar.projectKey=Deveops
   ```

2. **Ou passer la clé en paramètre Maven** :
   ```groovy
   sh """
       mvn sonar:sonar \\
           -Dsonar.host.url=${env.SONAR_HOST_URL} \\
           -Dsonar.login=${env.SONAR_TOKEN} \\
           -Dsonar.projectKey=Deveops
   """
   ```

## Solution Recommandée : Créer le Projet

### Étape 1 : Accéder à SonarQube

1. Ouvrez votre navigateur
2. Allez sur : **http://localhost:9000** (ou http://172.29.114.102:9000)
3. Connectez-vous avec :
   - **Login** : `admin`
   - **Password** : `admin` (première fois), puis changez à `sonar`

### Étape 2 : Créer le Projet dans SonarQube

1. Dans SonarQube, cliquez sur **Projects** (en haut)
2. Cliquez sur **Create Project** (bouton en haut à droite)
3. Choisissez **Manually**
4. Remplissez les champs :
   - **Project key** : `tn.esprit:student-management`
   - **Display name** : `Student Management`
5. Cliquez sur **Set Up**

### Étape 2 : Créer un Token Global (Optionnel mais Recommandé)

1. **My Account** → **Security**
2. **Generate Tokens** :
   - **Name** : `jenkins-global`
   - **Type** : **Global Analysis Token** (ou laissez "User Token")
   - **Generate**
3. Copiez le token

### Étape 3 : Mettre à jour le Jenkinsfile (si nouveau token)

Si vous avez créé un nouveau token global, mettez à jour :

```groovy
environment {
    SONAR_TOKEN = "votre-nouveau-token-global"
}
```

### Étape 4 : Relancer le Pipeline

Le pipeline devrait maintenant fonctionner.

## Vérification

Après avoir créé le projet, vous pouvez vérifier :

1. **Dans SonarQube** :
   - Allez sur : http://localhost:9000/projects
   - Vous devriez voir "Student Management"

2. **Relancer le Pipeline Jenkins** :
   - Le stage "MVN SONARQUBE" devrait réussir

## Fichiers Mis à Jour

✅ **sonar-project.properties** : Clé du projet mise à jour à `tn.esprit:student-management`

## Notes Importantes

- La clé du projet dans SonarQube doit correspondre à `tn.esprit:student-management`
- Un token de type "Project" ne peut analyser que le projet auquel il est lié
- Un token global peut analyser tous les projets
- Le token actuel est lié au projet "Deveops", donc il faut soit créer le projet "Student Management", soit utiliser un token global

