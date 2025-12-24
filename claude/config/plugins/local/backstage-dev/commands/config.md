---
description: Edit Backstage app-config with validation and environment awareness
argument-hint: <section> [--env=dev|local|production]
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Backstage Configuration Editor

Edit app-config.yaml files with validation and best practices.

## Arguments

$ARGUMENTS

**Sections:**
- `app` - Application settings (title, baseUrl)
- `backend` - Backend settings (database, listen, cors)
- `integrations` - Source control integrations
- `proxy` - API proxy endpoints
- `techdocs` - Documentation settings
- `auth` - Authentication providers
- `catalog` - Catalog locations and rules
- `scaffolder` - Template scaffolder settings
- `search` - Search engine configuration
- `kubernetes` - Kubernetes cluster settings
- `permission` - Permission policies

## Configuration Files

**Hierarchy (later overrides earlier):**
1. `app-config.yaml` - Base configuration
2. `app-config.dev.yaml` - Docker development overrides
3. `app-config.local.yaml` - Local secrets (gitignored)
4. `app-config.production.yaml` - Production settings

## Process

### 1. Identify Target File
Based on --env flag or section sensitivity:
- Secrets/tokens → `app-config.local.yaml`
- Docker dev settings → `app-config.dev.yaml`
- Production → `app-config.production.yaml`
- Default → `app-config.yaml`

### 2. Read Current Configuration
Read the target file and understand current structure.

### 3. Apply Changes
Edit with proper YAML formatting and structure.

### 4. Validate
- Check YAML syntax
- Verify environment variable references: `${VAR_NAME}`
- Warn about hardcoded secrets

## Section Reference

### app
```yaml
app:
  title: My Developer Portal
  baseUrl: http://localhost:3000
  # Production: https://backstage.mycompany.com

organization:
  name: My Company
```

### backend
```yaml
backend:
  baseUrl: http://localhost:7007
  listen:
    port: 7007
    host: 0.0.0.0  # Required for Docker
  database:
    client: pg  # or better-sqlite3
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
  cors:
    origin: http://localhost:3000
    methods: [GET, HEAD, PATCH, POST, PUT, DELETE]
    credentials: true
  csp:
    connect-src: ["'self'", 'http:', 'https:']
```

### integrations
```yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
  gitlab:
    - host: gitlab.com
      token: ${GITLAB_TOKEN}
```

### proxy
```yaml
proxy:
  endpoints:
    '/circleci':
      target: https://circleci.com/api/v1.1
      headers:
        Circle-Token: ${CIRCLECI_TOKEN}
    '/jenkins':
      target: http://jenkins.internal
      changeOrigin: true
```

### techdocs
```yaml
techdocs:
  builder: 'local'  # or 'external'
  generator:
    runIn: 'docker'  # or 'local'
  publisher:
    type: 'local'  # or 'awsS3', 'googleGcs'
    # For S3:
    # awsS3:
    #   bucketName: my-techdocs-bucket
    #   region: us-east-1
```

### auth
```yaml
auth:
  environment: development
  providers:
    guest:
      dangerouslyAllowOutsideDevelopment: true
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
```

### catalog
```yaml
catalog:
  import:
    entityFilename: catalog-info.yaml
    pullRequestBranchName: backstage-integration
  rules:
    - allow: [Component, System, API, Resource, Location, Domain, Group, User, Template]
  locations:
    - type: file
      target: ../../examples/entities.yaml
    - type: url
      target: https://github.com/org/repo/blob/main/catalog-info.yaml
```

### kubernetes
```yaml
kubernetes:
  serviceLocatorMethod:
    type: multiTenant
  clusterLocatorMethods:
    - type: config
      clusters:
        - name: production
          url: https://k8s.example.com
          authProvider: serviceAccount
          serviceAccountToken: ${K8S_TOKEN}
```

## Security Guidelines

1. **Never commit secrets** - Use `${ENV_VAR}` syntax
2. **Use app-config.local.yaml** for local development secrets
3. **Validate production config** before deployment
4. **Set proper CORS origins** in production
5. **Enable CSP headers** for security
