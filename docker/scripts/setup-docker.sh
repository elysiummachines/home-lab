#!/bin/bash
# setup-docker.sh + Secure Docker Environment Setup
# Creates proper directory structure with S.B.P

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        log_error "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# check if we can use sudo
check_sudo() {
    if ! sudo -v; then
        log_error "User $USER does not have sudo privileges!"
        exit 1
    fi
}

# Installation mode
if [[ "$1" == "--install" ]] || [[ "$1" == "-i" ]]; then
    log_info "Installing docker-setup to /usr/local/bin..."
    sudo install -m 755 "$0" /usr/local/bin/docker-setup
    log_success "Installed! Now run: docker-setup"
    exit 0
fi

# Help mode
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Docker Environment Setup"
    echo ""
    echo "Usage:"
    echo "  ./$(basename "$0")        # Run setup directly"
    echo "  ./$(basename "$0") --install  # Install to /usr/local/bin"
    echo "  ./$(basename "$0") --help     # Show this help"
    echo ""
    echo "Features:"
    echo "  • Installs Docker and Docker Compose"
    echo "  • Creates secure directory structure"
    echo "  • Sets proper permissions (security-focused)"
    echo "  • Configures Docker group membership"
    echo "  • Creates example project"
    echo ""
    echo "After installation:"
    echo "  docker-setup               # Run from anywhere"
    exit 0
fi

# ===== MAIN SETUP CODE =====
clear
echo "========================================"
echo "   Docker Environment Setup"
echo "========================================"
echo ""

# Pre-checks
check_root
check_sudo

# 1. Install Docker
log_info "Step 1/7: Installing Docker and Docker Compose..."
sudo apt update
sudo apt install -y docker.io docker-compose

# 2. Ensure Docker group exists
log_info "Step 2/7: Setting up Docker group..."
sudo groupadd -f docker

# 3. Add current user to Docker group
log_info "Step 3/7: Adding $USER to Docker group..."
sudo usermod -aG docker "$USER"

# 4. Create main Docker directory
log_info "Step 4/7: Creating secure directory structure..."
mkdir -p -m 750 ~/docker

# 5. Create subdirectories with appropriate permissions
log_info "Step 5/7: Setting directory permissions..."
mkdir -p -m 770 ~/docker/volumes     # RWX for Docker containers
mkdir -p -m 750 ~/docker/compose     # Compose YAML files
mkdir -p -m 750 ~/docker/configs     # App configurations
mkdir -p -m 700 ~/docker/secrets     # Most restrictive for passwords/keys
mkdir -p -m 750 ~/docker/backups     # For backups

# 6. Set proper ownership
log_info "Step 6/7: Setting ownership..."
sudo chown -R "$USER":docker ~/docker

# 7. Create useful starter files
log_info "Step 7/7: Creating starter files and examples..."

# .gitignore to prevent committing secrets
cat > ~/docker/.gitignore << 'EOF'
# Docker Secrets & Data
/secrets/
/volumes/
/backups/
*.env
.env.*
*.secret
docker-compose.override.yml

# IDE/Editor files
.vscode/
.idea/
*.swp
*.swo
.DS_Store
EOF

# Show installed versions at the end
echo ""
echo "✅ Installed versions:"
docker --version || echo "Docker: Run after logout"
docker-compose --version || echo "Docker Compose: Check installation"
echo ""

# README usage instructions
cat > ~/docker/README.md << 'EOF'
# Docker Environment

## Directory Structure:
- `stacks/` - Docker Compose YAML files
- `configs/` - Application configuration files
- `volumes/` - Persistent container data
- `secrets/` - Sensitive files (passwords, keys) - 700 permissions
- `compose/` - Docker Compose utilities
- `backups/` - Backup files

## Quick Start:
1. Create a new stack:
   ```bash
   cd ~/docker/stacks
   mkdir myapp && cd myapp
   nano docker-compose.yml
