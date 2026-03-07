# Deployment Guide

## Prerequisites

### Required Tools
- AWS CLI (configured with credentials)
- AWS SAM CLI
- Python 3.12
- Node.js 18+
- Git

### AWS Account Requirements
- IAM permissions for:
  - Lambda
  - API Gateway
  - S3
  - DynamoDB
  - CloudWatch
  - Glue
  - CloudFormation

## Step-by-Step Deployment

### 1. Clone Repository
```bash
git clone <repository-url>
cd legal-doc-processing
```

### 2. Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
```

### 3. Install Backend Dependencies

For each Lambda function:
```bash
cd backend/lambdas/upload_handler
pip install -r requirements.txt -t .

cd ../summarize
pip install -r requirements.txt -t .

cd ../deviation_detection
pip install -r requirements.txt -t .

cd ../comparison_agent
pip install -r requirements.txt -t .

cd ../status
pip install -r requirements.txt -t .
```

### 4. Deploy Backend with SAM

```bash
cd infrastructure

# Build
sam build --template-file template.yaml

# Deploy (first time - guided)
sam deploy --guided

# Follow prompts:
# - Stack Name: legal-doc-processing-dev
# - AWS Region: us-east-1
# - Parameter Environment: dev
# - Confirm changes: Y
# - Allow SAM CLI IAM role creation: Y
# - Save arguments to configuration file: Y

# Subsequent deployments
sam deploy
```

Or use the deployment script:
```bash
chmod +x deploy.sh
./deploy.sh dev
```

### 5. Get API Endpoint

After deployment, note the API endpoint:
```bash
aws cloudformation describe-stacks \
  --stack-name legal-doc-processing-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text
```

### 6. Configure Frontend

```bash
cd frontend

# Create .env file
cp .env.example .env

# Edit .env and add your API endpoint
# REACT_APP_API_ENDPOINT=https://your-api-id.execute-api.us-east-1.amazonaws.com/dev
```

### 7. Install Frontend Dependencies

```bash
npm install
```

### 8. Run Frontend Locally

```bash
npm start
```

The app will open at http://localhost:3000

### 9. Build Frontend for Production

```bash
npm run build
```

### 10. Deploy Frontend (Optional - S3 + CloudFront)

```bash
# Create S3 bucket for frontend
aws s3 mb s3://legal-doc-frontend-prod

# Enable static website hosting
aws s3 website s3://legal-doc-frontend-prod \
  --index-document index.html \
  --error-document index.html

# Upload build files
aws s3 sync build/ s3://legal-doc-frontend-prod --delete

# Make public (if needed)
aws s3api put-bucket-policy \
  --bucket legal-doc-frontend-prod \
  --policy file://bucket-policy.json
```

## Verification

### Test API Endpoints

```bash
# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name legal-doc-processing-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text)

# Test upload endpoint
curl -X POST ${API_ENDPOINT}/upload \
  -H "Content-Type: application/json" \
  -d '{"mode":"single","file_content":"test","file_name":"test.pdf"}'
```

### Check Lambda Functions

```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `legal`)].FunctionName'
```

### Check S3 Buckets

```bash
aws s3 ls | grep legal-doc
```

### Check DynamoDB Table

```bash
aws dynamodb describe-table --table-name legal-documents-dev
```

### Check Glue Crawler

```bash
aws glue get-crawler --name legal-doc-crawler-dev
```

## Monitoring

### CloudWatch Logs

```bash
# View Lambda logs
aws logs tail /aws/lambda/legal-upload-handler-dev --follow

# View all log groups
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/legal
```

### CloudWatch Metrics

Access CloudWatch Console:
- Lambda invocations
- API Gateway requests
- S3 operations
- DynamoDB operations

## Troubleshooting

### Lambda Timeout Issues

Increase timeout in `template.yaml`:
```yaml
Globals:
  Function:
    Timeout: 900  # Increase if needed
```

### Memory Issues

Increase memory in `template.yaml`:
```yaml
Globals:
  Function:
    MemorySize: 3008  # Increase if needed
```

### Cold Start Optimization

1. Use Lambda provisioned concurrency
2. Implement Lambda layers for common dependencies
3. Optimize package size

### S3 Event Trigger Not Working

Check Lambda permissions:
```bash
aws lambda get-policy --function-name legal-summarize-dev
```

### CORS Issues

Update API Gateway CORS settings in `template.yaml`

## Cost Optimization

### Lambda
- Use appropriate memory settings
- Implement timeout optimization
- Use Lambda layers for shared dependencies

### S3
- Enable lifecycle policies
- Use appropriate storage classes
- Enable S3 Intelligent-Tiering

### DynamoDB
- Use on-demand billing for variable workloads
- Enable auto-scaling for provisioned capacity

### API Gateway
- Enable caching
- Use usage plans and API keys

## Security Best Practices

1. Enable encryption at rest for S3 and DynamoDB
2. Use IAM roles with least privilege
3. Enable CloudTrail logging
4. Use VPC for Lambda functions (if needed)
5. Implement API Gateway authentication
6. Enable AWS WAF for API Gateway

## Rollback

```bash
# Delete stack
aws cloudformation delete-stack --stack-name legal-doc-processing-dev

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name legal-doc-processing-dev
```

## Multi-Environment Deployment

```bash
# Deploy to staging
./deploy.sh staging

# Deploy to production
./deploy.sh prod
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: aws-actions/setup-sam@v2
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: sam build
      - run: sam deploy --no-confirm-changeset --no-fail-on-empty-changeset
```
