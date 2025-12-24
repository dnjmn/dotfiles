# Go (Golang) Configuration
# Fully XDG-compliant paths

# === ENVIRONMENT ===
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export GOBIN="$HOME/.local/bin"
export GOCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go-build"
export GOMODCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go/mod"

# Add Go binaries to PATH (GOBIN already added in options.zsh)
[[ -d "$GOPATH/bin" ]] && export PATH="$GOPATH/bin:$PATH"

# === ALIASES ===
alias gob='go build'
alias gor='go run'
alias got='go test'
alias gotv='go test -v'
alias gotc='go test -cover'
alias gof='go fmt ./...'
alias goi='go install'
alias gog='go get'
alias gom='go mod'
alias gomt='go mod tidy'
alias gomi='go mod init'
alias gomu='go mod download'
alias gov='go vet ./...'

# Linting (requires golangci-lint)
alias golint='golangci-lint run'
alias golintfix='golangci-lint run --fix'

# === FUNCTIONS ===

# Initialize new Go module with sensible defaults
gomod() {
    local name="${1:-$(basename "$PWD")}"
    if [[ -f "go.mod" ]]; then
        echo "go.mod already exists"
        return 1
    fi
    go mod init "$name"
    echo "Initialized module: $name"
}

# Run tests with coverage and open in browser
gocover() {
    local pkg="${1:-.}"
    go test -coverprofile=/tmp/coverage.out "$pkg" && \
    go tool cover -html=/tmp/coverage.out
}

# Run all tests recursively
gotest() {
    go test -race -cover ./...
}

# Build with common flags
gobuild() {
    local output="${1:-$(basename "$PWD")}"
    go build -ldflags="-s -w" -o "$output" .
}

# Quick benchmark
gobench() {
    local pkg="${1:-.}"
    go test -bench=. -benchmem "$pkg"
}

# Show module dependencies as tree
godeps() {
    go mod graph | sed -e 's/@[^ ]*//g' | sort -u
}

# Update all dependencies
goup() {
    go get -u ./...
    go mod tidy
}

# Generate mocks for interface (requires mockgen)
gomock() {
    local source="$1"
    local dest="${2:-mocks}"
    if ! command -v mockgen &>/dev/null; then
        echo "Install mockgen: go install github.com/golang/mock/mockgen@latest"
        return 1
    fi
    mockgen -source="$source" -destination="$dest/$(basename "$source")"
}
