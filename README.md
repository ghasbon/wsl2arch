# Waydroid on Arch Linux WSL2

A comprehensive installation guide and automated script for running Waydroid (Android container) on Arch Linux within WSL2.

## 🚀 Quick Start

```bash
# Make the script executable
chmod +x install-waydroid-wsl2.sh

# Run the installation script
./install-waydroid-wsl2.sh
```

## 📋 Prerequisites

- **Windows 10/11** with WSL2 enabled
- **Arch Linux** distribution installed in WSL2
- **Minimum 4GB RAM** (8GB+ recommended)
- **10GB+ free disk space** (for Android system images)
- **Administrator privileges** on Windows

### WSL2 Setup

1. Enable WSL2 on Windows:
```powershell
# Run as Administrator
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

2. Install Arch Linux WSL2:
   - Download from Microsoft Store or use [ArchWSL](https://github.com/yuk7/ArchWSL)

3. Set WSL2 as default:
```powershell
wsl --set-default-version 2
```

## 🔧 Manual Installation Steps

If you prefer to install manually, follow these steps:

### 1. Update System
```bash
sudo pacman -Syu --noconfirm
```

### 2. Install Essential Packages
```bash
sudo pacman -S --needed --noconfirm \
    base-devel git curl wget python python-pip python-pipx \
    docker lxc linux-headers dkms
```

### 3. Install AUR Helper (yay)
```bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
```

### 4. Install Waydroid Dependencies
```bash
sudo pacman -S --needed --noconfirm \
    wayland weston python-gbinder python-pygobject \
    lxc sqlite dnsmasq gtk3 gobject-introspection \
    python-gobject nftables dbus systemd

# Install Waydroid from AUR
yay -S --noconfirm waydroid
```

### 5. Configure Services
```bash
sudo systemctl enable --now systemd-resolved
sudo systemctl enable --now dbus
sudo systemctl enable --now docker
```

### 6. Enable systemd in WSL2
```bash
sudo tee /etc/wsl.conf > /dev/null << EOF
[boot]
systemd=true

[network]
generateResolvConf=false
EOF
```

**Important:** Restart WSL2 after this step:
```powershell
wsl --shutdown
```

### 7. Initialize Waydroid
```bash
sudo waydroid init
```

## 🎮 Usage

### Starting Waydroid

1. **Using the provided startup script:**
```bash
~/start-waydroid.sh
```

2. **Manual startup:**
```bash
# Start Waydroid session
waydroid session start &

# Show Waydroid UI
waydroid show-full-ui
```

### Common Waydroid Commands

```bash
# Initialize Waydroid (first time only)
sudo waydroid init

# Start session in background
waydroid session start

# Stop session
waydroid session stop

# Show full UI
waydroid show-full-ui

# Install APK
waydroid app install /path/to/app.apk

# Launch specific app
waydroid app launch com.example.app

# Get shell access
waydroid shell

# Check status
waydroid status
```

## 📁 Project Structure

```
waydroid-arch-wsl2-install/
├── install-waydroid-wsl2.sh      # Main installation script
├── project-actions-log.md        # Development actions log
├── README.md                     # This documentation
└── logs/                         # Installation logs (created during run)
```

## ⚠️ Known Issues & Limitations

### WSL2 Limitations
- **Kernel Modules:** WSL2 uses a custom kernel that might not support all Android container requirements
- **Graphics:** Limited GPU acceleration support
- **Hardware Access:** Restricted access to hardware features (camera, sensors, etc.)
- **Network:** NAT networking can cause connectivity issues with some apps

### Common Problems

1. **Waydroid fails to start:**
   ```bash
   # Check required kernel modules
   lsmod | grep -E 'binder|ashmem'
   
   # If missing, WSL2 kernel might not support them
   ```

2. **Graphics/Display issues:**
   - WSL2 has limited display server support
   - Consider using X11 forwarding or WSLg

3. **Performance issues:**
   - Ensure adequate RAM allocation to WSL2
   - Close unnecessary Windows applications

## 🛠️ Troubleshooting

### Check WSL2 Configuration
```bash
# Verify WSL2 version
wsl --list --verbose

# Check systemd status
systemctl --version
```

### Waydroid Diagnostics
```bash
# Check Waydroid status
waydroid status

# View logs
journalctl -u waydroid-container
sudo dmesg | grep waydroid
```

### Service Issues
```bash
# Restart services
sudo systemctl restart systemd-resolved
sudo systemctl restart dbus

# Check service status
systemctl status waydroid-container
```

## 🔄 Alternative Solutions

If Waydroid doesn't work in your WSL2 environment, consider these alternatives:

1. **Android Studio Emulator** with WSL2 support
2. **Genymotion** with VirtualBox
3. **Docker-based Android containers** (anbox-cloud)
4. **Native Windows Android emulators** (BlueStacks, NoxPlayer)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙋‍♂️ Support

- **Issues:** Create an issue on GitHub
- **Discussions:** Use GitHub Discussions for questions
- **Waydroid Official:** [Waydroid Documentation](https://docs.waydro.id/)
- **Arch Linux:** [Arch Wiki](https://wiki.archlinux.org/)

## 📚 References

- [Waydroid Official Website](https://waydro.id/)
- [Waydroid GitHub Repository](https://github.com/waydroid/waydroid)
- [Arch Linux WSL2 Setup](https://wiki.archlinux.org/title/WSL)
- [WSL2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)

---

**Note:** This project is experimental and may not work on all WSL2 configurations due to kernel limitations. Results may vary based on your specific Windows and WSL2 setup.
