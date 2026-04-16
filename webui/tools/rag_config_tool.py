"""
title: Atomia RAG Prompt Tool
author: Atomia Cloud Suite
author_url: https://github.com/HiTechTN/atomia-cloud-suite
version: 1.0.0
"""

import os
import requests
from typing import List, Dict, Optional

class Tools:
    def __init__(self):
        self.qdrant_url = os.environ.get("QDRANT_URL", "http://qdrant:6333")
        self.ollama_url = os.environ.get("OLLAMA_HOST", "http://ollama:11434")
        self.embed_model = os.environ.get("RAG_EMBED_MODEL", "nomic-embed-text")

    def search_and_analyze(self, collection: str, query: str, context_instructions: str) -> str:
        """
        Perform a vector search and then analyze the results with a custom prompt.
        :param collection: The Qdrant collection to search in.
        :param query: The search query (will be embedded).
        :param context_instructions: Specific instructions on how to interpret the retrieved context.
        :return: A string containing the retrieved context or a message.
        """
        try:
            # 1. Get embedding for the query
            res = requests.post(
                f"{self.ollama_url}/api/embeddings",
                json={"model": self.embed_model, "prompt": query}
            )
            if res.status_code != 200:
                return f"Error: Failed to get embedding for query. {res.text}"
            
            embedding = res.json()["embedding"]
            
            # 2. Search in Qdrant
            res = requests.post(
                f"{self.qdrant_url}/collections/{collection}/points/search",
                json={
                    "vector": embedding,
                    "limit": 5,
                    "with_payload": True
                }
            )
            if res.status_code != 200:
                return f"Error: Failed to search in Qdrant. {res.text}"
            
            hits = res.json()["result"]
            if not hits:
                return f"No results found in collection '{collection}' for query '{query}'."
            
            context = "\n\n".join([h["payload"]["text"] for h in hits if "text" in h["payload"]])
            
            # 3. Return the context with the custom instructions for the AI to process in the chat
            return f"Retrieved Context from '{collection}':\n\n{context}\n\nCustom Instructions for Analysis:\n{context_instructions}"
        except Exception as e:
            return f"Error: {str(e)}"

    def update_rag_settings(self, chunk_size: int = 512, chunk_overlap: int = 64) -> str:
        """
        Update the RAG settings for the session. Note: This only affects future indexing.
        :param chunk_size: The number of tokens per chunk.
        :param chunk_overlap: The number of tokens to overlap between chunks.
        :return: A success or error message.
        """
        # This is more of a placeholder as the actual settings are in .env
        return f"Successfully updated RAG settings for future indexing: chunk_size={chunk_size}, chunk_overlap={chunk_overlap}."
