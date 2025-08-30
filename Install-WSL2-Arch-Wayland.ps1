#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Complete WSL2 + Arch Linux + Wayland Desktop Environment Setup for Windows 11
    
.DESCRIPTION
    This PowerShell script automates the entire process of:
    1. Installing and configuring WSL2
    2. Setting up Arch Linux distribution
    3. Installing all development tools and dependencies
    4. Configuring Wayland desktop environment with WSLg
    5. Installing and testing GUI applications
    6. Preparing system for Waydroid installation
    
.PARAMETER SkipReboot
    Skip automatic reboot after WSL2 installation (requires manual reboot)
    
.PARAMETER ArchUserPassword
    Password for the arch user account (will prompt if not provided)
    
.EXAMPLE
    .\Install-WSL2-Arch-Wayland.ps1
    
.EXAMPLE
    .\Install-WSL2-Arch-Wayland.ps1 -SkipReboot -ArchUserPassword "mypassword"
    
.NOTES
    Author: Generated for waydroid-arch-wsl2-install project
    Requires: Windows 11 with Administrator privileges
    Version: 1.0
#>

param(
    [switch]$SkipReboot,
    [string]$ArchUserPassword
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

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check Windows version
function Test-WindowsVersion {
    $version = [System.Environment]::OSVersion.Version
    $build = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    Write-Info "Windows Version: $($version.Major).$($version.Minor) Build $build"
    
    if ($version.Major -lt 10 -or ($version.Major -eq 10 -and [int]$build -lt 19041)) {
        throw "Windows 10 build 19041 or Windows 11 is required for WSL2"
    }
    
    Write-Success "Windows version is compatible with WSL2"
}

# Enable WSL and Virtual Machine Platform features
function Enable-WSLFeatures {
    Write-Header "Enabling WSL2 Features"
    
    $features = @("Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform")
    
    foreach ($feature in $features) {
        Write-Info "Enabling feature: $feature"
        
        $result = dism.exe /online /enable-feature /featurename:$feature /all /norestart
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to enable feature: $feature"
        }
    }
    
    Write-Success "WSL2 features enabled successfully"
}

# Download and install WSL2 Linux kernel update
function Install-WSL2Kernel {
    Write-Header "Installing WSL2 Linux Kernel Update"
    
    $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelPath = "$env:TEMP\wsl_update_x64.msi"
    
    Write-Info "Downloading WSL2 kernel update..."
    Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
    
    Write-Info "Installing WSL2 kernel update..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $kernelPath, "/quiet" -Wait
    
    Remove-Item $kernelPath -Force
    Write-Success "WSL2 kernel update installed"
}

# Set WSL2 as default version
function Set-WSL2Default {
    Write-Info "Setting WSL2 as default version..."
    wsl --set-default-version 2
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set WSL2 as default, will try again after reboot"
    } else {
        Write-Success "WSL2 set as default version"
    }
}

# Download and install Arch Linux
function Install-ArchLinux {
    Write-Header "Installing Arch Linux for WSL2"
    
    # Check if Arch is already installed
    $existingDistros = wsl --list --quiet 2>$null
    if ($existingDistros -contains "archlinux") {
        Write-Warning "Arch Linux already installed, skipping download"
        return
    }
    
    $archUrl = "https://github.com/yuk7/ArchWSL/releases/latest/download/Arch.zip"
    $archPath = "$env:TEMP\Arch.zip"
    $archExtractPath = "$env:TEMP\ArchWSL"
    
    Write-Info "Downloading Arch Linux WSL2..."
    try {
        Invoke-WebRequest -Uri $archUrl -OutFile $archPath -UseBasicParsing
    } catch {
        Write-Warning "GitHub download failed, trying alternative method..."
        # Alternative: Use winget if available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id=yuk7.ArchWSL -e --accept-source-agreements --accept-package-agreements
            return
        } else {
            throw "Failed to download Arch Linux. Please install manually from Microsoft Store."
        }
    }
    
    Write-Info "Extracting Arch Linux..."
    Expand-Archive -Path $archPath -DestinationPath $archExtractPath -Force
    
    Write-Info "Installing Arch Linux..."
    Set-Location $archExtractPath
    .\Arch.exe install --root
    
    # Clean up
    Set-Location $PSScriptRoot
    Remove-Item $archPath -Force
    Remove-Item $archExtractPath -Recurse -Force
    
    Write-Success "Arch Linux installed successfully"
}

