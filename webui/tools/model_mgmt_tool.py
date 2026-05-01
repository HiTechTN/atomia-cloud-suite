"""
title: Atomia Model Management Tool
author: Atomia Cloud Suite
author_url: https://github.com/HiTechTN/atomia-cloud-suite
version: 1.0.0
"""

import os
import requests
import json
from typing import List, Dict, Optional

class Tools:
    def __init__(self):
        self.ollama_url = os.environ.get("OLLAMA_HOST", "http://ollama:11434")

    def list_local_models(self) -> str:
        """
        List all AI models currently available in the Ollama backend.
        :return: A formatted list of models.
        """
        try:
            res = requests.get(f"{self.ollama_url}/api/tags")
            if res.status_code != 200:
                return f"Error: Failed to fetch models from Ollama. {res.text}"
            
            data = res.json()
            models = data.get("models", [])
            if not models:
                return "No models found in Ollama."
            
            result = ["Local Ollama Models:"]
            for m in models:
                size_gb = m.get('size', 0) / (1024**3)
                result.append(f"• {m['name']} ({size_gb:.2f} GB) - Modified: {m.get('modified_at', 'unknown')}")
            
            return "\n".join(result)
        except Exception as e:
            return f"Error: {str(e)}"

    def pull_model(self, model_name: str) -> str:
        """
        Download a new model from the Ollama library.
        :param model_name: The name of the model (e.g., 'llama3', 'mistral').
        :return: A success or error message.
        """
        try:
            # Note: We use a non-streaming call for simplicity here, 
            # though for large models streaming is better.
            res = requests.post(
                f"{self.ollama_url}/api/pull",
                json={"name": model_name, "stream": False}
            )
            if res.status_code != 200:
                return f"Error pulling model '{model_name}': {res.text}"
            
            return f"Successfully pulled model '{model_name}'."
        except Exception as e:
            return f"Error: {str(e)}"

    def delete_model(self, model_name: str) -> str:
        """
        Remove a model from the Ollama backend to free up space.
        :param model_name: The name of the model to delete.
        :return: A success message.
        """
        try:
            res = requests.delete(
                f"{self.ollama_url}/api/delete",
                json={"name": model_name}
            )
            if res.status_code != 200:
                return f"Error deleting model '{model_name}': {res.text}"
            
            return f"Successfully deleted model '{model_name}'."
        except Exception as e:
            return f"Error: {str(e)}"

    def register_custom_model(self, model_name: str, base_model: str, system_prompt: str) -> str:
        """
        Create a custom model variant with a specific system prompt.
        :param model_name: The new name for your custom model.
        :param base_model: The base model to use (e.g., 'llama3').
        :param system_prompt: The instructions for the AI behavior.
        :return: A success message.
        """
        try:
            modelfile = f"FROM {base_model}\nSYSTEM \"\"\"{system_prompt}\"\"\""
            res = requests.post(
                f"{self.ollama_url}/api/create",
                json={"name": model_name, "modelfile": modelfile, "stream": False}
            )
            if res.status_code != 200:
                return f"Error creating custom model '{model_name}': {res.text}"
            
            return f"Successfully registered custom model '{model_name}' based on '{base_model}'."
        except Exception as e:
            return f"Error: {str(e)}"
