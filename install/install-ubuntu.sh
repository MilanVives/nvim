#!/bin/bash

# Neovim Installation Script for Ubuntu
# Downloads and installs the latest stable release
# Supports automated/non-interactive execution for Ansible and CI/CD
#
# AUTOMATION FEATURES:
# - Non-interactive mode: Use --non-interactive or NVIM_NON_INTERACTIVE=true
# - Force reinstall: Use --force-reinstall or NVIM_FORCE_REINSTALL=true
# - Root user support: Works correctly when run as root in containers
# - Proper home directory detection: Handles both root and non-root users
# - Shell profile detection: Automatically detects .bashrc, .zshrc, or .bash_profile
#
# ANSIBLE EXAMPLE:
#   - name: Install Neovim
#     script: install-ubuntu.sh --non-interactive --force-reinstall
#     become: yes
#     environment:
#       NVIM_NON_INTERACTIVE: "true"
#       NVIM_FORCE_REINSTALL: "true"

set -e  # Exit on any error

# Default values
NON_INTERACTIVE=${NVIM_NON_INTERACTIVE:-false}
FORCE_REINSTALL=${NVIM_FORCE_REINSTALL:-false}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --force-reinstall)
            FORCE_REINSTALL=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --non-interactive    Skip all interactive prompts (for automation)"
            echo "  --force-reinstall    Force reinstallation even if Neovim exists"
            echo "  --help              Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  NVIM_NON_INTERACTIVE=true    Same as --non-interactive"
            echo "  NVIM_FORCE_REINSTALL=true    Same as --force-reinstall"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
    
    # Get the actual home directory (works for root and non-root users)
    local home_dir="${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6)}"
    
    # Create config directory if it doesn't exist
    mkdir -p "$home_dir/.config/nvim"
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if init.lua exists in the parent directory
    if [[ -f "$SCRIPT_DIR/../init.lua" ]]; then
        log_info "Copying init.lua to $home_dir/.config/nvim/"
        cp "$SCRIPT_DIR/../init.lua" "$home_dir/.config/nvim/"
        
        # Fix the Neotree keymap syntax if needed
        sed -i "s/vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left')/vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left<CR>', {})/" "$home_dir/.config/nvim/init.lua" 2>/dev/null || true
        
        log_info "Neovim configuration installed successfully!"
        log_info "Your plugins (Neo-tree, Telescope, Catppuccin theme, etc.) will be automatically installed on first run"
    else
        log_warn "init.lua not found in $SCRIPT_DIR/../init.lua"
        log_warn "Please manually copy your configuration to $home_dir/.config/nvim/init.lua"
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing Neovim dependencies..."
    
    # Update package lists
    sudo apt update
    
    # Install essential tools for Neovim plugins
    sudo apt install -y \
        ripgrep \
        fd-find \
        bat \
        fzf \
        git \
        curl \
        unzip \
        build-essential
    
    log_info "Dependencies installed successfully!"
    log_info "  - ripgrep: Fast text search for Telescope live_grep"
    log_info "  - fd-find: Fast file finder for Telescope find_files"
    log_info "  - bat: Syntax-highlighted file previews"
    log_info "  - fzf: Fuzzy finder"
}

# Check if Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "This script is designed for Ubuntu only"
    exit 1
fi

log_info "Starting Neovim installation for Ubuntu..."

# Install dependencies first
install_dependencies

# Check if Neovim is already installed
if command -v nvim &> /dev/null; then
    current_version=$(nvim --version | head -n1)
    log_warn "Neovim is already installed: $current_version"
    
    if [[ "$FORCE_REINSTALL" == "true" ]]; then
        log_info "Force reinstall flag set - proceeding with reinstallation"
    elif [[ "$NON_INTERACTIVE" == "true" ]]; then
        log_info "Non-interactive mode - skipping reinstallation (use --force-reinstall to override)"
        log_info "Installation completed (existing version retained)"
        exit 0
    else
        read -p "Do you want to reinstall with the latest version? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
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

# Update PATH in shell profile if not already present
# Get the actual home directory (works for root and non-root users)
home_dir="${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6)}"
shell_profile="$home_dir/.bashrc"

# Try to detect the appropriate shell profile
if [[ -f "$home_dir/.zshrc" ]] && [[ "$SHELL" == *"zsh"* ]]; then
    shell_profile="$home_dir/.zshrc"
elif [[ -f "$home_dir/.bash_profile" ]]; then
    shell_profile="$home_dir/.bash_profile"
fi

log_info "Updating PATH in $shell_profile..."
if ! grep -q "/opt/nvim-linux64/bin" "$shell_profile" 2>/dev/null; then
    echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >> "$shell_profile"
    log_info "Added Neovim to PATH in $shell_profile"
else
    log_info "Neovim path already exists in $shell_profile"
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

# Set up Neovim configuration
setup_nvim_config

log_info "Neovim installation completed successfully!"
log_warn "Please restart your terminal or run 'source $shell_profile' to update your PATH"
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
echo
echo "Installed dependencies:"
echo "  ✓ ripgrep       - Fast text search"
echo "  ✓ fd-find (fdfind) - Fast file finder"
echo "  ✓ bat (batcat)     - Syntax highlighting"
echo "  ✓ fzf           - Fuzzy finder"
