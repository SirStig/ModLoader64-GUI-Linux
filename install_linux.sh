#!/bin/bash

# ModLoader64-GUI Linux Installer & Fixer

echo "ModLoader64-GUI Linux Installer"
echo "==============================="

# Detect Package Manager
if command -v dnf >/dev/null; then
    PKG_MANAGER="dnf"
elif command -v apt >/dev/null; then
    PKG_MANAGER="apt"
elif command -v pacman >/dev/null; then
    PKG_MANAGER="pacman"
fi

echo "Detected Package Manager: $PKG_MANAGER"

# Install Dependencies (Basic check, might need sudo)
echo "Checking for dependencies..."
if [ "$PKG_MANAGER" = "dnf" ]; then
    # Fedora/RHEL
    # FORCE 64-bit packages. Added SFML for audio/input support.
    sudo dnf install -y glew.x86_64 libappindicator-gtk3.x86_64 libXScrnSaver.x86_64 speexdsp.x86_64 SFML.x86_64
elif [ "$PKG_MANAGER" = "apt" ]; then
    # Debian/Ubuntu
    sudo apt update
    sudo apt install -y glew-utils libglew-dev libappindicator3-1 libxss1 libspeexdsp1 libsfml-dev
elif [ "$PKG_MANAGER" = "pacman" ]; then
    # Arch/SteamOS
    sudo pacman -S --noconfirm glew libappindicator-gtk3 speexdsp sfml
fi

# Clean up old fixes to prevent stale symlinks
rm -rf ./libs
mkdir -p ./libs

# --- GLEW Fix ---
echo "Checking for GLEW..."

GLEW_PATH=""
# Try finding specific 64-bit paths first
for search_path in /usr/lib64 /usr/lib/x86_64-linux-gnu /lib64 /usr/lib; do
    if [ -d "$search_path" ]; then
        FOUND=$(find "$search_path" -maxdepth 1 -name "libGLEW.so*" 2>/dev/null | grep -v "libGLEW.so.2.1" | head -n 1)
        if [ -n "$FOUND" ] && [ -e "$FOUND" ]; then
            GLEW_PATH="$FOUND"
            break
        fi
    fi
done

if [ -z "$GLEW_PATH" ]; then
    echo "WARNING: Could not find any system libGLEW. Please ensure it is installed."
else
    echo "Found system GLEW at: $GLEW_PATH"
    echo "Creating compatibility symlink for libGLEW.so.2.1..."
    ln -sf "$GLEW_PATH" ./libs/libGLEW.so.2.1
fi

# --- SFML Fix (2.5 Compatibility) ---
echo "Checking for SFML..."
# Map of required libraries to look for
SFML_LIBS=("libsfml-system.so" "libsfml-audio.so" "libsfml-graphics.so" "libsfml-window.so" "libsfml-network.so")

for lib in "${SFML_LIBS[@]}"; do
    TARGET_NAME="${lib}.2.5"
    FOUND_LIB=""
    
    # Search for any version of this lib (e.g., .2.6) in 64-bit paths
    for search_path in /usr/lib64 /usr/lib/x86_64-linux-gnu /lib64 /usr/lib; do
        if [ -d "$search_path" ]; then
            # Find the library (e.g., libsfml-system.so.2.6)
            FOUND=$(find "$search_path" -maxdepth 1 -name "${lib}*" 2>/dev/null | head -n 1)
            if [ -n "$FOUND" ] && [ -e "$FOUND" ]; then
                FOUND_LIB="$FOUND"
                break
            fi
        fi
    done

    if [ -n "$FOUND_LIB" ]; then
        echo "Found $lib at: $FOUND_LIB"
        # Always symlink to .2.5 to satisfy the requirement
        echo "Creating compatibility symlink for $TARGET_NAME..."
        ln -sf "$FOUND_LIB" "./libs/$TARGET_NAME"
    else
        echo "WARNING: Could not find system $lib. Audio/Input might fail."
    fi
done

chmod +x start_linux.sh

# Generate .desktop file
echo "Generating .desktop file..."
CURRENT_DIR=$(pwd)
ICON_PATH="$CURRENT_DIR/resources/ml64.png"

if [ ! -f "$ICON_PATH" ]; then
    if [ -f "$CURRENT_DIR/ml64.png" ]; then
        ICON_PATH="$CURRENT_DIR/ml64.png"
    fi
fi

cat > ModLoader64-GUI.desktop << EOF
[Desktop Entry]
Name=ModLoader64 GUI
Comment=Play N64 mods the modern way!
Exec="$CURRENT_DIR/start_linux.sh"
Path=$CURRENT_DIR
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Game;Network;
StartupNotify=true
EOF

chmod +x ModLoader64-GUI.desktop

echo "Installation complete!"
echo "IMPORTANT: Move 'start_linux.sh', 'libs', and 'ModLoader64-GUI.desktop' to your ModLoader folder if they aren't there already."
echo "Run ./start_linux.sh to start the application."
