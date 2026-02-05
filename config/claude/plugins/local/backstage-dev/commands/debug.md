---
description: Debug common Backstage issues with guided troubleshooting
argument-hint: [issue-type]
allowed-tools: [Read, Bash, Glob, Grep]
---

# Backstage Debugger

Diagnose and fix common Backstage issues.

## Arguments

$ARGUMENTS

**Issue types:**
- `catalog` - Entity processing, orphans, refresh issues
- `techdocs` - Documentation build/publish failures
- `auth` - Authentication and authorization problems
- `plugin` - Plugin loading and registration failures
- `config` - Configuration errors and validation
- `database` - Database connection issues
- `build` - Build and compilation errors
- `startup` - Application startup failures

## Diagnostic Process

### 1. Gather Context
- Read error messages from terminal output
- Check recent changes to relevant files
- Identify affected components

### 2. Run Diagnostics
Execute targeted checks based on issue type.

### 3. Identify Root Cause
Analyze symptoms and trace to source.

### 4. Provide Fix
Step-by-step resolution with commands.

## Issue-Specific Debugging

### Catalog Issues

**Entity not appearing:**
```bash
# Check catalog processor logs
yarn start 2>&1 | grep -i "catalog"

# Verify entity YAML
cat <path>/catalog-info.yaml

# Check catalog locations in config
grep -A 20 "catalog:" app-config.yaml
```

**Common causes:**
- Invalid YAML syntax
- Missing `apiVersion` or `kind`
- Entity not in catalog locations
- Cyclic dependencies
- Invalid owner/system references

**Orphaned entities:**
- Check if source location still exists
- Verify entity hasn't been renamed
- Check for broken references

### TechDocs Issues

**Build failures:**
```bash
# Check mkdocs.yml exists
ls <entity-dir>/mkdocs.yml

# Test local build
npx @techdocs/cli generate --source-dir <entity-dir> --output-dir ./site

# Check Docker (if using docker generator)
docker ps
```

**Common causes:**
- Missing `mkdocs.yml`
- Invalid MkDocs configuration
- Missing docs/ directory
- Plugin dependencies not installed
- Docker not running (if using docker generator)

### Auth Issues

**Login failures:**
```bash
# Check auth configuration
grep -A 30 "auth:" app-config.yaml

# Verify environment variables
echo $AUTH_GITHUB_CLIENT_ID
echo $AUTH_GITHUB_CLIENT_SECRET
```

**Common causes:**
- Missing OAuth credentials
- Incorrect callback URL
- Provider not registered in backend
- Guest auth disabled without alternative
- CORS blocking authentication flow

### Plugin Issues

**Plugin not loading:**
```bash
# Check frontend registration
grep -r "plugin-<name>" packages/app/src/App.tsx

# Check backend registration
grep -r "plugin-<name>" packages/backend/src/index.ts

# Verify package exists
ls plugins/<name>/package.json
```

**Common causes:**
- Plugin not registered in App.tsx or index.ts
- Missing dependencies in package.json
- Export/import mismatch
- Wrong `backstage.role` in package.json

### Config Issues

**Configuration errors:**
```bash
# Validate YAML syntax
yarn backstage-cli config:check

# Check for undefined env vars
grep -r '\${[A-Z_]*}' app-config*.yaml
```

**Common causes:**
- Invalid YAML syntax
- Undefined environment variables
- Wrong config file being loaded
- Conflicting settings across config files

### Database Issues

**Connection failures:**
```bash
# Check PostgreSQL is running
pg_isready -h localhost -p 5432

# Check environment variables
echo $POSTGRES_HOST
echo $POSTGRES_USER

# Test connection
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d backstage -c "SELECT 1"
```

**Common causes:**
- PostgreSQL not running
- Wrong credentials
- Network/firewall blocking connection
- Database doesn't exist
- Missing pg client library

### Build Issues

**TypeScript errors:**
```bash
# Run type check
yarn tsc

# Check specific package
yarn workspace @internal/plugin-<name> tsc
```

**Common causes:**
- Missing type definitions
- Version mismatch between packages
- Circular imports
- Missing dependencies

### Startup Issues

**Application won't start:**
```bash
# Check for port conflicts
lsof -i :3000
lsof -i :7007

# Clear caches
rm -rf node_modules/.cache
rm -rf packages/*/dist

# Reinstall dependencies
yarn install
```

**Common causes:**
- Port already in use
- Missing dependencies
- Corrupted node_modules
- Invalid configuration
- Database not accessible

## Quick Checks

### General Health
```bash
# Check all services
yarn start

# Check backend only
yarn start:backend

# Check frontend only
yarn start:frontend
```

### Dependency Issues
```bash
# Check for version conflicts
yarn dedupe

# Update Backstage packages
yarn backstage-cli versions:bump
```

### Clean Slate
```bash
# Full reset
rm -rf node_modules
rm -rf packages/*/node_modules
rm -rf plugins/*/node_modules
yarn install
yarn tsc
yarn build
```

## Output

Provide:
1. Identified issue with file:line reference
2. Root cause explanation
3. Step-by-step fix commands
4. Prevention tips for future
