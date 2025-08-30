# PowerShell Automation Scripts

This directory contains comprehensive PowerShell scripts that automate the entire WSL2 + Arch Linux + Wayland setup process from scratch.

## 📁 Available Scripts

### 🚀 `Install-WSL2-Arch-Wayland.ps1` - Complete Setup from Scratch
**Full automation script that installs everything from zero to fully working Wayland desktop environment.**

**What it does:**
- ✅ Enables WSL2 Windows features
- ✅ Downloads and installs WSL2 kernel update
- ✅ Downloads and installs Arch Linux distribution
- ✅ Configures complete development environment
- ✅ Sets up Wayland desktop with WSLg
- ✅ Installs and tests GUI applications
- ✅ Creates all helper scripts and testing tools

**Requirements:**
- Windows 11 (or Windows 10 build 19041+)
- Administrator privileges
- Internet connection
- ~5GB free disk space

**Usage:**
```powershell
# Run as Administrator
.\Install-WSL2-Arch-Wayland.ps1

# With options
.\Install-WSL2-Arch-Wayland.ps1 -SkipReboot -ArchUserPassword "mypassword"
```

---

### 🔧 `Setup-Arch-Wayland.ps1` - Arch Linux + Wayland Setup
**For users who already have WSL2 installed and want to add Arch Linux + Wayland environment.**

**What it does:**
- ✅ Installs Arch Linux distribution (if not present)
- ✅ Configures complete development stack
- ✅ Sets up Wayland desktop environment
- ✅ Installs GUI applications and testing tools
- ✅ Optimizes WSL2 configuration

**Requirements:**
- WSL2 already installed and working
- Administrator privileges
- Internet connection

**Usage:**
```powershell
# Run as Administrator  
.\Setup-Arch-Wayland.ps1

# With options
.\Setup-Arch-Wayland.ps1 -ArchUserPassword "mypassword" -ForceReinstall
```

---

### 🧪 `Test-Wayland-Setup.ps1` - Quick Environment Test
**Quick testing script to verify if your current setup is working correctly.**

**What it does:**
- ✅ Tests WSL2 status and Arch Linux availability
- ✅ Verifies development tools (Python, Docker, Git, yay)
- ✅ Checks Wayland environment configuration
- ✅ Tests GUI applications with live GUI tests
- ✅ Provides clear pass/fail results and next steps

**Requirements:**
- Existing WSL2 + Arch Linux setup
- No administrator privileges needed (read-only)

**Usage:**
```powershell
# Can run as regular user
.\Test-Wayland-Setup.ps1
```

---

## 🎯 Which Script Should You Use?

### 🆕 **New to WSL2? Start Here:**
```powershell
# Complete setup from scratch (requires reboot)
.\Install-WSL2-Arch-Wayland.ps1
```

### 🔄 **Have WSL2, Need Arch + Wayland:**
```powershell
# Add Arch Linux and Wayland to existing WSL2
.\Setup-Arch-Wayland.ps1
```

### ✅ **Want to Test Current Setup:**
```powershell
# Quick test without making changes
.\Test-Wayland-Setup.ps1
```

---

## 📋 What Gets Installed

### **System Components:**
- WSL2 with latest kernel update
- Arch Linux distribution (rolling release)
- systemd support in WSL2
- Optimized WSL2 configuration

### **Development Environment:**
- **Python 3.13.7** with pip and pipx
- **Docker 28.3.3** with WSL2 integration
- **Git** version control system
- **yay 12.5.0** AUR helper (compiled from source)
- **Go 1.24.6** programming language
- **base-devel** compilation tools

### **Wayland Desktop Environment:**
- **WSLg** - Native Windows 11 Wayland compositor
- **Wayland protocols** and libraries
- **Weston 14.0.2** - Backup Wayland compositor
- **XWayland** - X11 application compatibility
- **Environment variables** properly configured

### **GUI Applications:**
- **GNOME Calculator 48.1** - Calculator app
- **Gedit 48.2** - Text editor
- **Firefox 142.0.1** - Web browser
- **XEyes** - X11 test application
- **GTK3/GTK4** - GUI toolkit support

