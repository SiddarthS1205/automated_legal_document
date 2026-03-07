import React, { useState } from 'react';
import './ResultsDisplay.css';

const ResultsDisplay = ({ results, mode, onReset }) => {
  const [activeTab, setActiveTab] = useState('summary');

  const renderSummary = () => (
    <div className="results-section">
      <h2>Executive Summary</h2>
      <div className="summary-content">
        <pre>{results.summary || 'Summary not available'}</pre>
      </div>
    </div>
  );

  const renderClauses = () => (
    <div className="results-section">
      <h2>Extracted Clauses</h2>
      <div className="clauses-grid">
        {results.extracted_clauses && Object.entries(results.extracted_clauses).map(([key, value]) => (
          <div key={key} className="clause-card">
            <h3>{key}</h3>
            <p>{value || 'Not found'}</p>
          </div>
        ))}
      </div>
    </div>
  );

  const renderDeviations = () => {
    const deviations = results.deviation_flags || [];
    const riskScore = results.risk_score || 0;

    return (
      <div className="results-section">
        <h2>Deviation Analysis</h2>
        
        <div className="risk-score-container">
          <div className="risk-score">
            <div className="score-circle" style={{
              background: `conic-gradient(
                ${riskScore > 70 ? '#e74c3c' : riskScore > 40 ? '#f39c12' : '#27ae60'} ${riskScore * 3.6}deg,
                #ecf0f1 ${riskScore * 3.6}deg
              )`
            }}>
              <div className="score-inner">
                <span className="score-value">{riskScore}</span>
                <span className="score-label">Risk Score</span>
              </div>
            </div>
          </div>
          <div className="risk-summary">
            <p><strong>Total Deviations:</strong> {deviations.length}</p>
            <p><strong>High Risk:</strong> {deviations.filter(d => d['Risk Level'] === 'High').length}</p>
            <p><strong>Medium Risk:</strong> {deviations.filter(d => d['Risk Level'] === 'Medium').length}</p>
          </div>
        </div>

        <div className="deviations-list">
          {deviations.length === 0 ? (
            <p className="no-deviations">No significant deviations detected</p>
          ) : (
            deviations.map((deviation, index) => (
              <div key={index} className={`deviation-card risk-${deviation['Risk Level']?.toLowerCase()}`}>
                <div className="deviation-header">
                  <h3>{deviation.Clause}</h3>
                  <span className={`risk-badge ${deviation['Risk Level']?.toLowerCase()}`}>
                    {deviation['Risk Level']}
                  </span>
                </div>
                <p className="deviation-reason">{deviation.Reason}</p>
                {deviation.Context && (
                  <p className="deviation-context"><em>{deviation.Context}</em></p>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    );
  };

  const renderComparison = () => {
    const conflicts = results.conflicts || [];
    const summary = results.comparison_summary || '';

    return (
      <div className="results-section">
        <h2>Document Comparison</h2>
        
        <div className="comparison-summary">
          <pre>{summary}</pre>
        </div>

        <div className="conflicts-list">
          <h3>Detailed Conflicts ({conflicts.length})</h3>
          {conflicts.length === 0 ? (
            <p className="no-conflicts">No conflicts detected</p>
          ) : (
            conflicts.map((conflict, index) => (
              <div key={index} className={`conflict-card severity-${conflict.Severity?.toLowerCase()}`}>
                <div className="conflict-header">
                  <h4>{conflict.Clause}</h4>
                  <div className="conflict-badges">
                    <span className={`type-badge ${conflict.Type?.toLowerCase().replace(' ', '-')}`}>
                      {conflict.Type}
                    </span>
                    <span className={`severity-badge ${conflict.Severity?.toLowerCase()}`}>
                      {conflict.Severity}
                    </span>
                  </div>
                </div>
                <p className="conflict-summary">{conflict['Conflict Summary']}</p>
                
                <div className="version-comparison">
                  <div className="version-box">
                    <h5>Version 1</h5>
                    <p>{conflict.Version1 || 'Not present'}</p>
                  </div>
                  <div className="version-box">
                    <h5>Version 2</h5>
                    <p>{conflict.Version2 || 'Not present'}</p>
                  </div>
                </div>

                {conflict['Similarity Score'] !== undefined && (
                  <p className="similarity-score">
                    Similarity: {(conflict['Similarity Score'] * 100).toFixed(0)}%
                  </p>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="results-container">
      <div className="results-header">
        <h1>Analysis Results</h1>
        <button className="reset-button" onClick={onReset}>
          New Analysis
        </button>
      </div>

      <div className="results-tabs">
        <button
          className={activeTab === 'summary' ? 'active' : ''}
          onClick={() => setActiveTab('summary')}
        >
          Summary
        </button>
        <button
          className={activeTab === 'clauses' ? 'active' : ''}
          onClick={() => setActiveTab('clauses')}
        >
          Clauses
        </button>
        <button
          className={activeTab === 'deviations' ? 'active' : ''}
          onClick={() => setActiveTab('deviations')}
        >
          Deviations
        </button>
        {mode === 'compare' && (
          <button
            className={activeTab === 'comparison' ? 'active' : ''}
            onClick={() => setActiveTab('comparison')}
          >
            Comparison
          </button>
        )}
      </div>

      <div className="results-content">
        {activeTab === 'summary' && renderSummary()}
        {activeTab === 'clauses' && renderClauses()}
        {activeTab === 'deviations' && renderDeviations()}
        {activeTab === 'comparison' && mode === 'compare' && renderComparison()}
      </div>

      <div className="document-info">
        <p><strong>Document ID:</strong> {results.doc_id}</p>
        <p><strong>Status:</strong> {results.status}</p>
        <p><strong>Processing Stage:</strong> {results.processing_stage}</p>
      </div>
    </div>
  );
};

export default ResultsDisplay;
