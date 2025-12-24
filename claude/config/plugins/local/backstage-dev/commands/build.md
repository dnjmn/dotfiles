---
description: Build and prepare Backstage for deployment
argument-hint: [--target=docker|local|check]
allowed-tools: [Bash, Read, Glob, Grep]
---

# Backstage Build Workflow

Build and prepare Backstage for deployment.

## Arguments

$ARGUMENTS

**Targets:**
- `check` - Run type checks and linting only (default)
- `local` - Build for local testing
- `docker` - Build Docker image for deployment

## Build Process

### 1. Pre-Build Checks

```bash
# Type checking
yarn tsc

# Linting
yarn lint

# Run tests
yarn test --no-watch
```

### 2. Backend Build

```bash
# Build backend bundle
yarn build:backend

# Output: packages/backend/dist/
```

### 3. Docker Build (if --target=docker)

```bash
# Build Docker image
yarn build-image

# Or with custom tag
docker build -t backstage:latest -f packages/backend/Dockerfile .
```

## Deployment Checklist

### Configuration

- [ ] `app-config.production.yaml` exists and is configured
- [ ] Database connection string is set
- [ ] `backend.baseUrl` matches production URL
- [ ] `app.baseUrl` matches production URL
- [ ] CORS origins are correct for production

### Environment Variables

```bash
# Required for production
POSTGRES_HOST=
POSTGRES_PORT=5432
POSTGRES_USER=
POSTGRES_PASSWORD=

# GitHub integration
GITHUB_TOKEN=

# Auth (if not using guest)
AUTH_GITHUB_CLIENT_ID=
AUTH_GITHUB_CLIENT_SECRET=
```

### Security

- [ ] Guest auth disabled or restricted
- [ ] CSP headers configured
- [ ] HTTPS enabled
- [ ] Secrets not in config files

### TechDocs (if using external storage)

```yaml
techdocs:
  builder: external
  publisher:
    type: awsS3  # or googleGcs, azureBlobStorage
    awsS3:
      bucketName: my-techdocs-bucket
      region: us-east-1
```

### Database

- [ ] PostgreSQL configured (not SQLite)
- [ ] Database migrations run
- [ ] Connection pool sized appropriately

## Docker Deployment

### Dockerfile Structure

```dockerfile
FROM node:22-bookworm-slim

# Install dependencies for native modules
RUN apt-get update && apt-get install -y \
  python3 g++ build-essential libsqlite3-dev

WORKDIR /app

# Copy built backend
COPY packages/backend/dist packages/backend/dist
COPY app-config*.yaml ./

# Install production dependencies
RUN yarn install --production

# Run as non-root user
USER node

CMD ["node", "packages/backend/dist/index.js"]
```

### Docker Compose (Production)

```yaml
version: '3.8'
services:
  backstage:
    image: backstage:latest
    ports:
      - "7007:7007"
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_USER=backstage
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=backstage
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=backstage
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backstage
  template:
    metadata:
      labels:
        app: backstage
    spec:
      containers:
        - name: backstage
          image: backstage:latest
          ports:
            - containerPort: 7007
          env:
            - name: POSTGRES_HOST
              valueFrom:
                secretKeyRef:
                  name: backstage-secrets
                  key: postgres-host
          readinessProbe:
            httpGet:
              path: /healthcheck
              port: 7007
            initialDelaySeconds: 30
            periodSeconds: 10
```

## Build Verification

### Local Testing

```bash
# Start with production config
yarn start --config app-config.yaml --config app-config.production.yaml

# Test in Docker
docker run -p 7007:7007 \
  -e POSTGRES_HOST=host.docker.internal \
  backstage:latest
```

### Health Check

```bash
# Backend health
curl http://localhost:7007/healthcheck

# Catalog API
curl http://localhost:7007/api/catalog/entities

# Search API
curl http://localhost:7007/api/search/query
```

## Output

After build completion:
1. Build status (success/failure)
2. Output location
3. Image tag (if Docker)
4. Remaining checklist items
5. Deployment commands
