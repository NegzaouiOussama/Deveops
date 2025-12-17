# Script PowerShell pour tester les endpoints Department

$baseUrl = "http://127.0.0.1:41607/student"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Test des endpoints Department" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Test GET - Récupérer tous les départements
Write-Host "1. GET - Récupérer tous les départements :" -ForegroundColor Yellow
Write-Host "URL: $baseUrl/Department/getAllDepartment" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/getAllDepartment" -Method Get -ContentType "application/json"
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# 2. Test POST - Créer un département
Write-Host "2. POST - Créer un département :" -ForegroundColor Yellow
Write-Host "URL: $baseUrl/Department/createDepartment" -ForegroundColor Gray

$department = @{
    name = "Informatique"
    location = "Bâtiment A, Étage 2"
    phone = "+216 71 840 840"
    head = "Dr. Ahmed Ben Ali"
} | ConvertTo-Json

Write-Host "Données envoyées:" -ForegroundColor Gray
$department
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/createDepartment" -Method Post -Body $department -ContentType "application/json"
    Write-Host "Réponse:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# 3. Test GET - Vérifier que le département a été créé
Write-Host "3. GET - Vérifier que le département est créé :" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/getAllDepartment" -Method Get -ContentType "application/json"
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# 4. Test POST - Créer un deuxième département
Write-Host "4. POST - Créer un deuxième département :" -ForegroundColor Yellow

$department2 = @{
    name = "Génie Civil"
    location = "Bâtiment B, Étage 1"
    phone = "+216 71 840 841"
    head = "Dr. Fatma Trabelsi"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/createDepartment" -Method Post -Body $department2 -ContentType "application/json"
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# 5. Test GET final
Write-Host "5. GET - Liste finale de tous les départements :" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/getAllDepartment" -Method Get -ContentType "application/json"
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Tests terminés !" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan


