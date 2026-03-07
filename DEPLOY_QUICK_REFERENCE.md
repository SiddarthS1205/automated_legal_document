# ⚡ AWS Deployment Quick Reference

One-page reference for deploying to AWS.

## 🚀 Quick Deploy (3 Steps)

### 1. Pre-Flight Check
```bash
# Mac/Linux
./pre-deploy-check.sh

# Windows
pre-deploy-check.bat
```

### 2. Deploy Backend
```bash
cd infrastructure

# Mac/Linux
./deploy.sh dev

# Windows
deploy.bat dev
```

### 3. Get API Endpoint
```bash
aws cloudformation describe-stacks \
  --stack-name legal-doc-processing-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text
```

## 📋 Prerequisites

| Tool | Check | Install |
|------|-------|---------|
| Node.js 18+ | `node --version` | https://nodejs.org/ |
| Python 3.12 | `python3 --version` | https://www.python.org/ |
| AWS CLI | `aws --version` | https://aws.amazon.com/cli/ |
| SAM CLI | `sam --version` | https://aws.amazon.com/serverless/sam/ |

## 🔑 AWS Setup

```bash
# Configure credentials
aws configure

# Verify
aws sts get-caller-identity
```

## 📦 Install Dependencies

**Windows (PowerShell):**
```powershell
cd backend/lambdas
foreach ($dir in "upload_handler", "summarize", "deviation_detection", "comparison_agent", "status") {
    cd $dir; pip install -r requirements.txt -t . --upgrade; cd ..
}
```

**Mac/Linux:**
```bash
cd backend/lambdas
for dir in upload_handler summarize deviation_detection comparison_agent status; do
    cd $dir && pip install -r requirements.txt -t . --upgrade && cd ..
done
```

## 🎯 Deploy Commands

### Full Deployment
```bash
cd infrastructure
sam build
sam deploy --guided
```

### Update Deployment
```bash
cd infrastructure
sam build
sam deploy
```

### Delete Deployment
```bash
aws cloudformation delete-stack --stack-name legal-doc-processing-dev
```

## 🧪 Test Deployment

```bash
# Set API endpoint
API_ENDPOINT="YOUR_API_ENDPOINT"

# Test upload
curl -X POST $API_ENDPOINT/upload \
  -H "Content-Type: application/json" \
  -d '{"mode":"single","file_content":"dGVzdA==","file_name":"test.pdf"}'
```

## 🎨 Configure Frontend

```bash
cd frontend

# Create production env
echo "REACT_APP_API_ENDPOINT=YOUR_API_ENDPOINT" > .env.production

# Build
npm run build

# Test locally
npx serve -s build
```

## 🌐 Deploy Frontend to S3

```bash
# Create bucket
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://legal-doc-frontend-prod-$ACCOUNT

# Enable website
aws s3 website s3://legal-doc-frontend-prod-$ACCOUNT \
  --index-document index.html

# Upload
aws s3 sync build/ s3://legal-doc-frontend-prod-$ACCOUNT --delete

# Get URL
echo "http://legal-doc-frontend-prod-$ACCOUNT.s3-website-us-east-1.amazonaws.com"
```

## 🔍 Verify Resources

```bash
# List Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `legal`)].FunctionName'

# List S3 buckets
aws s3 ls | grep legal-doc

# Check DynamoDB table
aws dynamodb describe-table --table-name legal-documents-dev

# View logs
aws logs tail /aws/lambda/legal-upload-handler-dev --follow
```

## 📊 Get All Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name legal-doc-processing-dev \
  --query 'Stacks[0].Outputs' \
  --output table
```

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Stack exists | `aws cloudformation delete-stack --stack-name legal-doc-processing-dev` |
| No credentials | `aws configure` |
| Python version | Use Python 3.12 |
| Timeout | Increase in template.yaml |
| CORS error | Update API Gateway CORS |

## 💰 Cost Estimate

| Usage | Monthly Cost |
|-------|--------------|
| 100 docs | ~$2 |
| 1,000 docs | ~$12 |
| 10,000 docs | ~$100 |

## 📞 Quick Links

- **Full Guide**: [AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md)
- **Checklist**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **Detailed Docs**: [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

## 🎯 Deployment Flow

```
1. Pre-flight check
   ↓
2. Install dependencies
   ↓
3. SAM build
   ↓
4. SAM deploy
   ↓
5. Get API endpoint
   ↓
6. Configure frontend
   ↓
7. Deploy frontend
   ↓
8. Test & verify
```

## ⚡ One-Liner Deploy

```bash
cd infrastructure && sam build && sam deploy --guided
```

## 🔄 Update After Code Changes

```bash
cd infrastructure && sam build && sam deploy
```

## 🗑️ Complete Cleanup

```bash
# Delete stack
aws cloudformation delete-stack --stack-name legal-doc-processing-dev

# Delete S3 buckets
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://legal-doc-upload-dev-$ACCOUNT --force
aws s3 rb s3://legal-doc-processed-dev-$ACCOUNT --force
aws s3 rb s3://legal-doc-frontend-prod-$ACCOUNT --force
```

## 📝 Environment Variables

```bash
# Set region
export AWS_DEFAULT_REGION=us-east-1

# Set profile
export AWS_PROFILE=default
```

## 🎉 Success Checklist

- [ ] All Lambda functions deployed
- [ ] API Gateway accessible
- [ ] S3 buckets created
- [ ] DynamoDB table created
- [ ] Test upload successful
- [ ] Frontend configured
- [ ] Frontend deployed
- [ ] All features working

---

**Need detailed help?** See [AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md)
