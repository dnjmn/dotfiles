---
description: Validate Backstage Software Template YAML syntax and structure
argument-hint: [template-path]
allowed-tools: [Read, Grep, Glob, Bash]
---

# Template Validator

Validate v1beta3 Software Template syntax, structure, and common issues.

## Arguments

$ARGUMENTS

**Defaults:** Current template if in template directory, or prompts for path.

## Validation Checks

### 1. Schema Validation
- `apiVersion: scaffolder.backstage.io/v1beta3`
- `kind: Template`
- Required fields: `metadata.name`, `spec.owner`, `spec.type`

### 2. Metadata Validation
- `name` is kebab-case
- `title` is present and descriptive
- `description` explains purpose
- `tags` are lowercase

### 3. Parameter Validation
For each parameter step:
- `title` is present
- `required` array lists required fields
- `properties` has valid JSON Schema:
  - Valid `type` (string, number, boolean, array, object)
  - `pattern` is valid regex
  - `enum` values match type
  - `ui:field` is valid picker name

### 4. Step Validation
For each step:
- `id` is unique and camelCase
- `name` is descriptive
- `action` is valid action ID
- `input` has required fields for action

### 5. Templating Syntax
- `${{ }}` syntax (not `{{ }}` Jinja)
- Valid parameter references: `${{ parameters.fieldName }}`
- Valid step output references: `${{ steps.stepId.output.fieldName }}`
- Valid filters: `parseRepoUrl`, `parseEntityRef`

### 6. Skeleton Validation
- `./skeleton` directory exists
- Referenced files in fetch:template exist
- `catalog-info.yaml` in skeleton is valid

### 7. Output Validation
- Output links reference valid step outputs
- Entity refs use correct format

## Common Issues

### Templating
```yaml
# WRONG - Jinja syntax
name: {{ parameters.name }}

# CORRECT - Nunjucks syntax
name: ${{ parameters.name }}
```

### Action IDs
```yaml
# WRONG - dashes cause issues in template expressions
- id: fetch-template
  action: fetch:template

# CORRECT - use camelCase
- id: fetchTemplate
  action: fetch:template
```

### RepoUrl Picker
```yaml
# WRONG - missing required options
repoUrl:
  type: string
  ui:field: RepoUrlPicker

# CORRECT - include allowed hosts
repoUrl:
  type: string
  ui:field: RepoUrlPicker
  ui:options:
    allowedHosts:
      - github.com
```

### Owner Picker
```yaml
# WRONG - no catalog filter
owner:
  type: string
  ui:field: OwnerPicker

# CORRECT - filter to groups
owner:
  type: string
  ui:field: OwnerPicker
  ui:options:
    catalogFilter:
      kind: Group
```

### Step References
```yaml
# WRONG - wrong output field
repoContentsUrl: ${{ steps.publish.output.remoteUrl }}

# CORRECT - use repoContentsUrl output
repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
```

## Process

1. Read template.yaml
2. Parse YAML structure
3. Run all validation checks
4. Report issues with file:line references
5. Suggest fixes for common problems

## Output Format

```
Validation Results for: examples/templates/my-template/template.yaml

ERRORS (must fix):
- Line 15: Parameter 'name' missing 'type' field
- Line 42: Step 'publish' uses invalid action 'publish:github:enterprise'

WARNINGS (should fix):
- Line 8: Missing 'description' in metadata
- Line 25: OwnerPicker without catalogFilter

INFO:
- Template uses 3 parameters and 4 steps
- Skeleton directory found with 5 files
```

## Dry Run Testing

After validation, suggest running template dry-run:
```bash
# In Backstage UI
# Navigate to /create → select template → Run Dry Run

# Or via API (if available)
curl -X POST http://localhost:7007/api/scaffolder/v2/tasks/dry-run \
  -H 'Content-Type: application/json' \
  -d '{"templateRef": "template:default/my-template", "values": {...}}'
```
