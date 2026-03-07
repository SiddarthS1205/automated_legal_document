# ☁️ AWS Deployment Guide

Complete guide to deploy the Legal Document Processing System to AWS.

## 📋 Prerequisites

### Required Tools
- ✅ AWS Account with admin access
- ✅ AWS CLI installed and configured
- ✅ AWS SAM CLI installed
- ✅ Python 3.12 installed
- ✅ Node.js 18+ installed
- ✅ Git installed

### AWS Permissions Required
Your IAM user/role needs permissions for:
- Lambda (create, update, invoke)
- API Gateway (create, update)
- S3 (create buckets, put/get objects)
- DynamoDB (create tables)
- CloudFormation (create/update stacks)
- IAM (create roles, attach policies)
- CloudWatch (create log groups)
- Glue (create database, crawler)

## 🔧 Step 1: Install Prerequisites

### Install AWS CLI

**Windows:**
```powershell
# Download and run installer from:
# https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Mac:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify:**
```bash
aws --version
# Should show: aws-cli/2.x.x
```

### Install AWS SAM CLI

**Windows:**
```powershell
# Download and run installer from:
# https://github.com/aws/aws-sam-cli/releases/latest/download/AWS_SAM_CLI_64_PY3.msi
```

**Mac:**
```bash
brew install aws-sam-cli
```

**Linux:**
```bash
# Download the installer
wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
sudo ./sam-installation/install
```

**Verify:**
```bash
sam --version
# Should show: SAM CLI, version 1.x.x
```

### Install Python 3.12

**Windows:**
Download from https://www.python.org/downloads/

**Mac:**
```bash
brew install python@3.12
```

**Linux:**
```bash
sudo apt update
sudo apt install python3.12 python3.12-venv python3-pip
```

**Verify:**
```bash
python3 --version
# Should show: Python 3.12.x
```

## 🔑 Step 2: Configure AWS Credentials

### Option A: Using AWS CLI Configure (Recommended)

```bash
aws configure
```

You'll be prompted for:
```
AWS Access Key ID: YOUR_ACCESS_KEY
AWS Secret Access Key: YOUR_SECRET_KEY
Default region name: us-east-1
Default output format: json
```

### Option B: Using Environment Variables

**Windows (PowerShell):**
```powershell
$env:AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
$env:AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
$env:AWS_DEFAULT_REGION="us-east-1"
```

**Mac/Linux:**
```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-1"
```

### Verify Configuration

```bash
aws sts get-caller-identity
```

Should return your AWS account details.

## 📦 Step 3: Prepare Lambda Dependencies

The Lambda functions need their dependencies packaged. Run this script:

```bash
# Windows (PowerShell)
cd backend/lambdas

# For each Lambda function
foreach ($dir in "upload_handler", "summarize", "deviation_detection", "comparison_agent", "status") {
    cd $dir
    pip install -r requirements.txt -t . --upgrade
    cd ..
}

cd ../..
```

```bash
# Mac/Linux
cd backend/lambdas

for dir in upload_handler summarize deviation_detection comparison_agent status; do
    cd $dir
    pip install -r requirements.txt -t . --upgrade
    cd ..
done

cd ../..
```

## 🚀 Step 4: Deploy to AWS

### Option A: Using Deployment Script (Recommended)

```bash
cd infrastructure

# Make script executable (Mac/Linux only)
chmod +x deploy.sh

# Deploy to dev environment
./deploy.sh dev

# Or deploy to production
./deploy.sh prod
```

### Option B: Manual SAM Deployment

```bash
cd infrastructure

# Build
sam build --template-file template.yaml

# Deploy (first time - guided)
sam deploy --guided

# Follow the prompts:
# Stack Name: legal-doc-processing-dev
# AWS Region: us-east-1
# Parameter Environment: dev
# Confirm changes before deploy: Y
# Allow SAM CLI IAM role creation: Y
# Disable rollback: N
# Save arguments to configuration file: Y
# SAM configuration file: samconfig.toml
# SAM configuration environment: default

