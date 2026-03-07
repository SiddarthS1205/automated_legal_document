# 🚀 Complete AWS Deployment Commands

Copy and paste these commands in order to deploy everything to AWS.

## ✅ Step 1: Verify Prerequisites

```powershell
# Check Node.js
node --version

# Check Python
python --version

# Check AWS CLI
aws --version

# Check SAM CLI
sam --version

# Check AWS credentials
aws sts get-caller-identity
```

**If any command fails, install the missing tool first!**

## 🔧 Step 2: Configure AWS (If Not Done)

```powershell
# Configure AWS credentials
aws configure

# You'll be prompted for:
# AWS Access Key ID: [Enter your key]
# AWS Secret Access Key: [Enter your secret]
# Default region name: us-east-1
# Default output format: json
```

## 📦 Step 3: Install Lambda Dependencies

```powershell
# Navigate to backend lambdas
cd backend\lambdas

# Install dependencies for each Lambda function
cd upload_handler
pip install -r requirements.txt -t . --upgrade
cd ..

cd summarize
pip install -r requirements.txt -t . --upgrade
cd ..

cd deviation_detection
pip install -r requirements.txt -t . --upgrade
cd ..

cd comparison_agent
pip install -r requirements.txt -t . --upgrade
cd ..

cd status
pip install -r requirements.txt -t . --upgrade
cd ..

# Go back to project root
cd ..\..
```

## ☁️ Step 4: Deploy Backend to AWS

```powershell
# Navigate to infrastructure folder
cd infrastructure

# Build SAM application
sam build --template-file template.yaml

# Deploy to AWS (first time - guided)
sam deploy --guided

# You'll be prompted for:
# Stack Name: legal-doc-processing-dev
# AWS Region: us-east-1
# Parameter Environment: dev
# Confirm changes before deploy: Y
# Allow SAM CLI IAM role creation: Y
# Disable rollback: N
# Save arguments to configuration file: Y
# SAM configuration file: samconfig.toml
# SAM configuration environment: default

# Wait for deployment to complete (10-15 minutes)
```

## 📊 Step 5: Get API Endpoint

```powershell
# Get all outputs
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs" --output table

# Or get just the API endpoint
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text
```

**Copy the API endpoint URL!** You'll need it for the frontend.

## 🧪 Step 6: Test Backend

```powershell
# Set your API endpoint (replace with your actual endpoint)
$API_ENDPOINT = "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/dev"

# Test upload endpoint
curl -X POST "$API_ENDPOINT/upload" -H "Content-Type: application/json" -d '{\"mode\":\"single\",\"file_content\":\"dGVzdA==\",\"file_name\":\"test.pdf\"}'

# You should get a response with doc_id
```

## 🎨 Step 7: Configure Frontend

```powershell
# Go back to project root
cd ..

# Navigate to frontend
cd frontend

# Create production environment file
"REACT_APP_API_ENDPOINT=$API_ENDPOINT" | Out-File -FilePath .env.production -Encoding utf8

# Install frontend dependencies (if not done)
npm install

# Build frontend
npm run build

# Test locally with production API
npx serve -s build
# Open http://localhost:3000 and test
```

## 🌐 Step 8: Deploy Frontend to S3 (Optional)

```powershell
# Get your AWS account ID
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# Create S3 bucket for frontend
aws s3 mb s3://legal-doc-frontend-prod-$ACCOUNT_ID

# Enable static website hosting
aws s3 website s3://legal-doc-frontend-prod-$ACCOUNT_ID --index-document index.html --error-document index.html

# Upload build files
aws s3 sync build/ s3://legal-doc-frontend-prod-$ACCOUNT_ID --delete

# Create bucket policy file
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::legal-doc-frontend-prod-$ACCOUNT_ID/*"
    }
  ]
}
"@ | Out-File -FilePath bucket-policy.json -Encoding utf8

# Apply bucket policy
aws s3api put-bucket-policy --bucket legal-doc-frontend-prod-$ACCOUNT_ID --policy file://bucket-policy.json

# Get website URL
Write-Host "Frontend URL: http://legal-doc-frontend-prod-$ACCOUNT_ID.s3-website-us-east-1.amazonaws.com"
```

## ✅ Step 9: Verify Deployment

```powershell
# Check Lambda functions
aws lambda list-functions --query "Functions[?contains(FunctionName, 'legal')].FunctionName" --output table

# Check S3 buckets
aws s3 ls | Select-String "legal-doc"

# Check DynamoDB table
aws dynamodb describe-table --table-name legal-documents-dev --query "Table.TableName"

# View Lambda logs
aws logs tail /aws/lambda/legal-upload-handler-dev --follow
```

## 🎉 You're Done!

Your Legal Document Processing System is now live on AWS!

**API Endpoint:** Check Step 5 output
**Frontend URL:** Check Step 8 output (if deployed)

---

## 🔄 Update Deployment (After Code Changes)

```powershell
cd infrastructure
sam build
sam deploy
```

## 🗑️ Delete Everything (Cleanup)

```powershell
# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name legal-doc-processing-dev

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name legal-doc-processing-dev

# Delete S3 buckets manually
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
aws s3 rb s3://legal-doc-upload-dev-$ACCOUNT_ID --force
aws s3 rb s3://legal-doc-processed-dev-$ACCOUNT_ID --force
aws s3 rb s3://legal-doc-frontend-prod-$ACCOUNT_ID --force
```

---

## 🐛 Troubleshooting Commands

```powershell
# If stack already exists
aws cloudformation delete-stack --stack-name legal-doc-processing-dev
aws cloudformation wait stack-delete-complete --stack-name legal-doc-processing-dev

# Check CloudFormation events
aws cloudformation describe-stack-events --stack-name legal-doc-processing-dev --max-items 10

# Check Lambda function
aws lambda get-function --function-name legal-upload-handler-dev

# Test Lambda directly
aws lambda invoke --function-name legal-upload-handler-dev --payload '{}' response.json
cat response.json

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/legal

# Get latest log events
aws logs tail /aws/lambda/legal-upload-handler-dev --since 1h
```
