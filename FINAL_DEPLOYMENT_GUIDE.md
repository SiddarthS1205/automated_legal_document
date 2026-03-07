# 🎯 Final Deployment Guide

## You're Ready to Deploy!

All the hard work is done. Your SAM build succeeded, configuration is correct, and everything is ready to go to AWS.

## Quick Deploy (Copy & Paste)

Open PowerShell in this directory and run:

```powershell
.\DEPLOY_NOW_SIMPLE.ps1
```

That's it! The script will:
1. Clean up any old files
2. Build your Lambda functions
3. Deploy to AWS (no prompts)
4. Show your API endpoint

## What You'll See

```
========================================
AWS SAM Deployment - No Prompts
========================================

Step 1: Building Lambda functions...
Building codeuri: ...\upload_handler runtime: python3.11
Building codeuri: ...\summarize runtime: python3.11
Building codeuri: ...\deviation_detection runtime: python3.11
Building codeuri: ...\comparison_agent runtime: python3.11
Building codeuri: ...\status runtime: python3.11
Build Succeeded

Step 2: Deploying to AWS...
Creating CloudFormation stack...
Waiting for stack creation...
Stack creation complete!

========================================
Deployment Complete!
========================================

API Endpoint: https://abc123.execute-api.us-east-1.amazonaws.com/Prod
```

## After Deployment

1. **Copy the API endpoint** (the URL shown at the end)

2. **Update frontend configuration**:
   ```powershell
   cd frontend
   ```
   
   Edit `.env` file:
   ```
   REACT_APP_API_URL=https://your-api-endpoint-here.amazonaws.com/Prod
   ```

3. **Start the frontend**:
   ```powershell
   npm start
   ```

4. **Open your browser**:
   ```
   http://localhost:3000
   ```

## AWS Resources Created

Your deployment creates:

| Resource | Purpose | Cost |
|----------|---------|------|
| S3 Bucket | Document storage | Free tier eligible |
| DynamoDB Table | Document metadata | Free tier eligible |
| 5 Lambda Functions | Document processing | Free tier: 1M requests/month |
| API Gateway | REST API | Free tier: 1M requests/month |
| IAM Roles | Permissions | Free |

**Estimated monthly cost**: $0-5 for light usage

## Verify Deployment

Check if your stack is deployed:

```powershell
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].StackStatus" --output text
```

Should show: `CREATE_COMPLETE`

Get your API endpoint anytime:

```powershell
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text
```

## Troubleshooting

### PowerShell Execution Policy
If you see "script is not digitally signed":
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Deployment Fails
1. Check AWS credentials: `aws sts get-caller-identity`
2. Check region: Should be `us-east-1`
3. Check CloudFormation console for error details

### Can't Find API Endpoint
Run this command:
```powershell
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs" --output table
```

## Testing Your Deployment

1. Open frontend: `http://localhost:3000`
2. Upload a legal document (PDF)
3. Wait for processing (30-60 seconds)
4. View results:
   - Document summary
   - Extracted clauses
   - Deviation analysis
5. Try comparison mode with 2 documents

## What's Next?

After successful deployment:
- ✅ Test all features
- ✅ Upload sample documents
- ✅ Try comparison mode
- ✅ Check AWS CloudWatch logs
- ✅ Monitor costs in AWS Billing

## Clean Up (When Done Testing)

To delete all AWS resources:

```powershell
cd infrastructure
sam delete --stack-name legal-doc-processing-dev --region us-east-1 --no-prompts
```

This removes everything and stops all charges.

## Support

- **AWS Console**: Check CloudFormation for stack status
- **Logs**: CloudWatch Logs for Lambda function logs
- **Costs**: AWS Billing dashboard

---

## 🚀 Ready? Run This Now:

```powershell
.\DEPLOY_NOW_SIMPLE.ps1
```

Good luck! Your deployment should complete in 5-10 minutes.
