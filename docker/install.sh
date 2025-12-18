#!/bin/bash

# Docker Installation Script
# Cross-platform: macOS (Docker Desktop via Homebrew Cask) and Linux (Docker Engine)
# Date: 2025-12-18

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Docker Setup"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Check if Docker is already installed
docker_installed() {
    if command -v docker &>/dev/null; then
        return 0
    fi
    # macOS: Check for Docker Desktop
    if is_macos && [[ -d "/Applications/Docker.app" ]]; then
        return 0
    fi
    return 1
}

get_docker_version() {
    if command -v docker &>/dev/null; then
        docker --version 2>/dev/null | head -1
    else
        echo "not in PATH"
    fi
}

# Install Docker
print_step "Installing Docker..."

if docker_installed; then
    print_ok "Docker already installed ($(get_docker_version))"
else
    if is_macos; then
        # macOS: Install Docker Desktop via Homebrew Cask
        # Note: Docker Desktop cask may require sudo for some symlinks
        ensure_homebrew
        if ! init_brew; then
            print_warn "Brew not initialized in current session - may need manual setup"
        fi

        # Try cask install - may fail if sudo not available
        if pkg_install_cask docker; then
            print_ok "Docker Desktop installed"
        else
            print_warn "Homebrew cask install failed (may need sudo for system symlinks)"
            print_info "Trying alternative: download Docker Desktop directly..."

            # Download Docker Desktop DMG directly
            DMG_URL="https://desktop.docker.com/mac/main/arm64/Docker.dmg"
            if is_x86_64; then
                DMG_URL="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
            fi

            TMP_DMG="/tmp/Docker.dmg"
            if curl -fsSL -o "$TMP_DMG" "$DMG_URL"; then
                print_info "Mounting DMG..."
                hdiutil attach "$TMP_DMG" -quiet
                print_info "Copying Docker.app to /Applications..."
                cp -R "/Volumes/Docker/Docker.app" "/Applications/" 2>/dev/null || {
                    print_warn "Could not copy to /Applications (may need permission)"
                    print_info "You can manually drag Docker.app from the mounted DMG"
                }
                hdiutil detach "/Volumes/Docker" -quiet 2>/dev/null || true
                rm -f "$TMP_DMG"
            else
                print_error "Failed to download Docker Desktop"
                print_info "Please download manually from: https://www.docker.com/products/docker-desktop/"
            fi
        fi
        print_info "Please launch Docker.app to complete setup"
    else
        # Linux: Install Docker Engine via official convenience script
        # This installs at system level but doesn't require sudo for running containers
        # after adding user to docker group
        print_info "Installing Docker Engine for Linux..."

        # Check if we can use Homebrew docker CLI + docker-compose
        if command -v brew &>/dev/null || init_brew 2>/dev/null; then
            print_info "Installing Docker CLI tools via Homebrew..."
            pkg_install docker docker-compose docker-credential-helper
            print_ok "Docker CLI tools installed"
            print_warn "Note: This installs CLI tools only. For Docker daemon:"
            print_warn "  - Use Docker Desktop for Linux, or"
            print_warn "  - Install Docker Engine via: curl -fsSL https://get.docker.com | sh"
        else
            # Fallback: Use official Docker install script
            print_info "Downloading Docker install script..."
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            print_info "Running Docker install script (may require sudo)..."
            sh /tmp/get-docker.sh
            rm /tmp/get-docker.sh

            # Add user to docker group for rootless operation
            if command -v usermod &>/dev/null; then
                print_info "Adding user to docker group..."
                sudo usermod -aG docker "$USER" || print_warn "Could not add user to docker group"
                print_info "Log out and back in for group changes to take effect"
            fi
        fi
    fi
fi

# Install docker-compose if not already available (for systems where it's separate)
print_step "Checking docker-compose..."
if command -v docker-compose &>/dev/null; then
    print_ok "docker-compose already installed ($(docker-compose --version 2>/dev/null | head -1))"
elif docker compose version &>/dev/null 2>&1; then
    print_ok "docker compose (plugin) already available"
else
    if command -v brew &>/dev/null || init_brew 2>/dev/null; then
        pkg_install docker-compose
    else
        print_warn "docker-compose not found - install manually if needed"
    fi
fi

# Summary
echo ""
echo "======================================"
print_ok "Docker setup complete!"
echo "======================================"
echo ""

if is_macos; then
    print_info "Next steps:"
    echo "  1. Launch Docker Desktop from Applications"
    echo "  2. Complete the Docker Desktop setup wizard"
    echo "  3. Verify: docker run hello-world"
else
    print_info "Next steps:"
    echo "  1. Log out and back in (for docker group)"
    echo "  2. Start Docker daemon: sudo systemctl start docker"
    echo "  3. Enable on boot: sudo systemctl enable docker"
    echo "  4. Verify: docker run hello-world"
fi
echo ""
print_info "Useful commands:"
echo "  • Check version: docker --version"
echo "  • List containers: docker ps -a"
echo "  • List images: docker images"
echo "  • System info: docker info"
echo ""
