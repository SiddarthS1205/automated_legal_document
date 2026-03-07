# Deploy Upload Handler Lambda with Base64 Fix
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Deploying Upload Handler Lambda Function" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$functionName = "legal-upload-handler-dev"
$region = "us-east-1"

Write-Host "Building Lambda function..." -ForegroundColor Yellow
Write-Host ""

# Build only the upload handler function
sam build UploadHandlerFunction --template-file infrastructure/template.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] SAM build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Build completed" -ForegroundColor Green
Write-Host ""

Write-Host "Deploying function to AWS..." -ForegroundColor Yellow
Write-Host ""

# Deploy the function (use --resolve-s3 to auto-create deployment bucket)
sam deploy --no-confirm-changeset --no-fail-on-empty-changeset --stack-name legal-doc-processing-dev --region $region --resolve-s3 --capabilities CAPABILITY_IAM

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] Upload handler deployed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The base64 decoding fix is now live." -ForegroundColor White
    Write-Host "You can upload a NEW PDF to test the fix." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Note: The old stuck document (497264a6) has a corrupted PDF" -ForegroundColor Yellow
    Write-Host "and cannot be recovered. Please upload a fresh PDF." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
