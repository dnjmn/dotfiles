# Obsidian Setup

**Installed**: 2025-11-26 | **Method**: AppImage

## Quick Install

```bash
./obsidian/install.sh
```

## Config Locations

| Type | Path |
|------|------|
| AppImage | `~/.local/share/obsidian/Obsidian.AppImage` |
| Config | `~/.config/obsidian/` |
| Desktop Entry | `~/.local/share/applications/obsidian.desktop` |
| Vaults | User-defined (recommend `~/Documents/Obsidian/`) |

## Key Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+N` | New note |
| `Ctrl+O` | Open quick switcher |
| `Ctrl+P` | Command palette |
| `Ctrl+E` | Toggle edit/preview |
| `Ctrl+G` | Open graph view |
| `Ctrl+,` | Settings |
| `Ctrl+Shift+F` | Search all files |
| `[[` | Link to note |
| `![[` | Embed note/image |

## Recommended Plugins

### Community Plugins
- **Templater** - Advanced templates
- **Dataview** - Query notes like a database
- **Obsidian Git** - Auto backup to git
- **Calendar** - Daily notes calendar
- **Kanban** - Project boards

### Core Plugins (enable in Settings)
- Daily notes
- Templates
- Backlinks
- Graph view
- Outline

## Sync Options

| Method | Notes |
|--------|-------|
| Git | Free, use Obsidian Git plugin |
| Syncthing | Free, P2P sync |
| Obsidian Sync | Paid ($8/mo), official |

## Update

Re-run the installer to update:

```bash
./obsidian/install.sh
```

Or force reinstall:

```bash
./obsidian/install.sh --force
```

## Changelog

| Date | Change |
|------|--------|
| 2025-11-26 | Initial automated setup |
