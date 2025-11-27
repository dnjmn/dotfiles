# Zsh Shell Setup

## Overview
Zsh (Z Shell) is a powerful shell with advanced features, configured here with Oh My Zsh framework, Powerlevel10k theme, and productivity plugins. This setup follows XDG Base Directory specification to keep the home directory clean.

**Installation Date:** 2025-11-07
**Framework:** Oh My Zsh
**Theme:** Powerlevel10k
**XDG Compliant:** Yes

## What Was Installed

### 1. Zsh Shell
- **Installation method:** APT package manager
- **Default shell:** Set as login shell

### 2. Oh My Zsh Framework
- **Location:** `~/.local/share/oh-my-zsh` (XDG_DATA_HOME)
- **Purpose:** Plugin and theme management framework
- **Official site:** https://ohmyz.sh

### 3. Powerlevel10k Theme
- **Location:** `~/.local/share/oh-my-zsh/custom/themes/powerlevel10k`
- **Features:**
  - Fast rendering with instant prompt
  - Git status integration
  - Command execution time
  - Exit code indicators
  - Highly customizable

### 4. Productivity Plugins

**Essential Plugins:**
- **zsh-autosuggestions** - Suggests commands as you type based on history
- **zsh-syntax-highlighting** - Real-time syntax highlighting (green=valid, red=invalid)
- **zsh-completions** - Additional completion definitions

**Navigation:**
- **z** - Jump to frequently used directories
- **fzf** - Fuzzy finder for files, history, and more

**Git Integration:**
- **git** - Aliases and functions for git commands

**Utilities:**
- **command-not-found** - Suggests package installation for unknown commands
- **sudo** - Press ESC twice to add sudo to the previous command
- **extract** - Universal archive extraction
- **colored-man-pages** - Colorized man pages

### 5. Additional Tools
- **fzf** - Fuzzy finder (Ctrl+R for history, Ctrl+T for files)
- **fd** - Fast alternative to find
- **bat** - Cat clone with syntax highlighting
- **tree** - Directory tree visualization

## XDG Directory Structure

This setup follows the XDG Base Directory specification to avoid cluttering the home directory:

```
~/
├── .zshenv                                    # ONLY zsh file in home (sets ZDOTDIR)
├── .config/
│   ├── zsh/                                   # XDG_CONFIG_HOME
│   │   └── env.zsh                            # Secret environment variables (not version controlled)
│   └── kube/
│       └── config.yaml                        # Kubernetes config (XDG compliant location)
├── .local/
│   ├── share/oh-my-zsh/                       # XDG_DATA_HOME - Oh My Zsh installation
│   │   ├── oh-my-zsh.sh
│   │   ├── custom/
│   │   │   ├── themes/powerlevel10k/
│   │   │   └── plugins/
│   │   │       ├── zsh-autosuggestions/
│   │   │       ├── zsh-syntax-highlighting/
│   │   │       └── zsh-completions/
│   │   └── plugins/
│   └── state/zsh/                             # XDG_STATE_HOME
│       └── history                            # Command history
├── .cache/
│   ├── zsh/                                   # XDG_CACHE_HOME
│   │   └── zcompdump-*                        # Completion cache
│   └── oh-my-zsh/                             # Oh My Zsh cache
└── Developer/repos/dnjmn/dotfiles/zsh/    # ZDOTDIR (version controlled)
    ├── .zshrc                                 # Main configuration
    ├── .zshenv                                # Environment variables
    ├── .p10k.zsh                              # Powerlevel10k config (created on first run)
    ├── install.sh                             # Installation script
    ├── home-zshenv                            # Template for ~/.zshenv
    └── xdg-env-template.zsh                   # Template for secret env vars
```

## Key Features

### Auto-suggestions
- Suggests commands based on history as you type
- Accept with `Ctrl+Space` or `End` key
- Grayed out text shows the suggestion

### Syntax Highlighting
- Commands turn **green** if valid
- Commands turn **red** if invalid
- Helps catch typos before running commands

### Smart Completion
- Tab completion for commands, files, and arguments
- Case-insensitive matching
- Menu selection for multiple matches
- Cached for better performance

### Directory Navigation
```bash
# Jump to frequently used directories
z dotfiles          # Jump to dotfiles directory
z repos             # Jump to repos directory

# Quick navigation aliases
..                  # cd ..
...                 # cd ../..
....                # cd ../../..
~                   # cd ~
-                   # cd to previous directory
```

### Fuzzy Finding (fzf)
- `Ctrl+R` - Search command history
- `Ctrl+T` - Find files in current directory
- `Alt+C` - Change to a directory

