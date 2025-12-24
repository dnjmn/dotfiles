---
name: backend-plugin
description: This skill provides patterns for creating and integrating Backstage backend plugins. Use when the user mentions "backend plugin", "packages/backend", "backend.add", "createBackendPlugin", or asks about backend services.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Backend Plugin Development

Expert patterns for Backstage backend plugins (New Backend System).

## Plugin Registration

**packages/backend/src/index.ts:**
```typescript
import { createBackend } from '@backstage/backend-defaults';

const backend = createBackend();

// Core plugins
backend.add(import('@backstage/plugin-app-backend'));
backend.add(import('@backstage/plugin-catalog-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend'));
backend.add(import('@backstage/plugin-techdocs-backend'));
backend.add(import('@backstage/plugin-auth-backend'));
backend.add(import('@backstage/plugin-search-backend'));

// Custom plugins
backend.add(import('@internal/plugin-my-plugin-backend'));

backend.start();
```

## Creating a Backend Plugin

### Plugin Structure
```
plugins/my-plugin-backend/
├── src/
│   ├── plugin.ts           # Plugin definition
│   ├── service/
│   │   └── router.ts       # HTTP routes
│   └── index.ts            # Exports
├── package.json
└── catalog-info.yaml
```

### Plugin Definition

**plugins/my-plugin-backend/src/plugin.ts:**
```typescript
import {
  coreServices,
  createBackendPlugin,
} from '@backstage/backend-plugin-api';
import { createRouter } from './service/router';

export const myPlugin = createBackendPlugin({
  pluginId: 'my-plugin',
  register(env) {
    env.registerInit({
      deps: {
        logger: coreServices.logger,
        httpRouter: coreServices.httpRouter,
        config: coreServices.rootConfig,
        database: coreServices.database,
        auth: coreServices.auth,
        httpAuth: coreServices.httpAuth,
      },
      async init({ logger, httpRouter, config, database, auth, httpAuth }) {
        logger.info('Initializing my-plugin backend');

        const router = await createRouter({
          logger,
          config,
          database,
          auth,
          httpAuth,
        });

        httpRouter.use(router);

        // Allow unauthenticated access to health endpoint
        httpRouter.addAuthPolicy({
          path: '/health',
          allow: 'unauthenticated',
        });
      },
    });
  },
});

export default myPlugin;
```

### Router Implementation

**plugins/my-plugin-backend/src/service/router.ts:**
```typescript
import { Router } from 'express';
import { Logger } from 'winston';
import {
  AuthService,
  HttpAuthService,
  DatabaseService,
} from '@backstage/backend-plugin-api';
import { Config } from '@backstage/config';

export interface RouterOptions {
  logger: Logger;
  config: Config;
  database: DatabaseService;
  auth: AuthService;
  httpAuth: HttpAuthService;
}

export async function createRouter(
  options: RouterOptions,
): Promise<Router> {
  const { logger, config, database, httpAuth } = options;
  const router = Router();

  // Health check (unauthenticated)
  router.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  // Authenticated endpoint
  router.get('/data', async (req, res) => {
    // Verify credentials
    const credentials = await httpAuth.credentials(req, {
      allow: ['user'],
    });

    const userEntityRef = credentials.principal.userEntityRef;
    logger.info(`Request from user: ${userEntityRef}`);

    // Your business logic here
    const data = await fetchData();

    res.json({ data, user: userEntityRef });
  });

  // POST with body parsing
  router.post('/items', async (req, res) => {
    const credentials = await httpAuth.credentials(req, {
      allow: ['user'],
    });

    const { name, description } = req.body;

    // Validate input
    if (!name) {
      res.status(400).json({ error: 'Name is required' });
      return;
    }

    // Create item
    const item = await createItem({ name, description });

    res.status(201).json(item);
  });

  return router;
}

async function fetchData() {
  // Implementation
  return { items: [] };
}

async function createItem(input: { name: string; description?: string }) {
  // Implementation
  return { id: '1', ...input };
}
```

### Package.json

