---
name: software-template
description: This skill provides patterns for creating Backstage Software Templates (Scaffolder). Use when the user mentions "template", "scaffolder", "software template", "Create Component", or asks about automating project creation.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Software Template Authoring

Expert patterns for Backstage v1beta3 Software Templates.

## Template Structure

```
examples/templates/my-template/
├── template.yaml           # Main template definition
└── skeleton/               # Template content
    ├── catalog-info.yaml   # Catalog entity (templated)
    ├── README.md           # Project readme (templated)
    ├── package.json        # If Node.js project
    └── src/                # Source code skeleton
```

## Template YAML Structure

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: golang-service-template
  title: Go Microservice
  description: Create a new Go microservice with gRPC and Kubernetes manifests
  tags:
    - recommended
    - golang
    - grpc
    - kubernetes
spec:
  owner: group:platform-team
  type: service

  # UI Form Definition
  parameters:
    - title: Service Details
      required:
        - name
        - description
        - owner
      properties:
        name:
          title: Service Name
          type: string
          description: Unique name for the service (kebab-case)
          pattern: '^[a-z][a-z0-9-]*$'
          ui:autofocus: true
          ui:help: 'Must start with lowercase letter, only lowercase letters, numbers, and hyphens'

        description:
          title: Description
          type: string
          description: Brief description of the service
          ui:widget: textarea

        owner:
          title: Owner
          type: string
          description: Team that owns this service
          ui:field: OwnerPicker
          ui:options:
            catalogFilter:
              kind: Group

    - title: Technical Options
      properties:
        enableMetrics:
          title: Enable Prometheus Metrics
          type: boolean
          default: true

        enableTracing:
          title: Enable OpenTelemetry Tracing
          type: boolean
          default: true

        goVersion:
          title: Go Version
          type: string
          enum: ['1.22', '1.21', '1.20']
          default: '1.22'

    - title: Repository Configuration
      required:
        - repoUrl
      properties:
        repoUrl:
          title: Repository Location
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts:
              - github.com
            allowedOwners:
              - myorg

  # Backend Execution Steps
  steps:
    - id: fetchTemplate
      name: Fetch Template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}
          description: ${{ parameters.description }}
          owner: ${{ parameters.owner }}
          enableMetrics: ${{ parameters.enableMetrics }}
          enableTracing: ${{ parameters.enableTracing }}
          goVersion: ${{ parameters.goVersion }}
          destination: ${{ parameters.repoUrl | parseRepoUrl }}

    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        allowedHosts:
          - github.com
        repoUrl: ${{ parameters.repoUrl }}
        description: ${{ parameters.description }}
        defaultBranch: main
        protectDefaultBranch: false
        repoVisibility: internal

    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: /catalog-info.yaml

  # Output Links
  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: Open in Catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
      - title: View Pipelines
        icon: github
        url: ${{ steps.publish.output.remoteUrl }}/actions
```

## Parameter Types

### String
```yaml
name:
  title: Name
  type: string
  pattern: '^[a-z][a-z0-9-]*$'
  minLength: 3
  maxLength: 50
  default: 'my-service'
```

### Number
```yaml
replicas:
  title: Replicas
  type: number
  minimum: 1
  maximum: 10
  default: 2
```

### Boolean
```yaml
enableFeature:
  title: Enable Feature
  type: boolean
  default: false
```

### Enum (Dropdown)
```yaml
environment:
  title: Environment
  type: string
  enum: ['development', 'staging', 'production']
  enumNames: ['Development', 'Staging', 'Production']
  default: 'development'
```

### Array
```yaml
tags:
  title: Tags
  type: array
  items:
    type: string
  uniqueItems: true
```

## UI Fields (Pickers)

### OwnerPicker
```yaml
owner:
  title: Owner
  type: string
  ui:field: OwnerPicker
  ui:options:
    catalogFilter:
      kind: Group
```

### RepoUrlPicker
```yaml
repoUrl:
  title: Repository
  type: string
  ui:field: RepoUrlPicker
  ui:options:
    allowedHosts:
      - github.com
      - gitlab.com
    allowedOwners:
      - myorg
```

### EntityPicker
```yaml
system:
  title: System
  type: string
  ui:field: EntityPicker
  ui:options:
    catalogFilter:
      kind: System
```

### OwnedEntityPicker
```yaml
component:
  title: Component
  type: string
  ui:field: OwnedEntityPicker
  ui:options:
    kinds:
      - Component
```

## Built-in Actions

### fetch:template
```yaml
- id: fetchTemplate
  action: fetch:template
  input:
    url: ./skeleton
    values:
      name: ${{ parameters.name }}
    targetPath: ./  # Optional, defaults to workspace root
```

### fetch:plain
```yaml
- id: fetchDocs
  action: fetch:plain
  input:
    url: https://github.com/org/docs/tree/main/templates
    targetPath: ./docs
```

### publish:github
```yaml
- id: publish
  action: publish:github
  input:
    allowedHosts: ['github.com']
    repoUrl: ${{ parameters.repoUrl }}
    description: ${{ parameters.description }}
    defaultBranch: main
    protectDefaultBranch: true
    repoVisibility: internal  # public, private, internal
    topics: ['backstage', 'service']
```

### catalog:register
```yaml
- id: register
  action: catalog:register
  input:
    repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
    catalogInfoPath: /catalog-info.yaml
```

### debug:log
```yaml
- id: debug
  action: debug:log
  input:
    message: 'Values: ${{ parameters | dump }}'
```

## Templating Syntax

**Nunjucks syntax (NOT Jinja):**
```yaml
# CORRECT
${{ parameters.name }}
${{ steps.publish.output.remoteUrl }}
${{ parameters.repoUrl | parseRepoUrl }}

# WRONG (Jinja syntax)
{{ parameters.name }}
```

**Common filters:**
- `parseRepoUrl` - Parse repo URL to components
- `parseEntityRef` - Parse entity reference
- `dump` - JSON stringify for debugging

**Conditionals in skeleton files:**
```
{%- if values.enableMetrics %}
metrics:
  enabled: true
{%- endif %}
```

## Skeleton Templating

**skeleton/catalog-info.yaml:**
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: ${{ values.name }}
  description: ${{ values.description }}
  annotations:
    github.com/project-slug: ${{ values.destination.owner }}/${{ values.destination.repo }}
    backstage.io/techdocs-ref: dir:.
spec:
  type: service
  lifecycle: experimental
  owner: ${{ values.owner }}
```

**skeleton/README.md:**
```markdown
# ${{ values.name }}

${{ values.description }}

## Getting Started

```bash
go run ./cmd/server
```
```

## Best Practices

1. **Use camelCase for step IDs**: Avoids issues in template expressions
2. **Validate inputs**: Use pattern, minLength, enum for validation
3. **Provide defaults**: Make forms easier to complete
4. **Use ui:help**: Guide users on field requirements
5. **Test with dry-run**: Validate before publishing
6. **Document templates**: Add clear descriptions
