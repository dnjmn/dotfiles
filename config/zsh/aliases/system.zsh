# System Package Manager Aliases - Cross-Platform
# Auto-detects brew (macOS/Linux) vs apt (Linux fallback)

if command -v brew &>/dev/null; then
  # Homebrew (macOS or Linuxbrew)
  alias update="brew update && brew upgrade"
  alias install="brew install"
  alias remove="brew uninstall"
  alias search="brew search"
  alias cleanup="brew cleanup && brew autoremove"
  alias outdated="brew outdated"
elif command -v apt &>/dev/null; then
  # Debian/Ubuntu apt
  alias update="sudo apt update && sudo apt upgrade -y"
  alias install="sudo apt install"
  alias remove="sudo apt remove"
  alias search="apt search"
  alias cleanup="sudo apt autoremove && sudo apt autoclean"
  alias outdated="apt list --upgradable"
elif command -v dnf &>/dev/null; then
  # Fedora/RHEL dnf
  alias update="sudo dnf upgrade -y"
  alias install="sudo dnf install"
  alias remove="sudo dnf remove"
  alias search="dnf search"
  alias cleanup="sudo dnf autoremove"
fi
