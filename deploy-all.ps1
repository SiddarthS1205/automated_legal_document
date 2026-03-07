# Complete AWS Deployment Script for Windows PowerShell
# This script deploys the entire Legal Document Processing System to AWS

param(
    [string]$Environment = "dev",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Legal Document Processing System - AWS Deployment" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Environment: $Environment" -ForegroundColor Yellow
Write-Host "  Region: $Region" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Function to check command existence
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

# Step 1: Check Prerequisites
Write-Host "Step 1: Checking Prerequisites..." -ForegroundColor Green
Write-Host ""

$errors = 0

if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js installed: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Node.js not installed" -ForegroundColor Red
    Write-Host "Install from: https://nodejs.org/" -ForegroundColor Yellow
    $errors++
}

if (Test-Command "python") {
    $pythonVersion = python --version
    Write-Host "[OK] Python installed: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Python not installed" -ForegroundColor Red
    $errors++
}

if (Test-Command "aws") {
    $awsVersion = aws --version
    Write-Host "[OK] AWS CLI installed: $awsVersion" -ForegroundColor Green
} else {
    Write-Host "[ERROR] AWS CLI not installed" -ForegroundColor Red
    Write-Host "Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    $errors++
}

if (Test-Command "sam") {
    $samVersion = sam --version
    Write-Host "[OK] AWS SAM CLI installed: $samVersion" -ForegroundColor Green
} else {
    Write-Host "[ERROR] AWS SAM CLI not installed" -ForegroundColor Red
    Write-Host "Install from: https://aws.amazon.com/serverless/sam/" -ForegroundColor Yellow
    $errors++
}

Write-Host ""
Write-Host "Checking AWS credentials..." -ForegroundColor Cyan
try {
    $identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] AWS credentials configured" -ForegroundColor Green
        $accountId = (aws sts get-caller-identity --query Account --output text)
        Write-Host "    Account ID: $accountId" -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] AWS credentials not configured" -ForegroundColor Red
        Write-Host "Run: aws configure" -ForegroundColor Yellow
        $errors++
    }
} catch {
    Write-Host "[ERROR] AWS credentials not configured" -ForegroundColor Red
    $errors++
}

if ($errors -gt 0) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  $errors error(s) found. Please fix them before deploying." -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[SUCCESS] All prerequisites met!" -ForegroundColor Green
Write-Host ""

# Ask for confirmation
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host "  Ready to deploy to AWS" -ForegroundColor Yellow
Write-Host "  This will create resources in your AWS account" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Continue with deployment? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Step 2: Install Lambda Dependencies
Write-Host "Step 2: Installing Lambda Dependencies..." -ForegroundColor Green
Write-Host ""

$lambdaDirs = @("upload_handler", "summarize", "deviation_detection", "comparison_agent", "status")

Push-Location backend\lambdas

foreach ($dir in $lambdaDirs) {
    Write-Host "Installing dependencies for $dir..." -ForegroundColor Cyan
    Push-Location $dir
    pip install -r requirements.txt -t . --upgrade --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies for $dir" -ForegroundColor Red
        Pop-Location
        Pop-Location
        exit 1
    }
    Pop-Location
    Write-Host "[OK] $dir dependencies installed" -ForegroundColor Green
}

Pop-Location

Write-Host ""
Write-Host "[SUCCESS] All Lambda dependencies installed!" -ForegroundColor Green
Write-Host ""

# Step 3: Build SAM Application
Write-Host "Step 3: Building SAM Application..." -ForegroundColor Green
Write-Host ""

Push-Location infrastructure

# Clean build directory to avoid file locking issues
Write-Host "Cleaning previous build..." -ForegroundColor Cyan
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
            Write-Host "[WARNING] Failed to clean build directory (attempt $retryCount/$maxRetries)" -ForegroundColor Yellow
            Write-Host "    Waiting 2 seconds and retrying..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
        } else {
            Write-Host "[WARNING] Could not clean build directory, continuing anyway..." -ForegroundColor Yellow
        }
    }
}

Write-Host "Running sam build..." -ForegroundColor Cyan
sam build --template-file template.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] SAM build failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""
Write-Host "[SUCCESS] SAM build complete!" -ForegroundColor Green
Write-Host ""

# Step 4: Deploy to AWS
Write-Host "Step 4: Deploying to AWS..." -ForegroundColor Green
Write-Host ""
Write-Host "This will take 10-15 minutes..." -ForegroundColor Yellow
Write-Host ""

$stackName = "legal-doc-processing-$Environment"

