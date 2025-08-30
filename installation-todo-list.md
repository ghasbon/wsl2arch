# WSL2 + Arch Linux + Waydroid Installation Todo List

This document outlines the complete process for installing WSL2, Arch Linux, testing GUI functionality, and installing Waydroid on Windows 11.

## Phase 1: WSL2 Setup

### 1. Enable WSL and Virtual Machine Platform features
- [ ] Use PowerShell as administrator to enable WSL and Virtual Machine Platform features required for WSL2
- [ ] This requires a system restart
- **Commands to run:**
  ```powershell
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
  ```

### 2. Install WSL2 and set as default version
- [ ] Download and install the WSL2 Linux kernel update package
- [ ] Set WSL2 as the default version for new distributions
- **Commands to run:**
  ```powershell
  wsl --update
  wsl --set-default-version 2
  ```

### 3. Install Arch Linux on WSL2
- [ ] Download and install Arch Linux WSL distribution (ArchWSL or similar)
- [ ] Alternatively, manually import an Arch Linux rootfs if needed
- **Options:**
  - Install from Microsoft Store (if available)
  - Download ArchWSL from GitHub releases
  - Manual rootfs import

### 4. Configure Arch Linux basic setup
- [ ] Set up user account
- [ ] Update package manager (pacman)
- [ ] Install essential packages
- [ ] Configure basic system settings in the Arch installation
- **Commands to run in Arch:**
  ```bash
  pacman -Syu
  pacman -S base-devel git wget curl
  ```

## Phase 2: GUI Testing

### 5. Research and install X server for Windows
- [ ] Investigate X server options for Windows:
  - VcXsrv (free, open source)
  - Xming (free version available)
  - X410 (paid, Microsoft Store)
- [ ] Install and configure the chosen X server
- [ ] Configure firewall rules if needed

### 6. Research Wayland native implementations for Windows
- [ ] Investigate Wayland compositor options that work with WSL2 on Windows
- [ ] Options to explore:
  - Weston
  - Other native Wayland solutions
  - WSLg (Windows Subsystem for Linux GUI) - built-in option

### 7. Install GUI desktop environment in Arch
- [ ] Install a lightweight desktop environment or window manager
- **Options:**
  - XFCE (lightweight, stable)
  - i3 (tiling window manager)
  - GNOME (full-featured)
  - KDE Plasma (full-featured)
- **Sample commands:**
  ```bash
  # For XFCE
  pacman -S xfce4 xfce4-goodies
  
  # For i3
  pacman -S i3-wm i3status dmenu
  ```

### 8. Test GUI functionality with X server
- [ ] Configure DISPLAY variable in WSL2
- [ ] Test X11 forwarding with simple GUI applications
- [ ] Verify X server setup works
- **Test commands:**
  ```bash
  export DISPLAY=:0
  pacman -S xorg-xclock xorg-xeyes
  xclock &
  xeyes &
  ```

### 9. Test GUI functionality with Wayland (if available)
- [ ] If Wayland compositor is available, configure it
- [ ] Test native Wayland applications
- [ ] Verify Wayland functionality works from WSL2

## Phase 3: Waydroid Installation

### 10. Install Waydroid dependencies in Arch
- [ ] Install required packages for Waydroid
- **Dependencies to install:**
  ```bash
  pacman -S python lxc dnsmasq iptables-nft
  pacman -S linux-headers # if available in WSL2
  ```

### 11. Install Waydroid in Arch Linux
- [ ] Install Waydroid from AUR or compile from source
- [ ] Configure Waydroid for the WSL2 environment
- **Commands:**
  ```bash
  # Install yay (AUR helper) first
  git clone https://aur.archlinux.org/yay.git
  cd yay && makepkg -si
  
  # Install Waydroid
  yay -S waydroid
  ```

### 12. Configure Waydroid for WSL2 environment
- [ ] Set up Waydroid configuration
- [ ] Handle potential networking issues
- [ ] Configure any WSL2-specific settings needed for Android container
- [ ] May need to configure kernel modules or use alternative container runtime

### 13. Test Waydroid functionality
- [ ] Initialize Waydroid
- [ ] Download Android images
- [ ] Start Waydroid session
- [ ] Test basic Android functionality including app installation and GUI rendering
- **Commands:**
  ```bash
  waydroid init
  waydroid session start
  waydroid show-full-ui
  ```

### 14. Document the complete setup process
- [ ] Create documentation of all steps
- [ ] Note configurations used
- [ ] Record troubleshooting notes for future reference
- [ ] Consider creating automation scripts

## Important Notes

- **System Requirements:** Windows 11 with virtualization support enabled in BIOS
- **Restart Required:** After enabling WSL features
- **Administrator Access:** Required for initial Windows feature enabling
- **Potential Issues:** 
  - Waydroid may have limitations in WSL2 due to kernel constraints
  - GPU acceleration may be limited
  - Some Android features may not work properly in containerized environment

## Useful Resources

- [Microsoft WSL2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [ArchWSL GitHub Repository](https://github.com/yuk7/ArchWSL)
- [Waydroid Official Documentation](https://docs.waydro.id/)
- [WSLg Documentation](https://github.com/microsoft/wslg)

---
*Generated on: 2025-08-29*
