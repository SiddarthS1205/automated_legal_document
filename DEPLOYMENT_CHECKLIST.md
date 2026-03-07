# ☁️ AWS Deployment Checklist

Use this checklist to ensure a smooth deployment to AWS.

## 📋 Pre-Deployment

### Prerequisites Installation
- [ ] Node.js 18+ installed (`node --version`)
- [ ] Python 3.12 installed (`python3 --version`)
- [ ] pip installed (`pip --version`)
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS SAM CLI installed (`sam --version`)
- [ ] Git installed (optional) (`git --version`)

### AWS Account Setup
- [ ] AWS account created
- [ ] IAM user created with admin access
- [ ] Access Key ID obtained
- [ ] Secret Access Key obtained
- [ ] AWS CLI configured (`aws configure`)
- [ ] Credentials verified (`aws sts get-caller-identity`)

### Project Preparation
- [ ] All project files downloaded/cloned
- [ ] In correct directory
- [ ] All Lambda requirements.txt files present
- [ ] SAM template.yaml exists
- [ ] Frontend package.json exists

### Run Pre-Flight Check
- [ ] Run `./pre-deploy-check.sh` (Mac/Linux)
- [ ] Or run `pre-deploy-check.bat` (Windows)
- [ ] All checks passed or warnings acceptable

## 🚀 Deployment Steps

### 1. Install Lambda Dependencies
- [ ] Navigate to project root
- [ ] Run dependency installation:

**Windows:**
```powershell
cd backend/lambdas
foreach ($dir in "upload_handler", "summarize", "deviation_detection", "comparison_agent", "status") {
    cd $dir
    pip install -r requirements.txt -t . --upgrade
    cd ..
}
```

**Mac/Linux:**
```bash
cd backend/lambdas
for dir in upload_handler summarize deviation_detection comparison_agent status; do
    cd $dir
    pip install -r requirements.txt -t . --upgrade
    cd ..
done
```

- [ ] All dependencies installed successfully
- [ ] No error messages

### 2. Deploy Backend

**Option A: Using Script (Recommended)**
- [ ] Navigate to infrastructure folder: `cd infrastructure`
- [ ] Make script executable (Mac/Linux): `chmod +x deploy.sh`
- [ ] Run deployment: `./deploy.sh dev` or `deploy.bat dev`
- [ ] Wait for completion (10-15 minutes)
- [ ] No errors in output

**Option B: Manual SAM Deployment**
- [ ] Navigate to infrastructure folder: `cd infrastructure`
- [ ] Build: `sam build --template-file template.yaml`
- [ ] Deploy: `sam deploy --guided`
- [ ] Answer prompts:
  - [ ] Stack Name: `legal-doc-processing-dev`
  - [ ] AWS Region: `us-east-1` (or your preferred region)
  - [ ] Parameter Environment: `dev`
  - [ ] Confirm changes: `Y`
  - [ ] Allow IAM role creation: `Y`
  - [ ] Save configuration: `Y`
- [ ] Deployment successful

### 3. Capture Deployment Outputs
- [ ] Run: `aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query 'Stacks[0].Outputs' --output table`
- [ ] Copy ApiEndpoint URL
- [ ] Copy UploadBucket name
- [ ] Copy ProcessedBucket name
- [ ] Copy DocumentTable name
- [ ] Save outputs for reference

### 4. Test Backend Deployment

**Test API Endpoint:**
- [ ] Set API endpoint variable:
```bash
API_ENDPOINT="YOUR_API_ENDPOINT_HERE"
```

- [ ] Test upload:
```bash
curl -X POST $API_ENDPOINT/upload \
  -H "Content-Type: application/json" \
  -d '{"mode":"single","file_content":"dGVzdA==","file_name":"test.pdf"}'
```

- [ ] Received response with `doc_id`
- [ ] No errors

**Check AWS Resources:**
- [ ] Lambda functions created (5 total)
- [ ] API Gateway created
- [ ] S3 buckets created (2 total)
- [ ] DynamoDB table created
- [ ] Glue database created
- [ ] Glue crawler created
- [ ] CloudWatch log groups created

### 5. Configure Frontend
- [ ] Navigate to frontend folder: `cd frontend`
- [ ] Create `.env.production` file
- [ ] Add API endpoint:
```
REACT_APP_API_ENDPOINT=YOUR_API_ENDPOINT_HERE
```
- [ ] Save file

### 6. Test Frontend Locally with AWS Backend
- [ ] In frontend folder
- [ ] Install dependencies: `npm install`
- [ ] Build: `npm run build`
- [ ] Test locally: `npx serve -s build`
- [ ] Open http://localhost:3000
- [ ] Upload test document
- [ ] Verify processing works
- [ ] Check all features

### 7. Deploy Frontend (Optional)

