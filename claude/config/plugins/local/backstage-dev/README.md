# backstage-dev

Comprehensive Claude Code plugin for Backstage IDP development.

## Installation

This plugin is project-level and shared via git. It's automatically available when working in the `app/backstage` directory.

To test manually:
```bash
claude --plugin-dir app/backstage/.claude/plugins/backstage-dev
```

## Installation

```bash
claude plugin install /path/to/backstage-dev --scope project
```

## Slash Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/backstage-dev:plugin` | Scaffold new plugins | `/backstage-dev:plugin frontend my-plugin` |
| `/backstage-dev:template` | Create software templates | `/backstage-dev:template my-template --type=service` |
| `/backstage-dev:validate-template` | Validate template YAML | `/backstage-dev:validate-template` |
| `/backstage-dev:entity` | Generate catalog entities | `/backstage-dev:entity Component my-service` |
| `/backstage-dev:config` | Edit app-config | `/backstage-dev:config backend --env=production` |
| `/backstage-dev:debug` | Debug common issues | `/backstage-dev:debug catalog` |
| `/backstage-dev:build` | Build and deploy prep | `/backstage-dev:build --target=docker` |
| `/backstage-dev:customize-page` | Customize entity pages | `/backstage-dev:customize-page component --add-tab=metrics` |

## Skills (Auto-Triggered)

Skills provide context-aware assistance when you mention relevant topics:

| Skill | Triggers On |
|-------|-------------|
| `app-config` | "app-config", "configuration", "backend settings" |
| `catalog-info` | "catalog-info.yaml", "entity", "Component", "API" |
| `software-template` | "template", "scaffolder", "Create Component" |
| `entity-page` | "EntityPage", "entity tabs", "entity cards" |
| `backend-plugin` | "backend plugin", "packages/backend" |
| `proxy-config` | "proxy", "API proxy", "external API" |
| `techdocs` | "TechDocs", "documentation", "mkdocs" |

## Agents (Deep Analysis)

| Agent | Use Case |
|-------|----------|
| `backstage-plugin-reviewer` | Review plugin code for Backstage patterns |
| `template-validator` | Debug and validate software templates |
| `catalog-analyzer` | Analyze entity relationships and ownership |
| `config-auditor` | Audit configuration for security and completeness |
| `backstage-architect` | Design feature architectures |

Agents are invoked automatically based on context or explicitly:
```
Use the backstage-plugin-reviewer agent to review my changes
```

## Hooks

The plugin includes validation hooks that run after file modifications:

- **YAML Validation**: Checks template, catalog, and config files
- **Secret Detection**: Warns about hardcoded credentials
- **Syntax Hints**: Suggests fixes for common issues

## MCP Server (Backstage API Integration)

When Backstage is running, the MCP server provides live API access:

**Tools:**
- `catalog_list_entities` - List entities by kind/filter
- `catalog_get_entity` - Get entity by reference
- `catalog_get_entity_ancestry` - Get entity relationships
- `catalog_validate_entity` - Validate entity YAML
- `template_list` - List available templates
- `scaffolder_list_actions` - List scaffolder actions

**Configuration:**

Set `BACKSTAGE_URL` environment variable (default: `http://localhost:7007`):
```bash
export BACKSTAGE_URL=http://localhost:7007
```

## Directory Structure

```
backstage-dev/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/                  # Slash commands
│   ├── backstage-plugin.md
│   ├── template-create.md
│   ├── template-validate.md
│   ├── catalog-entity.md
│   ├── config-edit.md
│   ├── backstage-debug.md
│   ├── backstage-build.md
│   └── entity-page.md
├── agents/                    # Subagents
│   ├── backstage-plugin-reviewer.md
│   ├── template-validator.md
│   ├── catalog-analyzer.md
│   ├── config-auditor.md
│   └── backstage-architect.md
├── skills/                    # Context-aware skills
│   ├── app-config/SKILL.md
│   ├── catalog-info/SKILL.md
│   ├── software-template/SKILL.md
│   ├── entity-page/SKILL.md
│   ├── backend-plugin/SKILL.md
│   ├── proxy-config/SKILL.md
│   └── techdocs/SKILL.md
├── hooks/                     # Validation hooks
│   ├── hooks.json
│   └── validate_yaml.py
├── mcp/                       # MCP server
│   └── backstage-catalog-server.ts
├── .mcp.json                  # MCP configuration
└── README.md
```

## Examples

### Create a new backend plugin
```
/backstage-dev:plugin backend metrics-service
```

### Create a software template
```
/backstage-dev:template golang-grpc-service --type=service
```

### Generate a catalog entity
```
/backstage-dev:entity API orders-api --system=commerce
```

### Debug catalog issues
```
/backstage-dev:debug catalog
```

### Review plugin code
```
Use the backstage-plugin-reviewer agent to check my plugin
```

### Analyze catalog structure
```
Use the catalog-analyzer agent to map our entity relationships
```

## Requirements

- Python 3 (for hooks)
- Node.js 20+ (for MCP server)
- Backstage running locally (for MCP server features)

## Contributing

This plugin is maintained as part of the Backstage deployment. Modifications should be committed to git for team sharing.
