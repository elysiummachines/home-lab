#!/bin/bash

# Directory where Keychain is installed
INSTALL_DIR="/opt/keychain"

# Temp directory for download
TEMP_DIR="/tmp/keychain_update"

# Create a temporary directory for update
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# Downloading latest version
wget https://github.com/funtoo/keychain/archive/refs/heads/master.zip

# Unzip downloaded
unzip master.zip

# Replace the old version with new one
sudo rm -rf "$INSTALL_DIR"
sudo mv keychain-master "$INSTALL_DIR"

# Ensure the script is executable
sudo chmod +x "$INSTALL_DIR/keychain"

# Clean up the temporary directory
rm -rf "$TEMP_DIR"

echo "It is done....."
