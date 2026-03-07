# API Documentation

## Base URL

```
https://{api-id}.execute-api.{region}.amazonaws.com/{environment}
```

## Authentication

Currently, the API does not require authentication. For production, implement:
- API Keys
- AWS IAM authentication
- Cognito User Pools
- Custom authorizers

## Endpoints

### 1. Upload Single Document

Upload a single legal document for processing.

**Endpoint:** `POST /upload`

**Request Body:**
```json
{
  "mode": "single",
  "file_content": "base64_encoded_file_content",
  "file_name": "contract.pdf",
  "content_type": "application/pdf"
}
```

**Parameters:**
- `mode` (string, required): Must be "single"
- `file_content` (string, required): Base64 encoded file content
- `file_name` (string, required): Original filename
- `content_type` (string, optional): MIME type (default: application/pdf)

**Response:**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "uploaded",
  "message": "Document uploaded successfully. Processing initiated.",
  "s3_key": "uploads/550e8400-e29b-41d4-a716-446655440000/contract.pdf"
}
```

**Status Codes:**
- `200 OK`: Document uploaded successfully
- `400 Bad Request`: Invalid request parameters
- `500 Internal Server Error`: Server error

**Example:**
```bash
curl -X POST https://api-endpoint/upload \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "single",
    "file_content": "JVBERi0xLjQKJeLjz9MK...",
    "file_name": "contract.pdf",
    "content_type": "application/pdf"
  }'
```

---

### 2. Compare Two Documents

Upload two document versions for comparison.

**Endpoint:** `POST /compare`

**Request Body:**
```json
{
  "mode": "compare",
  "file1_content": "base64_encoded_file1_content",
  "file1_name": "contract_v1.pdf",
  "file2_content": "base64_encoded_file2_content",
  "file2_name": "contract_v2.pdf"
}
```

**Parameters:**
- `mode` (string, required): Must be "compare"
- `file1_content` (string, required): Base64 encoded first file
- `file1_name` (string, required): First filename
- `file2_content` (string, required): Base64 encoded second file
- `file2_name` (string, required): Second filename

**Response:**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440001",
  "status": "uploaded",
  "message": "Documents uploaded successfully. Comparison processing initiated.",
  "s3_keys": [
    "uploads/550e8400-e29b-41d4-a716-446655440001/version1/contract_v1.pdf",
    "uploads/550e8400-e29b-41d4-a716-446655440001/version2/contract_v2.pdf"
  ]
}
```

**Status Codes:**
- `200 OK`: Documents uploaded successfully
- `400 Bad Request`: Invalid request parameters
- `500 Internal Server Error`: Server error

---

### 3. Get Document Status

Retrieve processing status and results for a document.

**Endpoint:** `GET /status/{doc_id}`

**Path Parameters:**
- `doc_id` (string, required): Document ID returned from upload

**Response (Processing):**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "uploaded",
  "processing_stage": "clause_extraction_complete",
  "mode": "single",
  "timestamp": "2024-02-24T10:30:00.000Z"
}
```

**Response (Complete - Single Document):**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "complete",
  "processing_stage": "deviation_detection_complete",
  "mode": "single",
  "timestamp": "2024-02-24T10:30:00.000Z",
  "extracted_clauses": {
    "Parties": "Agreement between Company A and Company B",
    "Term": "12 months from effective date",
    "Payment Clause": "Net 30 payment terms",
    "Liability": "Limited to contract value",
    "Confidentiality": "5 year confidentiality period",
    "Termination": "30 days written notice",
    "Governing Law": "State of Delaware",
    "Intellectual Property": "All IP remains with creator",
    "Warranties": "Standard warranties apply",
    "Force Majeure": "Standard force majeure provisions"
  },
  "summary": "EXECUTIVE LEGAL SUMMARY\n\nCONTRACT PURPOSE:\n...",
  "deviation_flags": [
    {
      "Clause": "Liability",
      "Risk Level": "High",
      "Reason": "Risky keyword 'unlimited' detected in Liability",
      "Type": "Risky Wording",
      "Context": "Party shall have unlimited liability..."
    }
  ],
  "risk_score": 45
}
```

