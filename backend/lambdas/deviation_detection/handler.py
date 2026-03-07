import json
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

PROCESSED_BUCKET = os.environ.get('PROCESSED_BUCKET')
TABLE_NAME = os.environ.get('TABLE_NAME')

# Standard contract template
STANDARD_TEMPLATE = {
    "Parties": {
        "required": True,
        "standard_text": "Agreement between two or more identified legal entities",
        "risk_keywords": ["unidentified", "unnamed", "tbd"]
    },
    "Term": {
        "required": True,
        "standard_text": "Defined contract duration with specific start and end dates",
        "risk_keywords": ["indefinite", "perpetual", "unlimited"]
    },
    "Payment Clause": {
        "required": True,
        "standard_text": "Clear payment terms with amounts, schedule, and method specified",
        "risk_keywords": ["variable", "discretionary", "unspecified"]
    },
    "Liability": {
        "required": True,
        "standard_text": "Limited liability with caps and exclusions clearly defined",
        "risk_keywords": ["unlimited", "uncapped", "no limit", "full liability"]
    },
    "Confidentiality": {
        "required": True,
        "standard_text": "Mutual confidentiality obligations with defined scope and duration",
        "risk_keywords": ["no confidentiality", "public", "unrestricted"]
    },
    "Termination": {
        "required": True,
        "standard_text": "Clear termination rights with notice periods and conditions",
        "risk_keywords": ["no termination", "irrevocable", "perpetual"]
    },
    "Governing Law": {
        "required": True,
        "standard_text": "Specified jurisdiction and governing law",
        "risk_keywords": ["unspecified", "tbd", "to be determined"]
    },
    "Intellectual Property": {
        "required": False,
        "standard_text": "Clear IP ownership and licensing terms",
        "risk_keywords": ["transfer", "assignment", "waiver"]
    },
    "Warranties": {
        "required": True,
        "standard_text": "Standard warranties with limitations and disclaimers",
        "risk_keywords": ["no warranty", "as is", "no representation"]
    },
    "Force Majeure": {
        "required": False,
        "standard_text": "Standard force majeure provisions",
        "risk_keywords": []
    }
}

def lambda_handler(event, context):
    """
    Detects deviations from standard contract template
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        doc_id = event.get('doc_id')
        clauses = event.get('clauses', {})
        
        if not doc_id or not clauses:
            raise ValueError("Missing doc_id or clauses")
        
        # Perform deviation detection
        deviation_flags = detect_deviations(clauses)
        
        # Calculate risk score
        risk_score = calculate_risk_score(deviation_flags)
        
        # Store results
        result = {
            'doc_id': doc_id,
            'deviation_flags': deviation_flags,
            'risk_score': risk_score,
            'total_deviations': len(deviation_flags)
        }
        
        # Save to S3
        result_key = f"processed/{doc_id}/deviation_analysis.json"
        s3_client.put_object(
            Bucket=PROCESSED_BUCKET,
            Key=result_key,
            Body=json.dumps(result, indent=2),
            ContentType='application/json'
        )
        
        # Update DynamoDB
        table = dynamodb.Table(TABLE_NAME)
        table.update_item(
            Key={'doc_id': doc_id},
            UpdateExpression='SET processing_stage = :stage, deviation_key = :key, risk_score = :score',
            ExpressionAttributeValues={
                ':stage': 'deviation_detection_complete',
                ':key': result_key,
                ':score': risk_score
            }
        )
        
        logger.info(f"Deviation detection complete for {doc_id}: {len(deviation_flags)} deviations found")
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Error in deviation detection: {str(e)}", exc_info=True)
        raise

def detect_deviations(clauses):
    """Detect deviations using rule-based approach"""
    
    deviations = []
    
    # Check for missing clauses
    for clause_name, template in STANDARD_TEMPLATE.items():
        if template['required']:
            clause_value = clauses.get(clause_name, "")
            
            if not clause_value or clause_value == "Not found":
                deviations.append({
                    "Clause": clause_name,
                    "Risk Level": "High",
                    "Reason": f"Required clause '{clause_name}' is missing",
                    "Type": "Missing Clause"
                })
    
    # Check for risky keywords
    for clause_name, clause_value in clauses.items():
        if clause_name in STANDARD_TEMPLATE:
            template = STANDARD_TEMPLATE[clause_name]
            risk_keywords = template.get('risk_keywords', [])
            
            if clause_value and clause_value != "Not found":
                clause_lower = clause_value.lower()
                
                for keyword in risk_keywords:
                    if keyword in clause_lower:
                        deviations.append({
                            "Clause": clause_name,
                            "Risk Level": "High",
                            "Reason": f"Risky keyword '{keyword}' detected in {clause_name}",
                            "Type": "Risky Wording",
                            "Context": clause_value[:200]
                        })
    
    # Simple text similarity check
    for clause_name, clause_value in clauses.items():
        if clause_name in STANDARD_TEMPLATE and clause_value and clause_value != "Not found":
            template = STANDARD_TEMPLATE[clause_name]
            standard_text = template['standard_text']
            
            # Simple word overlap similarity
            similarity = calculate_simple_similarity(clause_value, standard_text)
            
            if similarity < 0.3:
                deviations.append({
                    "Clause": clause_name,
                    "Risk Level": "Medium",
                    "Reason": f"Clause content significantly deviates from standard template",
                    "Type": "Modified Clause",
                    "Similarity Score": round(similarity, 2)
                })
    
    # Sort by risk level
    risk_order = {"High": 0, "Medium": 1, "Low": 2}
    deviations.sort(key=lambda x: risk_order.get(x['Risk Level'], 3))
    
    return deviations

def calculate_simple_similarity(text1, text2):
    """Calculate simple word overlap similarity"""
    try:
        if not text1 or not text2:
            return 0.0
        
        # Convert to lowercase and split into words
        words1 = set(text1.lower().split())
        words2 = set(text2.lower().split())
        
        # Calculate Jaccard similarity
        intersection = len(words1.intersection(words2))
        union = len(words1.union(words2))
        
        if union == 0:
            return 0.0
        
        return intersection / union
        
    except Exception as e:
        logger.error(f"Error calculating similarity: {str(e)}")
        return 0.0

def calculate_risk_score(deviations):
    """Calculate overall risk score (0-100)"""
    
    if not deviations:
        return 0
    
    risk_weights = {
        "High": 10,
        "Medium": 5,
        "Low": 2
    }
    
    total_score = sum(risk_weights.get(d['Risk Level'], 0) for d in deviations)
    
    # Normalize to 0-100 scale
    max_possible = len(deviations) * 10
    normalized_score = min(100, int((total_score / max_possible) * 100)) if max_possible > 0 else 0
    
    return normalized_score
