import json
import boto3
import os
import logging
from decimal import Decimal

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

PROCESSED_BUCKET = os.environ.get('PROCESSED_BUCKET')
TABLE_NAME = os.environ.get('TABLE_NAME')

def lambda_handler(event, context):
    """
    Get processing status and results for a document
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract doc_id from path parameters
        doc_id = event.get('pathParameters', {}).get('id')
        
        if not doc_id:
            return error_response(400, "Missing document ID")
        
        # Get status from DynamoDB
        table = dynamodb.Table(TABLE_NAME)
        response = table.get_item(Key={'doc_id': doc_id})
        
        if 'Item' not in response:
            return error_response(404, f"Document {doc_id} not found")
        
        item = response['Item']
        
        # Build response based on processing stage
        result = {
            'doc_id': doc_id,
            'status': item.get('status', 'unknown'),
            'processing_stage': item.get('processing_stage', 'unknown'),
            'mode': item.get('mode', 'single'),
            'timestamp': item.get('timestamp', '')
        }
        
        # Load processed results if available
        if item.get('processed_key'):
            try:
                extraction_data = load_s3_json(item['processed_key'])
                result['extracted_clauses'] = extraction_data.get('extracted_clauses', {})
                result['summary'] = extraction_data.get('summary', '')
            except Exception as e:
                logger.warning(f"Could not load extraction data: {str(e)}")
        
        if item.get('deviation_key'):
            try:
                deviation_data = load_s3_json(item['deviation_key'])
                result['deviation_flags'] = deviation_data.get('deviation_flags', [])
                result['risk_score'] = deviation_data.get('risk_score', 0)
            except Exception as e:
                logger.warning(f"Could not load deviation data: {str(e)}")
        
        if item.get('comparison_key'):
            try:
                comparison_data = load_s3_json(item['comparison_key'])
                result['conflicts'] = comparison_data.get('conflicts', [])
                result['comparison_summary'] = comparison_data.get('summary', '')
            except Exception as e:
                logger.warning(f"Could not load comparison data: {str(e)}")
        
        # Add risk score if available
        if 'risk_score' in item:
            result['risk_score'] = item['risk_score']
        
        return success_response(result)
        
    except Exception as e:
        logger.error(f"Error in status handler: {str(e)}", exc_info=True)
        return error_response(500, f"Internal server error: {str(e)}")

def load_s3_json(key):
    """Load JSON from S3"""
    response = s3_client.get_object(Bucket=PROCESSED_BUCKET, Key=key)
    return json.loads(response['Body'].read())

def convert_decimals(obj):
    """Convert Decimal objects to int or float for JSON serialization"""
    if isinstance(obj, list):
        return [convert_decimals(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_decimals(value) for key, value in obj.items()}
    elif isinstance(obj, Decimal):
        # Convert to int if it's a whole number, otherwise float
        return int(obj) if obj % 1 == 0 else float(obj)
    else:
        return obj

def success_response(data):
    """Generate success response"""
    # Convert any Decimal objects before JSON serialization
    data = convert_decimals(data)
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET, OPTIONS'
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
