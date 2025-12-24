---
name: app-config
description: This skill provides patterns for editing Backstage app-config.yaml files. Use when the user mentions "app-config", "configuration", "app-config.yaml", "backend settings", "database config", "auth config", or asks about Backstage environment settings.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Backstage App Configuration

Expert patterns for editing Backstage configuration files.

## Configuration File Hierarchy

Later files override earlier (merge, not replace):
1. `app-config.yaml` - Base configuration (committed)
2. `app-config.dev.yaml` - Docker development overrides
3. `app-config.local.yaml` - Local secrets (gitignored)
4. `app-config.production.yaml` - Production settings

Load order with CLI:
```bash
yarn start --config app-config.yaml --config app-config.dev.yaml
```

## Core Sections

### Application Settings
```yaml
app:
  title: My Developer Portal
  baseUrl: http://localhost:3000
  # Production: Use actual domain
  # baseUrl: https://backstage.company.com

organization:
  name: My Company
```

### Backend Configuration
```yaml
backend:
  baseUrl: http://localhost:7007
  listen:
    port: 7007
    host: 0.0.0.0  # Required for Docker/container access

  # Database - SQLite for dev, PostgreSQL for production
  database:
    client: pg  # or better-sqlite3
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}

  # Optional: Redis cache
  cache:
    store: redis
    connection: redis://localhost:6379

  # CORS - critical for frontend/backend communication
  cors:
    origin: http://localhost:3000
    methods: [GET, HEAD, PATCH, POST, PUT, DELETE]
    credentials: true

  # Content Security Policy
  csp:
    connect-src: ["'self'", 'http:', 'https:']
    img-src: ["'self'", 'data:', 'https:']
```

### Integrations (Source Control)
```yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}

  gitlab:
    - host: gitlab.com
      token: ${GITLAB_TOKEN}

  bitbucketCloud:
    - username: ${BITBUCKET_USERNAME}
      appPassword: ${BITBUCKET_APP_PASSWORD}

  azure:
    - host: dev.azure.com
      credentials:
        - personalAccessToken: ${AZURE_TOKEN}
```

### Authentication
```yaml
auth:
  environment: development
  providers:
    # Guest auth - development only
    guest:
      dangerouslyAllowOutsideDevelopment: true

    # GitHub OAuth
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}

    # Google OAuth
    google:
      development:
        clientId: ${AUTH_GOOGLE_CLIENT_ID}
        clientSecret: ${AUTH_GOOGLE_CLIENT_SECRET}

    # Okta OIDC
    okta:
      development:
        clientId: ${AUTH_OKTA_CLIENT_ID}
        clientSecret: ${AUTH_OKTA_CLIENT_SECRET}
        audience: ${AUTH_OKTA_AUDIENCE}
```

### Catalog Configuration
```yaml
catalog:
  import:
    entityFilename: catalog-info.yaml
    pullRequestBranchName: backstage-integration

  rules:
    - allow: [Component, System, API, Resource, Location, Domain, Group, User, Template]

  locations:
    # Local examples
    - type: file
      target: ../../examples/entities.yaml

    # GitHub URL
    - type: url
      target: https://github.com/org/repo/blob/main/catalog-info.yaml
      rules:
        - allow: [Component, API]

    # GitHub discovery (all repos)
    - type: github-discovery
      target: https://github.com/org/*/blob/main/catalog-info.yaml
```

### TechDocs Configuration
```yaml
techdocs:
  builder: 'local'  # or 'external' for CI/CD builds
  generator:
    runIn: 'docker'  # or 'local' if mkdocs installed
  publisher:
    type: 'local'   # Development
    # Production with S3:
    # type: 'awsS3'
    # awsS3:
    #   bucketName: my-techdocs-bucket
    #   region: us-east-1
    #   credentials:
    #     accessKeyId: ${AWS_ACCESS_KEY_ID}
    #     secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
```

### Proxy Configuration
```yaml
proxy:
  endpoints:
    '/circleci':
      target: https://circleci.com/api/v1.1
      headers:
        Circle-Token: ${CIRCLECI_TOKEN}
      changeOrigin: true

    '/jenkins':
      target: http://jenkins.internal:8080
      headers:
        Authorization: Basic ${JENKINS_AUTH}
      changeOrigin: true
```

### Scaffolder Configuration
```yaml
scaffolder:
  defaultAuthor:
    name: Backstage Scaffolder
    email: scaffolder@company.com
  defaultCommitMessage: "Initial commit from Backstage"
```

### Kubernetes Configuration
```yaml
kubernetes:
  serviceLocatorMethod:
    type: multiTenant
  clusterLocatorMethods:
    - type: config
      clusters:
        - name: production
          url: ${K8S_CLUSTER_URL}
          authProvider: serviceAccount
          serviceAccountToken: ${K8S_SERVICE_ACCOUNT_TOKEN}
          skipTLSVerify: false
          skipMetricsLookup: false
```

### Permission Configuration
```yaml
permission:
  enabled: true
  # Custom policy plugin would be registered in backend
```

## Environment Variables

**Always use `${VAR_NAME}` syntax for secrets:**

```yaml
# CORRECT - Reference environment variable
token: ${GITHUB_TOKEN}

# WRONG - Hardcoded secret
token: ghp_xxxxxxxxxxxxxxxxxxxx
```

**Required environment variables for production:**
- `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `GITHUB_TOKEN` (for GitHub integration)
- Auth provider credentials

## Best Practices

1. **Separate concerns**: Use different config files for different environments
2. **Never commit secrets**: Use environment variables
3. **Validate before deploy**: Run `yarn start` to catch config errors
4. **Document env vars**: Keep a list of required variables
5. **Use local file for dev secrets**: `app-config.local.yaml` is gitignored
