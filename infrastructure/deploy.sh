#!/bin/bash

# Cloud-Native Legal Document Processing System - Deployment Script

set -e

# Configuration
ENVIRONMENT=${1:-dev}
STACK_NAME="legal-doc-processing-${ENVIRONMENT}"
REGION=${AWS_REGION:-us-east-1}

echo "========================================="
echo "Legal Document Processing System"
echo "Deployment Script"
echo "========================================="
echo "Environment: ${ENVIRONMENT}"
echo "Stack Name: ${STACK_NAME}"
echo "Region: ${REGION}"
echo "========================================="

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v sam &> /dev/null; then
    echo "ERROR: AWS SAM CLI is not installed"
    echo "Install from: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed"
    exit 1
fi

echo "✓ Prerequisites check passed"

# Install Python dependencies
echo ""
echo "Installing Lambda dependencies..."

LAMBDA_DIRS=(
    "../backend/lambdas/upload_handler"
    "../backend/lambdas/summarize"
    "../backend/lambdas/deviation_detection"
    "../backend/lambdas/comparison_agent"
    "../backend/lambdas/status"
)

for dir in "${LAMBDA_DIRS[@]}"; do
    if [ -f "${dir}/requirements.txt" ]; then
        echo "Installing dependencies for ${dir}..."
        pip install -r "${dir}/requirements.txt" -t "${dir}/" --upgrade
    fi
done

echo "✓ Dependencies installed"

# Build SAM application
echo ""
echo "Building SAM application..."
sam build --template-file template.yaml

echo "✓ Build complete"

# Deploy
echo ""
echo "Deploying to AWS..."
sam deploy \
    --template-file .aws-sam/build/template.yaml \
    --stack-name ${STACK_NAME} \
    --capabilities CAPABILITY_IAM \
    --region ${REGION} \
    --parameter-overrides Environment=${ENVIRONMENT} \
    --no-fail-on-empty-changeset \
    --resolve-s3

echo "✓ Deployment complete"

# Get outputs
echo ""
echo "========================================="
echo "Deployment Outputs"
echo "========================================="

aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --region ${REGION} \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

# Run Glue crawler
echo ""
echo "Starting Glue crawler..."
CRAWLER_NAME="legal-doc-crawler-${ENVIRONMENT}"
aws glue start-crawler --name ${CRAWLER_NAME} --region ${REGION} || echo "Crawler already running or not found"

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Update frontend with API endpoint"
echo "2. Test API endpoints"
echo "3. Upload test documents"
echo ""
