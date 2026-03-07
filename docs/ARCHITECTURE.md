# System Architecture

## Overview

Cloud-native serverless legal document processing system built on AWS, leveraging GenAI for clause extraction and ML for deviation detection.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         React Frontend                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ File Upload  │  │  Comparison  │  │   Results    │          │
│  │  Component   │  │    Mode      │  │   Display    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway (REST)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ POST /upload │  │POST /compare │  │GET /status   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Upload     │    │   Upload     │    │   Status     │
│   Handler    │    │   Handler    │    │   Lambda     │
│   Lambda     │    │   Lambda     │    │              │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                    │
       │ Store             │ Store              │ Read
       ▼                   ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         S3 Upload Bucket                         │
│  uploads/{doc_id}/                                               │
│  uploads/{doc_id}/version1/                                      │
│  uploads/{doc_id}/version2/                                      │
└────────────────────────────┬────────────────────────────────────┘
                             │ S3 Event Trigger
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Summarize Lambda                            │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ 1. Extract text (PDF/DOCX)                           │       │
│  │ 2. GenAI clause extraction                           │       │
│  │ 3. Generate 1-page summary                           │       │
│  │ 4. Store results                                     │       │
│  │ 5. Trigger deviation detection                       │       │
│  └──────────────────────────────────────────────────────┘       │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Deviation   │    │  Comparison  │    │  Processed   │
│  Detection   │    │    Agent     │    │  S3 Bucket   │
│   Lambda     │    │   Lambda     │    │              │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                    │
       │ ML Analysis       │ Semantic Compare   │ Store Results
       ▼                   ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Processed S3 Bucket                           │
│  processed/{doc_id}/extraction_result.json                       │
│  processed/{doc_id}/deviation_analysis.json                      │
│  processed/{doc_id}/comparison_result.json                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Glue Crawler                            │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ - Catalogs processed JSON files                      │       │
│  │ - Infers schema                                      │       │
│  │ - Enables analytics via Athena                       │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        DynamoDB Table                            │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ doc_id (PK), timestamp, status, processing_stage     │       │
│  │ s3_keys, risk_score, metadata                        │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      CloudWatch Logs                             │
│  All Lambda function logs, metrics, and monitoring               │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Frontend Layer

**Technology:** React 18 + Axios

**Components:**
- `FileUpload`: Single document upload with drag-and-drop
- `ComparisonMode`: Two-document upload interface
- `ResultsDisplay`: Tabbed results viewer
- `App`: Main application orchestrator

**Features:**
- Responsive design
- Real-time status polling
- Base64 file encoding
- Error handling

### API Layer

**Technology:** AWS API Gateway (REST)

**Endpoints:**
- `POST /upload`: Single document upload
- `POST /compare`: Two-document comparison
- `GET /status/{id}`: Status and results retrieval

**Features:**
- CORS enabled
- Request/response logging
- Error handling
- CloudWatch integration

### Processing Layer

#### 1. Upload Handler Lambda

**Runtime:** Python 3.12  
**Memory:** 3008 MB  
**Timeout:** 900s

**Responsibilities:**
- Validate upload requests
- Generate unique document IDs
- Store files in S3
- Create DynamoDB records
- Return upload confirmation

**Triggers:** API Gateway

#### 2. Summarize Lambda

**Runtime:** Python 3.12  
**Memory:** 3008 MB  
**Timeout:** 900s

**Responsibilities:**
- Extract text from PDF/DOCX
- Call GenAI for clause extraction
- Generate executive summary
- Store results in S3
- Trigger downstream processing

**Triggers:** S3 ObjectCreated event

**Libraries:**
- PyPDF2: PDF text extraction
- python-docx: DOCX text extraction
- boto3: AWS SDK

#### 3. Deviation Detection Lambda

**Runtime:** Python 3.12  
**Memory:** 3008 MB  
**Timeout:** 900s

**Responsibilities:**
- Compare clauses to standard template
- Calculate TF-IDF similarity
- Detect risky keywords
- Calculate risk score
- Store deviation analysis

**Triggers:** Invoked by Summarize Lambda

**ML Models:**
- TF-IDF vectorization
- Cosine similarity
- Rule-based detection

#### 4. Comparison Agent Lambda

**Runtime:** Python 3.12  
**Memory:** 10240 MB  
**Timeout:** 900s

**Responsibilities:**
- Load both document extractions
- Calculate semantic similarity
- Identify conflicts
- Generate comparison summary
- Store comparison results

**Triggers:** Invoked by Summarize Lambda (comparison mode)

**ML Models:**
- Sentence Transformers (all-MiniLM-L6-v2)
- Embedding-based similarity
- Conflict classification

#### 5. Status Lambda

**Runtime:** Python 3.12  
**Memory:** 3008 MB  
**Timeout:** 900s

**Responsibilities:**
- Query DynamoDB for status
- Load results from S3
- Aggregate response
- Return to client

**Triggers:** API Gateway

### Storage Layer

#### S3 Buckets

**Upload Bucket:**
- Stores uploaded documents
- Triggers processing pipeline
- 90-day lifecycle policy
- Server-side encryption

**Processed Bucket:**
- Stores processing results (JSON)
- 30-day transition to IA
- Server-side encryption
- Versioning enabled

