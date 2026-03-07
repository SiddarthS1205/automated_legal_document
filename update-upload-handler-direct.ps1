# Direct Update of Upload Handler Lambda (without SAM)
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Updating Upload Handler Lambda Directly" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$functionName = "legal-upload-handler-dev"
$sourceDir = "backend/lambdas/upload_handler"
$zipFile = "upload-handler.zip"

Write-Host "Creating deployment package..." -ForegroundColor Yellow

# Remove old zip if exists
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

# Create zip with just the handler.py file (no dependencies needed)
Write-Host "Zipping handler.py..." -ForegroundColor White
Compress-Archive -Path "$sourceDir/handler.py" -DestinationPath $zipFile -CompressionLevel Fastest

if ($LASTEXITCODE -ne 0 -or !(Test-Path $zipFile)) {
    Write-Host "[ERROR] Failed to create zip file" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Deployment package created: $zipFile" -ForegroundColor Green
Write-Host ""

Write-Host "Updating Lambda function code..." -ForegroundColor Yellow
aws lambda update-function-code `
    --function-name $functionName `
    --zip-file "fileb://$zipFile" `
    --region us-east-1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] Upload handler updated!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The base64 decoding fix is now deployed." -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Upload a NEW PDF file to test the fix" -ForegroundColor White
    Write-Host "2. The old document (497264a6) has a corrupted PDF and cannot be recovered" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "[ERROR] Failed to update Lambda function" -ForegroundColor Red
    exit 1
}

# Clean up
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item $zipFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
