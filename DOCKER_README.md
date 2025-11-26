# Guide Docker pour Student Management

Ce guide explique comment construire et exécuter l'application Student Management avec Docker.

## Prérequis

- Docker installé
- Docker Compose installé (optionnel, pour docker-compose.yml)

## Méthode 1 : Docker Compose (Recommandé)

### Démarrer l'application complète (App + MySQL)

```bash
docker-compose up -d
```

Cette commande va :
- Démarrer MySQL dans un conteneur
- Construire l'image Docker de l'application
- Démarrer l'application Spring Boot
- Créer automatiquement le réseau et les volumes

### Voir les logs

```bash
# Logs de tous les services
docker-compose logs -f

# Logs de l'application seulement
docker-compose logs -f student-management

# Logs de MySQL seulement
docker-compose logs -f mysql
```

### Arrêter l'application

```bash
docker-compose down
```

### Arrêter et supprimer les volumes (supprime la base de données)

```bash
docker-compose down -v
```

## Méthode 2 : Docker seul

### Étape 1 : Construire l'image

```bash
docker build -t student-management:latest .
```

### Étape 2 : Démarrer MySQL (si pas déjà démarré)

```bash
docker run -d \
  --name student-mysql \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=studentdb \
  -p 3306:3306 \
  mysql:8.0
```

### Étape 3 : Démarrer l'application

```bash
docker run -d \
  --name student-management-app \
  -p 8089:8089 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://host.docker.internal:3306/studentdb \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=rootpassword \
  --link student-mysql:mysql \
  student-management:latest
```

## Accéder à l'application

Une fois démarrée, l'application est accessible à :
- **URL** : http://localhost:8089/student
- **Swagger UI** : http://localhost:8089/student/swagger-ui.html
- **API Docs** : http://localhost:8089/student/v3/api-docs

## Commandes utiles

### Voir les conteneurs en cours d'exécution

```bash
docker ps
```

### Voir les logs de l'application

```bash
docker logs -f student-management-app
```

### Arrêter l'application

```bash
docker stop student-management-app
```

### Redémarrer l'application

```bash
docker start student-management-app
```

### Supprimer le conteneur

```bash
docker rm student-management-app
```

### Supprimer l'image

```bash
docker rmi student-management:latest
```

### Entrer dans le conteneur

```bash
docker exec -it student-management-app sh
```

## Variables d'environnement

Vous pouvez personnaliser la configuration avec des variables d'environnement :

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `SPRING_DATASOURCE_URL` | URL de la base de données | `jdbc:mysql://mysql:3306/studentdb` |
| `SPRING_DATASOURCE_USERNAME` | Nom d'utilisateur MySQL | `root` |
| `SPRING_DATASOURCE_PASSWORD` | Mot de passe MySQL | `rootpassword` |
| `SPRING_JPA_HIBERNATE_DDL_AUTO` | Mode Hibernate | `update` |
| `SPRING_JPA_SHOW_SQL` | Afficher les requêtes SQL | `true` |

## Exemple avec variables personnalisées

```bash
docker run -d \
  --name student-management-app \
  -p 8089:8089 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb \
  -e SPRING_DATASOURCE_USERNAME=myuser \
  -e SPRING_DATASOURCE_PASSWORD=mypassword \
  student-management:latest
```

## Dépannage

### L'application ne démarre pas

1. Vérifier que MySQL est démarré et accessible
2. Vérifier les logs : `docker logs student-management-app`
3. Vérifier que le port 8089 n'est pas déjà utilisé

### Erreur de connexion à MySQL

1. Vérifier que MySQL est démarré : `docker ps`
2. Vérifier les variables d'environnement
3. Vérifier que les conteneurs sont sur le même réseau (avec docker-compose)

### Reconstruire l'image

```bash
docker-compose build --no-cache
```

## Structure des fichiers Docker

- **Dockerfile** : Définit comment construire l'image Docker
- **docker-compose.yml** : Orchestration de l'application et MySQL
- **.dockerignore** : Fichiers à exclure lors de la construction
- **application-docker.properties** : Configuration Spring Boot pour Docker

## Optimisations

Le Dockerfile utilise un build multi-stage pour :
- ✅ Réduire la taille de l'image finale
- ✅ Séparer les dépendances de build et d'exécution
- ✅ Utiliser une image JRE plus légère pour l'exécution

## Sécurité

- L'application s'exécute avec un utilisateur non-root
- Les mots de passe doivent être changés en production
- Utiliser des secrets Docker pour les informations sensibles

