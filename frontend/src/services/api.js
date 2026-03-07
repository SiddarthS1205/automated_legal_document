import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_ENDPOINT;

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    console.log('API Request:', config.method.toUpperCase(), config.url);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => {
    console.log('API Response:', response.status, response.config.url);
    return response;
  },
  (error) => {
    console.error('API Error:', error.response?.status, error.message);
    return Promise.reject(error);
  }
);

export const uploadDocument = async (fileContent, fileName, contentType) => {
  const response = await api.post('/upload', {
    mode: 'single',
    file_content: fileContent,
    file_name: fileName,
    content_type: contentType,
  });
  return response.data;
};

export const compareDocuments = async (file1Content, file1Name, file2Content, file2Name) => {
  const response = await api.post('/compare', {
    mode: 'compare',
    file1_content: file1Content,
    file1_name: file1Name,
    file2_content: file2Content,
    file2_name: file2Name,
  });
  return response.data;
};

export const getDocumentStatus = async (docId) => {
  const response = await api.get(`/status/${docId}`);
  return response.data;
};

export default api;
