$ErrorActionPreference = "Stop"
$BaseUrl = "http://localhost:4010"
$AuthHeader = "Authorization: Bearer test-token"

Write-Host "[1/5] Happy path: GET /health"
curl.exe -i "$BaseUrl/health"

Write-Host "`n[2/5] Happy path: GET /alerts/recent"
curl.exe -i "$BaseUrl/alerts/recent" -H $AuthHeader

Write-Host "`n[3/5] Happy path: POST /alerts"
# Dùng dấu ngoặc đơn để thoát các dấu ngoặc kép trong JSON
$json = '{\"sourceService\": \"core-business\", \"alertType\": \"UNAUTHORIZED_ACCESS\", \"severity\": \"HIGH\", \"message\": \"Phat hien truy cap\", \"relatedEventId\": \"0196fb3d-4ad7-7d1e-9f49-5d5148d2babc\"}'
curl.exe -i -X POST "$BaseUrl/alerts" -H $AuthHeader -H "Content-Type: application/json" -d "$json"

Write-Host "`n[4/5] Error case: GET /alerts/recent (No token)"
curl.exe -i "$BaseUrl/alerts/recent"

Write-Host "`n[5/5] Error case: POST /alerts (Invalid payload)"
$badJson = '{\"alertType\": 12345}'
curl.exe -i -X POST "$BaseUrl/alerts" -H $AuthHeader -H "Content-Type: application/json" -d "$badJson"