# Subsequent deployments
sam deploy
```

## ⏱️ Deployment Time

Expected deployment time: **10-15 minutes**

You'll see progress like:
```
Creating CloudFormation stack...
Creating Lambda functions...
Creating API Gateway...
Creating S3 buckets...
Creating DynamoDB table...
Creating Glue resources...
```

## 📊 Step 5: Get Deployment Outputs

After successful deployment:

```bash
aws cloudformation describe-stacks \
  --stack-name legal-doc-processing-dev \
  --query 'Stacks[0].Outputs' \
  --output table
```

You'll see:
```
---------------------------------------------------------
|                   DescribeStacks                      |
+------------------+------------------------------------+
|  OutputKey       |  OutputValue                       |
+------------------+------------------------------------+
|  ApiEndpoint     |  https://abc123.execute-api...     |
|  UploadBucket    |  legal-doc-upload-dev-123456...    |
|  ProcessedBucket |  legal-doc-processed-dev-123...    |
|  DocumentTable   |  legal-documents-dev               |
+------------------+------------------------------------+
```

**Save the ApiEndpoint URL - you'll need it for the frontend!**

## 🎨 Step 6: Configure Frontend

Update the frontend to use your AWS API:

```bash
cd frontend

# Create production environment file
echo "REACT_APP_API_ENDPOINT=YOUR_API_ENDPOINT_HERE" > .env.production

# Example:
# REACT_APP_API_ENDPOINT=https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev
```

## 🧪 Step 7: Test the Deployment

### Test with curl

```bash
# Set your API endpoint
API_ENDPOINT="https://your-api-id.execute-api.us-east-1.amazonaws.com/dev"

# Test upload endpoint
curl -X POST $API_ENDPOINT/upload \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "single",
    "file_content": "dGVzdCBjb250ZW50",
    "file_name": "test.pdf"
  }'

# You should get a response with doc_id
```

### Test with Frontend

```bash
cd frontend

# Build for production
npm run build

# Test locally with production API
# The build will use .env.production

# Serve the build
npx serve -s build

# Open http://localhost:3000 and test upload
```

## 🌐 Step 8: Deploy Frontend (Optional)

### Option A: S3 + CloudFront (Recommended)

```bash
cd frontend

# Build
npm run build

# Create S3 bucket for frontend
aws s3 mb s3://legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text)

# Enable static website hosting
aws s3 website s3://legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text) \
  --index-document index.html \
  --error-document index.html

# Upload build files
aws s3 sync build/ s3://legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text) --delete

# Make bucket public (create bucket-policy.json first)
cat > bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text)/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text) \
  --policy file://bucket-policy.json

# Get website URL
echo "Frontend URL: http://legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text).s3-website-us-east-1.amazonaws.com"
```

### Option B: Amplify Hosting

```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Initialize Amplify
cd frontend
amplify init

# Add hosting
amplify add hosting

# Choose: Hosting with Amplify Console
# Choose: Manual deployment

# Publish
amplify publish
```

## 🔍 Step 9: Verify Everything Works

### Check Lambda Functions

```bash
aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `legal`)].FunctionName' \
  --output table
```

Should show 5 functions:
- legal-upload-handler-dev
- legal-summarize-dev
- legal-deviation-detection-dev
- legal-comparison-agent-dev
- legal-status-dev

### Check S3 Buckets

```bash
aws s3 ls | grep legal-doc
```

Should show 2 buckets:
- legal-doc-upload-dev-...
- legal-doc-processed-dev-...

### Check DynamoDB Table

```bash
aws dynamodb describe-table --table-name legal-documents-dev
```

### Check API Gateway

```bash
aws apigateway get-rest-apis \
  --query 'items[?name==`legal-doc-api-dev`]' \
  --output table
```

### Check Glue Resources

```bash
# Check database
aws glue get-database --name legal_documents_dev

# Check crawler
aws glue get-crawler --name legal-doc-crawler-dev
```

## 📊 Step 10: Monitor Deployment

### CloudWatch Logs

```bash
# View Lambda logs
aws logs tail /aws/lambda/legal-upload-handler-dev --follow

# View all log groups
aws logs describe-log-groups \
  --log-group-name-prefix /aws/lambda/legal \
  --query 'logGroups[].logGroupName' \
  --output table
