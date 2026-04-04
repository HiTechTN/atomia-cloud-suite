"""
title: Atomia File System Tool
author: Atomia Cloud Suite
author_url: https://github.com/HiTechTN/atomia-cloud-suite
version: 1.0.0
"""

import os
import shutil
from typing import List, Optional

class Tools:
    def __init__(self):
        self.base_path = "/projects"

    def list_files(self, directory: str = ".") -> str:
        """
        List files and directories in a given path relative to the projects root.
        :param directory: The directory path to list (relative to /projects).
        :return: A string containing the list of files and directories.
        """
        try:
            full_path = os.path.abspath(os.path.join(self.base_path, directory))
            if not full_path.startswith(self.base_path):
                return "Error: Access denied. Cannot list files outside of /projects."
            
            if not os.path.exists(full_path):
                return f"Error: Directory '{directory}' not found."
            
            items = os.listdir(full_path)
            result = [f"{'DIR ' if os.path.isdir(os.path.join(full_path, i)) else 'FILE'} {i}" for i in items]
            return "\n".join(result) if result else "Directory is empty."
        except Exception as e:
            return f"Error: {str(e)}"

    def read_file(self, file_path: str) -> str:
        """
        Read the content of a file.
        :param file_path: The path to the file (relative to /projects).
        :return: The content of the file or an error message.
        """
        try:
            full_path = os.path.abspath(os.path.join(self.base_path, file_path))
            if not full_path.startswith(self.base_path):
                return "Error: Access denied. Cannot read files outside of /projects."
            
            if not os.path.isfile(full_path):
                return f"Error: File '{file_path}' not found."
            
            with open(full_path, "r", encoding="utf-8") as f:
                return f.read()
        except Exception as e:
            return f"Error: {str(e)}"

    def write_file(self, file_path: str, content: str) -> str:
        """
        Write content to a file. Overwrites if it exists.
        :param file_path: The path to the file (relative to /projects).
        :param content: The text content to write.
        :return: A success or error message.
        """
        try:
            full_path = os.path.abspath(os.path.join(self.base_path, file_path))
            if not full_path.startswith(self.base_path):
                return "Error: Access denied. Cannot write files outside of /projects."
            
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(content)
            return f"Successfully wrote to '{file_path}'."
        except Exception as e:
            return f"Error: {str(e)}"

    def delete_path(self, path: str) -> str:
        """
        Delete a file or directory.
        :param path: The path to delete (relative to /projects).
        :return: A success or error message.
        """
        try:
            full_path = os.path.abspath(os.path.join(self.base_path, path))
            if not full_path.startswith(self.base_path):
                return "Error: Access denied. Cannot delete outside of /projects."
            
            if os.path.isfile(full_path):
                os.remove(full_path)
            elif os.path.isdir(full_path):
                shutil.rmtree(full_path)
            else:
                return f"Error: Path '{path}' not found."
            return f"Successfully deleted '{path}'."
        except Exception as e:
            return f"Error: {str(e)}"
