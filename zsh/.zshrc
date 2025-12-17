# .zshrc - Modular Zsh Configuration Loader
# All configs split into config/, aliases/, functions/
# Source order: config -> aliases -> functions

# === P10K INSTANT PROMPT (MUST BE FIRST) ===
if [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# === CONFIGURATION ROOT ===
ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}"

# === SOURCE HELPER ===
_source_config() {
  [[ -f "$1" ]] && source "$1"
}

# === LOAD MODULES ===
# Order: config -> aliases -> functions
for f in "$ZSH_CONFIG_DIR"/config/*.zsh(N); do _source_config "$f"; done
for f in "$ZSH_CONFIG_DIR"/aliases/*.zsh(N); do _source_config "$f"; done
for f in "$ZSH_CONFIG_DIR"/functions/*.zsh(N); do _source_config "$f"; done

# === P10K CONFIGURATION ===
[[ -f "$ZDOTDIR/.p10k.zsh" ]] && source "$ZDOTDIR/.p10k.zsh"

# === LOCAL OVERRIDES (not version controlled) ===
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

