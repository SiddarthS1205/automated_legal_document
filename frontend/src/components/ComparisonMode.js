import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import axios from 'axios';
import './ComparisonMode.css';

const ComparisonMode = ({ onUploadComplete }) => {
  const [file1, setFile1] = useState(null);
  const [file2, setFile2] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState(null);

  const readFileAsBase64 = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target.result.split(',')[1]);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  };

  const handleUpload = async () => {
    if (!file1 || !file2) {
      setError('Please select both documents');
      return;
    }

    setUploading(true);
    setError(null);

    try {
      const file1Content = await readFileAsBase64(file1);
      const file2Content = await readFileAsBase64(file2);

      const payload = {
        mode: 'compare',
        file1_content: file1Content,
        file1_name: file1.name,
        file2_content: file2Content,
        file2_name: file2.name
      };

      const response = await axios.post(
        `${process.env.REACT_APP_API_ENDPOINT}/compare`,
        payload,
        {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );

      if (response.data.doc_id) {
        onUploadComplete(response.data.doc_id);
      } else {
        setError('Upload failed: No document ID returned');
      }
    } catch (err) {
      setError(`Upload failed: ${err.response?.data?.error || err.message}`);
    } finally {
      setUploading(false);
    }
  };

  const FileDropzone = ({ fileNumber, file, setFile }) => {
    const onDrop = useCallback((acceptedFiles) => {
      if (acceptedFiles.length > 0) {
        setFile(acceptedFiles[0]);
      }
    }, [setFile]);

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
      onDrop,
      accept: {
        'application/pdf': ['.pdf'],
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx']
      },
      maxFiles: 1,
      disabled: uploading
    });

    return (
      <div className="comparison-dropzone-container">
        <h3>Version {fileNumber}</h3>
        <div
          {...getRootProps()}
          className={`comparison-dropzone ${isDragActive ? 'active' : ''} ${file ? 'has-file' : ''}`}
        >
          <input {...getInputProps()} />
          {file ? (
            <div className="file-info">
              <svg className="file-icon" viewBox="0 0 24 24" fill="currentColor">
                <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8l-6-6z" />
                <path d="M14 2v6h6" />
              </svg>
              <p className="file-name">{file.name}</p>
              <p className="file-size">{(file.size / 1024).toFixed(2)} KB</p>
              <button
                className="remove-file"
                onClick={(e) => {
                  e.stopPropagation();
                  setFile(null);
                }}
              >
                Remove
              </button>
            </div>
          ) : (
            <div className="upload-prompt">
              <svg className="upload-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
              </svg>
              <p>Drop document here</p>
              <p className="file-types">PDF or DOCX</p>
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="comparison-mode-container">
      <div className="comparison-dropzones">
        <FileDropzone fileNumber={1} file={file1} setFile={setFile1} />
        <div className="vs-divider">VS</div>
        <FileDropzone fileNumber={2} file={file2} setFile={setFile2} />
      </div>

      <button
        className="compare-button"
        onClick={handleUpload}
        disabled={!file1 || !file2 || uploading}
      >
        {uploading ? 'Uploading...' : 'Compare Documents'}
      </button>

      {error && (
        <div className="error-message">
          <p>{error}</p>
        </div>
      )}
    </div>
  );
};

export default ComparisonMode;
