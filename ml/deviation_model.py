"""
ML Deviation Detection Model
Implements TF-IDF and Sentence Transformer based deviation detection
"""

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sentence_transformers import SentenceTransformer
import logging

logger = logging.getLogger(__name__)

class DeviationDetector:
    """
    ML-based deviation detector for legal clauses
    """
    
    def __init__(self, model_name='all-MiniLM-L6-v2'):
        """Initialize with sentence transformer model"""
        self.model = SentenceTransformer(model_name)
        self.tfidf_vectorizer = TfidfVectorizer(
            stop_words='english',
            max_features=500,
            ngram_range=(1, 2)
        )
    
    def calculate_tfidf_similarity(self, text1, text2):
        """Calculate TF-IDF based cosine similarity"""
        try:
            if not text1 or not text2:
                return 0.0
            
            tfidf_matrix = self.tfidf_vectorizer.fit_transform([text1, text2])
            similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
            
            return float(similarity)
        except Exception as e:
            logger.error(f"Error calculating TF-IDF similarity: {str(e)}")
            return 0.0
    
    def calculate_embedding_similarity(self, text1, text2):
        """Calculate semantic similarity using sentence embeddings"""
        try:
            if not text1 or not text2:
                return 0.0
            
            embeddings = self.model.encode([text1, text2])
            similarity = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]
            
            return float(similarity)
        except Exception as e:
            logger.error(f"Error calculating embedding similarity: {str(e)}")
            return 0.0
    
    def detect_deviations(self, extracted_clauses, standard_template):
        """
        Detect deviations from standard template
        
        Args:
            extracted_clauses: Dict of extracted clauses
            standard_template: Dict of standard clause templates
        
        Returns:
            List of deviation flags
        """
        deviations = []
        
        for clause_name, template_info in standard_template.items():
            extracted_value = extracted_clauses.get(clause_name, "")
            
            # Check for missing required clauses
            if template_info.get('required', False):
                if not extracted_value or extracted_value == "Not found":
                    deviations.append({
                        'clause': clause_name,
                        'type': 'missing',
                        'severity': 'high',
                        'reason': f"Required clause '{clause_name}' is missing"
                    })
                    continue
            
            # Skip if clause not found
            if not extracted_value or extracted_value == "Not found":
                continue
            
            # Calculate similarity with standard
            standard_text = template_info.get('standard_text', '')
            
            tfidf_sim = self.calculate_tfidf_similarity(extracted_value, standard_text)
            embedding_sim = self.calculate_embedding_similarity(extracted_value, standard_text)
            
            # Average similarity
            avg_similarity = (tfidf_sim + embedding_sim) / 2
            
            # Flag if similarity is low
            if avg_similarity < 0.4:
                deviations.append({
                    'clause': clause_name,
                    'type': 'modified',
                    'severity': 'medium',
                    'reason': f"Clause significantly deviates from standard (similarity: {avg_similarity:.2f})",
                    'similarity_score': round(avg_similarity, 2)
                })
            
            # Check for risky keywords
            risk_keywords = template_info.get('risk_keywords', [])
            for keyword in risk_keywords:
                if keyword.lower() in extracted_value.lower():
                    deviations.append({
                        'clause': clause_name,
                        'type': 'risky_wording',
                        'severity': 'high',
                        'reason': f"Risky keyword '{keyword}' detected",
                        'context': extracted_value[:200]
                    })
        
        return deviations
    
    def calculate_risk_score(self, deviations):
        """Calculate overall risk score (0-100)"""
        if not deviations:
            return 0
        
        severity_weights = {
            'high': 10,
            'medium': 5,
            'low': 2
        }
        
        total_score = sum(
            severity_weights.get(d.get('severity', 'low'), 0) 
            for d in deviations
        )
        
        # Normalize to 0-100
        max_possible = len(deviations) * 10
        normalized = min(100, int((total_score / max_possible) * 100)) if max_possible > 0 else 0
        
        return normalized


class ComparisonAgent:
    """
    Agent for comparing two document versions
    """
    
    def __init__(self, model_name='all-MiniLM-L6-v2'):
        """Initialize with sentence transformer model"""
        self.model = SentenceTransformer(model_name)
    
    def compare_clauses(self, clauses1, clauses2):
        """
        Compare two sets of clauses
        
        Args:
            clauses1: Dict of clauses from version 1
            clauses2: Dict of clauses from version 2
        
        Returns:
            List of conflicts
        """
        conflicts = []
        all_clauses = set(clauses1.keys()) | set(clauses2.keys())
        
        for clause_name in all_clauses:
            value1 = clauses1.get(clause_name, "")
            value2 = clauses2.get(clause_name, "")
            
            # Added clause
            if (not value1 or value1 == "Not found") and value2 and value2 != "Not found":
                conflicts.append({
                    'clause': clause_name,
                    'type': 'added',
                    'version1': None,
                    'version2': value2[:300],
                    'summary': f"Clause '{clause_name}' was added in Version 2"
                })
                continue
            
            # Removed clause
            if (not value2 or value2 == "Not found") and value1 and value1 != "Not found":
                conflicts.append({
                    'clause': clause_name,
                    'type': 'removed',
                    'version1': value1[:300],
                    'version2': None,
                    'summary': f"Clause '{clause_name}' was removed in Version 2"
                })
                continue
            
            # Modified clause
            if value1 and value2 and value1 != "Not found" and value2 != "Not found":
                similarity = self.calculate_similarity(value1, value2)
                
                if similarity < 0.85:  # Threshold for significant change
                    conflicts.append({
                        'clause': clause_name,
                        'type': 'modified',
                        'version1': value1[:300],
                        'version2': value2[:300],
                        'summary': f"Clause '{clause_name}' was modified",
                        'similarity': round(similarity, 2)
                    })
        
        return conflicts
    
    def calculate_similarity(self, text1, text2):
        """Calculate semantic similarity"""
        try:
            embeddings = self.model.encode([text1, text2])
            similarity = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]
            return float(similarity)
        except Exception as e:
            logger.error(f"Error calculating similarity: {str(e)}")
            return 0.0
