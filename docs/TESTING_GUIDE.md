# Testing Guide

## Overview

Comprehensive testing strategy for the Legal Document Processing System.

## Test Levels

### 1. Unit Tests

#### Backend Lambda Functions

**Setup:**
```bash
pip install pytest pytest-cov moto
```

**Test Structure:**
```
backend/
  tests/
    test_upload_handler.py
    test_summarize.py
    test_deviation_detection.py
    test_comparison_agent.py
    test_status.py
```

**Example Test:**
```python
# backend/tests/test_upload_handler.py
import json
import pytest
from moto import mock_s3, mock_dynamodb
from lambdas.upload_handler.handler import lambda_handler

@mock_s3
@mock_dynamodb
def test_upload_handler_single_mode():
    # Setup
    event = {
        'body': json.dumps({
            'mode': 'single',
            'file_content': 'test_content',
            'file_name': 'test.pdf'
        })
    }
    
    # Execute
    response = lambda_handler(event, {})
    
    # Assert
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert 'doc_id' in body
    assert body['status'] == 'uploaded'
```

**Run Tests:**
```bash
cd backend
pytest tests/ -v --cov=lambdas
```

#### ML Models

```python
# ml/tests/test_deviation_model.py
import pytest
from ml.deviation_model import DeviationDetector

def test_tfidf_similarity():
    detector = DeviationDetector()
    
    text1 = "This is a test contract clause"
    text2 = "This is a test contract clause"
    
    similarity = detector.calculate_tfidf_similarity(text1, text2)
    
    assert similarity > 0.9

def test_detect_missing_clause():
    detector = DeviationDetector()
    
    clauses = {
        "Parties": "Company A and Company B"
    }
    
    template = {
        "Parties": {"required": True},
        "Term": {"required": True}
    }
    
    deviations = detector.detect_deviations(clauses, template)
    
    assert len(deviations) > 0
    assert any(d['clause'] == 'Term' for d in deviations)
```

### 2. Integration Tests

#### API Integration Tests

**Setup:**
```bash
npm install --save-dev jest supertest
```

**Test API Endpoints:**
```javascript
// backend/tests/integration/api.test.js
const request = require('supertest');

const API_ENDPOINT = process.env.API_ENDPOINT;

describe('API Integration Tests', () => {
  test('POST /upload - single document', async () => {
    const response = await request(API_ENDPOINT)
      .post('/upload')
      .send({
        mode: 'single',
        file_content: Buffer.from('test').toString('base64'),
        file_name: 'test.pdf'
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('doc_id');
  });

  test('GET /status/{id} - retrieve status', async () => {
    // First upload
    const uploadResponse = await request(API_ENDPOINT)
      .post('/upload')
      .send({
        mode: 'single',
        file_content: Buffer.from('test').toString('base64'),
        file_name: 'test.pdf'
      });
    
    const docId = uploadResponse.body.doc_id;
    
    // Then check status
    const statusResponse = await request(API_ENDPOINT)
      .get(`/status/${docId}`);
    
    expect(statusResponse.status).toBe(200);
    expect(statusResponse.body.doc_id).toBe(docId);
  });
});
```

**Run Integration Tests:**
```bash
API_ENDPOINT=https://your-api.execute-api.us-east-1.amazonaws.com/dev npm test
```

### 3. End-to-End Tests

#### Frontend E2E Tests

**Setup:**
```bash
cd frontend
npm install --save-dev @testing-library/react @testing-library/jest-dom
```

**Test Components:**
```javascript
// frontend/src/components/__tests__/FileUpload.test.js
import { render, screen, fireEvent } from '@testing-library/react';
import FileUpload from '../FileUpload';

test('renders file upload component', () => {
  render(<FileUpload mode="single" onUploadComplete={() => {}} />);
  
  expect(screen.getByText(/drag & drop/i)).toBeInTheDocument();
});

test('handles file drop', async () => {
  const onUploadComplete = jest.fn();
  render(<FileUpload mode="single" onUploadComplete={onUploadComplete} />);
  
  const file = new File(['test'], 'test.pdf', { type: 'application/pdf' });
  const input = screen.getByRole('button');
  
  fireEvent.drop(input, {
    dataTransfer: {
      files: [file]
    }
  });
  
  // Wait for upload
  await screen.findByText(/uploading/i);
});
```

**Run Frontend Tests:**
```bash
cd frontend
npm test
```

### 4. Load Testing

#### Using Artillery

**Setup:**
```bash
npm install -g artillery
```

**Load Test Configuration:**
```yaml
# tests/load/artillery-config.yml
config:
  target: "https://your-api.execute-api.us-east-1.amazonaws.com/dev"
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 120
      arrivalRate: 10
      name: "Sustained load"
    - duration: 60
      arrivalRate: 20
      name: "Peak load"
  processor: "./load-test-processor.js"

scenarios:
  - name: "Upload and check status"
    flow:
      - post:
          url: "/upload"
          json:
            mode: "single"
            file_content: "{{ $randomBase64 }}"
            file_name: "test.pdf"
          capture:
            - json: "$.doc_id"
              as: "docId"
      - think: 5
      - get:
          url: "/status/{{ docId }}"
```

**Run Load Test:**
```bash
artillery run tests/load/artillery-config.yml
```

### 5. Security Testing

#### API Security Tests

