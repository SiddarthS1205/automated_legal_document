const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
const pdf = require('pdf-parse');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// In-memory storage for documents
const documents = new Map();

// Helper function to decode base64 file content and extract text
async function decodeFileContent(base64Content, fileName) {
  try {
    const buffer = Buffer.from(base64Content, 'base64');
    
    // Check if it's a PDF
    if (fileName.toLowerCase().endsWith('.pdf')) {
      console.log('📄 Extracting text from PDF...');
      try {
        const data = await pdf(buffer);
        console.log(`✅ Extracted ${data.text.length} characters from PDF`);
        return data.text;
      } catch (pdfError) {
        console.error('❌ PDF parsing error:', pdfError.message);
        return '';
      }
    } else {
      // Plain text file
      return buffer.toString('utf-8');
    }
  } catch (error) {
    console.error('❌ Error decoding file:', error);
    return '';
  }
}

// Helper function to extract clauses from text
function extractClauses(text) {
  const clauses = {};
  
  // Common legal clause patterns
  const clausePatterns = [
    { name: 'Parties', keywords: ['party', 'parties', 'between', 'entered into', 'corporation', 'llc', 'company'] },
    { name: 'Term', keywords: ['term', 'duration', 'period', 'commence', 'expiration', 'renewal'] },
    { name: 'Payment', keywords: ['payment', 'fee', 'invoice', 'compensation', 'price', 'cost'] },
    { name: 'Liability', keywords: ['liability', 'liable', 'damages', 'indemnif', 'limitation'] },
    { name: 'Confidentiality', keywords: ['confidential', 'proprietary', 'non-disclosure', 'secret'] },
    { name: 'Termination', keywords: ['terminat', 'cancel', 'end', 'cease', 'discontinue'] },
    { name: 'Governing Law', keywords: ['governing law', 'jurisdiction', 'venue', 'applicable law'] },
    { name: 'Intellectual Property', keywords: ['intellectual property', 'ip', 'patent', 'copyright', 'trademark', 'ownership'] },
    { name: 'Warranties', keywords: ['warrant', 'represent', 'guarantee', 'assurance'] },
    { name: 'Force Majeure', keywords: ['force majeure', 'act of god', 'beyond control', 'unforeseeable'] },
    { name: 'Dispute Resolution', keywords: ['dispute', 'arbitration', 'mediation', 'litigation'] },
    { name: 'Assignment', keywords: ['assign', 'transfer', 'delegate', 'successor'] }
  ];
  
  const sentences = text.split(/[.!?]+/).map(s => s.trim()).filter(s => s.length > 20);
  
  clausePatterns.forEach(pattern => {
    const matchingSentences = sentences.filter(sentence => {
      const lowerSentence = sentence.toLowerCase();
      return pattern.keywords.some(keyword => lowerSentence.includes(keyword.toLowerCase()));
    });
    
    if (matchingSentences.length > 0) {
      // Take the most relevant sentence (longest one with most keyword matches)
      const bestMatch = matchingSentences.reduce((best, current) => {
        const currentScore = pattern.keywords.filter(kw => 
          current.toLowerCase().includes(kw.toLowerCase())
        ).length;
        const bestScore = pattern.keywords.filter(kw => 
          best.toLowerCase().includes(kw.toLowerCase())
        ).length;
        return currentScore > bestScore ? current : best;
      });
      clauses[pattern.name] = bestMatch + '.';
    }
  });
  
  return clauses;
}

