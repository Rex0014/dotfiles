#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define directories
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

echo "🚀 Starting dotfiles installation..."
echo "📂 Dotfiles directory: $DOTFILES_DIR"

# List of files/folders to symlink
# Format: "source_inside_repo:destination_in_home"
FILES_TO_LINK=(
    "bashrc:.bashrc"
    "zshrc:.zshrc"
    "tmux.conf:.tmux.conf"
    "config/nvim:.config/nvim"
    "config/kitty:.config/kitty"
)

# Ensure base target directories exist
mkdir -p "$HOME/.config"

# Track if backup folder was actually used
BACKUP_CREATED=false

# Loop through and link files
for item in "${FILES_TO_LINK[@]}"; do
    # Split the string by the colon delimiter
    SRC="${item%%:*}"
    DST="${item#*:}"
    
    REPO_PATH="$DOTFILES_DIR/$SRC"
    HOME_PATH="$HOME/$DST"

    # Verify that the source file actually exists in the repository
    if [ ! -e "$REPO_PATH" ] && [ ! -d "$REPO_PATH" ]; then
        echo "⚠️  Warning: Source $REPO_PATH does not exist in repo. Skipping."
        continue
    fi

    # Handle existing files/directories/links at the target destination
    if [ -e "$HOME_PATH" ] || [ -L "$HOME_PATH" ]; then
        # If it's already a correct symlink, skip it
        if [ -L "$HOME_PATH" ] && [ "$(readlink "$HOME_PATH")" = "$REPO_PATH" ]; then
            echo "✅ $DST is already correctly linked."
            continue
        fi

        # Create backup directory on demand
        if [ "$BACKUP_CREATED" = false ]; then
            mkdir -p "$BACKUP_DIR"
            BACKUP_CREATED=true
            echo "📦 Existing configurations will be backed up to: $BACKUP_DIR"
        fi

        # Move existing file to backup directory
        echo "🔄 Backing up existing $DST"
        mkdir -p "$(dirname "$BACKUP_DIR/$DST")"
        mv "$HOME_PATH" "$BACKUP_DIR/$DST"
    fi

    # Ensure the parent directory tree exists in $HOME
    mkdir -p "$(dirname "$HOME_PATH")"

    # Create the symbolic link
    echo "🔗 Linking $DST -> $SRC"
    ln -s "$REPO_PATH" "$HOME_PATH"
done

echo "🎉 Dotfiles installation complete!"
if [ "$BACKUP_CREATED" = true ]; then
    echo "💾 Your previous configs are safe in $BACKUP_DIR"
fi