**Option A: S3 Static Website**
- [ ] Create S3 bucket:
```bash
aws s3 mb s3://legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text)
```

- [ ] Enable website hosting:
```bash
aws s3 website s3://legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text) \
  --index-document index.html \
  --error-document index.html
```

- [ ] Upload build:
```bash
aws s3 sync build/ s3://legal-doc-frontend-prod-$(aws sts get-caller-identity --query Account --output text) --delete
```

- [ ] Configure bucket policy (make public)
- [ ] Get website URL
- [ ] Test frontend URL

**Option B: AWS Amplify**
- [ ] Install Amplify CLI: `npm install -g @aws-amplify/cli`
- [ ] Initialize: `amplify init`
- [ ] Add hosting: `amplify add hosting`
- [ ] Publish: `amplify publish`
- [ ] Get Amplify URL
- [ ] Test frontend URL

## ✅ Post-Deployment Verification

### Backend Verification
- [ ] All 5 Lambda functions listed:
```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `legal`)].FunctionName'
```

- [ ] API Gateway accessible
- [ ] S3 buckets exist and accessible
- [ ] DynamoDB table exists
- [ ] Glue resources created

### Functional Testing
- [ ] Upload single document via API
- [ ] Check status endpoint
- [ ] Verify document processing
- [ ] Upload comparison documents
- [ ] Verify comparison results
- [ ] Check CloudWatch logs

### Frontend Testing
- [ ] Frontend loads correctly
- [ ] Can upload documents
- [ ] Processing status updates
- [ ] Results display correctly
- [ ] All tabs work
- [ ] Comparison mode works
- [ ] No console errors

### Monitoring Setup
- [ ] CloudWatch logs accessible
- [ ] Can view Lambda logs
- [ ] Can view API Gateway logs
- [ ] Metrics visible in CloudWatch

## 📊 Cost Monitoring

- [ ] Review AWS Cost Explorer
- [ ] Set up billing alerts
- [ ] Configure budget alerts
- [ ] Review resource usage

## 🔒 Security Review

- [ ] IAM roles have least privilege
- [ ] S3 buckets not publicly accessible (except frontend if needed)
- [ ] API Gateway CORS configured correctly
- [ ] CloudWatch logging enabled
- [ ] Encryption at rest enabled

## 📝 Documentation

- [ ] API endpoint documented
- [ ] Frontend URL documented
- [ ] AWS resource names documented
- [ ] Deployment date recorded
- [ ] Team notified

## 🎯 Optional Enhancements

- [ ] Set up CloudWatch alarms
- [ ] Configure auto-scaling (if needed)
- [ ] Set up CI/CD pipeline
- [ ] Add API authentication
- [ ] Configure custom domain
- [ ] Set up CloudFront CDN
- [ ] Enable AWS WAF
- [ ] Configure backup policies

## 🐛 Troubleshooting

If deployment fails:

### Check Prerequisites
- [ ] All tools installed
- [ ] AWS credentials valid
- [ ] Correct region selected
- [ ] Sufficient IAM permissions

### Check Logs
- [ ] SAM build output
- [ ] SAM deploy output
- [ ] CloudFormation events
- [ ] Lambda function logs

### Common Issues
- [ ] Stack already exists → Delete and retry
- [ ] Insufficient permissions → Check IAM
- [ ] Python version mismatch → Use Python 3.12
- [ ] Timeout issues → Increase Lambda timeout
- [ ] CORS errors → Update API Gateway CORS

## 🔄 Rollback Plan

If needed to rollback:

- [ ] Note current stack version
- [ ] Delete CloudFormation stack:
```bash
aws cloudformation delete-stack --stack-name legal-doc-processing-dev
```

- [ ] Wait for deletion:
```bash
aws cloudformation wait stack-delete-complete --stack-name legal-doc-processing-dev
```

- [ ] Manually delete S3 buckets if needed
- [ ] Redeploy previous version

## ✨ Success Criteria

Deployment is successful when:

- [ ] All AWS resources created
- [ ] API endpoint responds correctly
- [ ] Frontend can upload documents
- [ ] Documents are processed successfully
- [ ] Results are displayed correctly
- [ ] No errors in CloudWatch logs
- [ ] All features working as expected

## 📞 Support

If you need help:

1. Check [AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md)
2. Review [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
3. Check CloudWatch logs
4. Review CloudFormation events
5. Verify IAM permissions

## 🎉 Deployment Complete!

Once all items are checked:

- [ ] System is live on AWS
- [ ] All features tested
- [ ] Documentation updated
- [ ] Team notified
- [ ] Monitoring configured
- [ ] Ready for production use

**Congratulations! Your Legal Document Processing System is now running on AWS! 🚀**

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Environment:** _______________
**API Endpoint:** _______________
**Frontend URL:** _______________
