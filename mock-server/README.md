# Mock Server for Legal Document Processing System

A fully functional mock server that simulates AWS Lambda backend behavior for local development and testing.

## Features

✅ **Complete API Simulation**
- All 3 API endpoints (upload, compare, status)
- Realistic processing stages
- Simulated delays (3s, 6s, 9s)
- Unique document IDs

✅ **Realistic Mock Data**
- 10 legal clauses extracted
- Executive summary generation
- Deviation detection with risk scoring
- Document comparison with conflicts

✅ **Developer Friendly**
- CORS enabled
- Detailed console logging
- Debug endpoints
- Test HTML page included

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Server

```bash
npm start
```

Server will run on `http://localhost:3001`

### 3. Test with HTML Page

Open `test.html` in your browser:
```bash
# On Mac
open test.html

# On Windows
start test.html

# On Linux
xdg-open test.html
```

## API Endpoints

### POST /upload

Upload a single document for processing.

**Request:**
```json
{
  "mode": "single",
  "file_content": "base64_encoded_content",
  "file_name": "contract.pdf",
  "content_type": "application/pdf"
}
```

**Response:**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "uploaded",
  "message": "Document uploaded successfully. Processing initiated.",
  "s3_key": "uploads/550e8400-e29b-41d4-a716-446655440000/contract.pdf"
}
```

### POST /compare

Upload two documents for comparison.

**Request:**
```json
{
  "mode": "compare",
  "file1_content": "base64_encoded_content",
  "file1_name": "contract_v1.pdf",
  "file2_content": "base64_encoded_content",
  "file2_name": "contract_v2.pdf"
}
```

**Response:**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440001",
  "status": "uploaded",
  "message": "Documents uploaded successfully. Comparison processing initiated.",
  "s3_keys": [
    "uploads/.../version1/contract_v1.pdf",
    "uploads/.../version2/contract_v2.pdf"
  ]
}
```

### GET /status/:id

Get processing status and results.

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

**Response (Complete):**
```json
{
  "doc_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "complete",
  "processing_stage": "deviation_detection_complete",
  "mode": "single",
  "extracted_clauses": { ... },
  "summary": "...",
  "deviation_flags": [ ... ],
  "risk_score": 58
}
```

## Processing Stages

The mock server simulates realistic processing with delays:

1. **Immediate**: `status: "uploaded"`, `processing_stage: "pending"`
2. **After 3s**: `processing_stage: "clause_extraction_complete"` + clauses + summary
3. **After 6s**: `processing_stage: "deviation_detection_complete"` + deviations + risk_score
4. **After 9s** (compare mode): `processing_stage: "comparison_complete"` + conflicts

## Debug Endpoints

### GET /documents

List all documents in memory.

```bash
curl http://localhost:3001/documents
```

### DELETE /documents

Clear all documents from memory.

```bash
curl -X DELETE http://localhost:3001/documents
```

### GET /

Health check and server info.

```bash
curl http://localhost:3001/
```

## Testing with curl

### Upload Document

```bash
curl -X POST http://localhost:3001/upload \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "single",
    "file_content": "dGVzdCBjb250ZW50",
    "file_name": "test.pdf"
  }'
```

### Check Status

```bash
# Replace DOC_ID with actual ID from upload response
curl http://localhost:3001/status/DOC_ID
```

### Compare Documents

```bash
curl -X POST http://localhost:3001/compare \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "compare",
    "file1_content": "dGVzdCBjb250ZW50MQ==",
    "file1_name": "v1.pdf",
    "file2_content": "dGVzdCBjb250ZW50Mg==",
    "file2_name": "v2.pdf"
  }'
```

## Mock Data

### Extracted Clauses (10)

- Parties
- Term
- Payment Clause
- Liability
- Confidentiality
- Termination
- Governing Law
- Intellectual Property
- Warranties
- Force Majeure

### Deviation Flags (4)

1. **High Risk**: Unlimited liability for IP/confidentiality breaches
2. **Medium Risk**: Automatic renewal clause
3. **Medium Risk**: High interest rate on late payments
4. **Low Risk**: No arbitration clause

### Risk Score

- Default: 58/100
- Calculated based on severity weights

### Comparison Conflicts (5)

1. **High**: Payment terms changed (30→60 days, interest 1.0%→1.5%)
2. **High**: Liability cap modified with unlimited exception
3. **Medium**: Termination notice period doubled (30→60 days)
4. **Medium**: Confidentiality period extended (3→5 years)
5. **High**: New IP clause added

## Console Logging

The server logs all activity:

```
📤 Upload request received
✅ Document uploaded: 550e8400-e29b-41d4-a716-446655440000
📊 Status request for: 550e8400-e29b-41d4-a716-446655440000
✅ Status: complete - deviation_detection_complete
```

## Configuration

### Change Port

Edit `server.js`:
```javascript
const PORT = 3002; // Change to desired port
```

### Modify Processing Delays

Edit `simulateProcessing()` function:
```javascript
setTimeout(() => {
  // Stage 2
}, 5000); // Change from 3000 to 5000ms
```

### Customize Mock Data

Edit the mock data constants:
- `mockExtractedClauses`
- `mockSummary`
- `mockDeviationFlags`
- `mockConflicts`
- `mockComparisonSummary`

## Development Mode

Use nodemon for auto-restart on file changes:

```bash
npm run dev
```

## Integration with Frontend

The frontend is pre-configured to use the mock server in development:

**frontend/.env.development:**
```
REACT_APP_API_ENDPOINT=http://localhost:3001
```

Just start both servers:
```bash
# Terminal 1
cd mock-server
npm start

# Terminal 2
cd frontend
npm start
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 3001
lsof -i :3001

# Kill process
kill -9 PID
```

Or change the port in `server.js`.

### CORS Errors

CORS is enabled for all origins. If you still see errors:
1. Verify server is running
2. Check browser console for actual error
3. Try clearing browser cache

### Server Not Starting

1. Check Node.js version: `node --version` (should be 14+)
2. Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`
3. Check for syntax errors in `server.js`

## Production Note

⚠️ **This is a mock server for development only!**

For production:
- Deploy actual AWS Lambda functions
- Use real API Gateway
- Integrate with actual LLM services
- Implement proper authentication

## License

MIT