#### DynamoDB Table

**Schema:**
```
doc_id (String, PK)
timestamp (String, GSI)
status (String)
processing_stage (String)
mode (String)
s3_key / s3_key1 / s3_key2 (String)
processed_key (String)
deviation_key (String)
comparison_key (String)
risk_score (Number)
```

**Features:**
- On-demand billing
- Point-in-time recovery
- Streams enabled
- Global secondary index on timestamp

### Analytics Layer

#### AWS Glue

**Glue Database:** `legal_documents_{env}`

**Glue Crawler:**
- Runs daily at 2 AM
- Catalogs processed JSON files
- Infers schema automatically
- Updates metadata catalog

**Use Cases:**
- Query with Athena
- Analytics dashboards
- Compliance reporting
- Trend analysis

### Monitoring Layer

#### CloudWatch

**Log Groups:**
- `/aws/lambda/legal-upload-handler-{env}`
- `/aws/lambda/legal-summarize-{env}`
- `/aws/lambda/legal-deviation-detection-{env}`
- `/aws/lambda/legal-comparison-agent-{env}`
- `/aws/lambda/legal-status-{env}`

**Metrics:**
- Lambda invocations
- Duration
- Errors
- Throttles
- API Gateway requests

**Alarms:**
- Error rate > 5%
- Duration > 800s
- Throttles > 0

## Data Flow

### Single Document Processing

1. User uploads document via React frontend
2. Frontend encodes file to base64
3. POST request to `/upload` endpoint
4. Upload Handler Lambda:
   - Validates request
   - Generates doc_id
   - Stores in S3 upload bucket
   - Creates DynamoDB record
   - Returns doc_id
5. S3 event triggers Summarize Lambda
6. Summarize Lambda:
   - Downloads document
   - Extracts text
   - Calls GenAI for clause extraction
   - Generates summary
   - Stores results in processed bucket
   - Updates DynamoDB
   - Invokes Deviation Detection Lambda
7. Deviation Detection Lambda:
   - Loads extracted clauses
   - Compares to standard template
   - Calculates similarities
   - Detects deviations
   - Calculates risk score
   - Stores results
   - Updates DynamoDB
8. Frontend polls `/status/{doc_id}`
9. Status Lambda returns complete results
10. Frontend displays results

### Comparison Processing

1. User uploads two documents
2. Frontend encodes both to base64
3. POST request to `/compare` endpoint
4. Upload Handler Lambda stores both documents
5. S3 events trigger Summarize Lambda twice
6. Each Summarize Lambda processes one document
7. Second completion triggers Comparison Agent Lambda
8. Comparison Agent Lambda:
   - Loads both extractions
   - Calculates semantic similarities
   - Identifies conflicts
   - Generates comparison summary
   - Stores results
   - Updates DynamoDB
9. Frontend polls and displays comparison results

## Security

### IAM Roles

**Lambda Execution Roles:**
- S3 read/write permissions
- DynamoDB read/write permissions
- CloudWatch Logs write permissions
- Lambda invoke permissions

**Glue Crawler Role:**
- S3 read permissions
- Glue catalog write permissions

### Encryption

- S3: Server-side encryption (AES-256)
- DynamoDB: Encryption at rest
- API Gateway: HTTPS only
- Lambda: Environment variables encrypted

### Network

- All services in AWS VPC (optional)
- Security groups for Lambda
- Private subnets for sensitive operations

## Scalability

### Horizontal Scaling

- Lambda: Automatic scaling (up to 1000 concurrent)
- API Gateway: Unlimited requests
- DynamoDB: On-demand auto-scaling
- S3: Unlimited storage

### Performance Optimization

- Lambda: Provisioned concurrency for warm starts
- Lambda Layers: Shared dependencies
- S3: Transfer acceleration
- DynamoDB: DAX caching (optional)

## Cost Optimization

### Lambda
- Right-sized memory allocation
- Optimized timeout settings
- Lambda layers for common dependencies

### S3
- Lifecycle policies
- Intelligent-Tiering
- Compression

### DynamoDB
- On-demand billing for variable workloads
- TTL for temporary data

### API Gateway
- Caching enabled
- Usage plans

## Disaster Recovery

### Backup Strategy

- S3: Versioning enabled
- DynamoDB: Point-in-time recovery
- CloudFormation: Infrastructure as code

### Recovery Procedures

1. Redeploy stack from CloudFormation
2. Restore DynamoDB from backup
3. S3 data persists automatically

## Future Enhancements

1. **LLM Integration:**
   - AWS Bedrock integration
   - OpenAI API integration
   - Custom fine-tuned models

2. **Advanced ML:**
   - Custom clause classification models
   - Named entity recognition
   - Sentiment analysis

3. **Real-time Processing:**
   - WebSocket API
   - Real-time status updates
   - Streaming results

4. **Enhanced Analytics:**
   - QuickSight dashboards
   - Trend analysis
   - Predictive analytics

5. **Multi-tenancy:**
   - User authentication (Cognito)
   - Tenant isolation
   - Usage tracking

6. **Document Management:**
   - Document versioning
   - Audit trails
   - Collaboration features
