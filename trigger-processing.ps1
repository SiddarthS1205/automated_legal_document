# Manually trigger processing for stuck document
param(
    [string]$docId = "497264a6-db58-49ac-a942-8aa7fc917ecd"
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Manually Triggering Document Processing" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Document ID: $docId" -ForegroundColor White
Write-Host ""

# Create S3 event payload
$bucketName = "legal-doc-upload-dev-623242866456"
$s3Key = "uploads/$docId/Sample Construction Manager-At-Risk Contract March 2022.pdf"

$event = @"
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-east-1",
      "eventTime": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "s3SchemaVersion": "1.0",
        "bucket": {
          "name": "$bucketName",
          "arn": "arn:aws:s3:::$bucketName"
        },
        "object": {
          "key": "$s3Key"
        }
      }
    }
  ]
}
"@

Write-Host "Creating event payload..." -ForegroundColor Yellow
$event | Out-File -FilePath "s3-event.json" -Encoding ascii
Write-Host "[OK] Event payload created" -ForegroundColor Green
Write-Host ""

# Invoke the summarize Lambda
Write-Host "Invoking summarize Lambda function..." -ForegroundColor Yellow
aws lambda invoke `
    --function-name legal-summarize-dev `
    --payload file://s3-event.json `
    --cli-binary-format raw-in-base64-out `
    response.json

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Lambda invoked!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Yellow
    Get-Content response.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
} else {
    Write-Host "[ERROR] Failed to invoke Lambda" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Checking Processing Status" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Wait a bit for processing to start
Write-Host "Waiting 5 seconds for processing to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check CloudWatch logs
Write-Host "Recent summarize Lambda logs:" -ForegroundColor Yellow
aws logs tail /aws/lambda/legal-summarize-dev --since 2m --format short | Select-Object -Last 20

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check the frontend to see if results appear:" -ForegroundColor White
Write-Host "http://legal-doc-frontend-dev-623242866456.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan
Write-Host ""

# Clean up
Remove-Item "s3-event.json" -ErrorAction SilentlyContinue
Remove-Item "response.json" -ErrorAction SilentlyContinue
