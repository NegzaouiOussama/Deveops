# Créer un Token Global SonarQube

## Problème

Le token actuel est de type "Project" et lié uniquement à "Deveops". Il ne peut pas analyser le projet "Student Management".

## Solution : Créer un Token Global

Un token global peut analyser **tous les projets** dans SonarQube.

## Étapes

### 1. Accéder à SonarQube

1. Ouvrez : **http://localhost:9000**
2. Connectez-vous : `admin` / `sonar`

### 2. Créer le Token Global

1. Cliquez sur votre **avatar** (icône "A" en haut à droite)
2. Cliquez sur **My Account**
3. Allez dans l'onglet **Security**
4. Dans la section **Generate Tokens** :
   - **Name** : `jenkins-global`
   - **Type** : Sélectionnez **Global Analysis Token** (ou laissez "User Token")
   - **Expires in** : 30 days (ou No expiration)
   - Cliquez sur **Generate**

### 3. Copier le Token

⚠️ **IMPORTANT** : Copiez le token immédiatement ! Vous ne pourrez plus le voir après.

Le token ressemblera à : `sqp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### 4. Mettre à jour le Jenkinsfile

Remplacez le token dans le `Jenkinsfile` :

```groovy
environment {
    SONAR_TOKEN = "votre-nouveau-token-global"
}
```

### 5. Relancer le Pipeline

Le pipeline devrait maintenant fonctionner avec tous les projets.

## Avantages du Token Global

- ✅ Peut analyser **tous les projets** dans SonarQube
- ✅ Pas besoin de créer un token pour chaque projet
- ✅ Plus flexible et facile à gérer
- ✅ Fonctionne pour les projets futurs automatiquement

## Vérification

1. **Relancez le Pipeline Jenkins**
2. **Vérifiez dans SonarQube** : http://localhost:9000/projects
3. **Les résultats** apparaîtront sous "Student Management"

## Note

Le fichier `sonar-project.properties` a été remis à `tn.esprit:student-management` pour utiliser le projet "Student Management" que vous avez créé dans SonarQube.

