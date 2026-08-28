#!/bin/zsh

# Neovim Installation Script for Mac ARM64
# Downloads and installs Neovim for Apple Silicon Macs

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

# Set up Neovim configuration
setup_nvim_config() {
    log_info "Setting up Neovim configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p ~/.config/nvim
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if init.lua exists in the parent directory
    if [[ -f "$SCRIPT_DIR/../init.lua" ]]; then
        log_info "Copying init.lua to ~/.config/nvim/"
        cp "$SCRIPT_DIR/../init.lua" ~/.config/nvim/
        
        # Fix the Neotree keymap syntax if needed
        sed -i '' "s/vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left')/vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left<CR>', {})/" ~/.config/nvim/init.lua 2>/dev/null || true
        
        log_info "Neovim configuration installed successfully!"
        log_info "Your plugins (Neo-tree, Telescope, Catppuccin theme, etc.) will be automatically installed on first run"
    else
        log_warn "init.lua not found in $SCRIPT_DIR/../init.lua"
        log_warn "Please manually copy your configuration to ~/.config/nvim/init.lua"
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing Neovim dependencies..."
    
    # Check if Homebrew is available for dependencies
    if command -v brew &> /dev/null; then
        log_info "Using Homebrew to install dependencies..."
        brew install ripgrep fd bat fzf node 2>/dev/null || {
            log_warn "Some Homebrew packages failed to install, but Neovim will still work"
        }
        log_info "Dependencies installed successfully!"
        log_info "  - ripgrep: Fast text search for Telescope live_grep"
        log_info "  - fd: Fast file finder for Telescope find_files"
        log_info "  - bat: Syntax-highlighted file previews"
        log_info "  - fzf: Fuzzy finder"
        log_info "  - node: Required by several Mason LSP servers (pyright, ts_ls, html, cssls, jsonls)"
    else
        log_warn "Homebrew not found - some Telescope features may be limited"
        log_info "Consider installing: ripgrep, fd, bat, fzf, node manually"
        log_info "You can install Homebrew from: https://brew.sh"
    fi
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# Check if running on ARM64
if [[ $(uname -m) != "arm64" ]]; then
    log_error "This script is for Apple Silicon (ARM64) Macs only"
    log_info "Use install-mac-x86.sh for Intel Macs"
    exit 1
fi

log_info "Starting Neovim installation for Mac ARM64..."

# Install dependencies first
install_dependencies

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

# Download latest stable Neovim release for ARM64
log_info "Downloading latest Neovim release for ARM64..."
if ! curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-macos-arm64.tar.gz; then
    log_error "Failed to download Neovim"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verify download
if [[ ! -f "nvim-macos-arm64.tar.gz" ]]; then
    log_error "Download file not found"
    rm -rf "$TEMP_DIR"
    exit 1
fi

log_info "Download completed successfully"

# Extract
log_info "Extracting Neovim..."
tar xzf nvim-macos-arm64.tar.gz

# Verify extraction
if [[ ! -f "nvim-macos-arm64/bin/nvim" ]]; then
    log_error "Extraction failed - nvim binary not found"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Install to /usr/local (or /opt/homebrew if it exists)
if [[ -d "/opt/homebrew" ]]; then
    INSTALL_PREFIX="/opt/homebrew"
    log_info "Installing to $INSTALL_PREFIX (Homebrew prefix detected)"
else
    INSTALL_PREFIX="/usr/local"
    log_info "Installing to $INSTALL_PREFIX"
fi

# Remove existing installation
log_info "Removing existing Neovim installation (if any)..."
sudo rm -rf "$INSTALL_PREFIX/nvim-macos-arm64"

# Move to installation directory
log_info "Installing Neovim..."
sudo mv nvim-macos-arm64 "$INSTALL_PREFIX/"

# Create symlink
log_info "Creating symlink..."
sudo ln -sf "$INSTALL_PREFIX/nvim-macos-arm64/bin/nvim" "$INSTALL_PREFIX/bin/nvim"

# Update PATH in shell profile
SHELL_PROFILE=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ -f "$HOME/.bash_profile" ]]; then
    SHELL_PROFILE="$HOME/.bash_profile"
elif [[ -f "$HOME/.profile" ]]; then
    SHELL_PROFILE="$HOME/.profile"
fi

if [[ -n "$SHELL_PROFILE" ]]; then
    log_info "Updating PATH in $SHELL_PROFILE..."
    if ! grep -q "$INSTALL_PREFIX/bin" "$SHELL_PROFILE"; then
        echo "export PATH=\"$INSTALL_PREFIX/bin:\$PATH\"" >> "$SHELL_PROFILE"
        log_info "Added to PATH in $SHELL_PROFILE"
    else
        log_info "PATH already configured in $SHELL_PROFILE"
    fi
fi

# Update PATH for current session
export PATH="$INSTALL_PREFIX/bin:$PATH"

# Clean up
cd "$HOME"
rm -rf "$TEMP_DIR"
log_debug "Cleaned up temporary directory"

# Test installation
log_info "Testing Neovim installation..."
if "$INSTALL_PREFIX/nvim-macos-arm64/bin/nvim" --version &> /dev/null; then
    installed_version=$("$INSTALL_PREFIX/nvim-macos-arm64/bin/nvim" --version | head -n1)
    log_info "Installation successful!"
    log_info "Installed version: $installed_version"
else
    log_error "Installation test failed"
    exit 1
fi

# Set up Neovim configuration
setup_nvim_config

log_info "Neovim installation completed successfully!"
log_warn "Please restart your terminal or run 'source $SHELL_PROFILE' to update your PATH"
log_info "You can now run 'nvim' to start Neovim"

# Show basic usage info
echo
echo "Basic Neovim commands:"
echo "  nvim <file>     - Open a file"
echo "  nvim            - Start Neovim"
echo "  :q              - Quit (in Neovim)"
echo "  :q!             - Quit without saving"
echo "  :wq             - Save and quit"
echo
echo "Your custom keybindings:"
echo "  Ctrl+N          - Toggle Neo-tree file explorer"
echo "  Ctrl+F          - Find files (Telescope)"
echo "  Space+fg        - Live grep search (requires ripgrep)"
echo "  Space+fb        - Find buffers"
echo "  Space+fh        - Find help tags"
echo "  (leader key is Space)"
