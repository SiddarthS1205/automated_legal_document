Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AWS SAM Deployment - No Prompts" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Clean up invalid config file if it exists
if (Test-Path "infrastructure\y") {
    Write-Host "Removing invalid config file..." -ForegroundColor Yellow
    Remove-Item -Path "infrastructure\y" -Force
}

# Navigate to infrastructure directory
Set-Location infrastructure

Write-Host "Step 1: Building Lambda functions..." -ForegroundColor Green
sam build --template-file template.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host ""
Write-Host "Step 2: Deploying to AWS..." -ForegroundColor Green
sam deploy --stack-name legal-doc-processing-dev --capabilities CAPABILITY_IAM --region us-east-1 --parameter-overrides Environment=dev --resolve-s3 --no-confirm-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Getting API endpoint..." -ForegroundColor Yellow
$apiEndpoint = aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text

Write-Host ""
Write-Host "API Endpoint: $apiEndpoint" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update frontend/.env with: REACT_APP_API_URL=$apiEndpoint"
Write-Host "2. Run: cd frontend"
Write-Host "3. Run: npm start"
Write-Host ""

Set-Location ..
