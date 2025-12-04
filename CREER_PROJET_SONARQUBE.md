# Créer le Projet dans SonarQube

## Étape 1 : Accéder à SonarQube

1. Ouvrez votre navigateur
2. Allez sur : **http://localhost:9000** (ou http://172.29.114.102:9000)
3. Connectez-vous avec :
   - **Login** : `admin`
   - **Password** : `admin` (première fois), puis changez à `sonar`

## Étape 2 : Créer le Projet

1. Dans SonarQube, cliquez sur **Projects** (en haut)
2. Cliquez sur **Create Project** (bouton en haut à droite)
3. Choisissez **Manually**
4. Remplissez les champs :
   - **Project key** : `tn.esprit:student-management`
   - **Display name** : `Student Management`
5. Cliquez sur **Set Up**

## Étape 3 : Vérifier le Projet

Après création, vous devriez voir :
- Le projet "Student Management" dans la liste des projets
- La clé du projet : `tn.esprit:student-management`

## Étape 4 : Relancer le Pipeline Jenkins

1. Retournez dans Jenkins
2. Relancez votre pipeline
3. Le stage "MVN SONARQUBE" devrait maintenant réussir

## Vérification

### Dans SonarQube :
- URL : http://localhost:9000/projects
- Vous devriez voir "Student Management"

### Dans Jenkins :
- Le pipeline devrait se terminer avec succès
- Les résultats de l'analyse apparaîtront dans SonarQube

## Notes Importantes

- **Project key** : Doit être exactement `tn.esprit:student-management` (correspond au groupId:artifactId du pom.xml)
- **Token** : Le token actuel (`sqp_8dc68dea51a4ba5983fee4be1be10c4266e6ef4d`) est de type "Project" et lié à "Deveops"
  - Si vous avez des problèmes, créez un **Global Analysis Token** dans SonarQube → My Account → Security

## Alternative : Utiliser un Token Global

Si vous voulez analyser plusieurs projets avec le même token :

1. **My Account** → **Security**
2. **Generate Tokens** :
   - **Name** : `jenkins-global`
   - **Type** : **Global Analysis Token**
   - **Generate**
3. Copiez le nouveau token
4. Mettez à jour le `Jenkinsfile` avec le nouveau token

