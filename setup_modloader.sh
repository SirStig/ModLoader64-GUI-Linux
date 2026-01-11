#!/bin/bash

# =============================================================================
# ModLoader64 Full Auto-Setup for Linux / Steam Deck
# =============================================================================

# --- 1. Terminal Auto-Launch Wrapper ---
if [ ! -t 0 ]; then
    echo "Launching terminal..."
    if command -v konsole >/dev/null; then
        konsole --hold -e "$0" "$@"
        exit 0
    elif command -v gnome-terminal >/dev/null; then
        gnome-terminal -- "$0" "$@"
        exit 0
    elif command -v xterm >/dev/null; then
        xterm -hold -e "$0" "$@"
        exit 0
    else
        if command -v zenity >/dev/null; then
            zenity --error --text="Could not find a terminal emulator. Please run via terminal."
        fi
        exit 1
    fi
fi

# =============================================================================

echo "ModLoader64 Linux Setup Wizard"
echo "------------------------------"
echo "This script will:"
echo "1. Download ModLoader64"
echo "2. Install System Dependencies (requires sudo)"
echo "3. Fix known crashes (GLEW/SFML)"
echo "4. (Optional) Install 3DS Style Texture Pack"
echo "5. Create Desktop Shortcuts"
echo ""

APP_URL="https://github.com/hylian-modding/ModLoader64-GUI/releases/download/v1.1.60/modloader64-gui-1.1.60.tar.gz"
TEXTURE_PACK_URL="https://files.emulationking.com/n64/texturepacks/oot/Djipi_Zelda_3DS_2016_GlideN64%28HTC%29.zip"
INSTALL_DIR="$(pwd)/ModLoader64_Install"

