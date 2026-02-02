#!/bin/bash

# Ollama Installation Script
# Docker-based LLM inference engine with persistent model storage
# Supports macOS and Linux
# Date: 2026-01-24

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source platform helper
source "$REPO_DIR/lib/platform.sh"

echo "======================================"
echo "Ollama Setup (Docker)"
echo "======================================"
echo ""

# Print platform info
print_platform_info

# Ensure Docker is available
print_step "Checking Docker installation..."
if ! command -v docker &>/dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    print_info "Run: ./install.sh --docker"
    exit 1
fi
print_ok "Docker found: $(docker --version)"

# Check if Docker daemon is running
print_step "Checking Docker daemon..."
if ! docker ps &>/dev/null; then
    print_error "Docker daemon is not running"
    if is_macos; then
        print_info "Please launch Docker Desktop from /Applications/Docker.app"
    else
        print_info "Please start Docker daemon: sudo systemctl start docker"
    fi
    exit 1
fi
print_ok "Docker daemon is running"

# Set up XDG paths for ollama data
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
OLLAMA_DATA_DIR="$XDG_DATA_HOME/ollama"
OLLAMA_MODELS_DIR="$OLLAMA_DATA_DIR/models"

print_step "Setting up Ollama directories..."
mkdir -p "$OLLAMA_MODELS_DIR"
print_ok "Model directory: $OLLAMA_MODELS_DIR"

# Create docker-compose.yml for ollama
print_step "Creating Docker Compose configuration..."
DOCKER_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

cat > "$DOCKER_COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
    volumes:
      - ollama_data:/root/.ollama
    restart: unless-stopped
    # GPU support (uncomment for NVIDIA GPU on Linux)
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

volumes:
  ollama_data:
    driver: local
EOF

print_ok "Docker Compose config: $DOCKER_COMPOSE_FILE"

# Create helper shell functions file
print_step "Creating Ollama helper functions..."
OLLAMA_FUNCTIONS_FILE="$SCRIPT_DIR/.ollama-functions"

cat > "$OLLAMA_FUNCTIONS_FILE" << 'EOF'
#!/bin/bash
# Ollama helper functions for shell integration

# Start ollama container
ollama_start() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "[INFO] Starting Ollama container..."
    docker-compose -f "$script_dir/docker-compose.yml" up -d
    echo "[OK] Ollama container started at http://localhost:11434"
}

# Stop ollama container
ollama_stop() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "[INFO] Stopping Ollama container..."
    docker-compose -f "$script_dir/docker-compose.yml" down
    echo "[OK] Ollama container stopped"
}

# Pull a model
ollama_pull() {
    local model="${1:-}"
    if [[ -z "$model" ]]; then
        echo "Usage: ollama_pull <model>"
        echo "Examples: ollama_pull llama2, ollama_pull mistral"
        return 1
    fi
    echo "[INFO] Pulling model: $model"
    docker exec ollama ollama pull "$model"
}

# List available models
ollama_list() {
    echo "[INFO] Available models:"
    docker exec ollama ollama list
}

# Interactive chat with a model
ollama_chat() {
    local model="${1:-mistral}"
    echo "[INFO] Starting chat with $model..."
    docker exec -it ollama ollama run "$model"
}

# Check container status
ollama_status() {
    if docker ps | grep -q ollama; then
        echo "[OK] Ollama container is running"
        docker ps | grep ollama
    else
        echo "[WARN] Ollama container is not running"
        echo "Start with: ollama_start"
    fi
}
EOF

chmod +x "$OLLAMA_FUNCTIONS_FILE"
print_ok "Helper functions: $OLLAMA_FUNCTIONS_FILE"

# Check if ollama container is already running
if docker ps | grep -q ollama; then
    print_info "Ollama container is already running"
else
    print_step "Starting Ollama container..."
    if docker-compose -f "$DOCKER_COMPOSE_FILE" up -d; then
        print_ok "Ollama container started"

        # Wait for container to be ready
        sleep 3

        if docker ps | grep -q ollama; then
            print_ok "Container is healthy"
        fi
    else
        print_error "Failed to start Ollama container"
        exit 1
    fi
fi

# Summary
echo ""
echo "======================================"
print_ok "Ollama Docker setup complete!"
echo "======================================"
echo ""

print_info "Quick start:"
echo "  1. Models are stored in: $OLLAMA_MODELS_DIR"
echo "  2. API endpoint: http://localhost:11434"
echo ""

print_info "Useful commands:"
echo "  • Pull a model:     docker exec ollama ollama pull llama2"
echo "  • List models:      docker exec ollama ollama list"
echo "  • Run interactive:  docker exec -it ollama ollama run mistral"
echo "  • Stop container:   docker-compose -f $SCRIPT_DIR/docker-compose.yml down"
echo "  • View logs:        docker-compose -f $SCRIPT_DIR/docker-compose.yml logs -f"
echo ""

print_info "Helper functions available:"
echo "  Source the functions: source $OLLAMA_FUNCTIONS_FILE"
echo "  Then use:"
echo "    • ollama_start      - Start the container"
echo "    • ollama_stop       - Stop the container"
echo "    • ollama_pull MODEL - Pull a model"
echo "    • ollama_list       - List available models"
echo "    • ollama_chat MODEL - Interactive chat"
echo "    • ollama_status     - Check container status"
echo ""

print_info "Popular models:"
echo "  • llama2          - Meta's Llama 2 (7B, 13B, 70B variants)"
echo "  • mistral         - Mistral 7B (fast, capable)"
echo "  • neural-chat     - Intel Neural Chat (optimized)"
echo "  • orca-mini       - Orca Mini (small, fast)"
echo "  • dolphin-mixtral - Dolphin Mixtral (advanced)"
echo ""

print_info "To get started:"
echo "  1. Pull a model: docker exec ollama ollama pull mistral"
echo "  2. Chat with it: docker exec -it ollama ollama run mistral"
echo "  3. Or use REST API: curl http://localhost:11434/api/generate -d '{\"model\": \"mistral\", \"prompt\": \"Why is the sky blue?\"}'"
echo ""
