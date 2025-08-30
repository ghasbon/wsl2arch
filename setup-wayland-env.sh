#!/bin/bash

# Wayland Environment Setup for WSL2
# This script configures the proper environment variables for Wayland applications

echo "Setting up Wayland environment for WSL2..."

# Add Wayland environment variables to bashrc
cat >> ~/.bashrc << 'EOF'

# Wayland Environment Variables for WSL2
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
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
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "$XDG_RUNTIME_DIR"
    sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
    sudo chmod 700 "$XDG_RUNTIME_DIR"
fi

EOF

# Source the new environment
source ~/.bashrc

echo "Wayland environment configured successfully!"
echo "Applications will now prefer Wayland when available."

# Test the environment
echo "Current environment:"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "DISPLAY=$DISPLAY" 
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
