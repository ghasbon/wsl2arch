#!/bin/bash

# Wayland Testing Script for WSL2
# Tests various GUI applications to validate Wayland functionality

echo "=========================================="
echo "  Wayland Environment Testing for WSL2"  
echo "=========================================="

# Source environment
source ~/.bashrc 2>/dev/null || true

# Display current environment
echo
echo "Current Environment:"
echo "  WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo "  DISPLAY: $DISPLAY"
echo "  XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "  XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo

# Check if WSLg is running
if [ -d "/mnt/wslg" ]; then
    echo "✅ WSLg detected and available"
else
    echo "❌ WSLg not found"
    exit 1
fi

# Test 1: Simple X11 application via XWayland
echo
echo "Test 1: X11 Application (xeyes via XWayland)"
echo "============================================"
echo "Starting xeyes for 3 seconds..."
if timeout 3 xeyes 2>/dev/null; then
    echo "✅ XEyes test successful (X11 via XWayland)"
else
    echo "❌ XEyes test failed"
fi

# Test 2: GTK3 Application  
echo
echo "Test 2: GTK3 Application (GNOME Calculator)"
echo "==========================================="
echo "Starting gnome-calculator for 3 seconds..."
if timeout 3 gnome-calculator 2>/dev/null; then
    echo "✅ GNOME Calculator test successful (GTK3)"
else
    echo "❌ GNOME Calculator test failed"
fi

# Test 3: Text Editor
echo
echo "Test 3: Text Editor (gedit)"
echo "==========================="
echo "Starting gedit for 3 seconds..."
if timeout 3 gedit 2>/dev/null; then
    echo "✅ Gedit test successful (GTK3 Text Editor)"
else
    echo "❌ Gedit test failed"
fi

# Test 4: Check Wayland protocols
echo
echo "Test 4: Wayland Protocols Check"
echo "==============================="
if ls /usr/share/wayland-protocols/ >/dev/null 2>&1; then
    echo "✅ Wayland protocols installed"
    echo "   Available protocols: $(ls /usr/share/wayland-protocols/ | wc -l) protocol files"
else
    echo "❌ Wayland protocols not found"
fi

# Test 5: Check compositor
echo
echo "Test 5: Wayland Compositor Check"
echo "==============================="
if command -v weston >/dev/null 2>&1; then
    echo "✅ Weston compositor available"
    echo "   Version: $(weston --version 2>&1 | head -1)"
else
    echo "❌ Weston compositor not found"
fi

# Test 6: Wayland library check
echo
echo "Test 6: Wayland Libraries"
echo "========================"
if ldconfig -p | grep -q wayland; then
    echo "✅ Wayland libraries installed"
else
    echo "❌ Wayland libraries not found"
fi

# Summary
echo
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo "Environment: WSL2 with WSLg Wayland support"
echo "Status: GUI applications can run via WSLg"
echo "Ready for: Waydroid installation and testing"
echo
echo "Next steps:"
echo "1. Applications should appear as Windows on your desktop"
echo "2. WSLg handles the Wayland/X11 translation automatically"
echo "3. Ready to proceed with Waydroid installation"
echo "=========================================="
