"""
title: Atomia Code Generation Tool
author: Atomia Cloud Suite
author_url: https://github.com/HiTechTN/atomia-cloud-suite
version: 1.0.0
"""

import os
from typing import List, Dict

class Tools:
    def __init__(self):
        self.base_path = "/projects"

    def scaffold_project(self, project_name: str, tech_stack: str) -> str:
        """
        Scaffold a basic project structure based on a tech stack.
        :param project_name: The name of the project.
        :param tech_stack: The tech stack (e.g., 'react', 'python', 'nodejs').
        :return: A message describing the created structure.
        """
        try:
            project_path = os.path.join(self.base_path, project_name)
            os.makedirs(project_path, exist_ok=True)
            
            if tech_stack.lower() == "react":
                dirs = ["src", "src/components", "src/hooks", "public", "tests"]
                files = {
                    "package.json": '{\n  "name": "react-app",\n  "version": "1.0.0",\n  "dependencies": {\n    "react": "^18.0.0",\n    "react-dom": "^18.0.0"\n  }\n}',
                    "src/App.tsx": 'import React from "react";\n\nexport default function App() {\n  return <h1>Hello World</h1>;\n}',
                    "src/main.tsx": 'import React from "react";\nimport ReactDOM from "react-dom/client";\nimport App from "./App";\n\nReactDOM.createRoot(document.getElementById("root")!).render(<App />);'
                }
            elif tech_stack.lower() == "python":
                dirs = ["app", "tests", "docs"]
                files = {
                    "requirements.txt": "requests\npydantic",
                    "app/main.py": 'if __name__ == "__main__":\n    print("Hello from Atomia!")',
                    "tests/test_main.py": "def test_example():\n    assert True"
                }
            else:
                return f"Error: Tech stack '{tech_stack}' not supported for scaffolding yet."

            for d in dirs:
                os.makedirs(os.path.join(project_path, d), exist_ok=True)
            
            for f_path, content in files.items():
                full_f_path = os.path.join(project_path, f_path)
                os.makedirs(os.path.dirname(full_f_path), exist_ok=True)
                with open(full_f_path, "w", encoding="utf-8") as f:
                    f.write(content)
            
            return f"Successfully scaffolded {tech_stack} project '{project_name}' at {project_path}."
        except Exception as e:
            return f"Error: {str(e)}"

    def generate_unit_tests(self, file_path: str, source_code: str) -> str:
        """
        Generate unit tests for a given source code and save them.
        :param file_path: The path where the test file should be saved (relative to /projects).
        :param source_code: The source code to generate tests for (this is just used as a reference if the AI didn't already have it).
        :return: A success or error message.
        """
        # This tool is more of a placeholder for the AI to "commit" its generated tests
        # The AI can use write_file for this, but having a dedicated tool makes it more explicit.
        try:
            full_path = os.path.abspath(os.path.join(self.base_path, file_path))
            if not full_path.startswith(self.base_path):
                return "Error: Access denied."
            
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(source_code)
            return f"Successfully saved generated tests to '{file_path}'."
        except Exception as e:
            return f"Error: {str(e)}"
