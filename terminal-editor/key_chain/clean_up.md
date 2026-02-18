#!/bin/bash

TEMP_DIR="/tmp/keychain_update"

# Remove Temp directory
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
    echo "Temporary files cleaned up from /tmp."
else
    echo "No temporary files found."
fi

echo "it is done..."