### Git Integration
```bash
# Git aliases (in addition to Oh My Zsh)
gs                  # git status
ga                  # git add
gc                  # git commit
gp                  # git push
gl                  # git pull
gd                  # git diff
gco                 # git checkout
gb                  # git branch
glog                # git log --oneline --graph --decorate --all

# Quick commit functions
qc "message"        # git add -A && git commit -m "message"
qp "message"        # git add -A && git commit && git push
```

## Configuration Files

### Main Configuration: `ZDOTDIR/.zshrc`
Located at: `~/Developer/repos/dnjmn/dotfiles/zsh/.zshrc`

**Key Sections:**
1. **Oh My Zsh Configuration** - Theme and update settings
2. **Plugins** - Enabled plugins list
3. **User Configuration** - Editor, language
4. **Aliases** - Command shortcuts
5. **FZF Configuration** - Fuzzy finder settings
6. **Custom Functions** - Helper functions
7. **Path Configuration** - PATH modifications
8. **Powerlevel10k** - Theme settings

### Environment Variables: `ZDOTDIR/.zshenv`
Located at: `~/Developer/repos/dnjmn/dotfiles/zsh/.zshenv`

**Sets up:**
- XDG Base Directories
- Application-specific XDG paths
- Oh My Zsh directories
- History and cache locations

### Secret Variables: `~/.config/zsh/env.zsh`
**Use this file for:**
- API keys and tokens (e.g., Bitbucket, GitHub, OpenAI)
- Machine-specific environment variables
- Secrets that shouldn't be version controlled

**Currently contains:**
- `BITBUCKET_PULSE_TOKEN` - Bitbucket personal access token

**This file is NOT in the repository!**

## Essential Keyboard Shortcuts

### Command Line Editing
- `Ctrl+A` - Move to beginning of line
- `Ctrl+E` - Move to end of line
- `Ctrl+U` - Delete from cursor to beginning
- `Ctrl+K` - Delete from cursor to end
- `Ctrl+W` - Delete word before cursor
- `Alt+Backspace` - Delete word before cursor

### History
- `Ctrl+R` - Search history (fzf interface)
- `Up/Down` - Navigate history
- `Ctrl+P/N` - Previous/Next in history

### Auto-suggestions
- `Ctrl+Space` - Accept suggestion
- `End` - Accept suggestion
- `→` - Accept suggestion

### Fuzzy Finder (fzf)
- `Ctrl+R` - Search command history
- `Ctrl+T` - Find and insert file path
- `Alt+C` - cd into directory

### Special
- `ESC ESC` - Add sudo to previous command
- `Ctrl+L` - Clear screen
- `Ctrl+D` - Exit shell

## Common Aliases

### Navigation
```bash
..                  # cd ..
...                 # cd ../..
dev                 # cd ~/Developer
repos               # cd ~/Developer/repos
dotfiles            # cd ~/Developer/repos/dnjmn/dotfiles
```

### Configuration
```bash
zshconfig           # Edit .zshrc
zshenv              # Edit .zshenv
zshenvsecret        # Edit secret env file
zshreload           # Reload zsh configuration
```

### System
```bash
update              # sudo apt update && sudo apt upgrade -y
install             # sudo apt install
remove              # sudo apt remove
cleanup             # sudo apt autoremove && sudo apt autoclean
```

### Kubernetes
```bash
k                   # kubectl --context kind-llmariner-demo
kgp                 # Get pods
kgs                 # Get services
kgd                 # Get deployments
kl                  # Logs
ke                  # Exec into pod
```

### Docker
```bash
d                   # docker
dc                  # docker compose
dps                 # docker ps
di                  # docker images
dprune              # docker system prune -af
```

### Utilities
```bash
ll                  # ls -lh
la                  # ls -lha
lt                  # ls -lhtr (sorted by time)
weather             # curl wttr.in
myip                # curl ifconfig.me
ports               # netstat -tulanp
```

## Custom Functions

### mkcd
Create directory and cd into it:
```bash
mkcd new-project
```

### extract
Universal archive extraction:
```bash
extract file.tar.gz
extract file.zip
```

### f
Quick find:
```bash
f "*.js"            # Find all JavaScript files
```

## Powerlevel10k Configuration

### Initial Setup
On first launch, Powerlevel10k configuration wizard will run:
1. Answer questions about your terminal capabilities
2. Choose your preferred prompt style
3. Configuration saved to `ZDOTDIR/.p10k.zsh`

### Reconfigure
Run the configuration wizard again:
```bash
p10k configure
```

### Key Features
- Git status indicators
- Command execution time
- Exit code indicators
- Current directory (shortened)
- Time display
- Customizable segments

## How to Use

### Installation
```bash
cd ~/Developer/repos/dnjmn/dotfiles/zsh
./install.sh
```

### Post-Installation
1. Log out and log back in (or run `exec zsh`)
2. Complete Powerlevel10k setup wizard
3. Add secrets to `~/.config/zsh/env.zsh`

