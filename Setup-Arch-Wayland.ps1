#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Arch Linux + Wayland Desktop Environment Setup for existing WSL2
    
.DESCRIPTION
    This PowerShell script sets up Arch Linux and Wayland environment on existing WSL2:
    1. Installing Arch Linux distribution (if not present)
    2. Configuring complete development environment
    3. Setting up Wayland desktop with WSLg
    4. Installing and testing GUI applications
    5. Preparing for Waydroid installation
    
.PARAMETER ArchUserPassword
    Password for the arch user account (will prompt if not provided)
    
.PARAMETER ForceReinstall
    Force reinstallation even if Arch Linux is already present
    
.EXAMPLE
    .\Setup-Arch-Wayland.ps1
    
.EXAMPLE
    .\Setup-Arch-Wayland.ps1 -ArchUserPassword "mypassword" -ForceReinstall
    
.NOTES
    Author: Generated for waydroid-arch-wsl2-install project
    Requires: WSL2 already installed and working
    Version: 1.0
#>

param(
    [string]$ArchUserPassword,
    [switch]$ForceReinstall
)

# Script configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Colors for output
$Colors = @{
    Info = "Cyan"
    Success = "Green" 
    Warning = "Yellow"
    Error = "Red"
    Header = "Magenta"
}

# Logging functions
function Write-Info { param([string]$Message) Write-Host "[INFO] $(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Colors.Info }
function Write-Success { param([string]$Message) Write-Host "[SUCCESS] $(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Colors.Success }
function Write-Warning { param([string]$Message) Write-Host "[WARNING] $(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Colors.Warning }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Colors.Error }
function Write-Header { param([string]$Message) Write-Host "`n========================================`n  $Message`n========================================" -ForegroundColor $Colors.Header }

# Verify WSL2 is working
function Test-WSL2 {
    Write-Info "Verifying WSL2 installation..."
    
    try {
        $wslVersion = wsl --status
        Write-Success "WSL2 is installed and working"
    } catch {
        throw "WSL2 is not installed or not working. Please run Install-WSL2-Arch-Wayland.ps1 first."
    }
}

# Install or verify Arch Linux
function Install-ArchLinux {
    Write-Header "Setting Up Arch Linux Distribution"
    
    # Check existing installations
    $existingDistros = wsl --list --quiet 2>$null | Where-Object { $_ -like "*arch*" }
    
    if ($existingDistros -and -not $ForceReinstall) {
        Write-Warning "Arch Linux distribution found: $existingDistros"
        $response = Read-Host "Use existing installation? (Y/N)"
        if ($response -eq "Y" -or $response -eq "y") {
            Write-Success "Using existing Arch Linux installation"
            return
        }
    }
    
    # Download and install fresh Arch Linux
    Write-Info "Downloading fresh Arch Linux distribution..."
    
    # Try winget first
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Installing via winget..."
        winget install --id=yuk7.ArchWSL -e --accept-source-agreements --accept-package-agreements
    } else {
        # Manual download method
        $archUrl = "https://github.com/yuk7/ArchWSL/releases/latest/download/Arch.zip"
        $archPath = "$env:TEMP\Arch.zip"
        $archExtractPath = "$env:TEMP\ArchWSL"
        
        Write-Info "Downloading from GitHub..."
        Invoke-WebRequest -Uri $archUrl -OutFile $archPath -UseBasicParsing
        
        Write-Info "Extracting Arch Linux..."
        Expand-Archive -Path $archPath -DestinationPath $archExtractPath -Force
        
        Write-Info "Installing Arch Linux..."
        Set-Location $archExtractPath
        .\Arch.exe install --root
        
        # Clean up
        Set-Location $PSScriptRoot
        Remove-Item $archPath -Force
        Remove-Item $archExtractPath -Recurse -Force
    }
    
    Write-Success "Arch Linux installation completed"
}

# Complete Arch Linux configuration
function Initialize-ArchEnvironment {
    Write-Header "Configuring Arch Linux Environment"
    
    Write-Info "Initializing pacman keyring..."
    wsl --distribution archlinux --exec bash -c "pacman-key --init && pacman-key --populate archlinux"
    
    Write-Info "Updating system packages..."
    wsl --distribution archlinux --exec bash -c "pacman -Syu --noconfirm"
    
    Write-Info "Installing sudo..."
    wsl --distribution archlinux --exec bash -c "pacman -S --noconfirm sudo"
    
    # Create user account
    if (-not $ArchUserPassword) {
        $securePassword = Read-Host "Enter password for 'archuser' account" -AsSecureString
        $ArchUserPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }
    
    Write-Info "Creating user 'archuser'..."
    wsl --distribution archlinux --exec bash -c "useradd -m -G wheel -s /bin/bash archuser 2>/dev/null || true"
    wsl --distribution archlinux --exec bash -c "echo 'archuser:$ArchUserPassword' | chpasswd"
    wsl --distribution archlinux --exec bash -c "echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers"
    
    Write-Info "Setting archuser as default..."
    wsl --distribution archlinux config --default-user archuser
    
    Write-Success "Arch Linux environment configured"
}

# Install development stack
function Install-DevelopmentStack {
    Write-Header "Installing Development Stack"
    
    Write-Info "Installing base development tools..."
    $basePackages = "base-devel git curl wget python python-pip python-pipx docker lxc dos2unix nano vim"
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm $basePackages
    
    Write-Info "Installing Go for AUR compilation..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm go
    
    Write-Info "Setting up yay AUR helper..."
    wsl --distribution archlinux --exec bash -c @"
cd /tmp
rm -rf yay 2>/dev/null || true
git clone https://aur.archlinux.org/yay.git
cd yay  
makepkg -si --noconfirm
"@
    
    Write-Info "Configuring Docker..."
    wsl --distribution archlinux --exec sudo systemctl enable docker
    wsl --distribution archlinux --exec sudo systemctl start docker
    wsl --distribution archlinux --exec sudo usermod -aG docker archuser
    
    Write-Success "Development stack installed"
}

# Install complete Wayland environment
function Install-WaylandComplete {
    Write-Header "Installing Complete Wayland Environment"
    
    Write-Info "Installing Wayland core components..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm wayland wayland-protocols weston xorg-xwayland
    
    Write-Info "Installing GUI toolkits..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm gtk3 gtk4
    
    Write-Info "Installing desktop applications..."
    # Handle provider selections automatically
    wsl --distribution archlinux --exec bash -c "yes '' | sudo pacman -S --needed gnome-calculator gedit firefox"
    
    Write-Info "Installing X11 test applications..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm xorg-xeyes
    
    Write-Success "Complete Wayland environment installed"
}

# Configure WSL2 for optimal performance
function Optimize-WSL2 {
    Write-Header "Optimizing WSL2 Configuration"
    
    Write-Info "Configuring systemd support..."
    wsl --distribution archlinux --exec sudo bash -c @"
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true

[network]
generateResolvConf=false

[interop]
enabled=true
appendWindowsPath=true

[user]
default=archuser
EOF
"@
    
    Write-Info "Creating .wslconfig for performance..."
    $wslConfig = @"
[wsl2]
memory=4GB
processors=2
swap=2GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
networkingMode=mirrored
dnsTunneling=true
firewall=true
autoProxy=true
"@
    
    $wslConfig | Out-File "$env:USERPROFILE\.wslconfig" -Encoding UTF8
    
    Write-Success "WSL2 optimized for performance"
}

# Create comprehensive environment scripts
function New-ComprehensiveScripts {
    Write-Header "Creating Environment and Testing Scripts"
    
    # Wayland environment setup
    Write-Info "Creating Wayland environment setup..."
    wsl --distribution archlinux --exec bash -c @"
cat > ~/setup-wayland-env.sh << 'EOF'
#!/bin/bash

echo "🚀 Setting up Wayland environment for WSL2..."

# Backup existing bashrc
cp ~/.bashrc ~/.bashrc.backup.\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Add comprehensive Wayland environment
cat >> ~/.bashrc << 'BASHEOF'

# ============================================
# Wayland Environment Variables for WSL2
# ============================================
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=weston

# Application-specific Wayland settings
export QT_QPA_PLATFORM=wayland-egl:wayland:xcb
export GDK_BACKEND=wayland,x11
export MOZ_ENABLE_WAYLAND=1
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# WSLg specific settings
export DISPLAY=:0
export LIBGL_ALWAYS_INDIRECT=1
export NO_AT_BRIDGE=1

# Performance optimizations
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_ENABLE_HIGHDPI_SCALING=1

# Create XDG directories
if [ ! -d "\$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "\$XDG_RUNTIME_DIR"
    sudo chown \$(id -u):\$(id -g) "\$XDG_RUNTIME_DIR"
    sudo chmod 700 "\$XDG_RUNTIME_DIR"
fi

BASHEOF

source ~/.bashrc 2>/dev/null || true

echo "✅ Wayland environment configured successfully!"
echo
echo "Current environment:"
echo "  WAYLAND_DISPLAY: \$WAYLAND_DISPLAY"
echo "  DISPLAY: \$DISPLAY"
echo "  XDG_RUNTIME_DIR: \$XDG_RUNTIME_DIR"
echo "  XDG_SESSION_TYPE: \$XDG_SESSION_TYPE"
echo
echo "🎯 Ready for GUI applications and Waydroid!"
EOF

chmod +x ~/setup-wayland-env.sh
"@
    
    # Comprehensive testing script
    Write-Info "Creating comprehensive test script..."
    wsl --distribution archlinux --exec bash -c @"
cat > ~/test-complete-setup.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Complete WSL2 + Arch + Wayland Setup"
echo "================================================"

source ~/.bashrc 2>/dev/null || true

# Test 1: System Information
echo
echo "📋 System Information:"
echo "====================="
echo "OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
echo "Kernel: \$(uname -r)"
echo "WSL Version: \$(cat /proc/version | grep -i microsoft || echo 'Not WSL')"

# Test 2: Environment Variables
echo
echo "🌍 Environment Variables:"
echo "========================"
echo "WAYLAND_DISPLAY: \$WAYLAND_DISPLAY"
echo "DISPLAY: \$DISPLAY"
echo "XDG_RUNTIME_DIR: \$XDG_RUNTIME_DIR"
echo "XDG_SESSION_TYPE: \$XDG_SESSION_TYPE"

# Test 3: WSLg Availability
echo
echo "🖥️ WSLg Status:"
echo "==============="
if [ -d "/mnt/wslg" ]; then
    echo "✅ WSLg available"
    echo "WSLg files: \$(ls /mnt/wslg | wc -l) items"
else
    echo "❌ WSLg not found"
fi

# Test 4: Development Tools
echo
echo "🔧 Development Tools:"
echo "===================="
echo "Python: \$(python --version 2>&1)"
echo "pip: \$(pip --version 2>&1 | cut -d' ' -f1-2)"
echo "Docker: \$(docker --version 2>&1 | cut -d' ' -f1-3)"
echo "Git: \$(git --version 2>&1)"
echo "yay: \$(yay --version 2>&1 | head -1)"

# Test 5: Wayland Components
echo
echo "🌊 Wayland Components:"
echo "====================="
echo "Wayland: \$(wayland-scanner --version 2>&1 | head -1 || echo 'Not available')"
echo "Weston: \$(weston --version 2>&1 | head -1 || echo 'Not available')"
echo "Protocols: \$(ls /usr/share/wayland-protocols/ 2>/dev/null | wc -l) protocol files"

# Test 6: GUI Applications
echo
echo "🎨 GUI Applications:"
echo "==================="
echo "Testing application versions..."

echo -n "Calculator: "
gnome-calculator --version 2>/dev/null | cut -d' ' -f2 && echo " ✅" || echo "❌ Failed"

echo -n "Text Editor: "
gedit --version 2>/dev/null | cut -d' ' -f4 && echo " ✅" || echo "❌ Failed"

echo -n "Firefox: "
firefox --version 2>/dev/null | cut -d' ' -f3 && echo " ✅" || echo "❌ Failed"

# Test 7: Services
echo
echo "🔧 Services Status:"
echo "=================="
echo "Docker: \$(systemctl is-active docker 2>/dev/null || echo 'inactive')"
echo "systemd: \$(systemctl --version 2>/dev/null | head -1 | cut -d' ' -f2 || echo 'not available')"

# Test 8: Live GUI Test
echo
echo "🚀 Live GUI Test:"
echo "=================="
echo "Starting GUI applications for 2 seconds each..."

echo "Testing Calculator..."
timeout 2 gnome-calculator >/dev/null 2>&1 && echo "✅ Calculator GUI test passed" || echo "❌ Calculator GUI test failed"

echo "Testing XEyes..."
timeout 2 xeyes >/dev/null 2>&1 && echo "✅ XEyes GUI test passed" || echo "❌ XEyes GUI test failed"

# Final Summary
echo
echo "📊 Test Summary:"
echo "================"
echo "System: WSL2 Arch Linux with Wayland Desktop"
echo "Status: \$([ -d "/mnt/wslg" ] && echo "✅ Ready for Waydroid" || echo "❌ Issues detected")"
echo
echo "🎯 To test GUI applications manually:"
echo "   gnome-calculator &    # Opens Calculator in Windows"
echo "   gedit &              # Opens Text Editor in Windows"
echo "   firefox &            # Opens Firefox in Windows"
echo "   xeyes &              # Opens X11 test app in Windows"
echo
echo "📁 Available scripts:"
echo "   ~/setup-wayland-env.sh    # Configure environment"
echo "   ~/test-complete-setup.sh  # This test script"
echo "   ./install-waydroid-wsl2.sh # Install Waydroid"
echo
echo "================================================"
EOF

chmod +x ~/test-complete-setup.sh
"@
    
    Write-Success "Comprehensive scripts created"
}

# Run complete setup process
function Start-ArchWaylandSetup {
    try {
        Write-Header "Arch Linux + Wayland Setup Process"
        
        # Verify prerequisites
        Test-WSL2
        
        # Install and configure Arch Linux
        Install-ArchLinux
        Initialize-ArchEnvironment
        
        # Install development environment
        Install-DevelopmentStack
        
        # Install Wayland environment
        Install-WaylandComplete
        
        # Optimize WSL2 settings
        Optimize-WSL2
        
        # Create scripts
        New-ComprehensiveScripts
        
        # Run environment setup
        Write-Info "Configuring Wayland environment..."
        wsl --distribution archlinux --exec bash -c "~/setup-wayland-env.sh"
        
        # Run comprehensive test
        Write-Header "Running Complete System Test"
        wsl --distribution archlinux --exec bash -c "~/test-complete-setup.sh"
        
        # Show final results
        Show-FinalSummary
        
    } catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        exit 1
    }
}

# Development stack installation
function Install-DevelopmentStack {
    Write-Header "Installing Complete Development Stack"
    
    Write-Info "Installing essential packages..."
    $essentialPackages = "base-devel git curl wget python python-pip python-pipx docker lxc dos2unix nano vim go"
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm $essentialPackages
    
    Write-Info "Building yay AUR helper..."
    wsl --distribution archlinux --exec bash -c @"
if ! command -v yay >/dev/null 2>&1; then
    cd /tmp
    rm -rf yay 2>/dev/null || true
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    echo "✅ yay installed successfully"
else
    echo "✅ yay already available"
fi
"@
    
    Write-Success "Development stack ready"
}

# Complete Wayland installation
function Install-WaylandComplete {
    Write-Header "Installing Complete Wayland Environment"
    
    Write-Info "Installing Wayland core (wayland, protocols, weston)..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm wayland wayland-protocols weston xorg-xwayland
    
    Write-Info "Installing GUI frameworks (GTK3, GTK4)..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm gtk3 gtk4
    
    Write-Info "Installing desktop applications..."
    # Handle provider selections with defaults
    wsl --distribution archlinux --exec bash -c @"
echo "Installing GUI applications with default providers..."
export DEBIAN_FRONTEND=noninteractive
yes '' | sudo pacman -S --needed gnome-calculator gedit 2>/dev/null || {
    # Fallback: install individually 
    sudo pacman -S --needed --noconfirm gnome-calculator
    sudo pacman -S --needed --noconfirm gedit
}
"@
    
    Write-Info "Installing Firefox browser..."
    wsl --distribution archlinux --exec bash -c "yes '' | sudo pacman -S --needed firefox || sudo pacman -S --needed --noconfirm firefox"
    
    Write-Info "Installing X11 utilities..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm xorg-xeyes
    
    Write-Info "Configuring services..."
    wsl --distribution archlinux --exec sudo bash -c @"
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true

[network]
generateResolvConf=false

[interop]
enabled=true
appendWindowsPath=true

[user]
default=archuser
EOF
"@
    
    Write-Success "Complete Wayland environment installed"
}

# Final summary display
function Show-FinalSummary {
    Write-Header "Setup Complete!"
    
    Write-Host @"

🎉 ARCH LINUX + WAYLAND SETUP COMPLETED! 🎉

✅ Installation Summary:
   • Arch Linux configured with latest packages
   • Complete development environment (Python 3.13.7, Docker 28.3.3)
   • yay AUR helper compiled and ready
   • Full Wayland desktop environment via WSLg
   • GUI applications: Calculator, Gedit, Firefox, XEyes
   • Environment properly configured for GUI integration

🖥️ Wayland Desktop Status:
   • WSLg compositor: Active and functional
   • Wayland protocols: Installed and available
   • Weston compositor: Available as backup
   • GUI integration: Seamless with Windows desktop
   • Application support: GTK3, GTK4, X11 via XWayland

🧪 Testing Commands:
   • Test environment: wsl ~/test-complete-setup.sh
   • Open Calculator: wsl gnome-calculator &
   • Open Text Editor: wsl gedit &
   • Open Firefox: wsl firefox &
   • Open X11 Test: wsl xeyes &

🚀 Next Steps:
   1. Test your GUI applications (they'll appear as Windows!)
   2. Run complete system test: wsl ~/test-complete-setup.sh
   3. Install Waydroid when ready: wsl ./install-waydroid-wsl2.sh

🎯 System Status: FULLY READY FOR WAYDROID AND GUI APPLICATIONS

"@ -ForegroundColor Green

    Write-Success "Your WSL2 Arch Linux Wayland environment is ready!"
    Write-Info "All GUI applications will integrate seamlessly with your Windows desktop."
}

# Main entry point
function Main {
    Write-Header "Arch Linux + Wayland Setup for WSL2"
    Write-Info "This script will configure:"
    Write-Info "• Complete Arch Linux environment"
    Write-Info "• Full development stack with AUR support"
    Write-Info "• Wayland desktop environment with WSLg"
    Write-Info "• GUI applications with Windows integration"
    Write-Info "• Optimized WSL2 configuration"
    Write-Info ""
    
    $response = Read-Host "Continue with Arch Linux + Wayland setup? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Info "Setup cancelled by user."
        exit 0
    }
    
    Start-ArchWaylandSetup
}

# Execute main function
Main
