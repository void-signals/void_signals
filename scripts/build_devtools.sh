#!/bin/bash

# =============================================================================
# Void Signals DevTools Extension Build Script
# =============================================================================
#
# This script builds the DevTools extension and installs it to the correct
# location in void_signals_flutter package.
#
# Usage:
#   ./build_devtools.sh         # Build and install
#   ./build_devtools.sh --serve # Serve for development
#   ./build_devtools.sh --clean # Clean build artifacts
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEVTOOLS_DIR="$ROOT_DIR/packages/void_signals_devtools_extension"
FLUTTER_PKG_DIR="$ROOT_DIR/packages/void_signals_flutter"
EXTENSION_DIR="$FLUTTER_PKG_DIR/extension/devtools"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if flutter is available
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    log_info "Flutter version: $(flutter --version | head -n 1)"
}

# Clean build artifacts
clean() {
    log_info "Cleaning build artifacts..."
    
    if [ -d "$DEVTOOLS_DIR/build" ]; then
        rm -rf "$DEVTOOLS_DIR/build"
        log_info "Removed $DEVTOOLS_DIR/build"
    fi
    
    if [ -d "$EXTENSION_DIR/build" ]; then
        rm -rf "$EXTENSION_DIR/build"
        log_info "Removed $EXTENSION_DIR/build"
    fi
    
    log_success "Clean completed"
}

# Build the extension
build() {
    log_info "Building DevTools extension..."
    
    cd "$DEVTOOLS_DIR"
    
    # Get dependencies
    log_info "Getting dependencies..."
    flutter pub get
    
    # Build for web
    log_info "Building for web (HTML renderer)..."
    flutter build web \
        --web-renderer html \
        --release \
        --no-tree-shake-icons
    
    log_success "Build completed at: $DEVTOOLS_DIR/build/web"
}

# Install the extension to void_signals_flutter
install() {
    log_info "Installing DevTools extension..."
    
    # Ensure config.yaml exists
    if [ ! -f "$EXTENSION_DIR/config.yaml" ]; then
        log_info "Creating extension config.yaml..."
        mkdir -p "$EXTENSION_DIR"
        cat > "$EXTENSION_DIR/config.yaml" << EOF
name: void_signals
issueTracker: https://github.com/void-signals/void_signals/issues
version: 1.0.0
materialIconCodePoint: 0xe0d0
requiresConnection: true
EOF
    fi
    
    # Remove old build
    if [ -d "$EXTENSION_DIR/build" ]; then
        rm -rf "$EXTENSION_DIR/build"
    fi
    
    # Copy new build
    mkdir -p "$EXTENSION_DIR"
    cp -r "$DEVTOOLS_DIR/build/web" "$EXTENSION_DIR/build"
    
    log_success "DevTools extension installed to: $EXTENSION_DIR/build"
}

# Serve for development
serve() {
    log_info "Starting development server..."
    
    cd "$DEVTOOLS_DIR"
    flutter pub get
    flutter run -d chrome --web-port=9100
}

# Main
main() {
    case "${1:-}" in
        --clean)
            clean
            ;;
        --serve)
            check_flutter
            serve
            ;;
        --build-only)
            check_flutter
            build
            ;;
        --help|-h)
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  (no option)    Build and install the DevTools extension"
            echo "  --build-only   Build only without installing"
            echo "  --serve        Serve for development (hot reload)"
            echo "  --clean        Clean build artifacts"
            echo "  --help, -h     Show this help message"
            ;;
        *)
            check_flutter
            build
            install
            log_success "DevTools extension is ready!"
            log_info "The extension will be available in Flutter DevTools when debugging apps using void_signals_flutter"
            ;;
    esac
}

main "$@"
