#!/bin/bash

# Step 1: Remove the tmux binary from /usr/local/bin
echo "Removing tmux binary from /usr/local/bin..."
sudo rm -f /usr/local/bin/tmux

# Step 2: Remove development tools and dependencies installed for tmux
echo "Removing development tools and dependencies..."
sudo apt-get remove --purge git autoconf automake libtool pkg-config libevent-dev ncurses-dev build-essential bison -y
sudo apt-get autoremove -y

# Step 3: Clean up the tmux source directory
echo "Cleaning up the tmux source directory..."
rm -rf ~/tmux

# Step 4: Remove tmux plugins (TPM and tmux-resurrect)
echo "Removing tmux plugins..."
rm -rf ~/.tmux/plugins/tpm
rm -rf ~/.tmux/plugins/tmux-resurrect

# Step 5: Revert PATH changes in ~/.profile and reload the profile
echo "Reverting PATH changes in ~/.profile..."
sed -i '/export PATH=\/usr\/local\/bin:\$PATH/d' ~/.profile
source ~/.profile

# Step 6: Clear Bash history to remove tmux-related commands
echo "Clearing Bash history..."
history -c

# Final Step: Confirm cleanup completion
echo "Cleanup complete."
