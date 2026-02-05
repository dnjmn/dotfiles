#!/usr/bin/env python3
"""
Backstage YAML validation hook.
Runs after Write/Edit operations on YAML files to provide helpful feedback.
"""
import json
import sys
import re
from pathlib import Path


def validate_yaml_file(file_path: str) -> list:
    """Validate Backstage YAML files and return messages."""
    messages = []
    path = Path(file_path)

    if not path.suffix in ('.yaml', '.yml'):
        return messages

    file_name = path.name

    # Template files
    if file_name == 'template.yaml' or 'templates/' in file_path:
        messages.append({
            "type": "info",
            "message": f"Template modified: {file_name}. Run /backstage-dev:validate-template to check syntax."
        })

        # Check for common template issues
        try:
            content = path.read_text()

            # Check for Jinja syntax instead of Nunjucks
            if '{{ ' in content and '${{ ' not in content:
                messages.append({
                    "type": "warning",
                    "message": "Possible Jinja syntax detected. Backstage uses Nunjucks: ${{ }} not {{ }}"
                })

            # Check for dashes in step IDs
            if re.search(r"id:\s*['\"]?[\w]+-[\w]+", content):
                messages.append({
                    "type": "warning",
                    "message": "Step IDs with dashes can cause issues. Consider using camelCase."
                })

        except Exception:
            pass

    # Catalog entity files
    elif file_name == 'catalog-info.yaml' or 'catalog' in file_path:
        messages.append({
            "type": "info",
            "message": f"Catalog entity modified: {file_name}. Entity will be reprocessed by Backstage catalog."
        })

        # Check for common catalog issues
        try:
            content = path.read_text()

            if 'apiVersion:' not in content:
                messages.append({
                    "type": "warning",
                    "message": "Missing 'apiVersion' field. Required: backstage.io/v1alpha1"
                })

            if 'kind:' not in content:
                messages.append({
                    "type": "warning",
                    "message": "Missing 'kind' field. Required for catalog entities."
                })

            if 'owner:' not in content and 'kind: Location' not in content:
                messages.append({
                    "type": "info",
                    "message": "Consider adding 'owner' field for entity ownership."
                })

        except Exception:
            pass

    # App config files
    elif file_name.startswith('app-config'):
        env = 'base'
        if '.local.' in file_name:
            env = 'local'
        elif '.dev.' in file_name:
            env = 'development'
        elif '.production.' in file_name:
            env = 'production'

        messages.append({
            "type": "info",
            "message": f"Configuration ({env}) modified. Restart Backstage to apply: yarn start"
        })

        # Check for potential secrets
        try:
            content = path.read_text()

            # Check for hardcoded tokens (not env vars)
            secret_patterns = [
                (r"token:\s*['\"]?gh[ps]_\w+", "GitHub token"),
                (r"token:\s*['\"]?glpat-\w+", "GitLab token"),
                (r"password:\s*['\"]?[^${\s][^\s]+", "password"),
                (r"secret:\s*['\"]?[^${\s][^\s]+", "secret"),
            ]

            for pattern, secret_type in secret_patterns:
                if re.search(pattern, content, re.IGNORECASE):
                    messages.append({
                        "type": "error",
                        "message": f"Possible hardcoded {secret_type} detected! Use ${{ENV_VAR}} syntax."
                    })
                    break

            # Check for guest auth in production
            if 'production' in file_name and 'dangerouslyAllowOutsideDevelopment: true' in content:
                messages.append({
                    "type": "error",
                    "message": "Guest auth with dangerouslyAllowOutsideDevelopment in production config!"
                })

        except Exception:
            pass

    # MkDocs config
    elif file_name == 'mkdocs.yml':
        messages.append({
            "type": "info",
            "message": "TechDocs config modified. Test with: npx @techdocs/cli generate"
        })

        try:
            content = path.read_text()

            if 'techdocs-core' not in content:
                messages.append({
                    "type": "warning",
                    "message": "Missing 'techdocs-core' plugin. Required for Backstage TechDocs."
                })

        except Exception:
            pass

    return messages


def main():
    """Main entry point for the hook."""
    try:
        # Read tool input from stdin
        input_data = sys.stdin.read()
        if not input_data:
            return

        tool_input = json.loads(input_data)
        tool_name = tool_input.get('tool_name', '')
        tool_params = tool_input.get('tool_input', {})

        # Get file path from tool parameters
        file_path = tool_params.get('file_path', '')

        if not file_path:
            return

        # Validate and get messages
        messages = validate_yaml_file(file_path)

        # Output messages if any
        if messages:
            print(json.dumps(messages))

    except json.JSONDecodeError:
        # Invalid JSON input, silently ignore
        pass
    except Exception as e:
        # Log error but don't break the hook
        print(json.dumps([{
            "type": "error",
            "message": f"Hook error: {str(e)}"
        }]))


if __name__ == '__main__':
    main()