# Check if samconfig.toml exists
if (Test-Path "samconfig.toml") {
    Write-Host "Using existing SAM configuration..." -ForegroundColor Cyan
    sam deploy
} else {
    Write-Host "First-time deployment - using guided mode..." -ForegroundColor Cyan
    sam deploy --guided `
        --stack-name $stackName `
        --capabilities CAPABILITY_IAM `
        --region $Region `
        --parameter-overrides Environment=$Environment `
        --resolve-s3
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Deployment failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""
Write-Host "[SUCCESS] Deployment complete!" -ForegroundColor Green
Write-Host ""

# Step 5: Get Outputs
Write-Host "Step 5: Getting Deployment Outputs..." -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Deployment Outputs" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

aws cloudformation describe-stacks `
    --stack-name $stackName `
    --region $Region `
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" `
    --output table

# Get API endpoint
$apiEndpoint = aws cloudformation describe-stacks `
    --stack-name $stackName `
    --region $Region `
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" `
    --output text

Write-Host ""
Write-Host "API Endpoint: $apiEndpoint" -ForegroundColor Yellow
Write-Host ""

# Save API endpoint to file
$apiEndpoint | Out-File -FilePath "..\frontend\.env.production" -Encoding utf8
"REACT_APP_API_ENDPOINT=$apiEndpoint" | Out-File -FilePath "..\frontend\.env.production" -Encoding utf8

Pop-Location

# Step 6: Test Backend
Write-Host "Step 6: Testing Backend..." -ForegroundColor Green
Write-Host ""

Write-Host "Testing API endpoint..." -ForegroundColor Cyan
$testPayload = @{
    mode = "single"
    file_content = "dGVzdCBjb250ZW50"
    file_name = "test.pdf"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$apiEndpoint/upload" -Method Post -Body $testPayload -ContentType "application/json"
    Write-Host "[OK] API test successful!" -ForegroundColor Green
    Write-Host "    Document ID: $($response.doc_id)" -ForegroundColor Gray
} catch {
    Write-Host "[WARNING] API test failed, but deployment may still be successful" -ForegroundColor Yellow
    Write-Host "    Error: $_" -ForegroundColor Gray
}

Write-Host ""

# Step 7: Configure Frontend
Write-Host "Step 7: Configuring Frontend..." -ForegroundColor Green
Write-Host ""

Write-Host "Frontend environment file created at: frontend\.env.production" -ForegroundColor Cyan
Write-Host "API Endpoint configured: $apiEndpoint" -ForegroundColor Cyan

Write-Host ""

# Final Summary
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your Legal Document Processing System is now live on AWS!" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoint: $apiEndpoint" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test the API using the endpoint above" -ForegroundColor White
Write-Host "2. Build frontend: cd frontend && npm run build" -ForegroundColor White
Write-Host "3. Deploy frontend to S3 (optional)" -ForegroundColor White
Write-Host ""
Write-Host "To view logs:" -ForegroundColor Cyan
Write-Host "aws logs tail /aws/lambda/legal-upload-handler-$Environment --follow" -ForegroundColor White
Write-Host ""
Write-Host "To update deployment:" -ForegroundColor Cyan
Write-Host "cd infrastructure && sam build && sam deploy" -ForegroundColor White
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# Save deployment info
$deploymentInfo = @"
Deployment Information
======================
Date: $(Get-Date)
Environment: $Environment
Region: $Region
Stack Name: $stackName
API Endpoint: $apiEndpoint
Account ID: $accountId

Resources Created:
- 5 Lambda Functions
- API Gateway
- 2 S3 Buckets
- DynamoDB Table
- Glue Database & Crawler
- CloudWatch Log Groups
- IAM Roles

Next Steps:
1. Test API: curl -X POST $apiEndpoint/upload -H "Content-Type: application/json" -d '{"mode":"single","file_content":"dGVzdA==","file_name":"test.pdf"}'
2. Build frontend: cd frontend && npm run build
3. Deploy frontend: aws s3 sync frontend/build/ s3://legal-doc-frontend-prod-$accountId

Documentation:
- API Documentation: docs/API_DOCUMENTATION.md
- Deployment Guide: AWS_DEPLOYMENT.md
- Quick Reference: DEPLOY_QUICK_REFERENCE.md
"@

$deploymentInfo | Out-File -FilePath "deployment-info.txt" -Encoding utf8

Write-Host "Deployment information saved to: deployment-info.txt" -ForegroundColor Cyan
Write-Host ""
