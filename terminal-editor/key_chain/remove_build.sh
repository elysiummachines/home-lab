#!/bin/bash

# Directory where Keychain is installed
INSTALL_DIR="/opt/keychain"

# Remove the Keychain directory
if [ -d "$INSTALL_DIR" ]; then
    sudo rm -rf "$INSTALL_DIR"
    echo "Keychain has been removed from /opt."
else
    echo "Keychain not found in /opt."
fi

# Removing related entries from .bashrc
if grep -q "keychain" ~/.bashrc; then
    sed -i '/keychain/d' ~/.bashrc
    echo "Removed Keychain references from .bashrc."
fi

# Re-source .bashrc
source ~/.bashrc

echo "It is done....."
