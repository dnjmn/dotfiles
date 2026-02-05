#!/bin/bash
# install/ollama.sh - Local LLM inference via Docker

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/lib/platform.sh"

readonly NAME="ollama"

check_docker() {
    if ! command -v docker &>/dev/null; then
        print_error "Docker required. Run: ./install/docker.sh"
        exit 1
    fi
    if ! docker ps &>/dev/null; then
        print_error "Docker daemon not running"
        exit 1
    fi
    print_ok "Docker available"
}

setup_dirs() {
    mkdir -p "$XDG_DATA_HOME/ollama/models"
}

start_container() {
    if docker ps | grep -q ollama; then
        print_ok "Ollama container already running"
        return
    fi

    print_info "Starting Ollama container..."
    docker run -d \
        --name ollama \
        -p 11434:11434 \
        -v ollama_data:/root/.ollama \
        --restart unless-stopped \
        ollama/ollama:latest

    sleep 3
    docker ps | grep -q ollama && print_ok "Container started"
}

post_install() {
    echo ""
    print_info "Ollama setup complete!"
    echo "  API: http://localhost:11434"
    echo ""
    echo "Commands:"
    echo "  docker exec ollama ollama pull mistral"
    echo "  docker exec -it ollama ollama run mistral"
}

main() {
    echo "==> Installing $NAME"
    check_docker
    setup_dirs
    start_container
    post_install
    echo "==> Done"
}

main "$@"
