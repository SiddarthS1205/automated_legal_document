# 🚀 Start Local Development

This guide will help you run the entire system locally without deploying to AWS.

## Prerequisites

- Node.js 18+ installed
- npm or yarn installed

## Quick Start (3 Steps)

### Step 1: Install Mock Server Dependencies

```bash
cd mock-server
npm install
```

### Step 2: Install Frontend Dependencies

```bash
cd ../frontend
npm install
```

### Step 3: Start Both Servers

Open **TWO terminal windows**:

**Terminal 1 - Mock Server:**
```bash
cd mock-server
npm start
```

You should see:
```
🚀 ========================================
🚀 Legal Document Processing Mock Server
🚀 ========================================
🚀 Server running on http://localhost:3001
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm start
```

The React app will automatically open at `http://localhost:3000`

## 🎯 Testing the System

### Test Single Document Upload

1. Click on "Single Document" mode (default)
2. Drag and drop any PDF or DOCX file (or click to select)
3. Wait for processing (simulated, takes ~6 seconds)
4. View results in tabs:
   - **Summary**: Executive legal summary
   - **Clauses**: 10 extracted legal clauses
   - **Deviations**: Risk analysis with deviation flags

### Test Document Comparison

1. Click on "Compare Documents" mode
2. Upload two documents (can be the same file twice for testing)
3. Click "Compare Documents"
4. Wait for processing (simulated, takes ~9 seconds)
5. View results in tabs:
   - **Summary**: Executive summary
   - **Clauses**: Extracted clauses
   - **Deviations**: Risk analysis
   - **Comparison**: Side-by-side conflict analysis

## 🔍 What You'll See

### Mock Data Includes:

**Extracted Clauses:**
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

**Deviation Analysis:**
- 4 deviation flags
- Risk score: 58/100
- High, Medium, and Low severity items

**Comparison Results (Compare Mode):**
- 5 conflicts detected
- 3 High severity, 2 Medium severity
- Added, removed, and modified clauses
- Similarity scores

## 📊 Mock Server Features

The mock server simulates realistic AWS Lambda behavior:

- ✅ Accepts file uploads (base64 encoded)
- ✅ Generates unique document IDs
- ✅ Simulates processing stages:
  - `pending` → `clause_extraction_complete` → `deviation_detection_complete` → `complete`
- ✅ Returns realistic legal document analysis
- ✅ Supports both single and comparison modes
- ✅ Includes processing delays (3s, 6s, 9s stages)

## 🛠️ Development Tips

### View Mock Server Logs

The mock server logs all requests:
```
📤 Upload request received
✅ Document uploaded: 550e8400-e29b-41d4-a716-446655440000
📊 Status request for: 550e8400-e29b-41d4-a716-446655440000
✅ Status: complete - deviation_detection_complete
```

### Debug Endpoints

**List all documents:**
```bash
curl http://localhost:3001/documents
```

**Clear all documents:**
```bash
curl -X DELETE http://localhost:3001/documents
```

**Check server health:**
```bash
curl http://localhost:3001/
```

### Test with curl

**Upload document:**
```bash
curl -X POST http://localhost:3001/upload \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "single",
    "file_content": "dGVzdCBjb250ZW50",
    "file_name": "test.pdf"
  }'
```

**Check status:**
```bash
curl http://localhost:3001/status/YOUR_DOC_ID
```

## 🎨 Frontend Features to Test

### File Upload Component
- Drag and drop files
- Click to select files
- File type validation (PDF, DOCX only)
- Upload progress indicator
- Error handling

### Results Display
- Tabbed interface
- Risk score visualization (circular progress)
- Color-coded severity badges
- Expandable clause cards
- Side-by-side version comparison

### Comparison Mode
- Two-file upload interface
- VS divider animation
- Conflict highlighting
- Severity-based color coding

## 🔧 Troubleshooting

### Port Already in Use

If port 3001 is already in use, edit `mock-server/server.js`:
```javascript
const PORT = 3002; // Change to any available port
```

Then update `frontend/.env.development`:
```
REACT_APP_API_ENDPOINT=http://localhost:3002
```

### CORS Issues

The mock server has CORS enabled for all origins. If you still see CORS errors:
1. Check that the mock server is running
2. Verify the API endpoint in `.env.development`
3. Clear browser cache and reload

### Frontend Not Loading

1. Make sure you're in the `frontend` directory
2. Run `npm install` again
3. Delete `node_modules` and `package-lock.json`, then reinstall
4. Check for port conflicts (default: 3000)

### Mock Server Not Responding

1. Check that Node.js is installed: `node --version`
2. Verify you're in the `mock-server` directory
3. Check the console for error messages
4. Try restarting the server

## 📝 Customizing Mock Data

Edit `mock-server/server.js` to customize:

**Change processing delays:**
```javascript
setTimeout(() => {
  doc.processing_stage = 'clause_extraction_complete';
}, 3000); // Change 3000 to desired milliseconds
```

**Modify mock clauses:**
```javascript
const mockExtractedClauses = {
  "Parties": "Your custom text here",
  // ... add more
};
```

**Adjust risk score:**
```javascript
doc.risk_score = 75; // Change to 0-100
```

**Add more deviation flags:**
```javascript
const mockDeviationFlags = [
  {
    "Clause": "Custom Clause",
    "Risk Level": "High",
    "Reason": "Your reason here",
    "Type": "Risky Wording"
  },
  // ... add more
];
```

## 🚀 Next Steps

Once you're satisfied with local testing:

1. **Deploy to AWS**: Follow `docs/DEPLOYMENT_GUIDE.md`
2. **Update Frontend**: Change `.env` to use AWS API Gateway endpoint
3. **Test Production**: Verify with real AWS services

## 💡 Tips

- Use Chrome DevTools Network tab to see API calls
- Check React DevTools for component state
- Monitor mock server console for request logs
- Test with different file sizes and types
- Try uploading the same file twice in comparison mode

## 🎉 Enjoy Testing!

You now have a fully functional local development environment. The mock server provides realistic responses, and the frontend displays all features exactly as they would work in production.

**Happy Testing! 🚀**
