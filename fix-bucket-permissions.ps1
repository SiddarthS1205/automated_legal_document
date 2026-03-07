# Fix S3 Bucket Permissions
# Run this if you're getting 403 Forbidden errors

param(
    [string]$Environment = "dev"
)

Write-Host ""
Write-Host "Fixing bucket permissions..." -ForegroundColor Yellow
Write-Host ""

$accountId = aws sts get-caller-identity --query Account --output text
$bucketName = "legal-doc-frontend-$Environment-$accountId"

Write-Host "Bucket: $bucketName" -ForegroundColor Gray
Write-Host ""

# Step 1: Remove block public access
Write-Host "Step 1: Removing public access blocks..." -ForegroundColor Cyan
aws s3api put-public-access-block --bucket $bucketName --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

Write-Host "[OK] Public access blocks removed" -ForegroundColor Green
Write-Host ""

# Step 2: Apply bucket policy
Write-Host "Step 2: Applying bucket policy..." -ForegroundColor Cyan

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

Write-Host "[OK] Bucket policy applied" -ForegroundColor Green
Write-Host ""

# Step 3: Set ACLs on existing files
Write-Host "Step 3: Updating file permissions..." -ForegroundColor Cyan
aws s3 sync "s3://$bucketName" "s3://$bucketName" --acl public-read

Write-Host "[OK] File permissions updated" -ForegroundColor Green
Write-Host ""

$websiteUrl = "http://$bucketName.s3-website-us-east-1.amazonaws.com"

Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Permissions Fixed!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Try accessing your site now:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $websiteUrl" -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 2
Start-Process $websiteUrl

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
