#!/bin/zsh

# Neovim Installation Script via Homebrew
# Installs Neovim using Homebrew package manager

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
    log_info "Installing Neovim dependencies via Homebrew..."
    
    # Install essential tools for Neovim plugins
    brew install \
        ripgrep \
        fd \
        bat \
        fzf \
        node

    log_info "Dependencies installed successfully!"
    log_info "  - ripgrep: Fast text search for Telescope live_grep"
    log_info "  - fd: Fast file finder for Telescope find_files"
    log_info "  - bat: Syntax-highlighted file previews"
    log_info "  - fzf: Fuzzy finder"
    log_info "  - node: Required by several Mason LSP servers (pyright, ts_ls, html, cssls, jsonls)"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

log_info "Starting Neovim installation via Homebrew..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed"
    log_info "Please install Homebrew first: https://brew.sh"
    log_info "Or use one of the other Mac installation scripts"
    exit 1
fi

# Update Homebrew
log_info "Updating Homebrew..."
brew update

# Install dependencies first
install_dependencies

# Check if Neovim is already installed
if brew list neovim &> /dev/null; then
    current_version=$(nvim --version | head -n1 2>/dev/null || echo "Unknown version")
    log_warn "Neovim is already installed: $current_version"
    read -p "Do you want to upgrade to the latest version? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Upgrading Neovim..."
        brew upgrade neovim
    else
        log_info "Installation cancelled by user"
        exit 0
    fi
else
    # Install Neovim
    log_info "Installing Neovim..."
    brew install neovim
fi

# Verify installation
log_info "Verifying Neovim installation..."
if command -v nvim &> /dev/null; then
    installed_version=$(nvim --version | head -n1)
    log_info "Installation successful!"
    log_info "Installed version: $installed_version"
else
    log_error "Installation verification failed"
    exit 1
fi

# Check for optional dependencies
log_info "Checking for optional dependencies..."

dependencies_to_install=()

# Check for Python support
if ! python3 -c "import pynvim" &> /dev/null; then
    log_warn "Python neovim package not found (optional but recommended)"
    dependencies_to_install+=("python3 -m pip install --user pynvim")
fi

# Check for Node.js support
if ! npm list -g neovim &> /dev/null 2>&1; then
    if command -v npm &> /dev/null; then
        log_warn "Node.js neovim package not found (optional but recommended)"
        dependencies_to_install+=("npm install -g neovim")
    fi
fi

# Check for Ruby support
if ! gem list neovim -i &> /dev/null; then
    if command -v gem &> /dev/null; then
        log_warn "Ruby neovim gem not found (optional)"
        dependencies_to_install+=("gem install neovim")
    fi
fi

if [[ ${#dependencies_to_install[@]} -gt 0 ]]; then
    echo
    log_info "Optional dependencies that can enhance Neovim functionality:"
    for dep in "${dependencies_to_install[@]}"; do
        echo "  $dep"
    done
    echo
    read -p "Do you want to install these optional dependencies? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for dep in "${dependencies_to_install[@]}"; do
            log_info "Running: $dep"
            eval "$dep" || log_warn "Failed to install: $dep"
        done
    fi
fi

# Set up Neovim configuration
setup_nvim_config

log_info "Neovim installation completed successfully!"
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
echo "  ✓ fd            - Fast file finder"
echo "  ✓ bat           - Syntax highlighting"
echo "  ✓ fzf           - Fuzzy finder"
echo
echo "Homebrew commands for Neovim:"
echo "  brew upgrade neovim    - Upgrade to latest version"
echo "  brew uninstall neovim  - Remove Neovim"
echo "  brew info neovim       - Show package information"