### **Helper Scripts Created:**
- `~/setup-wayland-env.sh` - Environment configuration
- `~/test-wayland.sh` - Basic Wayland testing
- `~/test-complete-setup.sh` - Comprehensive system test

---

## 🚀 Quick Start Guide

### **Option 1: Complete Automated Setup**
```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to project directory
cd C:\Users\luis\workspace\waydroid-arch-wsl2-install

# 3. Run complete setup
.\Install-WSL2-Arch-Wayland.ps1

# 4. Follow prompts and wait for reboot (if needed)
# 5. Script will continue automatically after reboot
```

### **Option 2: Existing WSL2 Setup**
```powershell
# 1. Open PowerShell as Administrator  
# 2. Run Arch + Wayland setup
.\Setup-Arch-Wayland.ps1

# 3. Test when complete
.\Test-Wayland-Setup.ps1
```

---

## 🧪 Testing Your Installation

After running any setup script, test your environment:

```powershell
# Quick test
.\Test-Wayland-Setup.ps1

# Or test GUI applications directly
wsl gnome-calculator &    # Should open Calculator in Windows
wsl gedit &              # Should open Text Editor in Windows
wsl firefox &            # Should open Firefox in Windows
```

**Expected Result:** Applications should appear as native Windows on your desktop!

---

## 🛠️ Troubleshooting

### **Common Issues:**

1. **"Script cannot be loaded" Error:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **WSL2 Installation Fails:**
   - Ensure virtualization is enabled in BIOS
   - Check Windows version (need 19041+ or Windows 11)
   - Run Windows Update

3. **Arch Linux Download Fails:**
   - Script will try winget as fallback
   - Manually install from Microsoft Store if needed

4. **GUI Applications Don't Open:**
   - Check if WSLg is installed: `wsl ls /mnt/wslg`
   - Restart WSL2: `wsl --shutdown` then restart
   - Run environment setup: `wsl ~/setup-wayland-env.sh`

5. **Permission Errors:**
   - Ensure PowerShell is running as Administrator
   - Check Windows defender/antivirus blocking scripts

---

## 🔧 Script Parameters

### **Install-WSL2-Arch-Wayland.ps1 Parameters:**
- `-SkipReboot` - Skip automatic reboot (manual reboot required)
- `-ArchUserPassword "password"` - Set password for archuser account

### **Setup-Arch-Wayland.ps1 Parameters:**
- `-ArchUserPassword "password"` - Set password for archuser account  
- `-ForceReinstall` - Force reinstallation of Arch Linux

### **Test-Wayland-Setup.ps1 Parameters:**
- No parameters - runs read-only tests

---

## 📊 Success Indicators

After successful installation, you should see:

✅ **WSL2 Status:** `archlinux Running 2`  
✅ **Wayland Display:** `WAYLAND_DISPLAY=wayland-0`  
✅ **WSLg Available:** `/mnt/wslg directory exists`  
✅ **GUI Apps Working:** Applications open as Windows  
✅ **Development Tools:** Python, Docker, Git, yay all functional  

---

## 🎯 Next Steps After Installation

1. **Test GUI Applications:**
   ```powershell
   wsl gnome-calculator &
   wsl gedit &
   wsl firefox &
   ```

2. **Run Comprehensive Test:**
   ```powershell
   wsl ~/test-complete-setup.sh
   ```

3. **Install Waydroid:**
   ```powershell
   wsl ./install-waydroid-wsl2.sh
   ```

4. **Explore Your New Environment:**
   - All GUI applications integrate seamlessly with Windows
   - Use AUR packages with `wsl yay -S package-name`
   - Docker containers work natively
   - Full development environment ready

---

## 📝 Notes

- **Execution Policy:** Scripts may require setting PowerShell execution policy
- **Reboots:** Complete setup may require one reboot for WSL2 features
- **Internet:** All scripts require internet connection for downloads
- **Time:** Complete setup takes 15-30 minutes depending on internet speed
- **Space:** Requires ~5GB disk space for complete installation

---

**🎉 Ready to transform your Windows into a complete Linux development environment with GUI support!**