```bash
# Test CORS
curl -H "Origin: http://evil.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS \
  https://your-api.execute-api.us-east-1.amazonaws.com/dev/upload

# Test SQL injection (should be safe)
curl -X POST https://your-api.execute-api.us-east-1.amazonaws.com/dev/upload \
  -H "Content-Type: application/json" \
  -d '{"mode":"single","file_name":"test.pdf; DROP TABLE--"}'

# Test XSS (should be safe)
curl -X POST https://your-api.execute-api.us-east-1.amazonaws.com/dev/upload \
  -H "Content-Type: application/json" \
  -d '{"mode":"single","file_name":"<script>alert(1)</script>"}'
```

## Test Data

### Sample Documents

Create test documents in `tests/fixtures/`:

```
tests/
  fixtures/
    sample_contract.pdf
    sample_contract_v1.pdf
    sample_contract_v2.pdf
    malformed.pdf
    large_document.pdf
```

### Test Payloads

```json
// tests/fixtures/upload_payload.json
{
  "mode": "single",
  "file_content": "JVBERi0xLjQKJeLjz9MK...",
  "file_name": "test_contract.pdf",
  "content_type": "application/pdf"
}
```

## Manual Testing

### Test Checklist

#### Single Document Upload
- [ ] Upload PDF document
- [ ] Upload DOCX document
- [ ] Upload large document (>10MB)
- [ ] Upload invalid file type
- [ ] Check processing status
- [ ] Verify extracted clauses
- [ ] Verify summary generation
- [ ] Verify deviation detection
- [ ] Check risk score calculation

#### Document Comparison
- [ ] Upload two identical documents
- [ ] Upload two different versions
- [ ] Upload documents with major differences
- [ ] Verify conflict detection
- [ ] Verify similarity scores
- [ ] Check comparison summary

#### Error Handling
- [ ] Upload without file
- [ ] Upload corrupted file
- [ ] Check non-existent document status
- [ ] Test API timeout
- [ ] Test network errors

### Test Scenarios

#### Scenario 1: Standard Contract Processing
1. Upload standard contract PDF
2. Wait for processing (30-60 seconds)
3. Check status endpoint
4. Verify all clauses extracted
5. Verify summary generated
6. Check deviation flags
7. Verify risk score

#### Scenario 2: High-Risk Contract
1. Upload contract with risky clauses
2. Wait for processing
3. Verify high-risk deviations detected
4. Check risk score > 70
5. Verify specific risky keywords flagged

#### Scenario 3: Document Comparison
1. Upload two contract versions
2. Wait for processing (60-90 seconds)
3. Verify conflicts detected
4. Check specific clause changes
5. Verify severity levels
6. Check comparison summary

## Automated Testing Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.12'
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements-dev.txt
      - name: Run tests
        run: |
          cd backend
          pytest tests/ -v --cov=lambdas

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: |
          cd frontend
          npm install
      - name: Run tests
        run: |
          cd frontend
          npm test -- --coverage

  integration-test:
    runs-on: ubuntu-latest
    needs: [test-backend, test-frontend]
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to test environment
        run: |
          cd infrastructure
          sam deploy --stack-name test-stack --no-confirm-changeset
      - name: Run integration tests
        run: |
          npm run test:integration
      - name: Cleanup
        run: |
          aws cloudformation delete-stack --stack-name test-stack
```

## Performance Benchmarks

### Expected Performance

| Operation | Target | Acceptable |
|-----------|--------|------------|
| Upload API Response | < 1s | < 3s |
| Text Extraction | < 10s | < 30s |
| Clause Extraction | < 20s | < 60s |
| Deviation Detection | < 5s | < 15s |
| Comparison | < 30s | < 90s |
| Status API Response | < 500ms | < 2s |

### Load Test Targets

| Metric | Target |
|--------|--------|
| Concurrent Users | 100 |
| Requests/Second | 50 |
| Error Rate | < 1% |
| P95 Latency | < 5s |
| P99 Latency | < 10s |

## Monitoring Tests

### CloudWatch Alarms

```bash
# Create test alarm
aws cloudwatch put-metric-alarm \
  --alarm-name legal-doc-error-rate \
  --alarm-description "Alert on high error rate" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

### Log Analysis

```bash
# Check for errors in logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/legal-summarize-dev \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000

# Check processing times
aws logs filter-log-events \
  --log-group-name /aws/lambda/legal-summarize-dev \
  --filter-pattern "[time, request_id, level, msg, duration]" \
  --start-time $(date -d '1 hour ago' +%s)000
```

## Continuous Testing

### Pre-commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running tests before commit..."

# Backend tests
cd backend
pytest tests/ -v
if [ $? -ne 0 ]; then
    echo "Backend tests failed"
    exit 1
fi

# Frontend tests
cd ../frontend
npm test -- --watchAll=false
if [ $? -ne 0 ]; then
    echo "Frontend tests failed"
    exit 1
fi

echo "All tests passed!"
```

## Test Reports

### Generate Coverage Report

```bash
# Backend
cd backend
pytest tests/ --cov=lambdas --cov-report=html
open htmlcov/index.html

# Frontend
cd frontend
npm test -- --coverage --watchAll=false
open coverage/lcov-report/index.html
```

### Generate Test Report

```bash
# Backend
pytest tests/ --junitxml=test-results.xml

# Frontend
npm test -- --reporters=default --reporters=jest-junit
```
