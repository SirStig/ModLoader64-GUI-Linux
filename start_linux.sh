#!/bin/bash

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define the path to our local libGLEW
LOCAL_GLEW="$DIR/libs/libGLEW.so.2.1"

# Verify the symlink exists
if [ ! -e "$LOCAL_GLEW" ]; then
    echo "Error: $LOCAL_GLEW does not exist. Please run install_linux.sh first."
    exit 1
fi

# Set library path
export LD_LIBRARY_PATH="$DIR/libs:$LD_LIBRARY_PATH"

# Force PRELOADING the glew library. 
# This ensures that even if the app tries to look elsewhere, it uses our "2.1" (which is actually system 2.2+)
export LD_PRELOAD="$LOCAL_GLEW"

# Environment Variables for Steam Deck / Compatibility
# Force X11 backend for GDK (Electron)
export GDK_BACKEND=x11
# Force X11 backend for SDL (Mupen64Plus) - Crucial for window creation
export SDL_VIDEODRIVER=x11
# Ensure shared memory works
export EVENT_NOEPOLL=1

echo "Starting ModLoader64-GUI..."
echo "Working Directory: $DIR"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "LD_PRELOAD: $LD_PRELOAD"
echo "SDL_VIDEODRIVER: $SDL_VIDEODRIVER"

# Try to find the main executable
if [ -f "$DIR/modloader64-gui" ]; then
    EXEC="$DIR/modloader64-gui"
elif [ -f "$DIR/ModLoader64-GUI" ]; then
    EXEC="$DIR/ModLoader64-GUI"
else
    # Fallback: Find executable >10MB
    EXEC=$(find "$DIR" -maxdepth 1 -type f -executable -size +10M | head -n 1)
fi

if [ -n "$EXEC" ]; then
    echo "Found executable: $EXEC"
    "$EXEC" "$@"
else
    echo "ERROR: Could not find the ModLoader64-GUI executable."
    exit 1
fi