### Customization
1. Edit configuration: `zshconfig` or edit `ZDOTDIR/.zshrc`
2. Edit environment variables: `zshenv` or edit `ZDOTDIR/.zshenv`
3. Edit secrets: `zshenvsecret` or edit `~/.config/zsh/env.zsh`
4. Reload configuration: `zshreload` or `source ~/.zshrc`

## Troubleshooting

### Powerlevel10k Not Loading
```bash
# Check if theme is installed
ls $ZSH_CUSTOM/themes/powerlevel10k

# Reconfigure
p10k configure
```

### Plugins Not Working
```bash
# Check if plugins are installed
ls $ZSH_CUSTOM/plugins/

# Verify plugin is in .zshrc plugins array
grep plugins $ZDOTDIR/.zshrc
```

### Slow Startup
```bash
# Profile zsh startup
zsh -xv 2>&1 | ts -i '%.s' > /tmp/zsh-profile.log

# Check for slow plugins or commands
# Consider disabling heavy plugins or using lazy loading
```

### Completion Not Working
```bash
# Rebuild completion cache
rm -f $XDG_CACHE_HOME/zsh/zcompdump*
compinit
```

### History Not Saving
```bash
# Check history file location
echo $HISTFILE

# Ensure directory exists
mkdir -p $(dirname $HISTFILE)
```

## Migration from Bash

### Importing Bash History
```bash
# If you have bash history to import
cat ~/.bash_history >> $HISTFILE
```

### Bash Compatibility
Most bash scripts and commands work in zsh. For bash-specific scripts:
```bash
# Run with bash explicitly
bash script.sh

# Or add shebang to script
#!/bin/bash
```

## Advanced Features

### Local Overrides
Create `ZDOTDIR/local.zsh` for machine-specific customizations not in version control:
```bash
# Example: ZDOTDIR/local.zsh
export CUSTOM_PATH="/opt/custom/bin"
alias myalias="custom command"
```

### Plugin Management
Add new plugins by cloning to `$ZSH_CUSTOM/plugins/` and adding to `.zshrc`:
```bash
git clone https://github.com/user/plugin $ZSH_CUSTOM/plugins/plugin-name

# Then edit .zshrc and add 'plugin-name' to plugins array
```

## Resources

- [Zsh Official Documentation](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)

## Recent Configuration Changes

**2025-11-11 Environment Variables Migration:**
- Migrated all environment variables from `~/.bashrc` to zsh configuration
- **Kubernetes config moved to XDG:** `~/.kube/config.yaml` → `~/.config/kube/config.yaml`
- **KUBECONFIG:** Updated to `$XDG_CONFIG_HOME/kube/config.yaml` (zsh/.zshenv:43)
- **PATH additions in .zshenv:**
  - Homebrew initialization from `/home/linuxbrew/.linuxbrew/bin/brew` (zsh/.zshenv:57-60)
  - Go: `/usr/local/go/bin` and `$GOPATH/bin` with `GOPATH=$HOME/go` (zsh/.zshenv:62-64)
  - Neovim: `$HOME/Downloads/nvim-linux-x86_64/bin` (zsh/.zshenv:66-67)
  - Cargo (Rust): Sourced from `$HOME/.cargo/env` if exists (zsh/.zshenv:69-72)
  - Local bin: `$HOME/.local/bin` (zsh/.zshenv:74-75)
- **Secrets added to ~/.config/zsh/env.zsh:**
  - `BITBUCKET_PULSE_TOKEN` (not in repo, XDG compliant location)

**2025-11-11 Auto-correction Disabled:**
- Disabled command auto-correction (zsh/.zshrc:24)
- Prevents annoying "correct 'command' to '.command'" prompts

**2025-11-11 PATH Update:**
- Added `~/.npm-global/bin` to PATH (zsh/.zshrc:267-270)
- Fixes issue where NPM global binaries (like `claude`) were not accessible in new terminal sessions
- PATH now includes: `~/.local/bin`, `~/bin`, and `~/.npm-global/bin`

**2025-11-07 Initial Setup:**
- Implemented XDG Base Directory specification
- ZDOTDIR set to repository location (~/Developer/repos/dnjmn/dotfiles/zsh)
- Oh My Zsh installed to XDG_DATA_HOME (~/.local/share/oh-my-zsh)
- Only ~/.zshenv in home directory (minimal footprint)
- Secret environment variables in ~/.config/zsh/env.zsh
- Configured Powerlevel10k theme
- Enabled essential plugins: autosuggestions, syntax-highlighting, completions
- Added navigation plugins: z, fzf
- Configured git integration and aliases
- Added Kubernetes and Docker aliases
- Installed additional tools: fd, bat, tree

---

*Last updated: 2025-11-11*
