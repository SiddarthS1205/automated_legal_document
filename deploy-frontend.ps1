# Deploy Frontend to AWS S3 + CloudFront
# This creates a live public URL for your application

param(
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Frontend Deployment to AWS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Get AWS Account ID
$accountId = aws sts get-caller-identity --query Account --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to get AWS account ID. Check your credentials." -ForegroundColor Red
    exit 1
}

$bucketName = "legal-doc-frontend-$Environment-$accountId"
$region = "us-east-1"

Write-Host "Account ID: $accountId" -ForegroundColor Gray
Write-Host "Bucket Name: $bucketName" -ForegroundColor Gray
Write-Host "Region: $region" -ForegroundColor Gray
Write-Host ""

# Step 1: Get API Endpoint
Write-Host "Step 1: Getting API Endpoint..." -ForegroundColor Green
Write-Host ""

$apiEndpoint = aws cloudformation describe-stacks `
    --stack-name "legal-doc-processing-$Environment" `
    --region $region `
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" `
    --output text 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($apiEndpoint)) {
    Write-Host "[WARNING] Could not get API endpoint from CloudFormation" -ForegroundColor Yellow
    Write-Host "Please enter your API endpoint manually:" -ForegroundColor Yellow
    $apiEndpoint = Read-Host "API Endpoint"
}

Write-Host "API Endpoint: $apiEndpoint" -ForegroundColor Cyan
Write-Host ""

# Step 2: Update Frontend Configuration
Write-Host "Step 2: Configuring Frontend..." -ForegroundColor Green
Write-Host ""

$envContent = "REACT_APP_API_ENDPOINT=$apiEndpoint"
$envContent | Out-File -FilePath "frontend\.env.production" -Encoding utf8 -Force

Write-Host "[OK] Frontend configured with API endpoint" -ForegroundColor Green
Write-Host ""

# Step 3: Build Frontend
Write-Host "Step 3: Building Frontend..." -ForegroundColor Green
Write-Host ""

Push-Location frontend

Write-Host "Installing dependencies..." -ForegroundColor Cyan
npm install --silent

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] npm install failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "Building production bundle..." -ForegroundColor Cyan
$env:REACT_APP_API_ENDPOINT = $apiEndpoint
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

Write-Host "[OK] Frontend built successfully" -ForegroundColor Green
Write-Host ""

# Step 4: Create S3 Bucket
Write-Host "Step 4: Creating S3 Bucket..." -ForegroundColor Green
Write-Host ""

# Check if bucket exists
$ErrorActionPreference = "SilentlyContinue"
$bucketExists = aws s3 ls "s3://$bucketName" 2>&1
$ErrorActionPreference = "Stop"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Bucket already exists: $bucketName" -ForegroundColor Green
} else {
    Write-Host "Creating bucket: $bucketName" -ForegroundColor Cyan
    aws s3 mb "s3://$bucketName" --region $region
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to create bucket" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Bucket created" -ForegroundColor Green
}

Write-Host ""

# Step 5: Configure Bucket for Website Hosting
Write-Host "Step 5: Configuring Website Hosting..." -ForegroundColor Green
Write-Host ""

# Create bucket policy for public read access
$bucketPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$bucketName/*"
        }
    ]
}
"@

$bucketPolicy | Out-File -FilePath "bucket-policy.json" -Encoding utf8 -Force

# Disable block public access
aws s3api put-public-access-block `
    --bucket $bucketName `
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Apply bucket policy
aws s3api put-bucket-policy --bucket $bucketName --policy file://bucket-policy.json

# Enable website hosting
aws s3 website "s3://$bucketName" --index-document index.html --error-document index.html

Remove-Item bucket-policy.json -Force

Write-Host "[OK] Website hosting configured" -ForegroundColor Green
Write-Host ""

# Step 6: Upload Files
Write-Host "Step 6: Uploading Files to S3..." -ForegroundColor Green
Write-Host ""

aws s3 sync frontend/build/ "s3://$bucketName" --delete --cache-control "max-age=31536000,public" --exclude "index.html"
aws s3 cp frontend/build/index.html "s3://$bucketName/index.html" --cache-control "max-age=0,no-cache,no-store,must-revalidate"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Upload failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Files uploaded" -ForegroundColor Green
Write-Host ""

# Step 7: Get Website URL
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

$websiteUrl = "http://$bucketName.s3-website-$region.amazonaws.com"

Write-Host "Your application is now live at:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $websiteUrl" -ForegroundColor Yellow
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Save deployment info
$deploymentInfo = @"
Frontend Deployment Information
================================
Date: $(Get-Date)
Environment: $Environment
Region: $region
Account ID: $accountId

Live URL: $websiteUrl
S3 Bucket: $bucketName
API Endpoint: $apiEndpoint

To update the frontend:
1. Make changes to frontend code
2. Run: .\deploy-frontend.ps1

To add custom domain (optional):
1. Register domain in Route 53
2. Create CloudFront distribution
3. Add SSL certificate
4. Point domain to CloudFront

"@

$deploymentInfo | Out-File -FilePath "frontend-deployment-info.txt" -Encoding utf8

Write-Host "Deployment info saved to: frontend-deployment-info.txt" -ForegroundColor Gray
Write-Host ""
Write-Host "Opening browser..." -ForegroundColor Cyan
Start-Process $websiteUrl

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
