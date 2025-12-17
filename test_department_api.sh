#!/bin/bash

# Script de test pour les endpoints Department
# URL de base de l'application
BASE_URL="http://127.0.0.1:41607/student"

echo "========================================="
echo "Test des endpoints Department"
echo "========================================="
echo ""

# 1. Test GET - Récupérer tous les départements (doit être vide au début)
echo "1. GET - Récupérer tous les départements :"
echo "URL: ${BASE_URL}/Department/getAllDepartment"
curl -X GET "${BASE_URL}/Department/getAllDepartment" \
  -H "Content-Type: application/json" \
  -w "\n\nHTTP Status: %{http_code}\n"
echo ""
echo "----------------------------------------"
echo ""

# 2. Test POST - Créer un département
echo "2. POST - Créer un département :"
echo "URL: ${BASE_URL}/Department/createDepartment"
DEPARTMENT_JSON='{
  "name": "Informatique",
  "location": "Bâtiment A, Étage 2",
  "phone": "+216 71 840 840",
  "head": "Dr. Ahmed Ben Ali"
}'

echo "Données envoyées:"
echo "$DEPARTMENT_JSON" | jq .
echo ""

RESPONSE=$(curl -X POST "${BASE_URL}/Department/createDepartment" \
  -H "Content-Type: application/json" \
  -d "$DEPARTMENT_JSON" \
  -w "\nHTTP Status: %{http_code}" \
  -s)

echo "Réponse:"
echo "$RESPONSE" | head -n -1 | jq . 2>/dev/null || echo "$RESPONSE" | head -n -1
echo "HTTP Status: $(echo "$RESPONSE" | tail -n 1)"
echo ""
echo "----------------------------------------"
echo ""

# 3. Test GET - Vérifier que le département a été créé
echo "3. GET - Vérifier que le département est créé :"
curl -X GET "${BASE_URL}/Department/getAllDepartment" \
  -H "Content-Type: application/json" \
  -w "\n\nHTTP Status: %{http_code}\n" | jq .
echo ""
echo "----------------------------------------"
echo ""

# 4. Test POST - Créer un deuxième département
echo "4. POST - Créer un deuxième département :"
DEPARTMENT_JSON2='{
  "name": "Génie Civil",
  "location": "Bâtiment B, Étage 1",
  "phone": "+216 71 840 841",
  "head": "Dr. Fatma Trabelsi"
}'

curl -X POST "${BASE_URL}/Department/createDepartment" \
  -H "Content-Type: application/json" \
  -d "$DEPARTMENT_JSON2" \
  -w "\n\nHTTP Status: %{http_code}\n" | jq .
echo ""
echo "----------------------------------------"
echo ""

# 5. Test GET final - Vérifier tous les départements
echo "5. GET - Liste finale de tous les départements :"
curl -X GET "${BASE_URL}/Department/getAllDepartment" \
  -H "Content-Type: application/json" \
  -w "\n\nHTTP Status: %{http_code}\n" | jq .
echo ""

echo "========================================="
echo "Tests terminés !"
echo "========================================="


