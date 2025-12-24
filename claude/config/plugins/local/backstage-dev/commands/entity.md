---
description: Generate catalog-info.yaml for Backstage entities
argument-hint: <kind> <name> [--system=<system>] [--owner=<owner>]
allowed-tools: [Read, Write, Glob, Grep]
---

# Catalog Entity Generator

Generate Backstage catalog entity definitions (catalog-info.yaml).

## Arguments

$ARGUMENTS

**Supported kinds:**
- `Component` - Software component (service, website, library)
- `API` - API definition (openapi, asyncapi, graphql, grpc)
- `System` - Collection of components
- `Domain` - Business domain
- `Resource` - Infrastructure resource (database, queue, S3)
- `Group` - Team or organization
- `User` - Individual user
- `Location` - Reference to other entities

## Process

### 1. Parse Arguments
Extract kind, name, and optional flags from: $ARGUMENTS

### 2. Generate Entity YAML
Based on kind, generate appropriate structure.

### 3. Add Annotations
Include relevant annotations based on context:
- GitHub integration
- TechDocs reference
- Kubernetes labels

### 4. Output File
Write to appropriate location or display for copy.

## Entity Templates

### Component
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: <name>
  description: <description>
  annotations:
    github.com/project-slug: <org>/<repo>
    backstage.io/techdocs-ref: dir:.
    backstage.io/kubernetes-id: <name>
  tags:
    - <language>
    - <framework>
  links:
    - url: https://example.com/dashboard
      title: Dashboard
      icon: dashboard
spec:
  type: service  # service, website, library
  lifecycle: production  # experimental, production, deprecated
  owner: <owner>
  system: <system>
  dependsOn:
    - resource:default/<database>
  providesApis:
    - <api-name>
  consumesApis:
    - <external-api>
```

### API
```yaml
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: <name>
  description: <description>
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - rest
spec:
  type: openapi  # openapi, asyncapi, graphql, grpc
  lifecycle: production
  owner: <owner>
  system: <system>
  definition: |
    openapi: 3.0.0
    info:
      title: <name>
      version: 1.0.0
    paths:
      /health:
        get:
          summary: Health check
          responses:
            '200':
              description: OK
```

### System
```yaml
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: <name>
  description: <description>
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - <domain>
spec:
  owner: <owner>
  domain: <domain>
```

### Domain
```yaml
apiVersion: backstage.io/v1alpha1
kind: Domain
metadata:
  name: <name>
  description: <description>
spec:
  owner: <owner>
```

### Resource
```yaml
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: <name>
  description: <description>
  annotations:
    backstage.io/techdocs-ref: dir:.
spec:
  type: database  # database, s3, queue
  owner: <owner>
  system: <system>
  dependencyOf:
    - component:default/<component>
```

### Group
```yaml
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: <name>
  description: <description>
spec:
  type: team  # team, business-unit, product-area
  profile:
    displayName: <Display Name>
    email: team@example.com
    picture: https://example.com/logo.png
  parent: <parent-group>
  children: []
  members:
    - <user-ref>
```

### User
```yaml
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: <name>
spec:
  profile:
    displayName: <Full Name>
    email: user@example.com
    picture: https://example.com/avatar.png
  memberOf:
    - <group-ref>
```

### Location
```yaml
apiVersion: backstage.io/v1alpha1
kind: Location
metadata:
  name: <name>
  description: <description>
spec:
  type: url  # url, file
  target: https://github.com/org/repo/blob/main/catalog-info.yaml
  # Or for multiple targets:
  # targets:
  #   - ./path/to/entity1.yaml
  #   - ./path/to/entity2.yaml
```

## Common Annotations

| Annotation | Purpose |
|------------|---------|
| `github.com/project-slug` | GitHub repo (owner/repo) |
| `backstage.io/techdocs-ref` | TechDocs location |
| `backstage.io/kubernetes-id` | K8s workload identifier |
| `backstage.io/kubernetes-namespace` | K8s namespace |
| `jenkins.io/github-folder` | Jenkins folder path |
| `sonarqube.org/project-key` | SonarQube project |
| `jira.com/project-key` | Jira project key |
| `pagerduty.com/service-id` | PagerDuty service |

## Relationship Types

| Relation | Description |
|----------|-------------|
| `dependsOn` | This entity depends on another |
| `providesApi` | Component provides this API |
| `consumesApi` | Component consumes this API |
| `ownedBy` | Entity ownership (auto from owner) |
| `partOf` | Component is part of system |
| `hasPart` | System has components |
