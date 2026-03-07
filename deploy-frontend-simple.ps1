# Simple Frontend Deployment Script
# Deploys React app to S3 with public access

param(
    [string]$Environment = "dev"
)

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Frontend Deployment" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Get account ID
$accountId = aws sts get-caller-identity --query Account --output text
$bucketName = "legal-doc-frontend-$Environment-$accountId"
$region = "us-east-1"

Write-Host "Bucket: $bucketName" -ForegroundColor Gray
Write-Host ""

# Step 1: Get API Endpoint
Write-Host "Step 1: Getting API Endpoint..." -ForegroundColor Green
$apiEndpoint = aws cloudformation describe-stacks --stack-name "legal-doc-processing-$Environment" --region $region --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text 2>$null

if ([string]::IsNullOrEmpty($apiEndpoint)) {
    Write-Host "[WARNING] Could not get API endpoint" -ForegroundColor Yellow
    $apiEndpoint = Read-Host "Enter API Endpoint"
}

Write-Host "API: $apiEndpoint" -ForegroundColor Cyan
Write-Host ""

# Step 2: Configure and Build
Write-Host "Step 2: Building Frontend..." -ForegroundColor Green
"REACT_APP_API_ENDPOINT=$apiEndpoint" | Out-File -FilePath "frontend\.env.production" -Encoding utf8 -Force

Push-Location frontend
$env:REACT_APP_API_ENDPOINT = $apiEndpoint
npm run build --silent
Pop-Location

Write-Host "[OK] Build complete" -ForegroundColor Green
Write-Host ""

# Step 3: Create Bucket
Write-Host "Step 3: Setting up S3 Bucket..." -ForegroundColor Green

# Try to create bucket (ignore error if exists)
aws s3 mb "s3://$bucketName" --region $region 2>$null

# Remove block public access
Write-Host "Configuring public access..." -ForegroundColor Cyan
aws s3api put-public-access-block --bucket $bucketName --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Create and apply bucket policy
$policy = @"
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

$policy | Out-File -FilePath "temp-policy.json" -Encoding utf8 -Force
aws s3api put-bucket-policy --bucket $bucketName --policy file://temp-policy.json
Remove-Item temp-policy.json -Force

# Enable website hosting
aws s3 website "s3://$bucketName" --index-document index.html --error-document index.html

Write-Host "[OK] Bucket configured" -ForegroundColor Green
Write-Host ""

# Step 4: Upload Files
Write-Host "Step 4: Uploading Files..." -ForegroundColor Green

# Upload with public-read ACL
aws s3 sync frontend/build/ "s3://$bucketName" --delete --acl public-read

Write-Host "[OK] Upload complete" -ForegroundColor Green
Write-Host ""

# Step 5: Show URL
$websiteUrl = "http://$bucketName.s3-website-$region.amazonaws.com"

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your Live URL:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $websiteUrl" -ForegroundColor Yellow
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Save info
@"
Live URL: $websiteUrl
API Endpoint: $apiEndpoint
Bucket: $bucketName
Deployed: $(Get-Date)
"@ | Out-File -FilePath "LIVE_URL.txt" -Encoding utf8

Write-Host "URL saved to: LIVE_URL.txt" -ForegroundColor Gray
Write-Host ""

# Open browser
Start-Sleep -Seconds 2
Write-Host "Opening in browser..." -ForegroundColor Cyan
Start-Process $websiteUrl

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