**plugins/my-plugin-backend/package.json:**
```json
{
  "name": "@internal/plugin-my-plugin-backend",
  "version": "0.1.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "license": "Apache-2.0",
  "backstage": {
    "role": "backend-plugin",
    "pluginId": "my-plugin",
    "pluginPackages": [
      "@internal/plugin-my-plugin-backend"
    ]
  },
  "scripts": {
    "build": "backstage-cli package build",
    "lint": "backstage-cli package lint",
    "test": "backstage-cli package test",
    "clean": "backstage-cli package clean"
  },
  "dependencies": {
    "@backstage/backend-plugin-api": "^1.0.0",
    "@backstage/config": "^1.0.0",
    "express": "^4.18.0",
    "winston": "^3.0.0"
  },
  "devDependencies": {
    "@backstage/cli": "^0.27.0"
  }
}
```

### Index Export

**plugins/my-plugin-backend/src/index.ts:**
```typescript
export { myPlugin as default } from './plugin';
```

## Core Services

### Logger
```typescript
deps: {
  logger: coreServices.logger,
},
async init({ logger }) {
  logger.info('Plugin initialized');
  logger.warn('Warning message');
  logger.error('Error message', { error: err });
  logger.debug('Debug info', { data });
}
```

### Config
```typescript
deps: {
  config: coreServices.rootConfig,
},
async init({ config }) {
  const apiKey = config.getString('myPlugin.apiKey');
  const timeout = config.getOptionalNumber('myPlugin.timeout') ?? 5000;
  const enabled = config.getBoolean('myPlugin.enabled');
}
```

### Database
```typescript
deps: {
  database: coreServices.database,
},
async init({ database }) {
  const client = await database.getClient();

  // Run migrations
  if (!database.migrations?.skip) {
    await client.migrate.latest({
      directory: migrationsDir,
    });
  }

  // Query
  const items = await client('items').select('*');
}
```

### Auth & HttpAuth
```typescript
deps: {
  auth: coreServices.auth,
  httpAuth: coreServices.httpAuth,
},
async init({ auth, httpAuth }) {
  // In route handler
  router.get('/data', async (req, res) => {
    const credentials = await httpAuth.credentials(req, {
      allow: ['user', 'service'],
    });

    // Get user identity
    const userEntityRef = credentials.principal.userEntityRef;

    // Issue token for service-to-service calls
    const { token } = await auth.getPluginRequestToken({
      onBehalfOf: credentials,
      targetPluginId: 'catalog',
    });
  });
}
```

### Cache
```typescript
deps: {
  cache: coreServices.cache,
},
async init({ cache }) {
  const cacheClient = await cache.getClient();

  // Set with TTL
  await cacheClient.set('key', 'value', { ttl: 3600 });

  // Get
  const value = await cacheClient.get('key');

  // Delete
  await cacheClient.delete('key');
}
```

### Scheduler
```typescript
deps: {
  scheduler: coreServices.scheduler,
},
async init({ scheduler }) {
  await scheduler.scheduleTask({
    id: 'my-task',
    frequency: { minutes: 30 },
    timeout: { minutes: 10 },
    fn: async () => {
      // Task logic
    },
  });
}
```

## Extension Points

### Defining Extension Point
```typescript
import { createExtensionPoint } from '@backstage/backend-plugin-api';

export interface MyPluginApi {
  registerHandler(handler: Handler): void;
}

export const myPluginExtensionPoint = createExtensionPoint<MyPluginApi>({
  id: 'my-plugin',
});
```

### Exposing Extension Point
```typescript
export const myPlugin = createBackendPlugin({
  pluginId: 'my-plugin',
  register(env) {
    const handlers: Handler[] = [];

    env.registerExtensionPoint(myPluginExtensionPoint, {
      registerHandler(handler) {
        handlers.push(handler);
      },
    });

    env.registerInit({
      // Use handlers in init
    });
  },
});
```

### Creating a Module
```typescript
import { createBackendModule } from '@backstage/backend-plugin-api';
import { myPluginExtensionPoint } from '@internal/plugin-my-plugin-backend';

export const myPluginCustomModule = createBackendModule({
  pluginId: 'my-plugin',
  moduleId: 'custom-handler',
  register(env) {
    env.registerInit({
      deps: {
        myPlugin: myPluginExtensionPoint,
      },
      async init({ myPlugin }) {
        myPlugin.registerHandler(myCustomHandler);
      },
    });
  },
});
```

## Best Practices

1. **Use dependency injection**: Leverage coreServices
2. **Handle auth properly**: Use httpAuth.credentials()
3. **Validate input**: Check request body/params
4. **Log appropriately**: Info for important events, debug for details
5. **Return proper status codes**: 200, 201, 400, 401, 404, 500
6. **Use extension points**: For customization without modification
