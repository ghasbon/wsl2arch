#!/bin/bash

# Waydroid Installation Script for Arch Linux on WSL2
# Author: Generated for waydroid-arch-wsl2-install project
# Date: $(date)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if running on WSL2
check_wsl2() {
    log "Checking WSL2 environment..."
    
    if ! grep -qi microsoft /proc/version; then
        error "This script is designed for WSL2 environment only!"
        exit 1
    fi
    
    if ! grep -qi "arch" /etc/os-release; then
        error "This script is designed for Arch Linux only!"
        exit 1
    fi
    
    success "WSL2 Arch Linux environment confirmed"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    
    sudo pacman -Syu --noconfirm
    
    success "System packages updated"
}

# Install essential packages
install_essentials() {
    log "Installing essential packages..."
    
    local packages=(
        "base-devel"
        "git"
        "curl"
        "wget"
        "python"
        "python-pip"
        "python-pipx"
        "docker"
        "lxc"
        "linux-headers"
        "dkms"
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    success "Essential packages installed"
}

# Set up AUR helper if not exists
setup_yay() {
    log "Setting up yay AUR helper..."
    
    if command -v yay >/dev/null 2>&1; then
        success "yay is already installed"
        return
    fi
    
    # Create temporary user if root
    if [ "$EUID" -eq 0 ]; then
        warning "Cannot install yay as root. Creating temporary user..."
        useradd -m -G wheel -s /bin/bash tempuser 2>/dev/null || true
        echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
        
        sudo -u tempuser bash << 'EOF'
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
    else
        cd /tmp
        git clone https://aur.archlinux.org/yay.git || (cd yay && git pull)
        cd yay
        makepkg -si --noconfirm
    fi
    
    success "yay AUR helper installed"
}

# Install Waydroid dependencies
install_waydroid_deps() {
    log "Installing Waydroid dependencies..."
    
    # Install from official repos
    sudo pacman -S --needed --noconfirm \
        wayland \
        weston \
        python-gbinder \
        python-pygobject \
        lxc \
        sqlite \
        dnsmasq \
        gtk3 \
        gobject-introspection \
        python-gobject \
        nftables \
        dbus \
        systemd
    
    # Install from AUR if yay is available
    if command -v yay >/dev/null 2>&1; then
        log "Installing AUR packages..."
        yay -S --noconfirm \
            waydroid \
            python-pyclip || warning "Some AUR packages failed to install"
    fi
    
    success "Waydroid dependencies installed"
}

# Configure systemd services
configure_services() {
    log "Configuring systemd services..."
    
    # Enable and start required services
    sudo systemctl enable --now systemd-resolved
    sudo systemctl enable --now dbus
    
    # Docker configuration
    sudo systemctl enable --now docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    success "Services configured"
}

# Install Waydroid
install_waydroid() {
    log "Installing Waydroid..."
    
    # Method 1: Try from AUR
    if command -v yay >/dev/null 2>&1; then
        log "Attempting to install Waydroid from AUR..."
        yay -S --noconfirm waydroid || {
            warning "AUR installation failed, trying manual installation..."
            install_waydroid_manual
        }
    else
        install_waydroid_manual
    fi
}

# Manual Waydroid installation
install_waydroid_manual() {
    log "Installing Waydroid manually..."
    
    cd /tmp
    
    # Clone Waydroid repository
    if [ ! -d "waydroid" ]; then
        git clone https://github.com/waydroid/waydroid.git
    else
        cd waydroid && git pull && cd ..
    fi
    
    cd waydroid
    
    # Install Waydroid
    sudo python3 setup.py install
    
    success "Waydroid installed manually"
}

# Initialize Waydroid
initialize_waydroid() {
    log "Initializing Waydroid..."
    
    # Initialize Waydroid (this will download system images)
    warning "This step will download Android system images (several GB)"
    read -p "Continue with Waydroid initialization? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Skipping Waydroid initialization"
        return
    fi
    
    sudo waydroid init || {
        error "Waydroid initialization failed"
        log "This might be due to WSL2 limitations with Android containers"
        log "Please check the troubleshooting section in README.md"
        return 1
    }
    
    success "Waydroid initialized"
}

# Create startup script
create_startup_script() {
    log "Creating Waydroid startup script..."
    
    cat > ~/start-waydroid.sh << 'EOF'
#!/bin/bash

echo "Starting Waydroid services..."

# Start required services
sudo systemctl start systemd-resolved
sudo systemctl start dbus

# Start Waydroid container session
waydroid session start &

# Wait a moment for session to start
sleep 5

# Start Waydroid UI
waydroid show-full-ui

EOF
    
    chmod +x ~/start-waydroid.sh
    
    success "Startup script created at ~/start-waydroid.sh"
}

# WSL2 specific configurations
configure_wsl2() {
    log "Applying WSL2 specific configurations..."
    
    # Enable systemd in WSL2 if not already enabled
    if ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
        log "Enabling systemd in WSL2..."
        sudo tee /etc/wsl.conf > /dev/null << EOF
[boot]
systemd=true

[network]
generateResolvConf=false
EOF
        warning "WSL2 restart required for systemd changes to take effect"
        warning "Run 'wsl --shutdown' and restart WSL2"
    fi
    
    success "WSL2 configurations applied"
}

# Display final instructions
show_instructions() {
    echo
    success "Waydroid installation completed!"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart WSL2 if systemd was just enabled:"
    echo "   - Exit WSL2 completely"
    echo "   - Run 'wsl --shutdown' from PowerShell"
    echo "   - Restart WSL2"
    echo
    echo "2. Initialize Waydroid (if not done during installation):"
    echo "   sudo waydroid init"
    echo
    echo "3. Start Waydroid:"
    echo "   ~/start-waydroid.sh"
    echo "   or manually:"
    echo "   waydroid session start &"
    echo "   waydroid show-full-ui"
    echo
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "- If Waydroid fails to start, check kernel modules:"
    echo "  lsmod | grep -E 'binder|ashmem'"
    echo "- WSL2 might not support all required kernel features"
    echo "- Consider using Docker-based Android emulation as alternative"
    echo
}

# Main installation function
main() {
    echo -e "${BLUE}"
    echo "============================================="
    echo "  Waydroid Installation for WSL2 Arch Linux"
    echo "============================================="
    echo -e "${NC}"
    
    # Run installation steps
    check_wsl2
    update_system
    install_essentials
    setup_yay
    install_waydroid_deps
    configure_services
    configure_wsl2
    install_waydroid
    initialize_waydroid
    create_startup_script
    show_instructions
    
    success "Installation script completed!"
}

# Handle script interruption
trap 'error "Installation interrupted"; exit 1' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
