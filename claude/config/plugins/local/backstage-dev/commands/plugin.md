---
description: Scaffold a new Backstage plugin (frontend, backend, or full-stack)
argument-hint: <type> <name>
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep]
---

# Backstage Plugin Scaffolder

Create new Backstage plugins with proper structure and integration.

## Arguments

$ARGUMENTS

**Supported types:**
- `frontend` - React frontend plugin with routes and components
- `backend` - Node.js backend plugin with HTTP router
- `full` - Both frontend and backend plugins

## Process

### 1. Parse Arguments
Extract plugin type and name from: $ARGUMENTS
- Validate plugin name is kebab-case
- Check for naming conflicts in plugins/ directory

### 2. Scaffold Plugin
Run in `app/backstage/` directory:
```bash
yarn new
```
Select appropriate options based on type argument.

### 3. Frontend Plugin Integration
For frontend/full types, update `packages/app/src/App.tsx`:

```tsx
// Add import
import { <PluginName>Page } from '@internal/plugin-<name>';

// Add route in FlatRoutes
<Route path="/<name>" element={<<PluginName>Page />} />
```

### 4. Backend Plugin Integration
For backend/full types, update `packages/backend/src/index.ts`:

```typescript
// Add plugin registration
backend.add(import('@internal/plugin-<name>-backend'));
```

### 5. Create Catalog Entry
Generate `plugins/<name>/catalog-info.yaml`:
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: plugin-<name>
  description: Backstage plugin for <description>
  annotations:
    backstage.io/techdocs-ref: dir:.
spec:
  type: library
  lifecycle: experimental
  owner: platform-team
```

## Output

Provide:
1. List of files created/modified
2. Plugin directory location
3. Next steps for development
4. Example component/route code

## Plugin Structure Reference

**Frontend Plugin:**
```
plugins/<name>/
├── src/
│   ├── components/
│   │   └── ExampleComponent/
│   ├── plugin.ts        # createPlugin()
│   ├── routes.ts        # Route refs
│   └── index.ts
├── dev/
│   └── index.tsx        # Dev server
├── package.json         # backstage.role: "frontend-plugin"
└── catalog-info.yaml
```

**Backend Plugin:**
```
plugins/<name>-backend/
├── src/
│   ├── service/
│   │   └── router.ts    # Express router
│   ├── plugin.ts        # createBackendPlugin()
│   └── index.ts
├── package.json         # backstage.role: "backend-plugin"
└── catalog-info.yaml
```
