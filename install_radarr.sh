#Radarr

# Prompt user for architecture
echo "Your system architecture is: $(dpkg --print-architecture)"
echo "Please select your architecture:"
echo "1) AMD64 (use arch=x64)"
echo "2) ARM (use arch=arm)"
echo "3) ARM64 (use arch=arm64)"
read -p "Enter the number corresponding to your architecture (1, 2, or 3): " ARCH_OPTION

# Set the download link based on user input
case $ARCH_OPTION in
    1)
        DOWNLOAD_URL='http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64'
        ;;
    2)
        DOWNLOAD_URL='http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm'
        ;;
    3)
        DOWNLOAD_URL='http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64'
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

# Create installation directory
INSTALL_DIR="/opt/radarr"
sudo mkdir -p "$INSTALL_DIR"

# Download Radarr
wget "$DOWNLOAD_URL" -O /tmp/radarr.tar.gz

# Extract Radarr
sudo tar -xzf /tmp/radarr.tar.gz -C /tmp

# Move the extracted directory to the installation directory
sudo mv /tmp/Radarr/* "$INSTALL_DIR"

# Create a group for Radarr
sudo groupadd radarr

# Create a system user for Radarr and add it to the radarr group
sudo useradd -s /bin/false -g radarr radarr

# Change ownership of the installation directory
sudo chown -R radarr:radarr "$INSTALL_DIR"

# Create a systemd service file for Radarr
sudo bash -c 'cat << EOF | sudo tee /etc/systemd/system/radarr.service > /dev/null
[Unit]
Description=Radarr Daemon
After=syslog.target network.target
[Service]
User=radarr
Group=media
Type=simple

ExecStart=/opt/Radarr/Radarr -nobrowser -data=/var/lib/radarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start the Radarr service
sudo systemctl enable radarr
sudo systemctl start radarr

# Generate uninstall script
UNINSTALL_SCRIPT="/tmp/uninstall_radarr.sh"
sudo bash -c "cat << EOF > $UNINSTALL_SCRIPT
#!/bin/bash

# Stop the Radarr service
sudo systemctl stop radarr

# Disable the Radarr service
sudo systemctl disable radarr

# Remove the Radarr service file
sudo rm /etc/systemd/system/radarr.service

# Remove the Radarr installation directory
sudo rm -rf /opt/radarr

# Remove the Radarr user and group
sudo userdel radarr
sudo groupdel radarr

echo 'Radarr has been uninstalled successfully.'
EOF"

# Make the uninstall script executable
sudo chmod +x "$UNINSTALL_SCRIPT"

# Inform the user about the uninstall script
echo "Radarr has been installed and started. You can access it at http://localhost:7878"
echo "To uninstall Radarr, you can run the following script:"
echo "$UNINSTALL_SCRIPT"
