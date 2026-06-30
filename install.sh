#!/bin/bash

TARGET_DIR="$HOME/.config/Quickshell/InfoBar"
REPO_RAW_URL="https://raw.githubusercontent.com/ppkcomputers/Info-Bar/main"

echo "=== Info-Bar OSD Installer ==="

# 1. Sync databases and check for system updates
echo "Syncing package databases..."
sudo pacman -Sy

echo "Checking for pending system updates..."
if pacman -Qu &>/dev/null; then
    echo "⚠️ Pending updates were found for your system."
    read -p "Would you like to run a full system upgrade now? (y/N): " update_choice
    case "$update_choice" in
        [yY][eE][sS]|[yY])
            echo "Running full system upgrade (sudo pacman -Su)..."
            sudo pacman -Su
            ;;
        *)
            echo "Skipping system upgrade."
            ;;
    esac
else
    echo "✓ Your system is already up to date."
fi

echo "----------------------------------------"

# 2. Check/Install Pacman-Contrib (Required for paccache in sysclean)
if ! command -v paccache &> /dev/null; then
    echo "Notice: pacman-contrib is required for the system cleanup script."
    read -p "Would you like to install pacman-contrib now? (y/N): " pc_choice
    case "$pc_choice" in
        [yY][eE][sS]|[yY])
            sudo pacman -S --needed pacman-contrib
            ;;
        *)
            echo "Skipping pacman-contrib installation. Note: Cache trimming will be unavailable."
            ;;
    esac
else
    echo "✓ pacman-contrib is already installed."
fi

echo "----------------------------------------"

# 3. Check for Quickshell dependency
if ! command -v quickshell &> /dev/null; then
    echo "Notice: Quickshell is required to run the InfoBar OSD."
    read -p "Would you like to install quickshell now? (y/N): " qs_choice
    case "$qs_choice" in
        [yY][eE][sS]|[yY])
            sudo pacman -S --needed quickshell
            ;;
        *)
            echo "Skipping quickshell installation."
            ;;
    esac
else
    echo "✓ Quickshell is already installed."
fi

echo "----------------------------------------"

# 4. Create directory and download utility files
echo "Creating installation directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

echo "Downloading OSD script components..."
curl -sL "$REPO_RAW_URL/arch-sysclean.sh" -o "$TARGET_DIR/arch-sysclean.sh"
curl -sL "$REPO_RAW_URL/InfoBar.sh" -o "$TARGET_DIR/InfoBar.sh"

# 5. Apply execution permissions
echo "Setting executable permissions..."
chmod +x "$TARGET_DIR/arch-sysclean.sh" "$TARGET_DIR/InfoBar.sh"

echo "----------------------------------------"
echo "🎉 Installation complete!"
echo "Your files are ready at: $TARGET_DIR"
echo "You can run your bar using: $TARGET_DIR/InfoBar.sh"
echo "----------------------------------------"
