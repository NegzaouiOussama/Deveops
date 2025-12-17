# Commandes pour Tester les Endpoints Department

## 📋 Endpoints Disponibles

L'application est accessible sur : **http://127.0.0.1:41607/student**

### Endpoints Department :
- **GET** `/Department/getAllDepartment` - Récupérer tous les départements
- **GET** `/Department/getDepartment/{id}` - Récupérer un département par ID
- **POST** `/Department/createDepartment` - Créer un nouveau département
- **PUT** `/Department/updateDepartment` - Mettre à jour un département
- **DELETE** `/Department/deleteDepartment/{id}` - Supprimer un département

## 🚀 Commandes de Test (à exécuter dans WSL)

### 1. Vérifier que l'endpoint GET fonctionne (doit retourner `[]` si vide)

```bash
curl -X GET "http://127.0.0.1:41607/student/Department/getAllDepartment" \
  -H "Content-Type: application/json"
```

### 2. Créer un département (POST)

```bash
curl -X POST "http://127.0.0.1:41607/student/Department/createDepartment" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Informatique",
    "location": "Bâtiment A, Étage 2",
    "phone": "+216 71 840 840",
    "head": "Dr. Ahmed Ben Ali"
  }'
```

### 3. Créer un deuxième département

```bash
curl -X POST "http://127.0.0.1:41607/student/Department/createDepartment" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Génie Civil",
    "location": "Bâtiment B, Étage 1",
    "phone": "+216 71 840 841",
    "head": "Dr. Fatma Trabelsi"
  }'
```

### 4. Vérifier que les départements sont créés

```bash
curl -X GET "http://127.0.0.1:41607/student/Department/getAllDepartment" \
  -H "Content-Type: application/json" | jq .
```

### 5. Récupérer un département par ID (remplacez 1 par l'ID réel)

```bash
curl -X GET "http://127.0.0.1:41607/student/Department/getDepartment/1" \
  -H "Content-Type: application/json" | jq .
```

### 6. Mettre à jour un département (PUT)

```bash
curl -X PUT "http://127.0.0.1:41607/student/Department/updateDepartment" \
  -H "Content-Type: application/json" \
  -d '{
    "idDepartment": 1,
    "name": "Informatique et Réseaux",
    "location": "Bâtiment A, Étage 2",
    "phone": "+216 71 840 842",
    "head": "Dr. Ahmed Ben Ali"
  }'
```

### 7. Supprimer un département (remplacez 1 par l'ID réel)

```bash
curl -X DELETE "http://127.0.0.1:41607/student/Department/deleteDepartment/1" \
  -H "Content-Type: application/json"
```

## 🎯 Structure JSON d'un Department

```json
{
  "idDepartment": 1,        // Auto-généré, optionnel pour POST
  "name": "Informatique",
  "location": "Bâtiment A, Étage 2",
  "phone": "+216 71 840 840",
  "head": "Dr. Ahmed Ben Ali"
}
```

## 📝 Exemple Complet de Test

```bash
# 1. Vérifier l'état initial (doit être vide)
curl -X GET "http://127.0.0.1:41607/student/Department/getAllDepartment"

# 2. Créer un département
curl -X POST "http://127.0.0.1:41607/student/Department/createDepartment" \
  -H "Content-Type: application/json" \
  -d '{"name":"Informatique","location":"Bâtiment A","phone":"+216 71 840 840","head":"Dr. Ahmed"}'

# 3. Vérifier que le département est créé
curl -X GET "http://127.0.0.1:41607/student/Department/getAllDepartment" | jq .
```

## 🌐 Test via le Navigateur

Vous pouvez aussi tester via le navigateur :

- **GET** : http://127.0.0.1:41607/student/Department/getAllDepartment
- **Swagger UI** : http://127.0.0.1:41607/student/swagger-ui.html

## 🔧 Utiliser le Script de Test Automatique

Si vous avez créé le script `test_department_api.sh` :

```bash
# Rendre le script exécutable
chmod +x test_department_api.sh

# Exécuter le script
./test_department_api.sh
```

## ⚠️ Note

Si vous obtenez une erreur de connexion, vérifiez que :
1. Le tunnel Minikube est toujours actif (gardez le terminal ouvert)
2. L'application est déployée et fonctionne : `kubectl get pods -n devops`
3. Les logs de l'application : `kubectl logs -l app=student-management -n devops --tail=50`


