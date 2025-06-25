#!/bin/bash

# Neovim Installation Script for Ubuntu
# Downloads and installs the latest stable release

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "This script is designed for Ubuntu only"
    exit 1
fi

log_info "Starting Neovim installation for Ubuntu..."

# Check if Neovim is already installed
if command -v nvim &> /dev/null; then
    current_version=$(nvim --version | head -n1)
    log_warn "Neovim is already installed: $current_version"
    read -p "Do you want to reinstall with the latest version? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
log_debug "Using temporary directory: $TEMP_DIR"

# Download latest Neovim release
log_info "Downloading latest Neovim release..."
if ! curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz; then
    log_error "Failed to download Neovim"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verify download
if [[ ! -f "nvim-linux64.tar.gz" ]]; then
    log_error "Download file not found"
    rm -rf "$TEMP_DIR"
    exit 1
fi

log_info "Download completed successfully"

# Remove existing installation
log_info "Removing existing Neovim installation (if any)..."
sudo rm -rf /opt/nvim /opt/nvim-linux64

# Extract and install
log_info "Installing Neovim to /opt/nvim-linux64..."
sudo tar -C /opt -xzf nvim-linux64.tar.gz

# Verify installation
if [[ ! -f "/opt/nvim-linux64/bin/nvim" ]]; then
    log_error "Installation failed - nvim binary not found"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Create symlink for easier access
log_info "Creating symlink..."
sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim

# Update PATH in .bashrc if not already present
log_info "Updating PATH in ~/.bashrc..."
if ! grep -q "/opt/nvim-linux64/bin" ~/.bashrc; then
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >> ~/.bashrc
    log_info "Added Neovim to PATH in ~/.bashrc"
else
    log_info "Neovim path already exists in ~/.bashrc"
fi

# Also update PATH for current session
export PATH="$PATH:/opt/nvim-linux64/bin"

# Clean up
cd "$HOME"
rm -rf "$TEMP_DIR"
log_debug "Cleaned up temporary directory"

# Test installation
log_info "Testing Neovim installation..."
if /opt/nvim-linux64/bin/nvim --version &> /dev/null; then
    installed_version=$(/opt/nvim-linux64/bin/nvim --version | head -n1)
    log_info "Installation successful!"
    log_info "Installed version: $installed_version"
else
    log_error "Installation test failed"
    exit 1
fi

log_info "Neovim installation completed successfully!"
log_warn "Please restart your terminal or run 'source ~/.bashrc' to update your PATH"
log_info "You can now run 'nvim' to start Neovim"

# Show basic usage info
echo
echo "Basic Neovim commands:"
echo "  nvim <file>     - Open a file"
echo "  nvim            - Start Neovim"
echo "  :q              - Quit (in Neovim)"
echo "  :q!             - Quit without saving"
echo "  :wq             - Save and quit"
