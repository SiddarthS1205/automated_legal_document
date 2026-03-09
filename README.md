# Cloud-Native Legal Document Summarization & Clause Comparison System

🎯 **Production-ready serverless system for automated legal document analysis**

## ✨ Key Features

- 📄 **Multi-page contract processing** (PDF/DOCX)
- 🤖 **GenAI-powered clause extraction** (10 standard legal clauses)
- 📊 **1-page executive summary** generation
- 🔍 **ML-based deviation detection** with risk scoring
- ⚖️ **Document version comparison** with conflict analysis
- ☁️ **Fully serverless AWS architecture**

## 🚀 Tech Stack

- **Frontend**: React 18 + Axios
- **Backend**: AWS Lambda (Python 3.12), API Gateway, S3, DynamoDB, AWS Glue
- **ML/AI**: Sentence Transformers, TF-IDF, scikit-learn
- **Deployment**: AWS SAM (Infrastructure as Code)

## System Architecture

Frontend (React)
    ↓
API Gateway
    ↓
AWS Lambda
    ↓
S3 Storage
    ↓
ML Engine (Sentence Transformers)
    ↓
GenAI Clause Extraction
    ↓
Risk Analyzer

## 📁 Project Structure

```
├── 📖 Documentation
│   ├── QUICK_START.md          ⭐ Start here!
│   ├── INDEX.md                📚 Documentation index
│   └── docs/                   Detailed guides
├── 🖥️ mock-server/             Local testing server
├── 🎨 frontend/                React application
├── ⚡ backend/                 Lambda functions
├── 🤖 ml/                      ML models
└── ☁️ infrastructure/          AWS SAM templates
```

## Quick Start

### 🚀 Local Development (No AWS Required!)

Test the complete system locally with our mock server:

```bash
# 1. Start Mock Server (Terminal 1)
cd mock-server
npm install
npm start

# 2. Start Frontend (Terminal 2)
cd frontend
npm install
npm start
```

The app will open at `http://localhost:3000` with full functionality!

📖 **See [START_LOCAL.md](START_LOCAL.md) for detailed instructions**

### 🧪 Quick Test

Open `mock-server/test.html` in your browser to test the API without the frontend.

### ☁️ AWS Deployment

**Step 1: Pre-Flight Check**
```bash
# Mac/Linux
./pre-deploy-check.sh

# Windows
pre-deploy-check.bat
```

**Step 2: Deploy**
```bash
cd infrastructure

# Mac/Linux
./deploy.sh dev

# Windows
deploy.bat dev
```

**Step 3: Get API Endpoint**
```bash
aws cloudformation describe-stacks \
  --stack-name legal-doc-processing-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text
```

📖 **Detailed Guides:**
- ⚡ **[DEPLOY_QUICK_REFERENCE.md](DEPLOY_QUICK_REFERENCE.md)** - One-page quick reference
- 📋 **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Step-by-step checklist
- 📚 **[AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md)** - Complete deployment guide
- 🔧 **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - Technical details

## API Endpoints
- `POST /upload` - Upload single document
- `POST /compare` - Upload two documents for comparison
- `GET /status/{id}` - Check processing status

## 📚 Documentation

### Quick Links
- 📖 **[Documentation Index](INDEX.md)** - Navigate all docs
- ⚡ **[Quick Start Guide](QUICK_START.md)** - Get running in 3 minutes
- 🎨 **[Features Demo](FEATURES_DEMO.md)** - Visual walkthrough
- 🔧 **[Local Testing](START_LOCAL.md)** - Detailed setup guide

### Detailed Guides
- 🏗️ **[Architecture](docs/ARCHITECTURE.md)** - System design
- 📡 **[API Documentation](docs/API_DOCUMENTATION.md)** - Complete API reference
- ☁️ **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - AWS deployment
- 🧪 **[Testing Guide](docs/TESTING_GUIDE.md)** - Testing strategies
- 📋 **[Project Summary](docs/PROJECT_SUMMARY.md)** - Executive overview

## Live Demo
Frontend:
http://legal-doc-frontend-dev-623242866456.s3-website-us-east-1.amazonaws.com
This demo allows users to upload legal documents and generate AI-powered summaries and clause comparisons.

## Conclusion

This project demonstrates a cloud-native AI system for automated legal document analysis.

Key capabilities include:
- GenAI-based clause extraction
- ML-powered deviation detection
- Automated executive summaries
- Serverless AWS deployment

The architecture ensures scalability, cost efficiency, and real-time document analysis for legal professionals.
