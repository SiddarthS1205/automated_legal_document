# Test API Endpoints
$apiEndpoint = "https://6zurbbpdfg.execute-api.us-east-1.amazonaws.com/dev"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Testing Legal Document Processing API" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: OPTIONS request to /upload (CORS preflight)
Write-Host "Test 1: CORS Preflight - OPTIONS /upload" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$apiEndpoint/upload" -Method OPTIONS -UseBasicParsing -ErrorAction Stop
    Write-Host "[PASS] Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "CORS Headers:" -ForegroundColor Gray
    $response.Headers.GetEnumerator() | Where-Object { $_.Key -like "*Access-Control*" } | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
    }
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Check if frontend is accessible
Write-Host "Test 2: Frontend Accessibility" -ForegroundColor Yellow
$frontendUrl = "http://legal-doc-frontend-dev-623242866456.s3-website-us-east-1.amazonaws.com"
try {
    $response = Invoke-WebRequest -Uri $frontendUrl -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "[PASS] Frontend is accessible - Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Check S3 buckets
Write-Host "Test 3: S3 Buckets" -ForegroundColor Yellow
$uploadBucket = "legal-doc-upload-dev-623242866456"
$processedBucket = "legal-doc-processed-dev-623242866456"

try {
    aws s3 ls "s3://$uploadBucket" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Upload bucket exists: $uploadBucket" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Upload bucket not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Error checking upload bucket" -ForegroundColor Red
}

try {
    aws s3 ls "s3://$processedBucket" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Processed bucket exists: $processedBucket" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Processed bucket not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Error checking processed bucket" -ForegroundColor Red
}
Write-Host ""

# Test 4: Check DynamoDB table
Write-Host "Test 4: DynamoDB Table" -ForegroundColor Yellow
try {
    $table = aws dynamodb describe-table --table-name legal-documents-dev --query "Table.[TableName,TableStatus]" --output text 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] DynamoDB table exists: $table" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] DynamoDB table not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Error checking DynamoDB table" -ForegroundColor Red
}
Write-Host ""

# Test 5: Check Lambda functions
Write-Host "Test 5: Lambda Functions" -ForegroundColor Yellow
$functions = @(
    "legal-upload-handler-dev",
    "legal-summarize-dev",
    "legal-deviation-detection-dev",
    "legal-comparison-agent-dev",
    "legal-status-dev"
)

foreach ($func in $functions) {
    try {
        $status = aws lambda get-function --function-name $func --query "Configuration.State" --output text 2>&1
        if ($LASTEXITCODE -eq 0 -and $status -eq "Active") {
            Write-Host "[PASS] $func is Active" -ForegroundColor Green
        } else {
            Write-Host "[WARN] $func status: $status" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[FAIL] $func not found" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your application is deployed at:" -ForegroundColor White
Write-Host $frontendUrl -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open the URL in your browser" -ForegroundColor White
Write-Host "2. Try uploading a PDF document" -ForegroundColor White
Write-Host "3. Check the browser console (F12) for any errors" -ForegroundColor White
Write-Host "4. If upload fails, check CloudWatch logs:" -ForegroundColor White
Write-Host "   aws logs tail /aws/lambda/legal-upload-handler-dev --follow" -ForegroundColor Gray
Write-Host ""
