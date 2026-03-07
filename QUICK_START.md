# ⚡ Quick Start Guide

Get the Legal Document Processing System running locally in **3 minutes**!

## 🎯 What You'll Get

- ✅ Full React frontend with beautiful UI
- ✅ Mock backend that simulates AWS Lambda
- ✅ All features working: upload, analysis, comparison
- ✅ Realistic legal document processing
- ✅ No AWS account needed!

## 🚀 Option 1: Automated Start (Easiest)

### Windows

Double-click `start-local.bat` or run:
```cmd
start-local.bat
```

### Mac/Linux

```bash
chmod +x start-local.sh
./start-local.sh
```

**That's it!** Both servers will start automatically.

## 🔧 Option 2: Manual Start

### Step 1: Install Dependencies

```bash
# Mock Server
cd mock-server
npm install

# Frontend
cd ../frontend
npm install
```

### Step 2: Start Servers

**Terminal 1 - Mock Server:**
```bash
cd mock-server
npm start
```

Wait for: `🚀 Server running on http://localhost:3001`

**Terminal 2 - Frontend:**
```bash
cd frontend
npm start
```

Browser will open automatically at `http://localhost:3000`

## 🎮 Try It Out!

### Test 1: Single Document Upload

1. Click **"Single Document"** (default mode)
2. Drag & drop any PDF or DOCX file
3. Wait ~6 seconds for processing
4. Explore the tabs:
   - **Summary**: Executive legal summary
   - **Clauses**: 10 extracted clauses
   - **Deviations**: Risk analysis

### Test 2: Document Comparison

1. Click **"Compare Documents"**
2. Upload two files (can be the same file twice)
3. Click **"Compare Documents"**
4. Wait ~9 seconds
5. Check the **Comparison** tab for conflicts

### Test 3: Quick API Test

Open `mock-server/test.html` in your browser for a simple test interface.

## 📊 What You'll See

### Mock Data Includes:

**10 Legal Clauses:**
- Parties, Term, Payment, Liability
- Confidentiality, Termination
- Governing Law, IP Rights
- Warranties, Force Majeure

**Risk Analysis:**
- 4 deviation flags
- Risk score: 58/100
- High/Medium/Low severity levels

**Comparison (Compare Mode):**
- 5 conflicts detected
- Payment terms changed
- Liability modifications
- New IP clause added

## 🔍 Verify It's Working

### Check Mock Server

Visit: http://localhost:3001

You should see:
```json
{
  "message": "Legal Document Processing Mock Server",
  "status": "running"
}
```

### Check Frontend

Visit: http://localhost:3000

You should see the purple gradient UI with upload options.

## 🐛 Troubleshooting

### Port Already in Use

**Mock Server (3001):**
Edit `mock-server/server.js`:
```javascript
const PORT = 3002; // Change port
```

Then update `frontend/.env.development`:
```
REACT_APP_API_ENDPOINT=http://localhost:3002
```

**Frontend (3000):**
React will automatically suggest port 3001 if 3000 is busy.

### "npm: command not found"

Install Node.js from https://nodejs.org/ (version 18 or higher)

### Mock Server Not Responding

1. Check it's running: `curl http://localhost:3001`
2. Look for errors in the terminal
3. Try restarting: Ctrl+C, then `npm start`

### Frontend Shows Blank Page

1. Check browser console (F12) for errors
2. Verify mock server is running
3. Clear browser cache (Ctrl+Shift+R)
4. Check `.env.development` has correct API endpoint

### Files Not Uploading

1. Check file type (PDF or DOCX only)
2. Check file size (should work with any size in mock)
3. Open browser DevTools Network tab to see API calls
4. Check mock server console for errors

## 💡 Tips

### View API Calls

1. Open browser DevTools (F12)
2. Go to Network tab
3. Upload a document
4. See the API requests and responses

### Monitor Processing

Watch the mock server terminal to see:
```
📤 Upload request received
✅ Document uploaded: abc-123-def
📊 Status request for: abc-123-def
✅ Status: complete - deviation_detection_complete
```

### Test Different Scenarios

1. **Upload same file twice** in comparison mode
2. **Upload different file types** (PDF vs DOCX)
3. **Upload multiple times** to see different doc IDs
4. **Check status immediately** vs after waiting

### Customize Mock Data

Edit `mock-server/server.js` to change:
- Processing delays (lines 150-180)
- Mock clauses (lines 20-30)
- Risk scores (line 175)
- Deviation flags (lines 40-60)

## 📚 Next Steps

### Learn More

- **[START_LOCAL.md](START_LOCAL.md)** - Detailed local development guide
- **[mock-server/README.md](mock-server/README.md)** - Mock server documentation
- **[docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)** - API reference

### Deploy to AWS

When ready for production:
1. Read [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
2. Configure AWS credentials
3. Run `./infrastructure/deploy.sh dev`

### Customize

- **Frontend**: Edit React components in `frontend/src/components/`
- **Mock Data**: Edit `mock-server/server.js`
- **Styling**: Edit CSS files in `frontend/src/components/`

## 🎉 You're Ready!

You now have a fully functional legal document processing system running locally. Upload documents, explore the analysis, and see how it works!

**Need Help?**
- Check the troubleshooting section above
- Review the detailed guides in `/docs`
- Open the test page: `mock-server/test.html`

**Happy Testing! 🚀**
