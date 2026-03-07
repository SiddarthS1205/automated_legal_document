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

def lambda_handler(event, context):
    """
    Compares two document versions and identifies conflicts
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        doc_id = event.get('doc_id')
        
        if not doc_id:
            raise ValueError("Missing doc_id")
        
        # Load both document extractions
        clauses1 = load_extraction_result(doc_id, "version1")
        clauses2 = load_extraction_result(doc_id, "version2")
        
        # Perform comparison
        conflicts = compare_documents(clauses1, clauses2)
        
        # Generate comparison summary
        summary = generate_comparison_summary(conflicts, clauses1, clauses2)
        
        # Store results
        result = {
            'doc_id': doc_id,
            'conflicts': conflicts,
            'summary': summary,
            'total_conflicts': len(conflicts)
        }
        
        # Save to S3
        result_key = f"processed/{doc_id}/comparison_result.json"
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
            UpdateExpression='SET #status = :status, processing_stage = :stage, comparison_key = :key',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'complete',
                ':stage': 'comparison_complete',
                ':key': result_key
            }
        )
        
        logger.info(f"Comparison complete for {doc_id}: {len(conflicts)} conflicts found")
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Error in comparison agent: {str(e)}", exc_info=True)
        raise

def load_extraction_result(doc_id, version):
    """Load extraction result from S3"""
    
    key = f"processed/{doc_id}/{version}/extraction_result.json"
    
    try:
        response = s3_client.get_object(Bucket=PROCESSED_BUCKET, Key=key)
        data = json.loads(response['Body'].read())
        return data.get('extracted_clauses', {})
    except Exception as e:
        logger.error(f"Error loading extraction result for {version}: {str(e)}")
        # Try alternative key format
        key = f"processed/{doc_id}/extraction_result.json"
        response = s3_client.get_object(Bucket=PROCESSED_BUCKET, Key=key)
        data = json.loads(response['Body'].read())
        return data.get('extracted_clauses', {})

def compare_documents(clauses1, clauses2):
    """Compare two document versions and identify conflicts"""
    
    conflicts = []
    
    # Get all clause names
    all_clauses = set(clauses1.keys()) | set(clauses2.keys())
    
    for clause_name in all_clauses:
        value1 = clauses1.get(clause_name, "")
        value2 = clauses2.get(clause_name, "")
        
        # Check for added clauses
        if not value1 or value1 == "Not found":
            if value2 and value2 != "Not found":
                conflicts.append({
                    "Clause": clause_name,
                    "Type": "Added Clause",
                    "Version1": "Not present",
                    "Version2": value2[:300],
                    "Conflict Summary": f"Clause '{clause_name}' was added in Version 2",
                    "Severity": "Medium"
                })
                continue
        
        # Check for removed clauses
        if not value2 or value2 == "Not found":
            if value1 and value1 != "Not found":
                conflicts.append({
                    "Clause": clause_name,
                    "Type": "Removed Clause",
                    "Version1": value1[:300],
                    "Version2": "Not present",
                    "Conflict Summary": f"Clause '{clause_name}' was removed in Version 2",
                    "Severity": "High"
                })
                continue
        
        # Both exist - check for modifications
        if value1 and value2 and value1 != "Not found" and value2 != "Not found":
            # Calculate simple similarity
            similarity = calculate_simple_similarity(value1, value2)
            
            if similarity < 0.85:  # Significant difference threshold
                # Identify specific changes
                change_summary = identify_specific_changes(clause_name, value1, value2)
                
                # Determine severity
                severity = determine_conflict_severity(clause_name, similarity)
                
                conflicts.append({
                    "Clause": clause_name,
                    "Type": "Modified Clause",
                    "Version1": value1[:300],
                    "Version2": value2[:300],
                    "Conflict Summary": change_summary,
                    "Similarity Score": round(similarity, 2),
                    "Severity": severity
                })
    
    # Sort by severity
    severity_order = {"High": 0, "Medium": 1, "Low": 2}
    conflicts.sort(key=lambda x: severity_order.get(x['Severity'], 3))
    
    return conflicts

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

def identify_specific_changes(clause_name, value1, value2):
    """Identify specific changes between clause versions"""
    
    # Clause-specific change detection
    if clause_name == "Payment Clause":
        return analyze_payment_changes(value1, value2)
    elif clause_name == "Term":
        return analyze_term_changes(value1, value2)
    elif clause_name == "Liability":
        return analyze_liability_changes(value1, value2)
    else:
        return f"Content of '{clause_name}' has been modified between versions"

def analyze_payment_changes(value1, value2):
    """Analyze payment clause changes"""
    
    # Extract numbers (amounts, days)
    import re
    
    numbers1 = re.findall(r'\d+', value1)
    numbers2 = re.findall(r'\d+', value2)
    
    if numbers1 != numbers2:
        return f"Payment terms changed: numerical values differ (V1: {numbers1[:3]}, V2: {numbers2[:3]})"
    
    return "Payment clause wording modified"

def analyze_term_changes(value1, value2):
    """Analyze term clause changes"""
    
    import re
    
    # Look for duration changes
    duration_pattern = r'(\d+)\s*(year|month|day)s?'
    
    duration1 = re.findall(duration_pattern, value1.lower())
    duration2 = re.findall(duration_pattern, value2.lower())
    
    if duration1 != duration2:
        return f"Contract duration changed from {duration1} to {duration2}"
    
    return "Term clause modified"

def analyze_liability_changes(value1, value2):
    """Analyze liability clause changes"""
    
    # Check for liability cap changes
    if "unlimited" in value1.lower() and "unlimited" not in value2.lower():
        return "Liability changed from unlimited to limited"
    elif "unlimited" not in value1.lower() and "unlimited" in value2.lower():
        return "Liability changed from limited to unlimited (HIGH RISK)"
    
    return "Liability terms modified"

def determine_conflict_severity(clause_name, similarity):
    """Determine severity of conflict based on clause type and similarity"""
    
    critical_clauses = ["Liability", "Payment Clause", "Termination", "Intellectual Property"]
    
    if clause_name in critical_clauses:
        if similarity < 0.5:
            return "High"
        elif similarity < 0.75:
            return "Medium"
        else:
            return "Low"
    else:
        if similarity < 0.4:
            return "Medium"
        else:
            return "Low"

def generate_comparison_summary(conflicts, clauses1, clauses2):
    """Generate executive summary of comparison"""
    
    high_severity = len([c for c in conflicts if c['Severity'] == 'High'])
    medium_severity = len([c for c in conflicts if c['Severity'] == 'Medium'])
    low_severity = len([c for c in conflicts if c['Severity'] == 'Low'])
    
    added = len([c for c in conflicts if c['Type'] == 'Added Clause'])
    removed = len([c for c in conflicts if c['Type'] == 'Removed Clause'])
    modified = len([c for c in conflicts if c['Type'] == 'Modified Clause'])
    
    summary = f"""
DOCUMENT COMPARISON SUMMARY

Total Conflicts Detected: {len(conflicts)}

Severity Breakdown:
- High Severity: {high_severity}
- Medium Severity: {medium_severity}
- Low Severity: {low_severity}

Change Types:
- Added Clauses: {added}
- Removed Clauses: {removed}
- Modified Clauses: {modified}

Critical Changes:
"""
    
    # Add critical changes
    critical_conflicts = [c for c in conflicts if c['Severity'] == 'High'][:3]
    for conflict in critical_conflicts:
        summary += f"\n- {conflict['Clause']}: {conflict['Conflict Summary']}"
    
    if not critical_conflicts:
        summary += "\nNo critical changes detected."
    
    return summary.strip()
