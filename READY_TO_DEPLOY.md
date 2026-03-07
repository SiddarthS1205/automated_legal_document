# 🚀 READY TO DEPLOY TO AWS

## Current Status
✅ SAM build completed successfully  
✅ All Lambda functions built  
✅ Configuration file is correct  
✅ Invalid "y" file removed  
✅ Python 3.11 runtime configured  
✅ Dependencies simplified (no Docker needed)  

## Deploy Now - Choose One Method

### Method 1: PowerShell Script (Easiest)
```powershell
.\DEPLOY_NOW_SIMPLE.ps1
```

### Method 2: Batch Script
```cmd
DEPLOY_NOW_SIMPLE.bat
```

### Method 3: Manual Command
```powershell
cd infrastructure
sam deploy --stack-name legal-doc-processing-dev --capabilities CAPABILITY_IAM --region us-east-1 --parameter-overrides Environment=dev --resolve-s3 --no-confirm-changeset
```

## What Will Be Created in AWS

1. **S3 Bucket** - For document storage
2. **DynamoDB Table** - For document metadata
3. **5 Lambda Functions**:
   - Upload Handler
   - Summarize
   - Deviation Detection
   - Comparison Agent
   - Status
4. **API Gateway** - REST API endpoint
5. **IAM Roles** - For Lambda permissions

## After Deployment

1. The script will show your API endpoint URL
2. Copy that URL
3. Update `frontend/.env`:
   ```
   REACT_APP_API_URL=https://your-api-id.execute-api.us-east-1.amazonaws.com/Prod
   ```
4. Start the frontend:
   ```
   cd frontend
   npm start
   ```

## Troubleshooting

### PowerShell Execution Policy Error
If you see "script is not digitally signed":
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
Then run the script again.

### Deployment Takes Time
- First deployment: 5-10 minutes
- Creating all AWS resources
- This is normal!

### Check Deployment Status
```powershell
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].StackStatus" --output text
```

### Get API Endpoint Later
```powershell
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text
```

## Cost Estimate
- Free tier eligible
- Estimated: $0-5/month for light usage
- Pay only for what you use

## Need Help?
- Check AWS CloudFormation console for stack status
- Check CloudWatch logs for Lambda errors
- All resources are tagged with Environment=dev
