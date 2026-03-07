Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Legal Document Processing System - Fixed Deployment" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean up locked build directory
Write-Host "Step 1: Cleaning up build directory..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "infrastructure\.aws-sam") {
    Write-Host "Removing old build directory..." -ForegroundColor Yellow
    
    # Force remove with retry
    $maxRetries = 3
    $retryCount = 0
    $removed = $false
    
    while (-not $removed -and $retryCount -lt $maxRetries) {
        try {
            Remove-Item -Path "infrastructure\.aws-sam" -Recurse -Force -ErrorAction Stop
            $removed = $true
            Write-Host "[OK] Build directory removed" -ForegroundColor Green
        }
        catch {
            $retryCount++
            Write-Host "Attempt $retryCount failed, retrying..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            
            # Try to kill any processes that might be locking files
            Get-Process | Where-Object {$_.Path -like "*python*"} | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
    }
    
    if (-not $removed) {
        Write-Host "[WARNING] Could not remove build directory automatically" -ForegroundColor Yellow
        Write-Host "Please close any file explorers or editors viewing the infrastructure folder" -ForegroundColor Yellow
        Write-Host "Then press Enter to continue..." -ForegroundColor Yellow
        Read-Host
        Remove-Item -Path "infrastructure\.aws-sam" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "[SUCCESS] Cleanup complete!" -ForegroundColor Green
Write-Host ""

# Step 2: Navigate to infrastructure directory
Set-Location infrastructure

# Step 3: Build with SAM (SAM handles dependencies, not pip)
Write-Host "Step 2: Building Lambda functions with SAM..." -ForegroundColor Yellow
Write-Host ""

sam build --template-file template.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] SAM build failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Close any file explorers viewing the infrastructure folder" -ForegroundColor Yellow
    Write-Host "2. Close any editors with files open from .aws-sam folder" -ForegroundColor Yellow
    Write-Host "3. Run this script again" -ForegroundColor Yellow
    Write-Host ""
    Set-Location ..
    exit 1
}

Write-Host ""
Write-Host "[SUCCESS] Build complete!" -ForegroundColor Green
Write-Host ""

# Step 4: Deploy to AWS
Write-Host "Step 3: Deploying to AWS..." -ForegroundColor Yellow
Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow
Write-Host ""

sam deploy --stack-name legal-doc-processing-dev --capabilities CAPABILITY_IAM --region us-east-1 --parameter-overrides Environment=dev --resolve-s3 --no-confirm-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed!" -ForegroundColor Red
    Write-Host "Check the error messages above for details" -ForegroundColor Yellow
    Write-Host ""
    Set-Location ..
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Get API endpoint
Write-Host "Getting API endpoint..." -ForegroundColor Yellow
$apiEndpoint = aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "API Endpoint:" -ForegroundColor Green
Write-Host $apiEndpoint -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update frontend/.env with:" -ForegroundColor White
Write-Host "   REACT_APP_API_URL=$apiEndpoint" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Start the frontend:" -ForegroundColor White
Write-Host "   cd frontend" -ForegroundColor Cyan
Write-Host "   npm start" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Open browser: http://localhost:3000" -ForegroundColor White
Write-Host ""

Set-Location ..
