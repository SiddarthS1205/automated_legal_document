import React, { useState } from 'react';
import './App.css';
import FileUpload from './components/FileUpload';
import ResultsDisplay from './components/ResultsDisplay';
import ComparisonMode from './components/ComparisonMode';

function App() {
  const [mode, setMode] = useState('single'); // 'single' or 'compare'
  const [docId, setDocId] = useState(null);
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleUploadComplete = (uploadedDocId) => {
    setDocId(uploadedDocId);
    setLoading(true);
    pollStatus(uploadedDocId);
  };

  const pollStatus = async (id) => {
    const maxAttempts = 60;
    let attempts = 0;

    const poll = setInterval(async () => {
      attempts++;
      
      try {
        const response = await fetch(
          `${process.env.REACT_APP_API_ENDPOINT}/status/${id}`
        );
        
        if (response.ok) {
          const data = await response.json();
          
          // Check if processing is complete
          if (data.status === 'complete' || 
              data.processing_stage === 'deviation_detection_complete' ||
              data.processing_stage === 'comparison_complete') {
            setResults(data);
            setLoading(false);
            clearInterval(poll);
          }
        }
      } catch (error) {
        console.error('Error polling status:', error);
      }

      if (attempts >= maxAttempts) {
        setLoading(false);
        clearInterval(poll);
        alert('Processing timeout. Please check status manually.');
      }
    }, 3000);
  };

  const handleReset = () => {
    setDocId(null);
    setResults(null);
    setLoading(false);
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Legal Document Analysis System</h1>
        <p>AI-Powered Contract Processing & Comparison</p>
      </header>

      <main className="App-main">
        {!docId && (
          <div className="mode-selector">
            <button
              className={mode === 'single' ? 'active' : ''}
              onClick={() => setMode('single')}
            >
              Single Document
            </button>
            <button
              className={mode === 'compare' ? 'active' : ''}
              onClick={() => setMode('compare')}
            >
              Compare Documents
            </button>
          </div>
        )}

        {!docId && mode === 'single' && (
          <FileUpload
            mode="single"
            onUploadComplete={handleUploadComplete}
          />
        )}

        {!docId && mode === 'compare' && (
          <ComparisonMode
            onUploadComplete={handleUploadComplete}
          />
        )}

        {loading && (
          <div className="loading-container">
            <div className="spinner"></div>
            <p>Processing document... This may take a few minutes.</p>
            <p className="doc-id">Document ID: {docId}</p>
          </div>
        )}

        {results && !loading && (
          <ResultsDisplay
            results={results}
            mode={mode}
            onReset={handleReset}
          />
        )}
      </main>

      <footer className="App-footer">
        <p>Cloud-Native Legal Document Processing System</p>
        <p>Powered by AWS Lambda, S3, and GenAI</p>
      </footer>
    </div>
  );
}

export default App;