// Helper function to generate summary from text
function generateSummary(text, clauses, fileName) {
  const wordCount = text.split(/\s+/).filter(w => w.length > 0).length;
  const clauseCount = Object.keys(clauses).length;
  
  let summary = `EXECUTIVE LEGAL SUMMARY\n\n`;
  summary += `DOCUMENT: ${fileName}\n\n`;
  summary += `DOCUMENT ANALYSIS:\n`;
  summary += `- Document Length: ${wordCount} words\n`;
  summary += `- Clauses Identified: ${clauseCount}\n\n`;
  
  if (clauseCount === 0) {
    summary += `⚠️ WARNING: No standard legal clauses detected in this document.\n\n`;
    summary += `This document may not be a legal contract or agreement. It could be:\n`;
    summary += `- A non-legal document (letter, memo, report)\n`;
    summary += `- A document in a different format or language\n`;
    summary += `- A document with non-standard clause naming\n\n`;
    summary += `DOCUMENT CONTENT PREVIEW:\n`;
    const preview = text.substring(0, 500).trim();
    summary += preview + (text.length > 500 ? '...\n\n' : '\n\n');
    summary += `RECOMMENDATION: Please verify this is a legal document. If it is, consider reformatting with standard legal clause headings.`;
    return summary;
  }
  
  summary += `✅ LEGAL DOCUMENT DETECTED\n\n`;
  summary += `KEY CLAUSES FOUND:\n`;
  Object.keys(clauses).forEach(clauseName => {
    summary += `✓ ${clauseName}\n`;
  });
  
  summary += `\n`;
  
  // Add detailed clause information
  if (clauses['Parties']) {
    summary += `PARTIES:\n${clauses['Parties'].substring(0, 200)}${clauses['Parties'].length > 200 ? '...' : ''}\n\n`;
  }
  
  if (clauses['Term']) {
    summary += `TERM:\n${clauses['Term'].substring(0, 200)}${clauses['Term'].length > 200 ? '...' : ''}\n\n`;
  }
  
  if (clauses['Payment']) {
    summary += `PAYMENT:\n${clauses['Payment'].substring(0, 200)}${clauses['Payment'].length > 200 ? '...' : ''}\n\n`;
  }
  
  if (clauses['Termination']) {
    summary += `TERMINATION:\n${clauses['Termination'].substring(0, 200)}${clauses['Termination'].length > 200 ? '...' : ''}\n\n`;
  }
  
  // Add warnings for missing critical clauses
  const missingClauses = [];
  if (!clauses['Liability']) missingClauses.push('Liability');
  if (!clauses['Confidentiality']) missingClauses.push('Confidentiality');
  if (!clauses['Governing Law']) missingClauses.push('Governing Law');
  
  if (missingClauses.length > 0) {
    summary += `⚠️ MISSING CRITICAL CLAUSES:\n`;
    missingClauses.forEach(clause => {
      summary += `- ${clause}: Consider adding to protect your interests\n`;
    });
    summary += `\n`;
  }
  
  summary += `RECOMMENDATION:\n`;
  if (missingClauses.length > 0) {
    summary += `This document is missing ${missingClauses.length} critical clause(s). `;
  }
  summary += `Review all identified clauses carefully with legal counsel before signing.`;
  
  return summary;
}

// Helper function to detect deviations
function detectDeviations(clauses, text) {
  const deviations = [];
  
  // Check for missing critical clauses
  const criticalClauses = ['Liability', 'Termination', 'Governing Law'];
  criticalClauses.forEach(clauseName => {
    if (!clauses[clauseName]) {
      deviations.push({
        "Clause": clauseName,
        "Risk Level": "High",
        "Reason": `Missing critical clause: ${clauseName} clause not found in document`,
        "Type": "Missing Clause"
      });
    }
  });
  
  // Check for risky wording patterns
  const riskyPatterns = [
    { pattern: /unlimited.*liability/i, clause: 'Liability', risk: 'High', reason: 'Unlimited liability detected - no cap on damages' },
    { pattern: /automatic.*renew/i, clause: 'Term', risk: 'Medium', reason: 'Automatic renewal clause requires proactive management' },
    { pattern: /non-compete/i, clause: 'Restrictions', risk: 'High', reason: 'Non-compete clause may restrict future business activities' },
    { pattern: /perpetual/i, clause: 'Term', risk: 'Medium', reason: 'Perpetual term detected - no end date specified' },
    { pattern: /sole.*discretion/i, clause: 'General', risk: 'Medium', reason: 'Sole discretion clause gives one party unilateral control' }
  ];
  
  riskyPatterns.forEach(({ pattern, clause, risk, reason }) => {
    if (pattern.test(text)) {
      const match = text.match(pattern);
      const context = text.substring(Math.max(0, match.index - 50), Math.min(text.length, match.index + 150));
      deviations.push({
        "Clause": clause,
        "Risk Level": risk,
        "Reason": reason,
        "Type": "Risky Wording",
        "Context": context.trim()
      });
    }
  });
  
  return deviations;
}

