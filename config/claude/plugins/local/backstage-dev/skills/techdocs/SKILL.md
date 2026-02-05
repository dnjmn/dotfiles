---
name: techdocs
description: This skill provides patterns for setting up TechDocs in Backstage. Use when the user mentions "TechDocs", "documentation", "mkdocs", "docs-as-code", or asks about technical documentation.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# TechDocs Setup

Expert patterns for Backstage TechDocs (docs-as-code).

## Overview

TechDocs renders Markdown documentation from repositories directly in Backstage using MkDocs.

## Configuration

**app-config.yaml:**
```yaml
techdocs:
  # Build method
  builder: 'local'  # or 'external' for CI/CD

  # Generator settings
  generator:
    runIn: 'docker'  # or 'local' if mkdocs installed

  # Publishing settings
  publisher:
    type: 'local'   # Development only
    # For production, use cloud storage:
    # type: 'awsS3'
    # type: 'googleGcs'
    # type: 'azureBlobStorage'
```

### Local Development
```yaml
techdocs:
  builder: 'local'
  generator:
    runIn: 'docker'  # Requires Docker running
  publisher:
    type: 'local'
```

### Production with S3
```yaml
techdocs:
  builder: 'external'  # Docs built in CI/CD
  publisher:
    type: 'awsS3'
    awsS3:
      bucketName: ${TECHDOCS_S3_BUCKET_NAME}
      region: ${AWS_REGION}
      credentials:
        accessKeyId: ${AWS_ACCESS_KEY_ID}
        secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
```

### Production with GCS
```yaml
techdocs:
  builder: 'external'
  publisher:
    type: 'googleGcs'
    googleGcs:
      bucketName: ${TECHDOCS_GCS_BUCKET_NAME}
      projectId: ${GCP_PROJECT_ID}
```

### Production with Azure Blob
```yaml
techdocs:
  builder: 'external'
  publisher:
    type: 'azureBlobStorage'
    azureBlobStorage:
      containerName: ${TECHDOCS_AZURE_CONTAINER}
      credentials:
        accountName: ${AZURE_ACCOUNT_NAME}
        accountKey: ${AZURE_ACCOUNT_KEY}
```

## Entity Setup

### Add TechDocs Annotation
**catalog-info.yaml:**
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  annotations:
    backstage.io/techdocs-ref: dir:.
spec:
  type: service
  lifecycle: production
  owner: my-team
```

**Annotation options:**
- `dir:.` - Docs in same directory as catalog-info.yaml
- `dir:./docs` - Docs in subdirectory
- `url:https://github.com/org/repo/tree/main/docs` - External URL

## MkDocs Configuration

### Basic mkdocs.yml
```yaml
site_name: My Service Documentation
site_description: Documentation for My Service

nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - API Reference: api/index.md
  - Architecture: architecture.md
  - Runbook: operations/runbook.md

plugins:
  - techdocs-core

markdown_extensions:
  - admonition
  - codehilite
  - pymdownx.superfences
  - pymdownx.tabbed
  - toc:
      permalink: true
```

### Advanced mkdocs.yml
```yaml
site_name: My Service
site_description: Comprehensive documentation

nav:
  - Home: index.md
  - User Guide:
      - Overview: user-guide/overview.md
      - Installation: user-guide/installation.md
      - Configuration: user-guide/configuration.md
  - Developer Guide:
      - Contributing: dev/contributing.md
      - Architecture: dev/architecture.md
      - API: dev/api.md
  - Operations:
      - Deployment: ops/deployment.md
      - Monitoring: ops/monitoring.md
      - Runbook: ops/runbook.md

plugins:
  - techdocs-core
  - search

markdown_extensions:
  - admonition
  - codehilite:
      guess_lang: false
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.tasklist:
      custom_checkbox: true
  - toc:
      permalink: true
  - attr_list
  - md_in_html
```

## Directory Structure

```
my-service/
├── catalog-info.yaml
├── mkdocs.yml
└── docs/
    ├── index.md                 # Home page
    ├── getting-started.md
    ├── api/
    │   ├── index.md
    │   └── endpoints.md
    ├── architecture.md
    └── images/
        └── diagram.png
```

## Documentation Content

### index.md Example
```markdown
# My Service

Welcome to the documentation for My Service.

## Overview

My Service handles order processing and fulfillment.

## Quick Links

- [Getting Started](getting-started.md)
- [API Reference](api/index.md)
- [Architecture](architecture.md)

## Support

Contact the [Commerce Team](https://backstage.company.com/catalog/default/group/commerce-team) for questions.
```

### Using Admonitions
```markdown
!!! note
    This is a note callout.

!!! warning
    This is a warning callout.

!!! danger
    This is a danger callout.

!!! tip
    This is a tip callout.
```

### Code Blocks with Syntax Highlighting
```markdown
    ```python
    def hello_world():
        print("Hello, World!")
    ```

    ```go
    func main() {
        fmt.Println("Hello, World!")
    }
    ```
```

### Mermaid Diagrams
```markdown
    ```mermaid
    graph TD
        A[Client] --> B[API Gateway]
        B --> C[Order Service]
        C --> D[Database]
    ```
```

## Local Development

### TechDocs CLI
```bash
# Install CLI
npm install -g @techdocs/cli

# Generate docs locally
cd my-service
npx @techdocs/cli generate

# Serve locally for preview
npx @techdocs/cli serve

# Publish to storage (CI/CD)
npx @techdocs/cli publish --publisher-type awsS3 \
  --storage-name my-bucket \
  --entity default/Component/my-service
```

### Testing in Docker
```bash
# Generate docs using Docker (matches Backstage behavior)
npx @techdocs/cli generate --docker-image spotify/techdocs
```

## CI/CD Integration

### GitHub Actions
```yaml
name: TechDocs

on:
  push:
    branches: [main]
    paths:
      - 'docs/**'
      - 'mkdocs.yml'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install TechDocs CLI
        run: npm install -g @techdocs/cli

      - name: Generate docs
        run: npx @techdocs/cli generate --no-docker

      - name: Publish to S3
        run: |
          npx @techdocs/cli publish \
            --publisher-type awsS3 \
            --storage-name ${{ secrets.TECHDOCS_S3_BUCKET }} \
            --entity default/Component/my-service
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: us-east-1
```

## Troubleshooting

### Common Issues

1. **"TechDocs not found"**
   - Check `backstage.io/techdocs-ref` annotation
   - Verify mkdocs.yml exists

2. **"Failed to generate docs"**
   - Check mkdocs.yml syntax
   - Verify all nav files exist
   - Check Docker is running (if using docker generator)

3. **"Missing plugins"**
   - Ensure `techdocs-core` is in plugins list
   - Check for typos in extension names

4. **Images not loading**
   - Use relative paths: `./images/diagram.png`
   - Check image files are committed

### Debug Commands
```bash
# Validate mkdocs.yml
mkdocs build --strict

# Check generated output
ls -la site/

# Verify entity annotation
cat catalog-info.yaml | grep techdocs
```

## Best Practices

1. **Keep docs with code**: Same repo, version together
2. **Use nav section**: Organize documentation structure
3. **Include diagrams**: Mermaid or images for architecture
4. **Add runbooks**: Operational documentation
5. **Link to entities**: Reference other Backstage entities
6. **Review on PR**: Include docs in code review
