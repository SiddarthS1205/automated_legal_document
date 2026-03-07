#!/bin/bash

# Pre-Deployment Verification Script
# Checks if all prerequisites are met before AWS deployment

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║     AWS Deployment Pre-Flight Check                          ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0

# Function to check command existence
check_command() {
    if command -v $1 &> /dev/null; then
        echo "✅ $2 installed"
        if [ ! -z "$3" ]; then
            VERSION=$($1 $3 2>&1)
            echo "   Version: $VERSION"
        fi
        return 0
    else
        echo "❌ $2 NOT installed"
        echo "   Install from: $4"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Check Node.js
echo "Checking Node.js..."
if check_command "node" "Node.js" "--version" "https://nodejs.org/"; then
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ $NODE_VERSION -lt 18 ]; then
        echo "⚠️  Node.js version should be 18 or higher"
        WARNINGS=$((WARNINGS + 1))
    fi
fi
echo ""

# Check Python
echo "Checking Python..."
if check_command "python3" "Python 3" "--version" "https://www.python.org/"; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [ "$PYTHON_VERSION" != "3.12" ]; then
        echo "⚠️  Python 3.12 is recommended (found $PYTHON_VERSION)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi
echo ""

# Check pip
echo "Checking pip..."
check_command "pip" "pip" "--version" "https://pip.pypa.io/"
echo ""

# Check AWS CLI
echo "Checking AWS CLI..."
check_command "aws" "AWS CLI" "--version" "https://aws.amazon.com/cli/"
echo ""

# Check AWS SAM CLI
echo "Checking AWS SAM CLI..."
check_command "sam" "AWS SAM CLI" "--version" "https://aws.amazon.com/serverless/sam/"
echo ""

# Check Git
echo "Checking Git..."
check_command "git" "Git" "--version" "https://git-scm.com/"
echo ""

# Check AWS Credentials
echo "Checking AWS Credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials configured"
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)
    echo "   Account: $ACCOUNT"
    echo "   Region: $REGION"
else
    echo "❌ AWS credentials NOT configured"
    echo "   Run: aws configure"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check Lambda Dependencies
echo "Checking Lambda Dependencies..."
LAMBDA_DIRS=("upload_handler" "summarize" "deviation_detection" "comparison_agent" "status")
MISSING_DEPS=0

for dir in "${LAMBDA_DIRS[@]}"; do
    if [ -f "backend/lambdas/$dir/requirements.txt" ]; then
        echo "✅ backend/lambdas/$dir/requirements.txt found"
    else
        echo "❌ backend/lambdas/$dir/requirements.txt NOT found"
        MISSING_DEPS=$((MISSING_DEPS + 1))
    fi
done

if [ $MISSING_DEPS -gt 0 ]; then
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check SAM Template
echo "Checking SAM Template..."
if [ -f "infrastructure/template.yaml" ]; then
    echo "✅ infrastructure/template.yaml found"
else
    echo "❌ infrastructure/template.yaml NOT found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check Frontend
echo "Checking Frontend..."
if [ -f "frontend/package.json" ]; then
    echo "✅ frontend/package.json found"
    if [ -d "frontend/node_modules" ]; then
        echo "✅ frontend dependencies installed"
    else
        echo "⚠️  frontend dependencies not installed"
        echo "   Run: cd frontend && npm install"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ frontend/package.json NOT found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Summary
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║     Pre-Flight Check Summary                                 ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 All checks passed! You're ready to deploy."
    echo ""
    echo "Next steps:"
    echo "1. cd infrastructure"
    echo "2. ./deploy.sh dev"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  $WARNINGS warning(s) found, but you can proceed."
    echo ""
    echo "Next steps:"
    echo "1. cd infrastructure"
    echo "2. ./deploy.sh dev"
    echo ""
    exit 0
else
    echo "❌ $ERRORS error(s) and $WARNINGS warning(s) found."
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    exit 1
fi