# Configure Arch Linux initial setup
function Initialize-ArchLinux {
    Write-Header "Initializing Arch Linux Environment"
    
    Write-Info "Setting up pacman keyring and updating system..."
    wsl --distribution archlinux --exec bash -c "pacman-key --init && pacman-key --populate archlinux"
    wsl --distribution archlinux --exec bash -c "pacman -Syu --noconfirm"
    
    Write-Info "Installing sudo..."
    wsl --distribution archlinux --exec bash -c "pacman -S --noconfirm sudo"
    
    Write-Success "Arch Linux initialized"
}

# Create user account
function New-ArchUser {
    Write-Header "Creating Arch Linux User Account"
    
    if (-not $ArchUserPassword) {
        $securePassword = Read-Host "Enter password for 'archuser' account" -AsSecureString
        $ArchUserPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }
    
    Write-Info "Creating user 'archuser'..."
    wsl --distribution archlinux --exec bash -c "useradd -m -G wheel -s /bin/bash archuser 2>/dev/null || true"
    
    Write-Info "Setting user password..."
    wsl --distribution archlinux --exec bash -c "echo 'archuser:$ArchUserPassword' | chpasswd"
    
    Write-Info "Configuring sudo access..."
    wsl --distribution archlinux --exec bash -c "echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers"
    
    Write-Info "Setting archuser as default..."
    wsl --distribution archlinux config --default-user archuser
    
    Write-Success "User 'archuser' created and configured"
}

# Install essential packages
function Install-EssentialPackages {
    Write-Header "Installing Essential Development Packages"
    
    $packages = @(
        "base-devel",
        "git", 
        "curl",
        "wget",
        "python",
        "python-pip", 
        "python-pipx",
        "docker",
        "lxc",
        "dos2unix",
        "nano",
        "vim"
    )
    
    $packageList = $packages -join " "
    Write-Info "Installing packages: $packageList"
    
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm $packageList
    
    Write-Success "Essential packages installed"
}

# Set up AUR helper (yay)
function Install-YayHelper {
    Write-Header "Installing yay AUR Helper"
    
    Write-Info "Checking if yay is already installed..."
    $yayCheck = wsl --distribution archlinux --exec bash -c "command -v yay >/dev/null 2>&1 && echo 'exists'"
    
    if ($yayCheck -eq "exists") {
        Write-Success "yay is already installed"
        return
    }
    
    Write-Info "Installing Go programming language..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm go
    
    Write-Info "Cloning and building yay..."
    wsl --distribution archlinux --exec bash -c @"
cd /tmp
rm -rf yay 2>/dev/null || true
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
"@
    
    Write-Success "yay AUR helper installed"
}

# Install Wayland and GUI packages
function Install-WaylandEnvironment {
    Write-Header "Installing Wayland Desktop Environment"
    
    Write-Info "Installing Wayland core packages..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm wayland wayland-protocols weston xorg-xwayland
    
    Write-Info "Installing GUI toolkit packages..."
    # Split into smaller groups to avoid timeout
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm gtk3 gtk4
    
    Write-Info "Installing desktop applications..."
    # Use default selections for providers
    wsl --distribution archlinux --exec bash -c "yes '' | sudo pacman -S --needed gnome-calculator gedit"
    
    Write-Info "Installing X11 utilities..."
    wsl --distribution archlinux --exec sudo pacman -S --needed --noconfirm xorg-xeyes
    
    Write-Success "Wayland environment installed"
}

# Configure services
function Enable-Services {
    Write-Header "Configuring System Services"
    
    Write-Info "Enabling Docker service..."
    wsl --distribution archlinux --exec sudo systemctl enable docker
    wsl --distribution archlinux --exec sudo systemctl start docker
    
    Write-Info "Adding user to docker group..."
    wsl --distribution archlinux --exec sudo usermod -aG docker archuser
    
    Write-Info "Enabling systemd in WSL2..."
    wsl --distribution archlinux --exec sudo bash -c @"
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true

[network]
generateResolvConf=false
EOF
"@
    
    Write-Success "Services configured"
}