```

### CloudWatch Metrics

Access AWS Console → CloudWatch → Dashboards

Or use CLI:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=legal-upload-handler-dev \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## 💰 Cost Estimation

### Monthly Costs (Approximate)

**Low Usage (100 documents/month):**
- Lambda: $0.50
- API Gateway: $0.35
- S3: $0.50
- DynamoDB: $0.25
- **Total: ~$2/month**

**Medium Usage (1,000 documents/month):**
- Lambda: $5
- API Gateway: $3.50
- S3: $2
- DynamoDB: $1
- **Total: ~$12/month**

**High Usage (10,000 documents/month):**
- Lambda: $50
- API Gateway: $35
- S3: $10
- DynamoDB: $5
- **Total: ~$100/month**

### Free Tier Benefits (First 12 months)
- Lambda: 1M requests/month free
- API Gateway: 1M requests/month free
- S3: 5GB storage free
- DynamoDB: 25GB storage free

## 🔧 Troubleshooting

### Deployment Fails

**Error: "Stack already exists"**
```bash
# Delete existing stack
aws cloudformation delete-stack --stack-name legal-doc-processing-dev

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name legal-doc-processing-dev

# Try deployment again
```

**Error: "Insufficient permissions"**
- Check IAM permissions
- Ensure you have admin access or required permissions

**Error: "Python version mismatch"**
```bash
# Ensure Python 3.12 is installed
python3 --version

# Reinstall dependencies
cd backend/lambdas/upload_handler
pip install -r requirements.txt -t . --upgrade --python-version 3.12
```

### Lambda Timeout Issues

Edit `infrastructure/template.yaml`:
```yaml
Globals:
  Function:
    Timeout: 900  # Increase if needed
    MemorySize: 3008  # Increase if needed
```

Then redeploy:
```bash
sam deploy
```

### S3 Event Not Triggering

Check Lambda permissions:
```bash
aws lambda get-policy --function-name legal-summarize-dev
```

### CORS Issues

Update `infrastructure/template.yaml`:
```yaml
ApiGateway:
  Cors:
    AllowOrigin: "'https://your-frontend-domain.com'"  # Update this
```

Redeploy:
```bash
sam deploy
```

## 🔄 Update Deployment

To update after code changes:

```bash
cd infrastructure

# Build with latest code
sam build

# Deploy updates
sam deploy

# No need for --guided on subsequent deployments
```

## 🗑️ Delete Deployment

To completely remove everything:

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name legal-doc-processing-dev

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name legal-doc-processing-dev

# Manually delete S3 buckets (they're retained by default)
aws s3 rb s3://legal-doc-upload-dev-ACCOUNT_ID --force
aws s3 rb s3://legal-doc-processed-dev-ACCOUNT_ID --force

# Delete frontend bucket if created
aws s3 rb s3://legal-doc-frontend-prod-ACCOUNT_ID --force
```

## 🎯 Post-Deployment Checklist

- [ ] All Lambda functions deployed
- [ ] API Gateway endpoint accessible
- [ ] S3 buckets created
- [ ] DynamoDB table created
- [ ] Glue resources created
- [ ] CloudWatch logs working
- [ ] Test upload successful
- [ ] Test status endpoint
- [ ] Frontend configured with API endpoint
- [ ] Frontend deployed (if applicable)
- [ ] Monitoring set up
- [ ] Costs reviewed

## 🚀 Next Steps

1. **Test thoroughly** - Upload various documents
2. **Set up monitoring** - CloudWatch alarms
3. **Configure backups** - DynamoDB backups
4. **Set up CI/CD** - GitHub Actions or CodePipeline
5. **Add authentication** - Cognito or API keys
6. **Optimize costs** - Review usage and adjust resources

## 📞 Support

If you encounter issues:
1. Check CloudWatch logs
2. Review SAM build output
3. Verify IAM permissions
4. Check AWS service quotas
5. Review the detailed [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

## 🎉 Congratulations!

Your Legal Document Processing System is now live on AWS! 🚀

**API Endpoint:** Check CloudFormation outputs
**Frontend:** Deploy to S3 or Amplify
**Monitoring:** CloudWatch Console

Happy processing! ⚖️
