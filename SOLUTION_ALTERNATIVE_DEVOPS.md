# Solution Alternative : Utiliser le Projet "Deveops" Existant

## Problème

Le token SonarQube est de type "Project" et lié au projet "Deveops". Le projet "Student Management" n'existe pas dans SonarQube.

## Solution : Utiliser le Projet "Deveops"

Puisque le token est déjà configuré pour "Deveops", utilisons ce projet existant.

## Fichier Modifié

✅ **sonar-project.properties** : Clé du projet changée à `Deveops`

## Avantages

- ✅ Pas besoin de créer un nouveau projet dans SonarQube
- ✅ Le token actuel fonctionne immédiatement
- ✅ Solution rapide et simple

## Prochaines Étapes

1. **Relancez le Pipeline Jenkins**
2. **Vérifiez dans SonarQube** : http://localhost:9000/projects
3. **Les résultats** apparaîtront sous le projet "Deveops"

## Alternative : Créer un Token Global (Pour Plusieurs Projets)

Si vous voulez analyser plusieurs projets avec des clés différentes :

1. **SonarQube** → **My Account** → **Security**
2. **Generate Tokens** → **Type** : **Global Analysis Token**
3. **Name** : `jenkins-global`
4. **Generate** et copiez le token
5. Mettez à jour `SONAR_TOKEN` dans le Jenkinsfile
6. Remettez `sonar.projectKey=tn.esprit:student-management` dans `sonar-project.properties`

## Note

Le projet "Deveops" dans SonarQube contiendra maintenant les analyses du projet "Student Management". Si vous voulez séparer les projets, créez un token global et créez le projet "Student Management" dans SonarQube.

