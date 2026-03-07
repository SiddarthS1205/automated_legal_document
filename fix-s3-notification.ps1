# Fix S3 Bucket Notification Configuration
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Configuring S3 Bucket Notification" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$bucketName = "legal-doc-upload-dev-623242866456"
$functionName = "legal-summarize-dev"

# Get the Lambda function ARN
Write-Host "Getting Lambda function ARN..." -ForegroundColor Yellow
$lambdaArn = aws lambda get-function --function-name $functionName --query "Configuration.FunctionArn" --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to get Lambda function ARN" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Lambda ARN: $lambdaArn" -ForegroundColor Green
Write-Host ""

# Create notification configuration JSON
Write-Host "Creating notification configuration..." -ForegroundColor Yellow
$notificationConfig = @"
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "TriggerSummarizeOnUpload",
      "LambdaFunctionArn": "$lambdaArn",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "prefix",
              "Value": "uploads/"
            }
          ]
        }
      }
    }
  ]
}
"@

$notificationConfig | Out-File -FilePath "notification-config.json" -Encoding ascii
Write-Host "[OK] Configuration file created" -ForegroundColor Green
Write-Host ""

# Apply the notification configuration
Write-Host "Applying notification configuration to S3 bucket..." -ForegroundColor Yellow
aws s3api put-bucket-notification-configuration `
    --bucket $bucketName `
    --notification-configuration file://notification-config.json

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] S3 bucket notification configured!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The bucket will now trigger the summarize Lambda when files are uploaded." -ForegroundColor White
} else {
    Write-Host "[ERROR] Failed to configure S3 bucket notification" -ForegroundColor Red
    Write-Host ""
    Write-Host "This might be because:" -ForegroundColor Yellow
    Write-Host "1. The Lambda permission is not set correctly" -ForegroundColor White
    Write-Host "2. The bucket or Lambda function doesn't exist" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Verification" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Verify the configuration
Write-Host "Current notification configuration:" -ForegroundColor Yellow
aws s3api get-bucket-notification-configuration --bucket $bucketName --output json

Write-Host ""
Write-Host "[INFO] You can now upload a new PDF to test the processing pipeline" -ForegroundColor Cyan
Write-Host ""

# Clean up
Remove-Item "notification-config.json" -ErrorAction SilentlyContinue
