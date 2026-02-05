#!/usr/bin/env npx tsx
/**
 * Backstage Catalog MCP Server
 *
 * Provides tools for interacting with the Backstage Catalog API:
 * - List entities by kind/filter
 * - Get entity details
 * - Validate entity YAML
 * - List templates
 * - Dry-run templates
 *
 * Usage:
 *   npx tsx backstage-catalog-server.ts
 *
 * Environment:
 *   BACKSTAGE_URL - Base URL of Backstage instance (default: http://localhost:7007)
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';

const BACKSTAGE_URL = process.env.BACKSTAGE_URL || 'http://localhost:7007';

// Tool definitions
const tools: Tool[] = [
  {
    name: 'catalog_list_entities',
    description: 'List entities from the Backstage catalog with optional filtering by kind, namespace, or filter expression',
    inputSchema: {
      type: 'object',
      properties: {
        kind: {
          type: 'string',
          description: 'Entity kind to filter by (e.g., Component, API, System)',
        },
        namespace: {
          type: 'string',
          description: 'Namespace to filter by (default: default)',
        },
        filter: {
          type: 'string',
          description: 'Filter expression (e.g., "spec.type=service")',
        },
        limit: {
          type: 'number',
          description: 'Maximum number of entities to return (default: 50)',
        },
      },
    },
  },
  {
    name: 'catalog_get_entity',
    description: 'Get a specific entity by its reference (kind:namespace/name)',
    inputSchema: {
      type: 'object',
      properties: {
        entityRef: {
          type: 'string',
          description: 'Entity reference (e.g., component:default/my-service)',
        },
      },
      required: ['entityRef'],
    },
  },
  {
    name: 'catalog_get_entity_ancestry',
    description: 'Get the ancestry (parent chain) of an entity',
    inputSchema: {
      type: 'object',
      properties: {
        entityRef: {
          type: 'string',
          description: 'Entity reference (e.g., component:default/my-service)',
        },
      },
      required: ['entityRef'],
    },
  },
  {
    name: 'catalog_validate_entity',
    description: 'Validate an entity YAML against the catalog schema',
    inputSchema: {
      type: 'object',
      properties: {
        entityYaml: {
          type: 'string',
          description: 'YAML content of the entity to validate',
        },
        location: {
          type: 'string',
          description: 'Optional source location hint',
        },
      },
      required: ['entityYaml'],
    },
  },
  {
    name: 'template_list',
    description: 'List available Software Templates in the catalog',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'template_get',
    description: 'Get details of a specific template',
    inputSchema: {
      type: 'object',
      properties: {
        templateRef: {
          type: 'string',
          description: 'Template reference (e.g., template:default/my-template)',
        },
      },
      required: ['templateRef'],
    },
  },
  {
    name: 'scaffolder_list_actions',
    description: 'List available scaffolder actions',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
];

// API client functions
async function fetchFromBackstage(path: string, options: RequestInit = {}): Promise<any> {
  const url = `${BACKSTAGE_URL}${path}`;

  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Backstage API error: ${response.status} - ${text}`);
    }

    return response.json();
  } catch (error) {
    if (error instanceof Error) {
      if (error.message.includes('ECONNREFUSED')) {
        throw new Error(`Cannot connect to Backstage at ${BACKSTAGE_URL}. Is it running?`);
      }
      throw error;
    }
    throw new Error('Unknown error occurred');
  }
}

async function listEntities(args: {
  kind?: string;
  namespace?: string;
  filter?: string;
  limit?: number;
}): Promise<any> {
  const params = new URLSearchParams();

  if (args.kind) {
    params.append('filter', `kind=${args.kind}`);
  }
  if (args.namespace) {
    params.append('filter', `metadata.namespace=${args.namespace}`);
  }
  if (args.filter) {
    params.append('filter', args.filter);
  }
  if (args.limit) {
    params.append('limit', args.limit.toString());
  }

  const queryString = params.toString();
  const path = `/api/catalog/entities${queryString ? `?${queryString}` : ''}`;

  return fetchFromBackstage(path);
}

async function getEntity(entityRef: string): Promise<any> {
  // Parse entity ref: kind:namespace/name
  const match = entityRef.match(/^(?:([^:]+):)?(?:([^/]+)\/)?(.+)$/);
  if (!match) {
    throw new Error(`Invalid entity reference: ${entityRef}`);
  }

  const kind = match[1] || 'component';
  const namespace = match[2] || 'default';
  const name = match[3];

  const path = `/api/catalog/entities/by-name/${kind}/${namespace}/${name}`;
  return fetchFromBackstage(path);
}

async function getEntityAncestry(entityRef: string): Promise<any> {
  const path = `/api/catalog/entities/by-refs/ancestry`;
  return fetchFromBackstage(path, {
    method: 'POST',
    body: JSON.stringify({ entityRefs: [entityRef] }),
  });
}

async function validateEntity(entityYaml: string, location?: string): Promise<any> {
  const path = '/api/catalog/validate-entity';
  return fetchFromBackstage(path, {
    method: 'POST',
    body: JSON.stringify({
      entity: entityYaml,
      location: location || 'url:stdin',
    }),
  });
}

async function listTemplates(): Promise<any> {
  return listEntities({ kind: 'Template' });
}

async function getTemplate(templateRef: string): Promise<any> {
  return getEntity(templateRef);
}

async function listScaffolderActions(): Promise<any> {
  const path = '/api/scaffolder/v2/actions';
  return fetchFromBackstage(path);
}

// Tool handler
async function handleToolCall(name: string, args: Record<string, unknown>): Promise<string> {
  try {
    let result: any;

    switch (name) {
      case 'catalog_list_entities':
        result = await listEntities(args as any);
        break;
      case 'catalog_get_entity':
        result = await getEntity(args.entityRef as string);
        break;
      case 'catalog_get_entity_ancestry':
        result = await getEntityAncestry(args.entityRef as string);
        break;
      case 'catalog_validate_entity':
        result = await validateEntity(args.entityYaml as string, args.location as string);
        break;
      case 'template_list':
        result = await listTemplates();
        break;
      case 'template_get':
        result = await getTemplate(args.templateRef as string);
        break;
      case 'scaffolder_list_actions':
        result = await listScaffolderActions();
        break;
      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return JSON.stringify(result, null, 2);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return JSON.stringify({ error: message });
  }
}

// Server setup
async function main() {
  const server = new Server(
    {
      name: 'backstage-catalog',
      version: '1.0.0',
    },
    {
      capabilities: {
        tools: {},
      },
    }
  );

  // List tools handler
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return { tools };
  });

  // Call tool handler
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    const result = await handleToolCall(name, args || {});

    return {
      content: [
        {
          type: 'text',
          text: result,
        },
      ],
    };
  });

  // Start server
  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error(`Backstage MCP Server started. Connecting to ${BACKSTAGE_URL}`);
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