echo "Installation Directory: $INSTALL_DIR"
read -p "Press Enter to begin..."

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# --- 2. Download & Extract ModLoader ---
if [ ! -d "ModLoader" ]; then
    echo "Downloading ModLoader64..."
    wget -O ml64.tar.gz "$APP_URL"
    if [ $? -ne 0 ]; then
        echo "Error downloading ModLoader64."
         exit 1 
    fi
    
    echo "Extracting..."
    tar -xzf ml64.tar.gz
    rm ml64.tar.gz
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "modloader64-gui*" | head -n 1)
    if [ -n "$EXTRACTED_DIR" ]; then
        mv "$EXTRACTED_DIR"/* .
        rmdir "$EXTRACTED_DIR"
    fi
else
    echo "ModLoader folder detected, skipping download."
fi

# --- 3. Install Dependencies ---
echo "--- Installing Dependencies ---"
if command -v dnf >/dev/null; then
    sudo dnf install -y glew.x86_64 libappindicator-gtk3.x86_64 libXScrnSaver.x86_64 speexdsp.x86_64 SFML.x86_64
elif command -v apt >/dev/null; then
    sudo apt update
    sudo apt install -y glew-utils libglew-dev libappindicator3-1 libxss1 libspeexdsp1 libsfml-dev
elif command -v pacman >/dev/null; then
    # SteamOS / Arch Linux Detection
    IS_STEAMOS=false
    if grep -q "SteamOS" /etc/os-release; then
        IS_STEAMOS=true
        echo "Detected SteamOS."
        
        # 1. Disable Read-Only
        echo "Disabling SteamOS Read-Only File System..."
        sudo steamos-readonly disable
        
        # 2. Fix Database Lock
        if [ -f "/var/lib/pacman/db.lck" ]; then
            echo "Removing stale pacman database lock..."
            sudo rm /var/lib/pacman/db.lck
        fi
        
        # 3. Initialize Keys (Common issue on Deck)
        echo "Initializing Pacman Keys (this may take a moment)..."
        sudo pacman-key --init
        sudo pacman-key --populate archlinux holo
    fi

    echo "Updating Package Database & Installing Dependencies..."
    # -Sy fixes issues where local DB is out of sync causing 404s
    # --needed prevents reinstalling existing packages
    if [ "$IS_STEAMOS" = true ]; then
        sudo pacman -Sy --noconfirm --needed glew libappindicator-gtk3 speexdsp sfml sdl2_image libxscrnsaver unzip
    else
        # Standard Arch
        sudo pacman -Sy --noconfirm --needed glew libappindicator-gtk3 speexdsp sfml sdl2_image libxscrnsaver unzip
    fi
fi

# --- 4. Apply Fixes (GLEW/SFML) ---
echo "--- Applying Compatibility Fixes ---"
mkdir -p ./libs
rm -f ./libs/libGLEW.so.2.1 ./libs/libsfml*

# GLEW
GLEW_PATH=""
for search_path in /usr/lib64 /usr/lib/x86_64-linux-gnu /lib64 /usr/lib; do
    if [ -d "$search_path" ]; then
        FOUND=$(find "$search_path" -maxdepth 1 -name "libGLEW.so*" 2>/dev/null | grep -v "libGLEW.so.2.1" | head -n 1)
        if [ -n "$FOUND" ] && [ -e "$FOUND" ]; then
            GLEW_PATH="$FOUND"
            break
        fi
    fi
done
if [ -n "$GLEW_PATH" ]; then
    ln -sf "$GLEW_PATH" ./libs/libGLEW.so.2.1
    echo "Fixed GLEW: $GLEW_PATH"
fi

# SFML
SFML_LIBS=("libsfml-system.so" "libsfml-audio.so" "libsfml-graphics.so" "libsfml-window.so" "libsfml-network.so")
for lib in "${SFML_LIBS[@]}"; do
    TARGET_NAME="${lib}.2.5"
    FOUND_LIB=""
    for search_path in /usr/lib64 /usr/lib/x86_64-linux-gnu /lib64 /usr/lib; do
        if [ -d "$search_path" ]; then
            FOUND=$(find "$search_path" -maxdepth 1 -name "${lib}*" 2>/dev/null | head -n 1)
            if [ -n "$FOUND" ] && [ -e "$FOUND" ]; then
                FOUND_LIB="$FOUND"
                break
            fi
        fi
    done
    if [ -n "$FOUND_LIB" ]; then
        ln -sf "$FOUND_LIB" "./libs/$TARGET_NAME"
        echo "Fixed SFML: $lib"
    fi
done

# --- 5. Texture Pack Setup (Optional) ---
echo ""
read -p "Do you want to download and install the OOT 3DS Texture Pack? (y/n): " INSTALL_TEXTURES

if [[ "$INSTALL_TEXTURES" =~ ^[Yy]$ ]]; then
    # CACHE PATHS: Install to multiple standard locations
    CACHE_PATHS=("$HOME/.cache/mupen64plus/cache" "$HOME/.local/share/mupen64plus/cache")
    
    echo "Downloading Texture Pack (Djipi OOT)..."
    wget -O textures.zip "$TEXTURE_PACK_URL"

    if [ $? -eq 0 ]; then
        echo "Extracting textures..."
        unzip -o textures.zip -d extracted_textures
        HTC_FILE=$(find extracted_textures -name "*.htc" | head -n 1)
        
        if [ -n "$HTC_FILE" ]; then
            for target in "${CACHE_PATHS[@]}"; do
                echo "Installing to: $target"
                mkdir -p "$target"
                cp "$HTC_FILE" "$target/"
            done
            echo "Texture pack installed! (Ensure 'High Res Textures' are enabled in settings)"
        else
            echo "No .htc file found in the zip."
        fi
        rm -rf extracted_textures textures.zip
    else
        echo "Failed to download texture pack."
    fi
else
    echo "Skipping texture pack installation."
fi

# --- 6. shortcuts ---
echo "--- Creating Launcher ---"
# Start Script
cat > start_game.sh << 'EOF'
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export LD_LIBRARY_PATH="$DIR/libs:$LD_LIBRARY_PATH"
# Only preload if file exists
if [ -f "$DIR/libs/libGLEW.so.2.1" ]; then
    export LD_PRELOAD="$DIR/libs/libGLEW.so.2.1"
fi
export GDK_BACKEND=x11
export SDL_VIDEODRIVER=x11
export EVENT_NOEPOLL=1

# Robust executable finding
EXEC=""
if [ -f "$DIR/modloader64-gui" ]; then
    EXEC="$DIR/modloader64-gui"
elif [ -f "$DIR/ModLoader64-GUI" ]; then
    EXEC="$DIR/ModLoader64-GUI"
else
    EXEC=$(find "$DIR" -maxdepth 1 -type f -executable -size +10M | head -n 1)
fi

if [ -n "$EXEC" ]; then
    echo "Launching: $EXEC"
    "$EXEC" "$@"
else
    echo "ERROR: ModLoader executable not found in $DIR!"
    echo "Please check the installation folder."
    read -p "Press Enter to exit..." 
    exit 1
fi
EOF
chmod +x start_game.sh

# Desktop File
ICON_PATH=$(find "$INSTALL_DIR" -name "ml64.png" | head -n 1)
if [ -z "$ICON_PATH" ]; then ICON_PATH="$INSTALL_DIR/resources/ml64.png"; fi

cat > "ModLoader64 (OOT).desktop" << EOF
[Desktop Entry]
Name=ModLoader64 (OOT Online)
Comment=Play N64 mods the modern way!
Exec="$INSTALL_DIR/start_game.sh"
Path=$INSTALL_DIR
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Game;Network;
StartupNotify=true
EOF
chmod +x "ModLoader64 (OOT).desktop"

echo ""
echo "=========================================="
echo "    SETUP COMPLETE!"
echo "=========================================="
echo "Run './ModLoader64 (OOT).desktop' to play."
read -p "Press Enter to exit..."
