# Fix Deployment Issues Script
# Cleans up oversized Lambda packages and retries deployment

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Fixing Deployment Issues" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean comparison_agent directory
Write-Host "Step 1: Cleaning comparison_agent Lambda..." -ForegroundColor Green
Write-Host ""

$comparisonDir = "backend\lambdas\comparison_agent"

Write-Host "Removing all dependencies from comparison_agent..." -ForegroundColor Cyan

# Keep only handler.py and requirements.txt
Get-ChildItem $comparisonDir | Where-Object { 
    $_.Name -ne "handler.py" -and 
    $_.Name -ne "requirements.txt" -and
    $_.Name -ne "__pycache__"
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[OK] Cleaned comparison_agent directory" -ForegroundColor Green
Write-Host ""

# Step 2: Reinstall only required dependencies
Write-Host "Step 2: Reinstalling minimal dependencies..." -ForegroundColor Green
Write-Host ""

Push-Location $comparisonDir

Write-Host "Installing boto3 only..." -ForegroundColor Cyan
pip install boto3==1.34.51 -t . --upgrade --no-deps --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to install boto3" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Install boto3 dependencies
pip install botocore jmespath python-dateutil urllib3 -t . --upgrade --quiet

Pop-Location

Write-Host "[OK] Dependencies reinstalled" -ForegroundColor Green
Write-Host ""

# Step 3: Clean infrastructure build directory
Write-Host "Step 3: Cleaning infrastructure build..." -ForegroundColor Green
Write-Host ""

Push-Location infrastructure

$maxRetries = 3
$retryCount = 0
$cleaned = $false

while (-not $cleaned -and $retryCount -lt $maxRetries) {
    try {
        if (Test-Path ".aws-sam") {
            Remove-Item -Recurse -Force .aws-sam -ErrorAction Stop
            Write-Host "[OK] Build directory cleaned" -ForegroundColor Green
        }
        $cleaned = $true
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "[WARNING] Failed to clean (attempt $retryCount/$maxRetries)" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
}

Pop-Location

Write-Host ""
Write-Host "[SUCCESS] Cleanup complete!" -ForegroundColor Green
Write-Host ""

# Step 4: Show package sizes
Write-Host "Step 4: Verifying package sizes..." -ForegroundColor Green
Write-Host ""

$lambdaDirs = @("upload_handler", "summarize", "deviation_detection", "comparison_agent", "status")

foreach ($dir in $lambdaDirs) {
    $path = "backend\lambdas\$dir"
    $size = (Get-ChildItem $path -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    $sizeFormatted = "{0:N2}" -f $size
    
    if ($size -gt 50) {
        Write-Host "  $dir : $sizeFormatted MB [WARNING: Large]" -ForegroundColor Yellow
    } else {
        Write-Host "  $dir : $sizeFormatted MB [OK]" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Ready to deploy!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Run: .\deploy-all.ps1" -ForegroundColor Cyan
Write-Host ""
