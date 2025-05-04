
#Prowlarr
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
        DOWNLOAD_URL='http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64'
        ;;
    2)
        DOWNLOAD_URL='http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm'
        ;;
    3)
        DOWNLOAD_URL='http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64'
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

# Create installation directory
INSTALL_DIR="/opt/prowlarr"
sudo mkdir -p "$INSTALL_DIR"

# Download Prowlarr
wget "$DOWNLOAD_URL" -O /tmp/prowlarr.tar.gz

# Extract Prowlarr
sudo tar -xzf /tmp/prowlarr.tar.gz -C /tmp

# Move the extracted directory to the installation directory
sudo mv /tmp/Prowlarr/* "$INSTALL_DIR"

# Create a group for Prowlarr
sudo groupadd prowlarr

# Create a system user for Prowlarr and add it to the prowlarr group
sudo useradd -s /bin/false -g prowlarr prowlarr

# Change ownership of the installation directory
sudo chown -R prowlarr:prowlarr "$INSTALL_DIR"

# Create a systemd service file for Prowlarr
sudo bash -c 'cat << EOF | sudo tee /etc/systemd/system/prowlarr.service > /dev/null
[Unit]
Description=Prowlarr Daemon
After=syslog.target network.target
[Service]
User=prowlarr
Group=prowlarr
Type=simple

ExecStart=/opt/Prowlarr/Prowlarr -nobrowser -data=/var/lib/prowlarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start the Prowlarr service
sudo systemctl enable prowlarr
sudo systemctl start prowlarr

echo "Prowlarr has been installed and started. You can access it at http://localhost:9696"

# Generate uninstall script
UNINSTALL_SCRIPT="/tmp/uninstall_prowlarr.sh"
sudo bash -c "cat << EOF > $UNINSTALL_SCRIPT
#!/bin/bash

# Stop the Prowlarr service
sudo systemctl stop prowlarr

# Disable the Prowlarr service
sudo systemctl disable prowlarr

# Remove the Prowlarr service file
sudo rm /etc/systemd/system/prowlarr.service

# Remove the Prowlarr installation directory
sudo rm -rf /opt/prowlarr

# Remove the Prowlarr user and group
sudo userdel prowlarr
sudo groupdel prowlarr

echo 'Prowlarr has been uninstalled successfully.'
EOF"

# Make the uninstall script executable
sudo chmod +x "$UNINSTALL_SCRIPT"

# Inform the user about the uninstall script
echo "Prowlarr has been installed and started. You can access it at http://localhost:9696"
echo "To uninstall Prowlarr, you can run the following script:"
echo "$UNINSTALL_SCRIPT"
