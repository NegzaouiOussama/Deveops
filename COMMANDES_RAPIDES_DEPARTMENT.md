# Commandes Rapides pour Tester Department API

## 🎯 URLs des Endpoints

- **Base URL** : `http://127.0.0.1:41607/student`
- **GET All** : `http://127.0.0.1:41607/student/Department/getAllDepartment`
- **POST Create** : `http://127.0.0.1:41607/student/Department/createDepartment`

## 📝 Dans WSL (Bash)

### Créer un département
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

### Récupérer tous les départements
```bash
curl -X GET "http://127.0.0.1:41607/student/Department/getAllDepartment" | jq .
```

## 💻 Dans PowerShell (Windows)

### Créer un département
```powershell
$body = @{
    name = "Informatique"
    location = "Bâtiment A, Étage 2"
    phone = "+216 71 840 840"
    head = "Dr. Ahmed Ben Ali"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:41607/student/Department/createDepartment" `
  -Method Post -Body $body -ContentType "application/json" | ConvertTo-Json
```

### Récupérer tous les départements
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:41607/student/Department/getAllDepartment" `
  -Method Get | ConvertTo-Json
```

## 🌐 Dans le Navigateur

Ouvrez simplement cette URL dans votre navigateur :
- **GET All** : http://127.0.0.1:41607/student/Department/getAllDepartment
- **Swagger UI** : http://127.0.0.1:41607/student/swagger-ui.html

## ⚡ Commandes Ultra-Rapides (WSL)

```bash
# Créer un département
curl -X POST http://127.0.0.1:41607/student/Department/createDepartment -H "Content-Type: application/json" -d '{"name":"Informatique","location":"Bâtiment A","phone":"+216 71 840 840","head":"Dr. Ahmed"}'

# Vérifier
curl http://127.0.0.1:41607/student/Department/getAllDepartment | jq .
```


