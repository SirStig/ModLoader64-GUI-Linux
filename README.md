# ModLoader64-GUI (Linux & Steam Deck Edition)

This is a modified version/installer for **ModLoader64**, designed to provide a seamless "One-Click" experience for Linux users, specifically targeting **Steam Deck (SteamOS)** and **Fedora/Arch** distributions.

## 🚀 What is this?
ModLoader64 is an emulator and mod loading platform primarily for *Ocarina of Time Online*. While the original application supports Linux, modern distributions often face compatibility issues with missing dependencies (GLEW 2.1, SFML) and windowing systems (Wayland/Game Mode).

**This repository provides a `setup_modloader.sh` script that automatically:**
1.  Downloads the latest ModLoader64 release.
2.  **Fixes Crashes**: Automatically handles the complex `libGLEW` and `libSFML` version mismatches that prevent the game from starting on Steam Deck.
3.  **Installs Dependencies**: Detects your OS (SteamOS, Fedora, Ubuntu) and installs the required libraries.
4.  **Texture Packs**: Optionally downloads and installs high-resolution texture packs (e.g., OOT 3DS Retexture).
5.  **Desktop Integration**: Creates a working `.desktop` shortcut and launch script fixes for window resizing.

## 📥 Installation

1.  Download the **[setup_modloader.sh](https://github.com/SirStig/ModLoader64-GUI-Linux/releases)** script from the Releases page.
2.  Make the script executable:
    - *GUI*: Right-click file -> Properties -> Permissions -> Check "Is Executable".
    - *Terminal*: `chmod +x setup_modloader.sh`
3.  Run the script:
    - Double-click and choose "Run in Terminal".
    - Or run: `./setup_modloader.sh`
4.  Follow the prompts (enter sudo password for dependencies, chose 'y' for textures).
5.  Launch the game using the new shortcut: **ModLoader64 (OOT).desktop**.

## 🛠️ Technical Fixes Explained
For developers or curious users, here is what this installer addresses:

*   **GLEW Mismatch**: The app requires `libGLEW.so.2.1`. Modern Linux distros ship with 2.2+. The script identifies 64-bit system libraries and creates a local compatibility symlink, forcing the app to accept the newer version via `LD_PRELOAD`.
*   **SFML Dependency**: The app requires `libsfml-system.so.2.5` but doesn't ship with it. The script installs SFML and creates version aliases to ensure audio and input work correctly.
*   **Architecture Validity**: Forces installation of `x86_64` packages to prevent `ELFCLASS32` errors on mixed-architecture systems like SteamOS.
*   **Windowing**: Forces `GDK_BACKEND=x11` and `SDL_VIDEODRIVER=x11` to prevent black screens and crashes on Wayland compositors.

## 🎮 Credits
*   **Original ModLoader64 Team**: For the amazing platform and OOT Online.
*   **SirStig**: Linux installer & compatibility fixes.
