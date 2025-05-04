#!/bin/bash

#deluge
sudo apt install deluge
sudo apt install deluge-web
# Enable the Label plugin
CONFIG_DIR="$HOME/.config/deluge"
CORE_CONF="$CONFIG_DIR/core.conf"

# Create the configuration directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Check if core.conf exists, if not create a default one
if [ ! -f "$CORE_CONF" ]; then
    echo '{
        "file": 1,
        "version": 1,
        "plugins": [],
        "daemon": true,
        "loglevel": "info",
        "max_connections": 200,
        "max_download_speed": 0,
        "max_upload_speed": 0,
        "download_location": "~/Downloads",
        "move_completed": false,
        "move_completed_path": "",
        "preallocate": false,
        "autoadd": false,
        "autoadd_location": "",
        "autoadd_enabled": false,
        "autoadd_path": "",
        "autoadd_enabled": false
    }' > "$CORE_CONF"
fi

# Enable the Label plugin
sed -i 's/"plugins": \[/& "Label",/' "$CORE_CONF"

echo "Deluge and the Label plugin have been installed and enabled."