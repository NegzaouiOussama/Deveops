# Comment Voir les Résultats de l'Application

## 1. Vérifier les Conteneurs Docker

### Dans WSL, exécutez :

```bash
# Voir tous les conteneurs en cours d'exécution
docker ps

# Vous devriez voir :
# - student-mysql (port 3306)
# - student-management-container (port 8089)
```

## 2. Accéder à l'Application

### Depuis votre navigateur :

- **Application principale** : http://localhost:8089/student
- **Swagger UI** (Documentation API) : http://localhost:8089/student/swagger-ui.html
- **API Docs JSON** : http://localhost:8089/student/v3/api-docs

## 3. Voir les Logs de l'Application

### Dans WSL :

```bash
# Logs de l'application Spring Boot
docker logs student-management-container

# Logs en temps réel (suivre les nouveaux logs)
docker logs -f student-management-container

# Dernières 50 lignes
docker logs --tail 50 student-management-container
```

### Logs de MySQL :

```bash
docker logs student-mysql
docker logs -f student-mysql
```

## 4. Tester les Endpoints API

### Avec curl (dans WSL) :

```bash
# Tester la liste des étudiants
curl http://localhost:8089/student/students/getAllStudents

# Tester la liste des départements
curl http://localhost:8089/student/Department/getAllDepartment

# Tester la liste des inscriptions
curl http://localhost:8089/student/Enrollment/getAllEnrollment
```

### Avec le navigateur :

Ouvrez directement dans votre navigateur :
- http://localhost:8089/student/students/getAllStudents
- http://localhost:8089/student/Department/getAllDepartment

## 5. Voir les Résultats dans Jenkins

### Dans Jenkins :

1. **Aller dans votre job** : `Doc-Negzaoui`
2. **Cliquer sur le dernier build** (celui qui a réussi)
3. **Voir les sections** :
   - **Console Output** : Tous les logs d'exécution
   - **Test Result** : Résultats des tests JUnit
   - **Artifacts** : Le fichier JAR généré

## 6. Vérifier l'État des Conteneurs

### Commandes utiles :

```bash
# Voir tous les conteneurs (actifs et arrêtés)
docker ps -a

# Voir l'utilisation des ressources
docker stats

# Voir les images Docker
docker images

# Voir les réseaux Docker
docker network ls

# Inspecter un conteneur
docker inspect student-management-container
```

## 7. Tester la Base de Données MySQL

### Se connecter à MySQL :

```bash
# Entrer dans le conteneur MySQL
docker exec -it student-mysql mysql -uroot -p0000

# Dans MySQL, exécuter :
USE studentdb;
SHOW TABLES;
SELECT * FROM student;
SELECT * FROM department;
SELECT * FROM course;
SELECT * FROM enrollment;
EXIT;
```

## 8. Interface Swagger (Recommandé)

### Accéder à Swagger UI :

1. Ouvrez votre navigateur
2. Allez sur : **http://localhost:8089/student/swagger-ui.html**
3. Vous verrez :
   - Toutes les APIs disponibles
   - Possibilité de tester les endpoints directement
   - Documentation complète

## 9. Vérifier que l'Application Fonctionne

### Test rapide :

```bash
# Vérifier que le conteneur répond
curl http://localhost:8089/student/actuator/health

# Ou dans le navigateur :
# http://localhost:8089/student/actuator/health
```

## 10. Commandes de Gestion

### Arrêter les conteneurs :

```bash
docker stop student-management-container
docker stop student-mysql
```

### Redémarrer les conteneurs :

```bash
docker start student-mysql
docker start student-management-container
```

### Supprimer les conteneurs :

```bash
docker stop student-management-container student-mysql
docker rm student-management-container student-mysql
```

### Voir les ports utilisés :

```bash
docker port student-management-container
docker port student-mysql
```

## Résumé des URLs Importantes

| Service | URL | Description |
|---------|-----|-------------|
| Application | http://localhost:8089/student | Page d'accueil |
| Swagger UI | http://localhost:8089/student/swagger-ui.html | Documentation API interactive |
| API Docs | http://localhost:8089/student/v3/api-docs | Documentation JSON |
| Health Check | http://localhost:8089/student/actuator/health | État de l'application |
| Étudiants | http://localhost:8089/student/students/getAllStudents | Liste des étudiants |
| Départements | http://localhost:8089/student/Department/getAllDepartment | Liste des départements |
| Inscriptions | http://localhost:8089/student/Enrollment/getAllEnrollment | Liste des inscriptions |

## Dépannage

### Si l'application ne répond pas :

1. Vérifier que les conteneurs sont en cours d'exécution :
   ```bash
   docker ps
   ```

2. Vérifier les logs :
   ```bash
   docker logs student-management-container
   ```

3. Vérifier que les ports ne sont pas déjà utilisés :
   ```bash
   netstat -tuln | grep 8089
   netstat -tuln | grep 3306
   ```

4. Redémarrer les conteneurs :
   ```bash
   docker restart student-management-container
   ```