**Response (Complete - Comparison):**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440001",
  "status": "complete",
  "processing_stage": "comparison_complete",
  "mode": "compare",
  "timestamp": "2024-02-24T10:30:00.000Z",
  "extracted_clauses": { ... },
  "summary": "...",
  "deviation_flags": [ ... ],
  "risk_score": 45,
  "conflicts": [
    {
      "Clause": "Payment Clause",
      "Type": "Modified Clause",
      "Version1": "Payment within 30 days",
      "Version2": "Payment within 60 days",
      "Conflict Summary": "Payment terms changed from 30 to 60 days",
      "Similarity Score": 0.72,
      "Severity": "High"
    }
  ],
  "comparison_summary": "DOCUMENT COMPARISON SUMMARY\n\nTotal Conflicts Detected: 5\n..."
}
```

**Status Codes:**
- `200 OK`: Status retrieved successfully
- `404 Not Found`: Document ID not found
- `500 Internal Server Error`: Server error

**Example:**
```bash
curl https://api-endpoint/status/550e8400-e29b-41d4-a716-446655440000
```

---

## Processing Stages

Documents go through the following stages:

1. `pending` - Document uploaded, waiting for processing
2. `uploaded` - Document stored in S3
3. `clause_extraction_complete` - Text extracted and clauses identified
4. `deviation_detection_complete` - Deviation analysis complete (single mode)
5. `comparison_complete` - Comparison analysis complete (compare mode)
6. `complete` - All processing finished

## Data Models

### Extracted Clauses
```typescript
{
  "Parties": string,
  "Term": string,
  "Payment Clause": string,
  "Liability": string,
  "Confidentiality": string,
  "Termination": string,
  "Governing Law": string,
  "Intellectual Property": string,
  "Warranties": string,
  "Force Majeure": string
}
```

### Deviation Flag
```typescript
{
  "Clause": string,
  "Risk Level": "High" | "Medium" | "Low",
  "Reason": string,
  "Type": "Missing Clause" | "Risky Wording" | "Modified Clause",
  "Context"?: string,
  "Similarity Score"?: number
}
```

### Conflict
```typescript
{
  "Clause": string,
  "Type": "Added Clause" | "Removed Clause" | "Modified Clause",
  "Version1": string | null,
  "Version2": string | null,
  "Conflict Summary": string,
  "Similarity Score"?: number,
  "Severity": "High" | "Medium" | "Low"
}
```

## Error Responses

All error responses follow this format:

```json
{
  "error": "Error message description"
}
```

**Common Error Codes:**
- `400 Bad Request`: Invalid input parameters
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server-side error
- `503 Service Unavailable`: Service temporarily unavailable

## Rate Limits

Current implementation has no rate limits. For production:
- Implement API Gateway usage plans
- Set throttling limits
- Use API keys for tracking

## CORS

CORS is enabled for all origins (`*`). For production:
- Restrict to specific domains
- Configure allowed methods and headers

## Webhooks (Future Enhancement)

Future versions may support webhooks for processing completion:

```json
{
  "webhook_url": "https://your-domain.com/webhook",
  "events": ["processing_complete", "error"]
}
```

## SDK Examples

### JavaScript/Node.js
```javascript
const axios = require('axios');

async function uploadDocument(filePath) {
  const fs = require('fs');
  const fileContent = fs.readFileSync(filePath, 'base64');
  
  const response = await axios.post('https://api-endpoint/upload', {
    mode: 'single',
    file_content: fileContent,
    file_name: 'contract.pdf',
    content_type: 'application/pdf'
  });
  
  return response.data.doc_id;
}

async function getStatus(docId) {
  const response = await axios.get(`https://api-endpoint/status/${docId}`);
  return response.data;
}
```

### Python
```python
import requests
import base64

def upload_document(file_path):
    with open(file_path, 'rb') as f:
        file_content = base64.b64encode(f.read()).decode()
    
    response = requests.post('https://api-endpoint/upload', json={
        'mode': 'single',
        'file_content': file_content,
        'file_name': 'contract.pdf',
        'content_type': 'application/pdf'
    })
    
    return response.json()['doc_id']

def get_status(doc_id):
    response = requests.get(f'https://api-endpoint/status/{doc_id}')
    return response.json()
```

## Testing

Use the provided Postman collection in `/docs/postman_collection.json`

Or test with curl:
```bash
# Upload
DOC_ID=$(curl -X POST https://api-endpoint/upload \
  -H "Content-Type: application/json" \
  -d @test_payload.json | jq -r '.doc_id')

# Poll status
while true; do
  STATUS=$(curl https://api-endpoint/status/$DOC_ID | jq -r '.status')
  echo "Status: $STATUS"
  [ "$STATUS" = "complete" ] && break
  sleep 5
done

# Get results
curl https://api-endpoint/status/$DOC_ID | jq .
```