// Simulate processing delay with actual content analysis
async function simulateProcessing(docId, mode, fileContent1, fileName1, fileContent2 = null, fileName2 = null) {
  const doc = documents.get(docId);
  
  // Stage 1: Uploaded (immediate)
  doc.status = 'uploaded';
  doc.processing_stage = 'pending';
  
  // Decode file content (async for PDF parsing)
  const text1 = await decodeFileContent(fileContent1, fileName1);
  const text2 = fileContent2 ? await decodeFileContent(fileContent2, fileName2) : null;
  
  console.log(`📝 Extracted ${text1.length} characters from ${fileName1}`);
  if (text2) {
    console.log(`📝 Extracted ${text2.length} characters from ${fileName2}`);
  }
  
  // Stage 2: Clause extraction (after 3 seconds)
  setTimeout(() => {
    doc.processing_stage = 'clause_extraction_complete';
    
    const clauses1 = extractClauses(text1);
    doc.extracted_clauses = clauses1;
    doc.summary = generateSummary(text1, clauses1, fileName1);
    
    console.log(`📋 Extracted ${Object.keys(clauses1).length} clauses from document`);
  }, 3000);
  
  // Stage 3: Deviation detection (after 6 seconds)
  setTimeout(() => {
    doc.processing_stage = 'deviation_detection_complete';
    
    const deviations = detectDeviations(doc.extracted_clauses, text1);
    doc.deviation_flags = deviations;
    doc.risk_score = Math.min(100, deviations.length * 15 + Math.floor(Math.random() * 20));
    
    console.log(`⚠️  Detected ${deviations.length} deviation flags`);
    
    if (mode === 'single') {
      doc.status = 'complete';
    }
  }, 6000);
  
  // Stage 4: Comparison (after 9 seconds, only for compare mode)
  if (mode === 'compare' && text2) {
    setTimeout(() => {
      doc.processing_stage = 'comparison_complete';
      doc.status = 'complete';
      
      const clauses2 = extractClauses(text2);
      const conflicts = compareDocuments(doc.extracted_clauses, clauses2, text1, text2);
      doc.conflicts = conflicts;
      doc.comparison_summary = generateComparisonSummary(conflicts);
      
      console.log(`🔍 Comparison complete: ${conflicts.length} conflicts found`);
    }, 9000);
  }
}

// Helper function to compare two documents
function compareDocuments(clauses1, clauses2, text1, text2) {
  const conflicts = [];
  
  // Find clauses in both documents
  const allClauseNames = new Set([...Object.keys(clauses1), ...Object.keys(clauses2)]);
  
  allClauseNames.forEach(clauseName => {
    const clause1 = clauses1[clauseName];
    const clause2 = clauses2[clauseName];
    
    if (clause1 && clause2) {
      // Both documents have this clause - check if they're different
      if (clause1 !== clause2) {
        const similarity = calculateSimilarity(clause1, clause2);
        conflicts.push({
          "Clause": clauseName,
          "Type": "Modified Clause",
          "Version1": clause1,
          "Version2": clause2,
          "Conflict Summary": `${clauseName} clause has been modified between versions`,
          "Similarity Score": similarity,
          "Severity": similarity > 0.7 ? "Low" : similarity > 0.4 ? "Medium" : "High"
        });
      }
    } else if (clause1 && !clause2) {
      // Clause removed in version 2
      conflicts.push({
        "Clause": clauseName,
        "Type": "Removed Clause",
        "Version1": clause1,
        "Version2": "Not present",
        "Conflict Summary": `${clauseName} clause was removed in version 2`,
        "Severity": "High"
      });
    } else if (!clause1 && clause2) {
      // Clause added in version 2
      conflicts.push({
        "Clause": clauseName,
        "Type": "Added Clause",
        "Version1": "Not present",
        "Version2": clause2,
        "Conflict Summary": `${clauseName} clause was added in version 2`,
        "Severity": "Medium"
      });
    }
  });
  
  return conflicts;
}

// Helper function to calculate text similarity
function calculateSimilarity(text1, text2) {
  const words1 = new Set(text1.toLowerCase().split(/\s+/));
  const words2 = new Set(text2.toLowerCase().split(/\s+/));
  
  const intersection = new Set([...words1].filter(x => words2.has(x)));
  const union = new Set([...words1, ...words2]);
  
  return intersection.size / union.size;
}

// Helper function to generate comparison summary
function generateComparisonSummary(conflicts) {
  const highSeverity = conflicts.filter(c => c.Severity === 'High').length;
  const mediumSeverity = conflicts.filter(c => c.Severity === 'Medium').length;
  const lowSeverity = conflicts.filter(c => c.Severity === 'Low').length;
  
  const added = conflicts.filter(c => c.Type === 'Added Clause').length;
  const removed = conflicts.filter(c => c.Type === 'Removed Clause').length;
  const modified = conflicts.filter(c => c.Type === 'Modified Clause').length;
  
  let summary = `DOCUMENT COMPARISON SUMMARY\n\n`;
  summary += `Total Conflicts Detected: ${conflicts.length}\n\n`;
  
  if (conflicts.length === 0) {
    summary += `No significant differences found between the two documents.\n`;
    return summary;
  }
  
  summary += `Severity Breakdown:\n`;
  summary += `- High Severity: ${highSeverity}\n`;
  summary += `- Medium Severity: ${mediumSeverity}\n`;
  summary += `- Low Severity: ${lowSeverity}\n\n`;
  
  summary += `Change Types:\n`;
  summary += `- Added Clauses: ${added}\n`;
  summary += `- Removed Clauses: ${removed}\n`;
  summary += `- Modified Clauses: ${modified}\n\n`;
  
  if (highSeverity > 0) {
    summary += `Critical Changes:\n`;
    conflicts.filter(c => c.Severity === 'High').forEach(conflict => {
      summary += `- ${conflict.Clause}: ${conflict["Conflict Summary"]}\n`;
    });
    summary += `\n`;
  }
  
  summary += `RECOMMENDATION:\n`;
  if (highSeverity > 0) {
    summary += `High severity changes detected. Careful legal review required before acceptance.`;
  } else if (mediumSeverity > 0) {
    summary += `Medium severity changes detected. Review recommended to ensure alignment with business objectives.`;
  } else {
    summary += `Minor changes detected. Standard review process recommended.`;
  }
  
  return summary;
}

