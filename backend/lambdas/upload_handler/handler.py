import json
import boto3
import os
import uuid
from datetime import datetime
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

UPLOAD_BUCKET = os.environ.get('UPLOAD_BUCKET')
TABLE_NAME = os.environ.get('TABLE_NAME')

def lambda_handler(event, context):
    """
    Handles document upload and initiates processing pipeline
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse request
        body = json.loads(event.get('body', '{}'))
        
        # Generate unique document ID
        doc_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Handle single or comparison mode
        mode = body.get('mode', 'single')  # 'single' or 'compare'
        
        if mode == 'single':
            result = handle_single_upload(doc_id, body, timestamp)
        elif mode == 'compare':
            result = handle_comparison_upload(doc_id, body, timestamp)
        else:
            return error_response(400, "Invalid mode. Use 'single' or 'compare'")
        
        return success_response(result)
        
    except Exception as e:
        logger.error(f"Error in upload handler: {str(e)}", exc_info=True)
        return error_response(500, f"Internal server error: {str(e)}")

def handle_single_upload(doc_id, body, timestamp):
    """Handle single document upload"""
    import base64
    
    file_content = body.get('file_content')
    file_name = body.get('file_name')
    content_type = body.get('content_type', 'application/pdf')
    
    if not file_content or not file_name:
        raise ValueError("Missing file_content or file_name")
    
    # Decode base64 content
    try:
        file_bytes = base64.b64decode(file_content)
    except Exception as e:
        raise ValueError(f"Invalid base64 content: {str(e)}")
    
    # Generate S3 key
    s3_key = f"uploads/{doc_id}/{file_name}"
    
    # Upload to S3
    s3_client.put_object(
        Bucket=UPLOAD_BUCKET,
        Key=s3_key,
        Body=file_bytes,
        ContentType=content_type,
        Metadata={
            'doc_id': doc_id,
            'upload_timestamp': timestamp,
            'mode': 'single'
        }
    )
    
    # Store metadata in DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            'doc_id': doc_id,
            'timestamp': timestamp,
            'status': 'uploaded',
            'mode': 'single',
            's3_key': s3_key,
            'file_name': file_name,
            'processing_stage': 'pending'
        }
    )
    
    logger.info(f"Document uploaded successfully: {doc_id}")
    
    return {
        'doc_id': doc_id,
        'status': 'uploaded',
        'message': 'Document uploaded successfully. Processing initiated.',
        's3_key': s3_key
    }

def handle_comparison_upload(doc_id, body, timestamp):
    """Handle comparison mode with two documents"""
    import base64
    
    file1_content = body.get('file1_content')
    file1_name = body.get('file1_name')
    file2_content = body.get('file2_content')
    file2_name = body.get('file2_name')
    
    if not all([file1_content, file1_name, file2_content, file2_name]):
        raise ValueError("Missing file content or names for comparison mode")
    
    # Decode base64 content
    try:
        file1_bytes = base64.b64decode(file1_content)
        file2_bytes = base64.b64decode(file2_content)
    except Exception as e:
        raise ValueError(f"Invalid base64 content: {str(e)}")
    
    # Upload both documents
    s3_key1 = f"uploads/{doc_id}/version1/{file1_name}"
    s3_key2 = f"uploads/{doc_id}/version2/{file2_name}"
    
    for s3_key, content_bytes, name in [
        (s3_key1, file1_bytes, file1_name),
        (s3_key2, file2_bytes, file2_name)
    ]:
        s3_client.put_object(
            Bucket=UPLOAD_BUCKET,
            Key=s3_key,
            Body=content_bytes,
            ContentType='application/pdf',
            Metadata={
                'doc_id': doc_id,
                'upload_timestamp': timestamp,
                'mode': 'compare'
            }
        )
    
    # Store metadata
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            'doc_id': doc_id,
            'timestamp': timestamp,
            'status': 'uploaded',
            'mode': 'compare',
            's3_key1': s3_key1,
            's3_key2': s3_key2,
            'file1_name': file1_name,
            'file2_name': file2_name,
            'processing_stage': 'pending'
        }
    )
    
    logger.info(f"Comparison documents uploaded successfully: {doc_id}")
    
    return {
        'doc_id': doc_id,
        'status': 'uploaded',
        'message': 'Documents uploaded successfully. Comparison processing initiated.',
        's3_keys': [s3_key1, s3_key2]
    }

def success_response(data):
    """Generate success response"""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        'body': json.dumps(data)
    }

def error_response(status_code, message):
    """Generate error response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'error': message})
    }
