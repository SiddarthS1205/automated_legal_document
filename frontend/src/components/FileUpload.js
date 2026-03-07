import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import axios from 'axios';
import './FileUpload.css';

const FileUpload = ({ mode, onUploadComplete }) => {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState(null);

  const onDrop = useCallback(async (acceptedFiles) => {
    if (acceptedFiles.length === 0) return;

    const file = acceptedFiles[0];
    setUploading(true);
    setError(null);

    try {
      // Read file as base64
      const reader = new FileReader();
      
      reader.onload = async (e) => {
        const fileContent = e.target.result.split(',')[1]; // Remove data URL prefix

        const payload = {
          mode: 'single',
          file_content: fileContent,
          file_name: file.name,
          content_type: file.type
        };

        try {
          const response = await axios.post(
            `${process.env.REACT_APP_API_ENDPOINT}/upload`,
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

      reader.onerror = () => {
        setError('Failed to read file');
        setUploading(false);
      };

      reader.readAsDataURL(file);
    } catch (err) {
      setError(`Error: ${err.message}`);
      setUploading(false);
    }
  }, [onUploadComplete]);

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
    <div className="file-upload-container">
      <div
        {...getRootProps()}
        className={`dropzone ${isDragActive ? 'active' : ''} ${uploading ? 'disabled' : ''}`}
      >
        <input {...getInputProps()} />
        {uploading ? (
          <div className="upload-status">
            <div className="spinner-small"></div>
            <p>Uploading...</p>
          </div>
        ) : isDragActive ? (
          <p>Drop the file here...</p>
        ) : (
          <div className="upload-prompt">
            <svg className="upload-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
            <p>Drag & drop a legal document here</p>
            <p className="file-types">or click to select (PDF, DOCX)</p>
          </div>
        )}
      </div>

      {error && (
        <div className="error-message">
          <p>{error}</p>
        </div>
      )}
    </div>
  );
};

export default FileUpload;
