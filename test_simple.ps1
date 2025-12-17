# Test simple des endpoints Department

$baseUrl = "http://127.0.0.1:41607/student"

Write-Host "Test GET..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/getAllDepartment" -Method Get
    Write-Host "GET reussi!" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "Erreur GET: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest POST..." -ForegroundColor Yellow
$department = @{
    name = "IT"
    location = "Building A"
    phone = "+21671840840"
    head = "Dr. Ahmed"
}

$jsonBody = $department | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/createDepartment" -Method Post -Body $jsonBody -ContentType "application/json"
    Write-Host "POST reussi!" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "Erreur POST: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

Write-Host "`nVerification GET..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/Department/getAllDepartment" -Method Get
    $response | ConvertTo-Json
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}