// Routes

// Health check
app.get('/', (req, res) => {
  res.json({ 
    message: 'Legal Document Processing Mock Server',
    status: 'running',
    endpoints: [
      'POST /upload',
      'POST /compare',
      'GET /status/:id'
    ]
  });
});

// Upload single document
app.post('/upload', async (req, res) => {
  console.log('📤 Upload request received');
  
  const { mode, file_content, file_name, content_type } = req.body;
  
  if (!file_content || !file_name) {
    return res.status(400).json({ error: 'Missing file_content or file_name' });
  }
  
  const doc_id = uuidv4();
  const timestamp = new Date().toISOString();
  
  const document = {
    doc_id,
    timestamp,
    status: 'uploaded',
    mode: 'single',
    processing_stage: 'pending',
    file_name,
    s3_key: `uploads/${doc_id}/${file_name}`
  };
  
  documents.set(doc_id, document);
  
  // Start simulated processing with actual file content (async for PDF)
  simulateProcessing(doc_id, 'single', file_content, file_name);
  
  console.log(`✅ Document uploaded: ${doc_id} - ${file_name}`);
  
  res.json({
    doc_id,
    status: 'uploaded',
    message: 'Document uploaded successfully. Processing initiated.',
    s3_key: document.s3_key
  });
});

// Compare two documents
app.post('/compare', async (req, res) => {
  console.log('📤 Comparison request received');
  
  const { mode, file1_content, file1_name, file2_content, file2_name } = req.body;
  
  if (!file1_content || !file1_name || !file2_content || !file2_name) {
    return res.status(400).json({ error: 'Missing file content or names for comparison mode' });
  }
  
  const doc_id = uuidv4();
  const timestamp = new Date().toISOString();
  
  const document = {
    doc_id,
    timestamp,
    status: 'uploaded',
    mode: 'compare',
    processing_stage: 'pending',
    file1_name,
    file2_name,
    s3_key1: `uploads/${doc_id}/version1/${file1_name}`,
    s3_key2: `uploads/${doc_id}/version2/${file2_name}`
  };
  
  documents.set(doc_id, document);
  
  // Start simulated processing with actual file contents (async for PDF)
  simulateProcessing(doc_id, 'compare', file1_content, file1_name, file2_content, file2_name);
  
  console.log(`✅ Comparison documents uploaded: ${doc_id}`);
  console.log(`   File 1: ${file1_name}`);
  console.log(`   File 2: ${file2_name}`);
  
  res.json({
    doc_id,
    status: 'uploaded',
    message: 'Documents uploaded successfully. Comparison processing initiated.',
    s3_keys: [document.s3_key1, document.s3_key2]
  });
});

// Get document status
app.get('/status/:id', (req, res) => {
  const doc_id = req.params.id;
  
  console.log(`📊 Status request for: ${doc_id}`);
  
  const document = documents.get(doc_id);
  
  if (!document) {
    return res.status(404).json({ error: `Document ${doc_id} not found` });
  }
  
  console.log(`✅ Status: ${document.status} - ${document.processing_stage}`);
  
  res.json(document);
});

// List all documents (for debugging)
app.get('/documents', (req, res) => {
  const allDocs = Array.from(documents.values());
  res.json({
    total: allDocs.length,
    documents: allDocs
  });
});

// Clear all documents (for testing)
app.delete('/documents', (req, res) => {
  documents.clear();
  console.log('🗑️  All documents cleared');
  res.json({ message: 'All documents cleared' });
});

// Start server
app.listen(PORT, () => {
  console.log('');
  console.log('🚀 ========================================');
  console.log('🚀 Legal Document Processing Mock Server');
  console.log('🚀 ========================================');
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log('🚀');
  console.log('🚀 Available endpoints:');
  console.log(`🚀   POST   http://localhost:${PORT}/upload`);
  console.log(`🚀   POST   http://localhost:${PORT}/compare`);
  console.log(`🚀   GET    http://localhost:${PORT}/status/:id`);
  console.log(`🚀   GET    http://localhost:${PORT}/documents (debug)`);
  console.log(`🚀   DELETE http://localhost:${PORT}/documents (clear)`);
  console.log('🚀');
  console.log('🚀 Frontend should use:');
  console.log(`🚀   REACT_APP_API_ENDPOINT=http://localhost:${PORT}`);
  console.log('🚀 ========================================');
  console.log('');
});
