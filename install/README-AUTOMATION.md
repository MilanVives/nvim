# Ansible Automation for Neovim Installation

This directory contains scripts that are fully compatible with Ansible and other automation tools for unattended installation of Neovim on Ubuntu systems.

## Features

### ✅ Automation-Ready
- **Non-interactive mode**: No prompts that would hang automation
- **Root user support**: Works correctly in Docker containers and as root
- **Force reinstall**: Option to always reinstall regardless of existing installation
- **Proper error handling**: Exits with appropriate codes for automation
- **Home directory detection**: Works for both root (`/root`) and regular users

### ✅ Flexible Configuration
- Command line flags: `--non-interactive`, `--force-reinstall`
- Environment variables: `NVIM_NON_INTERACTIVE`, `NVIM_FORCE_REINSTALL`
- Shell profile detection: Automatically uses `.bashrc`, `.zshrc`, or `.bash_profile`

## Usage Examples

### 1. Basic Ansible Task

```yaml
- name: Install Neovim
  script: install-ubuntu.sh --non-interactive --force-reinstall
  become: yes
  environment:
    NVIM_NON_INTERACTIVE: "true"
    NVIM_FORCE_REINSTALL: "true"
```

### 2. With Repository Clone

```yaml
- name: Clone repository
  git:
    repo: "https://github.com/yourusername/nvim.git"
    dest: "/tmp/nvim-installer"
    
- name: Install Neovim
  script: "/tmp/nvim-installer/install/install-ubuntu.sh --non-interactive"
  become: yes
```

### 3. Direct Download & Execute

```yaml
- name: Download and install Neovim
  shell: |
    curl -fsSL https://raw.githubusercontent.com/yourusername/nvim/main/install/install-ubuntu.sh | \
    bash -s -- --non-interactive --force-reinstall
  environment:
    NVIM_NON_INTERACTIVE: "true"
    NVIM_FORCE_REINSTALL: "true"
  become: yes
```

### 4. Docker Container Installation

```yaml
- name: Install Neovim in Docker container  
  script: install-ubuntu.sh --non-interactive --force-reinstall
  environment:
    NVIM_NON_INTERACTIVE: "true"
    NVIM_FORCE_REINSTALL: "true"
  become: yes  # Runs as root in container
```

## Command Line Options

| Option | Environment Variable | Description |
|--------|---------------------|-------------|
| `--non-interactive` | `NVIM_NON_INTERACTIVE=true` | Skip all interactive prompts |
| `--force-reinstall` | `NVIM_FORCE_REINSTALL=true` | Force reinstallation even if Neovim exists |
| `--help` | - | Show usage information |

## Behavior in Different Modes

### Interactive Mode (Default)
- Prompts user if Neovim already exists
- Requires manual input
- **Not suitable for automation**

### Non-Interactive Mode
- If Neovim exists: Skips installation and exits successfully
- If Neovim doesn't exist: Installs automatically
- **Perfect for automation**

### Non-Interactive + Force Reinstall
- Always reinstalls Neovim regardless of existing installation
- **Best for ensuring latest version in automation**

## What Gets Installed

1. **Dependencies**: `ripgrep`, `fd-find`, `bat`, `fzf`, `git`, `curl`, `unzip`, `build-essential`
2. **Neovim**: Latest stable release to `/opt/nvim-linux64/`
3. **Symlink**: Creates `/usr/local/bin/nvim` → `/opt/nvim-linux64/bin/nvim`
4. **Configuration**: Copies `init.lua` to appropriate config directory
5. **PATH Update**: Adds Neovim to shell profile (`.bashrc`, `.zshrc`, etc.)

## Directory Handling

The script properly handles home directories for different users:
- **Regular user**: `~/.config/nvim`, `~/.bashrc`
- **Root user**: `/root/.config/nvim`, `/root/.bashrc`
- **Container**: Works correctly with any user context

## Error Handling

The script exits with appropriate codes:
- `0`: Success
- `1`: Error (missing dependencies, download failure, etc.)

This ensures Ansible tasks fail properly when something goes wrong.

## Testing

Test the script in different scenarios:

```bash
# Test non-interactive mode
./install-ubuntu.sh --non-interactive

# Test force reinstall
./install-ubuntu.sh --non-interactive --force-reinstall

# Test with environment variables
NVIM_NON_INTERACTIVE=true NVIM_FORCE_REINSTALL=true ./install-ubuntu.sh

# Test as root (in container)
docker run -it --rm ubuntu:22.04 bash -c "
  apt update && apt install -y curl &&
  curl -fsSL https://your-repo/install-ubuntu.sh | bash -s -- --non-interactive
"
```

## Complete Ansible Playbook

See `ansible-example.yml` for a complete working example that:
- Clones the repository
- Runs the installation script
- Verifies the installation
- Cleans up temporary files
- Handles multiple deployment scenarios