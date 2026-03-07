"""
Embedding utilities for semantic similarity and comparison
"""

import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import logging

logger = logging.getLogger(__name__)

class EmbeddingManager:
    """
    Manages sentence embeddings for legal document analysis
    """
    
    def __init__(self, model_name='all-MiniLM-L6-v2', cache_embeddings=True):
        """
        Initialize embedding manager
        
        Args:
            model_name: Name of sentence transformer model
            cache_embeddings: Whether to cache computed embeddings
        """
        self.model = SentenceTransformer(model_name)
        self.cache_embeddings = cache_embeddings
        self.embedding_cache = {}
    
    def encode(self, texts, use_cache=True):
        """
        Encode texts to embeddings
        
        Args:
            texts: Single text or list of texts
            use_cache: Whether to use cached embeddings
        
        Returns:
            Numpy array of embeddings
        """
        if isinstance(texts, str):
            texts = [texts]
        
        if use_cache and self.cache_embeddings:
            embeddings = []
            texts_to_encode = []
            indices_to_encode = []
            
            for i, text in enumerate(texts):
                if text in self.embedding_cache:
                    embeddings.append(self.embedding_cache[text])
                else:
                    texts_to_encode.append(text)
                    indices_to_encode.append(i)
            
            if texts_to_encode:
                new_embeddings = self.model.encode(texts_to_encode)
                
                # Cache new embeddings
                for text, embedding in zip(texts_to_encode, new_embeddings):
                    self.embedding_cache[text] = embedding
                
                # Insert at correct positions
                for idx, embedding in zip(indices_to_encode, new_embeddings):
                    embeddings.insert(idx, embedding)
            
            return np.array(embeddings)
        else:
            return self.model.encode(texts)
    
    def compute_similarity(self, text1, text2):
        """
        Compute cosine similarity between two texts
        
        Args:
            text1: First text
            text2: Second text
        
        Returns:
            Similarity score (0-1)
        """
        try:
            embeddings = self.encode([text1, text2])
            similarity = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]
            return float(similarity)
        except Exception as e:
            logger.error(f"Error computing similarity: {str(e)}")
            return 0.0
    
    def compute_similarity_matrix(self, texts1, texts2):
        """
        Compute similarity matrix between two sets of texts
        
        Args:
            texts1: First list of texts
            texts2: Second list of texts
        
        Returns:
            Similarity matrix (len(texts1) x len(texts2))
        """
        try:
            embeddings1 = self.encode(texts1)
            embeddings2 = self.encode(texts2)
            
            similarity_matrix = cosine_similarity(embeddings1, embeddings2)
            return similarity_matrix
        except Exception as e:
            logger.error(f"Error computing similarity matrix: {str(e)}")
            return np.zeros((len(texts1), len(texts2)))
    
    def find_most_similar(self, query_text, candidate_texts, top_k=5):
        """
        Find most similar texts to query
        
        Args:
            query_text: Query text
            candidate_texts: List of candidate texts
            top_k: Number of top results to return
        
        Returns:
            List of (index, similarity_score) tuples
        """
        try:
            query_embedding = self.encode([query_text])[0]
            candidate_embeddings = self.encode(candidate_texts)
            
            similarities = cosine_similarity([query_embedding], candidate_embeddings)[0]
            
            # Get top k indices
            top_indices = np.argsort(similarities)[::-1][:top_k]
            
            results = [(int(idx), float(similarities[idx])) for idx in top_indices]
            return results
        except Exception as e:
            logger.error(f"Error finding most similar: {str(e)}")
            return []
    
    def cluster_texts(self, texts, n_clusters=5):
        """
        Cluster texts based on semantic similarity
        
        Args:
            texts: List of texts to cluster
            n_clusters: Number of clusters
        
        Returns:
            List of cluster labels
        """
        try:
            from sklearn.cluster import KMeans
            
            embeddings = self.encode(texts)
            
            kmeans = KMeans(n_clusters=n_clusters, random_state=42)
            labels = kmeans.fit_predict(embeddings)
            
            return labels.tolist()
        except Exception as e:
            logger.error(f"Error clustering texts: {str(e)}")
            return [0] * len(texts)
    
    def clear_cache(self):
        """Clear embedding cache"""
        self.embedding_cache.clear()
        logger.info("Embedding cache cleared")


def batch_encode(texts, model_name='all-MiniLM-L6-v2', batch_size=32):
    """
    Encode texts in batches for efficiency
    
    Args:
        texts: List of texts
        model_name: Model name
        batch_size: Batch size for encoding
    
    Returns:
        Numpy array of embeddings
    """
    model = SentenceTransformer(model_name)
    
    all_embeddings = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        embeddings = model.encode(batch)
        all_embeddings.append(embeddings)
    
    return np.vstack(all_embeddings)
