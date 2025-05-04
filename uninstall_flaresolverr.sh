#!/bin/bash

# Define the installation directory and startup script
INSTALL_DIR="/opt/FlareSolverr"
START_SCRIPT="$INSTALL_DIR/start_flaresolverr.sh"

# Remove the FlareSolverr directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing FlareSolverr directory at $INSTALL_DIR..."
    sudo rm -rf "$INSTALL_DIR"
else
    echo "FlareSolverr directory not found at $INSTALL_DIR."
fi

# Remove the startup script if it exists
if [ -f "$START_SCRIPT" ]; then
    echo "Removing startup script at $START_SCRIPT..."
    sudo rm -f "$START_SCRIPT"
else
    echo "Startup script not found at $START_SCRIPT."
fi

# Remove the cron job for FlareSolverr
echo "Removing FlareSolverr from crontab..."
sudo crontab -l | grep -v "$START_SCRIPT" | sudo crontab -

echo "FlareSolverr uninstallation complete!"
