---
description: Create a new Backstage Software Template for scaffolding
argument-hint: <name> [--type=service|website|library]
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# Software Template Creator

Create v1beta3 Backstage Software Templates with proper structure.

## Arguments

$ARGUMENTS

**Defaults:**
- type: service

## Process

### 1. Create Template Directory
```
examples/templates/<name>/
├── template.yaml           # Main template definition
└── skeleton/               # Template content
    ├── catalog-info.yaml   # Entity for created component
    ├── README.md
    └── src/
```

### 2. Generate template.yaml

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: <name>-template
  title: <Title> Template
  description: Creates a new <type>
  tags:
    - recommended
    - <type>
spec:
  owner: platform-team
  type: <type>

  parameters:
    - title: Component Details
      required:
        - name
        - description
        - owner
      properties:
        name:
          title: Name
          type: string
          description: Unique name for the component
          pattern: '^[a-z][a-z0-9-]*$'
          ui:autofocus: true
        description:
          title: Description
          type: string
          description: Brief description of the component
        owner:
          title: Owner
          type: string
          description: Team that owns this component
          ui:field: OwnerPicker
          ui:options:
            catalogFilter:
              kind: Group

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
              - <your-org>

  steps:
    - id: fetch
      name: Fetch Template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}
          description: ${{ parameters.description }}
          owner: ${{ parameters.owner }}
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

    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: /catalog-info.yaml

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: Open in Catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
```

### 3. Create Skeleton Files

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
  type: <type>
  lifecycle: experimental
  owner: ${{ values.owner }}
```

**skeleton/README.md:**
```markdown
# ${{ values.name }}

${{ values.description }}

## Getting Started

TODO: Add getting started instructions
```

### 4. Register Template
Add to `app-config.yaml`:
```yaml
catalog:
  locations:
    - type: file
      target: ../../examples/templates/<name>/template.yaml
      rules:
        - allow: [Template]
```

## Key Concepts

### Parameter Types
- `string`, `number`, `boolean`, `array`, `object`
- JSON Schema validation with `pattern`, `minLength`, `enum`

### UI Fields
- `OwnerPicker` - Select entity owner
- `RepoUrlPicker` - Repository URL input
- `EntityPicker` - Generic entity selector
- `OwnedEntityPicker` - Entities owned by current user

### Built-in Actions
- `fetch:template` - Copy skeleton with templating
- `fetch:plain` - Copy without templating
- `publish:github` - Create GitHub repository
- `publish:gitlab` - Create GitLab repository
- `catalog:register` - Register entity in catalog
- `catalog:write` - Write catalog-info.yaml
- `debug:log` - Log values for debugging

### Templating Syntax
- `${{ parameters.name }}` - Access parameters
- `${{ steps.stepId.output.field }}` - Access step outputs
- `${{ parameters.repoUrl | parseRepoUrl }}` - Use filters
