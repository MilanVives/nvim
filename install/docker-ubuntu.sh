#!/bin/bash

# Docker Installation Script for Ubuntu
# Based on official Docker documentation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Allow running as root for container environments
# This is needed for installation inside Docker containers

# Check if Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "This script is designed for Ubuntu only"
    exit 1
fi

log_info "Starting Docker installation for Ubuntu..."

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    log_warn "Docker is already installed. Version: $(docker --version)"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
fi

# Update package index
log_info "Updating package index..."
sudo apt-get update -y

# Install prerequisite packages
log_info "Installing prerequisite packages..."
sudo apt-get install -y ca-certificates curl

# Create keyrings directory
log_info "Setting up Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key
if ! sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
    log_error "Failed to download Docker GPG key"
    exit 1
fi

sudo chmod a+r /etc/apt/keyrings/docker.asc

# Remove legacy one-line repo definition from older versions of this script,
# to avoid duplicate source entries alongside the deb822 file added below
sudo rm -f /etc/apt/sources.list.d/docker.list

# Add Docker repository (deb822 format, matching current Docker docs)
log_info "Adding Docker repository..."
echo \
"Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc" | \
  sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

# Update package index with Docker packages
log_info "Updating package index with Docker packages..."
sudo apt-get update -y

# Install Docker packages
log_info "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
log_info "Adding user to docker group..."
sudo groupadd -f docker
sudo usermod -aG docker $USER

# Start and enable Docker service
log_info "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Test Docker installation
log_info "Testing Docker installation..."
if sudo docker run hello-world &> /dev/null; then
    log_info "Docker installation successful!"
else
    log_error "Docker installation test failed"
    exit 1
fi

log_info "Docker installation completed successfully!"
log_warn "Please log out and log back in (or restart) for group changes to take effect"
log_info "You can then run 'docker run hello-world' to test without sudo"

# Show versions
log_info "Installed versions:"
docker --version
docker compose version
