---
name: plugin-patterns
description: This skill should be used when the user asks about "Greptile", "Notion commands", "Context7", "Playwright", "MCP tools", "cross-repo search", "documentation lookup", mentions plugin workflows, or needs guidance on using Claude Code plugins for specific tasks.
version: 1.0.0
---

# Plugin Workflow Patterns

## Greptile (Codebase AI)
**Use for:** cross-repo search, dependency analysis, finding patterns, PR insights

**Tools:**
- `list_merge_requests` → PRs by repo/branch/author
- `search_greptile_comments` → find review patterns
- `get_merge_request` → PR details + addressed comments

## Context7 (Documentation Lookup)
**Use BEFORE:** unfamiliar libraries, upgrades, API integrations
**Use WHEN:** learning new tools, checking breaking changes

Workflow:
1. Identify library/version
2. Fetch version-specific docs
3. Cross-reference with codebase usage

## Notion (Knowledge Management)
**Commands:**
- `/Notion:notion-create-page` → document solutions
- `/Notion:notion-create-task` → track work
- `/Notion:notion-search` → find docs
- `/Notion:notion-database-query` → query data

**After solving complex problems:**
1. Document solution approach
2. Capture decision rationale
3. Note error patterns discovered

## Playwright (Browser Automation)
**Use for:** E2E testing, visual regression, form automation
**Trigger:** UI features, critical user flows

## Commit Workflow
- `/commit-commands:commit` → atomic commits
- `/commit-commands:commit-push-pr` → full PR workflow
