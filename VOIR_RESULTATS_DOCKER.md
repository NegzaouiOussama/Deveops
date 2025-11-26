# Comment Voir les Résultats Docker

## 1. Voir les Images Docker Créées

### Dans WSL, exécutez :

```bash
# Voir toutes les images Docker
docker images

# Voir seulement les images de votre projet
docker images | grep student-management

# Voir les détails d'une image
docker image inspect student-management:latest
```

**Résultat attendu** :
```
REPOSITORY            TAG       IMAGE ID       CREATED         SIZE
student-management    latest    xxxxxx        2 minutes ago   200MB
student-management    15        xxxxxx        2 minutes ago   200MB
```

## 2. Voir les Conteneurs Docker

### Conteneurs en cours d'exécution :

```bash
# Voir tous les conteneurs actifs
docker ps

# Voir tous les conteneurs (actifs et arrêtés)
docker ps -a

# Voir seulement vos conteneurs
docker ps | grep student
```

**Résultat attendu** :
```
CONTAINER ID   IMAGE                        STATUS         PORTS                    NAMES
xxxxx          student-management:latest    Up 2 minutes   0.0.0.0:8089->8089/tcp  student-management-container
xxxxx          mysql:8.0                   Up 2 minutes   0.0.0.0:3306->3306/tcp  student-mysql
```

## 3. Voir les Logs des Conteneurs

### Logs de l'application :

```bash
# Voir tous les logs
docker logs student-management-container

# Voir les 50 dernières lignes
docker logs --tail 50 student-management-container

# Suivre les logs en temps réel
docker logs -f student-management-container

# Logs avec horodatage
docker logs -t student-management-container
```

### Logs de MySQL :

```bash
docker logs student-mysql
docker logs -f student-mysql
```

## 4. Voir l'Utilisation des Ressources

```bash
# Voir l'utilisation CPU, mémoire, etc.
docker stats

# Voir les stats d'un conteneur spécifique
docker stats student-management-container

# Stats sans rafraîchissement continu
docker stats --no-stream
```

## 5. Voir les Informations Détaillées

### Inspecter un conteneur :

```bash
# Informations complètes du conteneur
docker inspect student-management-container

# Informations au format JSON
docker inspect student-management-container --format='{{json .}}'

# Voir seulement la configuration réseau
docker inspect student-management-container | grep -A 20 NetworkSettings

# Voir les variables d'environnement
docker inspect student-management-container | grep -A 10 Env
```

### Inspecter une image :

```bash
# Informations de l'image
docker image inspect student-management:latest

# Voir l'historique de l'image
docker history student-management:latest

# Voir la taille de l'image
docker images student-management:latest
```

## 6. Voir les Ports Utilisés

```bash
# Voir les ports mappés d'un conteneur
docker port student-management-container

# Résultat attendu :
# 8089/tcp -> 0.0.0.0:8089

docker port student-mysql
# Résultat attendu :
# 3306/tcp -> 0.0.0.0:3306
```

## 7. Voir les Réseaux Docker

```bash
# Voir tous les réseaux
docker network ls

# Inspecter un réseau
docker network inspect bridge

# Voir les conteneurs connectés à un réseau
docker network inspect bridge | grep -A 10 Containers
```

## 8. Voir les Volumes Docker

```bash
# Voir tous les volumes
docker volume ls

# Inspecter un volume
docker volume inspect <volume-name>

# Voir l'utilisation de l'espace disque
docker system df
```

## 9. Commandes de Vérification Complètes

### Script de vérification rapide :

```bash
#!/bin/bash
echo "=== Images Docker ==="
docker images | grep student-management

echo ""
echo "=== Conteneurs Actifs ==="
docker ps | grep student

echo ""
echo "=== Tous les Conteneurs ==="
docker ps -a | grep student

echo ""
echo "=== Utilisation des Ressources ==="
docker stats --no-stream | grep student

echo ""
echo "=== Ports Utilisés ==="
docker port student-management-container 2>/dev/null || echo "Conteneur non trouvé"
docker port student-mysql 2>/dev/null || echo "MySQL non trouvé"

echo ""
echo "=== Logs Récents (Application) ==="
docker logs --tail 10 student-management-container 2>/dev/null || echo "Pas de logs"

echo ""
echo "=== Logs Récents (MySQL) ==="
docker logs --tail 10 student-mysql 2>/dev/null || echo "Pas de logs"
```

## 10. Voir dans Jenkins

### Dans l'interface Jenkins :

1. **Aller dans votre job** : `Doc-Negzaoui`
2. **Cliquer sur le build réussi**
3. **Dans "Console Output"**, cherchez les lignes :
   ```
   + docker build -t student-management:15 .
   + docker tag student-management:15 student-management:latest
   + docker run -d --name student-management-container ...
   ```

## 11. Commandes Utiles pour le Debugging

```bash
# Voir les processus dans un conteneur
docker top student-management-container

# Exécuter une commande dans le conteneur
docker exec student-management-container ps aux
docker exec student-management-container ls -la /app

# Entrer dans le conteneur (shell interactif)
docker exec -it student-management-container sh

# Voir les variables d'environnement du conteneur
docker exec student-management-container env

# Voir les fichiers dans le conteneur
docker exec student-management-container ls -la
```

## 12. Voir l'Historique des Builds

```bash
# Voir toutes les images avec leurs tags
docker images student-management --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}"

# Résultat attendu :
# REPOSITORY            TAG       CREATED AT              SIZE
# student-management    latest    2025-11-27 00:31:56     200MB
# student-management    15        2025-11-27 00:31:56     200MB
# student-management    14        2025-11-27 00:28:12     200MB
```

## 13. Vérifier que Tout Fonctionne

### Test complet :

```bash
# 1. Vérifier les images
echo "=== Images ==="
docker images | grep student-management

# 2. Vérifier les conteneurs
echo "=== Conteneurs ==="
docker ps | grep student

# 3. Vérifier les ports
echo "=== Ports ==="
netstat -tuln | grep 8089
netstat -tuln | grep 3306

# 4. Tester l'application
echo "=== Test Application ==="
curl http://localhost:8089/student/actuator/health || echo "Application non accessible"

# 5. Voir les logs
echo "=== Derniers Logs ==="
docker logs --tail 5 student-management-container
```

## Résumé des Commandes Essentielles

| Commande | Description |
|----------|-------------|
| `docker images` | Voir toutes les images |
| `docker ps` | Voir les conteneurs actifs |
| `docker ps -a` | Voir tous les conteneurs |
| `docker logs <container>` | Voir les logs |
| `docker stats` | Voir l'utilisation des ressources |
| `docker inspect <container>` | Informations détaillées |
| `docker port <container>` | Voir les ports mappés |
| `docker exec -it <container> sh` | Entrer dans le conteneur |

## Exemple de Sortie Attendue

```bash
$ docker images | grep student-management
student-management    latest    64fac4c4d045    2 minutes ago    200MB
student-management    15        64fac4c4d045    2 minutes ago    200MB

$ docker ps
CONTAINER ID   IMAGE                        STATUS         PORTS                    NAMES
a1b2c3d4e5f6   student-management:latest   Up 2 minutes   0.0.0.0:8089->8089/tcp  student-management-container
f6e5d4c3b2a1   mysql:8.0                   Up 2 minutes   0.0.0.0:3306->3306/tcp  student-mysql

$ docker logs --tail 5 student-management-container
2025-11-27 00:32:10.123  INFO --- Application started successfully
2025-11-27 00:32:10.456  INFO --- Server running on port 8089
```

