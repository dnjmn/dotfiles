#!/bin/bash
# install/docker.sh - Docker container runtime

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="docker"

check_installed() {
    command -v docker &>/dev/null || [[ -d "/Applications/Docker.app" ]]
}

install_docker() {
    if check_installed; then
        print_ok "Docker already installed"
        return
    fi

    ensure_homebrew
    if is_macos; then
        pkg_install_cask docker || {
            print_warn "Cask install failed, download from https://docker.com/products/docker-desktop"
        }
    else
        # Linux: Install CLI tools via brew, daemon separately
        pkg_install docker docker-compose
        print_warn "Docker daemon: curl -fsSL https://get.docker.com | sh"
    fi
}

install_compose() {
    if command -v docker-compose &>/dev/null || docker compose version &>/dev/null 2>&1; then
        print_ok "docker-compose available"
        return
    fi
    pkg_install docker-compose 2>/dev/null || true
}

post_install() {
    echo ""
    print_info "Docker setup complete!"
    if is_macos; then
        echo "  Launch Docker Desktop from Applications"
    else
        echo "  Start daemon: sudo systemctl start docker"
    fi
    echo "  Verify: docker run hello-world"
}

main() {
    echo "==> Installing $NAME"
    install_docker
    install_compose
    post_install
    echo "==> Done"
}

main "$@"
