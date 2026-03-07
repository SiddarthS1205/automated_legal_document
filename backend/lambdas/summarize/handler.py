import json
import boto3
import os
import logging
from io import BytesIO
import PyPDF2
import docx

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
lambda_client = boto3.client('lambda')

UPLOAD_BUCKET = os.environ.get('UPLOAD_BUCKET')
PROCESSED_BUCKET = os.environ.get('PROCESSED_BUCKET')
TABLE_NAME = os.environ.get('TABLE_NAME')
OPENAI_API_KEY = os.environ.get('OPENAI_API_KEY', '')

def lambda_handler(event, context):
    """
    Triggered by S3 upload event. Extracts text, generates summary and clauses.
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse S3 event
        for record in event.get('Records', []):
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            
            logger.info(f"Processing document: s3://{bucket}/{key}")
            
            # Extract doc_id from key
            doc_id = key.split('/')[1]
            
            # Download document
            response = s3_client.get_object(Bucket=bucket, Key=key)
            file_content = response['Body'].read()
            metadata = response.get('Metadata', {})
            mode = metadata.get('mode', 'single')
            
            # Extract text
            text = extract_text(file_content, key)
            
            # Extract clauses using GenAI
            extracted_clauses = extract_clauses_with_genai(text)
            
            # Generate 1-page summary
            summary = generate_legal_summary(text, extracted_clauses)
            
            # Store results
            result = {
                'doc_id': doc_id,
                'extracted_text': text[:5000],  # Store first 5000 chars
                'extracted_clauses': extracted_clauses,
                'summary': summary,
                's3_key': key
            }
            
            # Save to processed bucket
            processed_key = f"processed/{doc_id}/extraction_result.json"
            s3_client.put_object(
                Bucket=PROCESSED_BUCKET,
                Key=processed_key,
                Body=json.dumps(result, indent=2),
                ContentType='application/json'
            )
            
            # Update DynamoDB
            table = dynamodb.Table(TABLE_NAME)
            table.update_item(
                Key={'doc_id': doc_id},
                UpdateExpression='SET #status = :status, processing_stage = :stage, processed_key = :key',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'extracted',
                    ':stage': 'clause_extraction_complete',
                    ':key': processed_key
                }
            )
            
            # Trigger deviation detection
            invoke_deviation_detection(doc_id, extracted_clauses)
            
            # If comparison mode, check if both documents processed
            if mode == 'compare':
                check_and_trigger_comparison(doc_id)
            
            logger.info(f"Document processed successfully: {doc_id}")
        
        return {'statusCode': 200, 'body': 'Processing complete'}
        
    except Exception as e:
        logger.error(f"Error in summarize handler: {str(e)}", exc_info=True)
        raise

def extract_text(file_content, file_name):
    """Extract text from PDF or DOCX"""
    try:
        if file_name.lower().endswith('.pdf'):
            return extract_text_from_pdf(file_content)
        elif file_name.lower().endswith('.docx'):
            return extract_text_from_docx(file_content)
        else:
            raise ValueError(f"Unsupported file format: {file_name}")
    except Exception as e:
        logger.error(f"Error extracting text: {str(e)}")
        raise

def extract_text_from_pdf(file_content):
    """Extract text from PDF"""
    pdf_file = BytesIO(file_content)
    pdf_reader = PyPDF2.PdfReader(pdf_file)
    
    text = ""
    for page in pdf_reader.pages:
        text += page.extract_text() + "\n"
    
    return text.strip()

def extract_text_from_docx(file_content):
    """Extract text from DOCX"""
    doc_file = BytesIO(file_content)
    doc = docx.Document(doc_file)
    
    text = ""
    for paragraph in doc.paragraphs:
        text += paragraph.text + "\n"
    
    return text.strip()

def extract_clauses_with_genai(text):
    """
    Extract structured clauses using LLM
    In production, integrate with OpenAI/Bedrock/SageMaker
    """
    
    # Prompt engineering for clause extraction
    prompt = f"""
You are a legal document analysis expert. Extract the following clauses from the contract text below.
Return ONLY valid JSON with no additional text.

Required clauses:
- Parties: Names of contracting parties
- Term: Contract duration
- Payment Clause: Payment terms and amounts
- Liability: Liability limitations and indemnification
- Confidentiality: Confidentiality obligations
- Termination: Termination conditions
- Governing Law: Applicable law and jurisdiction
- Intellectual Property: IP rights and ownership
- Warranties: Warranties and representations
- Force Majeure: Force majeure provisions

Contract Text:
{text[:4000]}