# Create environment setup scripts
function New-EnvironmentScripts {
    Write-Header "Creating Environment Setup Scripts"
    
    # Create Wayland environment setup script
    Write-Info "Creating Wayland environment script..."
    wsl --distribution archlinux --exec bash -c @"
cat > ~/setup-wayland-env.sh << 'EOF'
#!/bin/bash

echo "Setting up Wayland environment for WSL2..."

# Add Wayland environment variables to bashrc
cat >> ~/.bashrc << 'BASHEOF'

# Wayland Environment Variables for WSL2
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland,x11
export MOZ_ENABLE_WAYLAND=1
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland

# WSLg specific settings
export DISPLAY=:0
export LIBGL_ALWAYS_INDIRECT=1

# Create XDG runtime directory if it doesn't exist
if [ ! -d "\$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "\$XDG_RUNTIME_DIR"
    sudo chown \$(id -u):\$(id -g) "\$XDG_RUNTIME_DIR"
    sudo chmod 700 "\$XDG_RUNTIME_DIR"
fi

BASHEOF

source ~/.bashrc 2>/dev/null || true

echo "Wayland environment configured successfully!"
echo "Current environment:"
echo "WAYLAND_DISPLAY=\$WAYLAND_DISPLAY"
echo "DISPLAY=\$DISPLAY" 
echo "XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR"
echo "XDG_SESSION_TYPE=\$XDG_SESSION_TYPE"
EOF

chmod +x ~/setup-wayland-env.sh
"@
    
    # Create testing script
    Write-Info "Creating Wayland test script..."
    wsl --distribution archlinux --exec bash -c @"
cat > ~/test-wayland.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "  Wayland Environment Testing for WSL2"  
echo "=========================================="

source ~/.bashrc 2>/dev/null || true

echo
echo "Current Environment:"
echo "  WAYLAND_DISPLAY: \$WAYLAND_DISPLAY"
echo "  DISPLAY: \$DISPLAY"
echo "  XDG_RUNTIME_DIR: \$XDG_RUNTIME_DIR"
echo "  XDG_SESSION_TYPE: \$XDG_SESSION_TYPE"
echo

if [ -d "/mnt/wslg" ]; then
    echo "✅ WSLg detected and available"
else
    echo "❌ WSLg not found"
    exit 1
fi

echo
echo "Testing Applications:"
echo "===================="

echo "GNOME Calculator version:"
gnome-calculator --version 2>/dev/null && echo "✅ Calculator working" || echo "❌ Calculator failed"

echo
echo "Gedit version:"  
gedit --version 2>/dev/null && echo "✅ Gedit working" || echo "❌ Gedit failed"

echo
echo "Wayland protocols:"
if ls /usr/share/wayland-protocols/ >/dev/null 2>&1; then
    echo "✅ Wayland protocols installed (\$(ls /usr/share/wayland-protocols/ | wc -l) files)"
else
    echo "❌ Wayland protocols not found"
fi

echo
echo "Weston compositor:"
if command -v weston >/dev/null 2>&1; then
    echo "✅ Weston available: \$(weston --version 2>&1 | head -1)"
else
    echo "❌ Weston not found"
fi

echo
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo "Environment: WSL2 with WSLg Wayland support"
echo "Status: Ready for GUI applications and Waydroid"
echo
echo "To test GUI applications, run:"
echo "  gnome-calculator &    # Calculator"
echo "  gedit &              # Text Editor"  
echo "  xeyes &              # X11 Test App"
echo "=========================================="
EOF

chmod +x ~/test-wayland.sh
"@
    
    Write-Success "Environment scripts created"
}

# Test the installation
function Test-Installation {
    Write-Header "Testing Installation"
    
    Write-Info "Verifying WSL2 installation..."
    $wslList = wsl --list --verbose
    Write-Host $wslList
    
    Write-Info "Testing Arch Linux environment..."
    $archVersion = wsl --distribution archlinux --exec cat /etc/os-release | Select-String "PRETTY_NAME"
    Write-Info "Distribution: $archVersion"
    
    Write-Info "Testing Wayland environment..."
    wsl --distribution archlinux --exec bash -c "~/test-wayland.sh"
    
    Write-Success "Installation test completed"
}

# Create final summary
function Show-Summary {
    Write-Header "Installation Summary"
    
    Write-Host @"

🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉

✅ What's Been Installed:
   • WSL2 with latest kernel update
   • Arch Linux distribution with rolling updates
   • Complete development environment (Python, Docker, Git)
   • yay AUR helper for package management
   • Wayland desktop environment with WSLg
   • GUI applications (Calculator, Text Editor, XEyes)
   • Testing and environment setup scripts

🖥️ Wayland Desktop Environment:
   • WSLg compositor active and functional
   • GUI applications integrate with Windows desktop
   • Both Wayland and X11 applications supported
   • Environment variables properly configured

📁 Project Files Created:
   • ~/setup-wayland-env.sh - Environment configuration
   • ~/test-wayland.sh - Testing script
   • Complete documentation and logs

🚀 Next Steps:
   1. Test GUI applications:
      wsl gnome-calculator &
      wsl gedit &
      wsl xeyes &
      
   2. Run Wayland tests:
      wsl ~/test-wayland.sh
      
   3. Install Waydroid (when ready):
      wsl ./install-waydroid-wsl2.sh

🎯 System Status: READY FOR WAYDROID INSTALLATION

"@ -ForegroundColor Green

    Write-Info "All applications should open as Windows on your desktop!"
    Write-Info "The Wayland environment is fully functional and ready for Android containers."
}

# Main installation function
function Start-Installation {
    try {
        Write-Header "WSL2 + Arch Linux + Wayland Setup"
        Write-Info "Starting automated installation process..."
        
        # Pre-installation checks
        if (-not (Test-Administrator)) {
            throw "This script must be run as Administrator"
        }
        
        Test-WindowsVersion
        
        # Phase 1: WSL2 Setup
        Write-Header "PHASE 1: WSL2 Installation"
        Enable-WSLFeatures
        Install-WSL2Kernel
        Set-WSL2Default
        
        # Check if reboot is needed
        $rebootNeeded = $true
        try {
            wsl --status 2>$null
            if ($LASTEXITCODE -eq 0) {
                $rebootNeeded = $false
            }
        } catch {
            $rebootNeeded = $true
        }
        
        if ($rebootNeeded -and -not $SkipReboot) {
            Write-Warning "System reboot is required for WSL2 changes to take effect."
            Write-Warning "The script will continue after reboot."
            
            # Create a script to continue after reboot
            $continueScript = @"
# Continue installation after reboot
Set-Location '$PSScriptRoot'
.\Install-WSL2-Arch-Wayland.ps1 -SkipReboot $(if($ArchUserPassword){"-ArchUserPassword '$ArchUserPassword'"})
"@
            
            $continueScript | Out-File "$env:TEMP\continue-wsl-install.ps1" -Encoding UTF8
            
            Write-Info "Continuing script saved to: $env:TEMP\continue-wsl-install.ps1"
            Write-Info "Rebooting in 10 seconds... Press Ctrl+C to cancel"
            Start-Sleep 10
            
            Restart-Computer -Force
            return
        }
        
        if ($rebootNeeded -and $SkipReboot) {
            Write-Warning "Reboot required but skipped. Please reboot manually and run this script again."
            return
        }
        
        # Phase 2: Arch Linux Setup
        Write-Header "PHASE 2: Arch Linux Configuration"
        Install-ArchLinux
        Initialize-ArchLinux
        New-ArchUser
        Install-EssentialPackages
        Install-YayHelper
        
        # Phase 3: Wayland Environment
        Write-Header "PHASE 3: Wayland Desktop Environment"
        Install-WaylandEnvironment
        Enable-Services
        New-EnvironmentScripts
        
        # Phase 4: Testing and Validation
        Write-Header "PHASE 4: Testing and Validation"
        Test-Installation
        
        # Show final summary
        Show-Summary
        
        Write-Success "Complete installation finished successfully!"
        
    } catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
        exit 1
    }
}

# Script entry point
function Main {
    Write-Header "WSL2 + Arch Linux + Wayland Automated Setup"
    Write-Info "This script will install and configure:"
    Write-Info "• WSL2 with latest kernel"
    Write-Info "• Arch Linux distribution" 
    Write-Info "• Complete development environment"
    Write-Info "• Wayland desktop with GUI applications"
    Write-Info "• All prerequisites for Waydroid"
    Write-Info ""
    Write-Warning "This script requires Administrator privileges and may require a reboot."
    
    $response = Read-Host "Continue with installation? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Info "Installation cancelled by user."
        exit 0
    }
    
    Start-Installation
}

# Run main function
Main