Return JSON format:
{{
  "Parties": "...",
  "Term": "...",
  "Payment Clause": "...",
  "Liability": "...",
  "Confidentiality": "...",
  "Termination": "...",
  "Governing Law": "...",
  "Intellectual Property": "...",
  "Warranties": "...",
  "Force Majeure": "..."
}}
"""
    
    # Call LLM (placeholder - integrate with actual LLM service)
    extracted = call_llm_for_extraction(prompt, text)
    
    return extracted

def call_llm_for_extraction(prompt, text):
    """
    Call LLM service for extraction
    Integrate with AWS Bedrock, OpenAI, or SageMaker endpoint
    """
    
    # For production, use actual LLM API
    # Example with OpenAI (requires openai package):
    # import openai
    # response = openai.ChatCompletion.create(
    #     model="gpt-4",
    #     messages=[{"role": "user", "content": prompt}],
    #     temperature=0.1
    # )
    # return json.loads(response.choices[0].message.content)
    
    # Fallback: Rule-based extraction for demo
    return extract_clauses_rule_based(text)

def extract_clauses_rule_based(text):
    """Rule-based clause extraction as fallback"""
    
    clauses = {
        "Parties": extract_section(text, ["parties", "between", "party"]),
        "Term": extract_section(text, ["term", "duration", "period"]),
        "Payment Clause": extract_section(text, ["payment", "compensation", "fee"]),
        "Liability": extract_section(text, ["liability", "indemnif", "damages"]),
        "Confidentiality": extract_section(text, ["confidential", "non-disclosure", "proprietary"]),
        "Termination": extract_section(text, ["termination", "terminate", "cancel"]),
        "Governing Law": extract_section(text, ["governing law", "jurisdiction", "applicable law"]),
        "Intellectual Property": extract_section(text, ["intellectual property", "ip rights", "copyright"]),
        "Warranties": extract_section(text, ["warrant", "represent", "guarantee"]),
        "Force Majeure": extract_section(text, ["force majeure", "act of god", "unforeseeable"])
    }
    
    return clauses

def extract_section(text, keywords):
    """Extract text section containing keywords"""
    text_lower = text.lower()
    sentences = text.split('.')
    
    for i, sentence in enumerate(sentences):
        if any(keyword in sentence.lower() for keyword in keywords):
            # Return context (current + next 2 sentences)
            context = '. '.join(sentences[i:min(i+3, len(sentences))])
            return context.strip()[:500]
    
    return "Not found"

def generate_legal_summary(text, clauses):
    """Generate 1-page executive legal summary"""
    
    prompt = f"""
Generate a professional 1-page executive legal summary for the following contract.

Extracted Clauses:
{json.dumps(clauses, indent=2)}

Format the summary with these sections:
1. Contract Purpose
2. Key Obligations
3. Risks
4. Term
5. Payment
6. Termination Conditions

Keep it concise, professional, and executive-level.
"""
    
    # Call LLM for summary generation
    summary = call_llm_for_summary(prompt, clauses)
    
    return summary

def call_llm_for_summary(prompt, clauses):
    """Generate summary using LLM"""
    
    # Fallback: Template-based summary
    summary = f"""
EXECUTIVE LEGAL SUMMARY

CONTRACT PURPOSE:
This agreement establishes the terms and conditions between the parties as identified in the contract.

KEY OBLIGATIONS:
- Parties: {clauses.get('Parties', 'Not specified')}
- Payment Terms: {clauses.get('Payment Clause', 'Not specified')}
- Confidentiality: {clauses.get('Confidentiality', 'Not specified')}

RISKS:
- Liability: {clauses.get('Liability', 'Not specified')}
- Termination: {clauses.get('Termination', 'Not specified')}

TERM:
{clauses.get('Term', 'Not specified')}

PAYMENT:
{clauses.get('Payment Clause', 'Not specified')}

TERMINATION CONDITIONS:
{clauses.get('Termination', 'Not specified')}

GOVERNING LAW:
{clauses.get('Governing Law', 'Not specified')}
"""
    
    return summary.strip()

def invoke_deviation_detection(doc_id, clauses):
    """Trigger deviation detection Lambda"""
    try:
        lambda_client.invoke(
            FunctionName=os.environ.get('DEVIATION_LAMBDA_ARN'),
            InvocationType='Event',
            Payload=json.dumps({
                'doc_id': doc_id,
                'clauses': clauses
            })
        )
        logger.info(f"Deviation detection triggered for {doc_id}")
    except Exception as e:
        logger.error(f"Error invoking deviation detection: {str(e)}")

def check_and_trigger_comparison(doc_id):
    """Check if both documents processed and trigger comparison"""
    try:
        # Check if both versions are processed
        processed_key1 = f"processed/{doc_id}/version1/extraction_result.json"
        processed_key2 = f"processed/{doc_id}/version2/extraction_result.json"
        
        # Check existence
        try:
            s3_client.head_object(Bucket=PROCESSED_BUCKET, Key=processed_key1)
            s3_client.head_object(Bucket=PROCESSED_BUCKET, Key=processed_key2)
            
            # Both exist, trigger comparison
            lambda_client.invoke(
                FunctionName=os.environ.get('COMPARISON_LAMBDA_ARN'),
                InvocationType='Event',
                Payload=json.dumps({'doc_id': doc_id})
            )
            logger.info(f"Comparison triggered for {doc_id}")
        except:
            logger.info(f"Waiting for both documents to be processed: {doc_id}")
    except Exception as e:
        logger.error(f"Error checking comparison status: {str(e)}")
