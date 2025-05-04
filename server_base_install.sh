#!/bin/bash
#openvpn
echo "Installing OpenVPN"
sudo apt-get update
sudo apt install openvpn
#pia
echo "Setting up PIA with OpenVPN"
# Function to display the menu
display_menu() {
    echo "Please choose a PIA server configuration:"
    echo "0) Default Configuration (UDP, AES-128-CBC+SHA1)"
    echo "1) Recommended Default windows only plus block-outside-dns (Windows only, UDP, AES-128-CBC+SHA1)"
    echo "2) Strong Configuration (UDP, AES-256-CBC+SHA256)"
    echo "3) TCP Configuration (TCP, AES-128-CBC+SHA1)"
    echo "4) Strong TCP Configuration (TCP, AES-256-CBC+SHA256)"
    echo "5) Exit"
}

# Display the menu
display_menu
read -p "Enter your choice [1-5]: " choice

# Set the configuration file based on user choice
case $choice in
    0)
        link="https://www.privateinternetaccess.com/openvpn/openvpn.zip"
        ;;
    1)
        link="https://www.privateinternetaccess.com/openvpn/openvpn-windows-block-outside-dns.zip"
        ;;
    2)
        link="https://www.privateinternetaccess.com/openvpn/openvpn-strong.zip"
        ;;
    3)
        link="https://www.privateinternetaccess.com/openvpn/openvpn-tcp.zip"
        ;;
    4)
        link="https://www.privateinternetaccess.com/openvpn/openvpn-strong-tcp.zip"
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

# Start OpenVPN with the selected configuration
# Download the OpenVPN configuration ZIP file
wget "$link" -O openvpn.zip

# Create a directory called PIA and unzip the downloaded file into it
mkdir -p PIA
unzip openvpn.zip -d PIA

cd PIA || { echo "Failed to change directory to PIA. Exiting..."; exit 1; }

# List the .ovpn files in the PIA directory
echo "Available .ovpn files in the PIA directory:"
ls *.ovpn

# Prompt the user to select an .ovpn file
read -p "Enter the name of the .ovpn file you want to use (without path) [Ie:ca_toronto.ovpn]: " ovpn_file

# Prompt for username and password
read -p "Enter your PIA username: " username
read -sp "Enter your PIA password: " password
echo

# Create auth.txt with the credentials
echo -e "$username\n$password" > auth.txt

echo "executing sudo openvpn --config '$ovpn_file' --auth-user-pass auth.txt &"
# Start OpenVPN with the selected configuration and auth.txt
sudo openvpn --config "$ovpn_file" --auth-user-pass auth.txt &

# Wait for a moment to allow OpenVPN to establish the connection
sleep 5

# Ask the user if the connection works
read -p "Does the OpenVPN connection work? (Y/N): " response
if [[ "$response" =~ ^[Yy]$ ]]; then
    # Get the absolute path to the OpenVPN binary and the files
    openvpn_path=$(which openvpn)
    ovpn_path=$(realpath "$ovpn_file")
    auth_path=$(realpath auth.txt)

    # Construct the command to be added to crontab
    cron_command="@reboot sudo $openvpn_path --config '$ovpn_path' --auth-user-pass '$auth_path'"

    # Print the command for debugging
    echo "Adding the following command to crontab:"
    echo "$cron_command"

    # Add the OpenVPN command to the superuser crontab for automatic startup
    (crontab -l 2>/dev/null; echo "$cron_command") | sudo crontab -

    echo "OpenVPN command added to crontab for automatic startup on boot."
else
    echo "Exiting without adding to crontab."
    exit 1
fi

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
sudo useradd -r -s /bin/false -g prowlarr prowlarr

# Change ownership of the installation directory
sudo chown -R prowlarr:prowlarr "$INSTALL_DIR"

# Create a systemd service file for Prowlarr
sudo bash -c 'cat << EOF > /etc/systemd/system/prowlarr.service
[Unit]
Description=Prowlarr Daemon
After=network.target

[Service]
User=prowlarr
Group=prowlarr
Type=simple
ExecStart=/opt/prowlarr/Prowlarr
Restart=on-failure
RestartSec=10
PrivateTmp=true

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

#flaresolverr

#Sonarr
wget -qO- https://raw.githubusercontent.com/Sonarr/Sonarr/develop/distribution/debian/install.sh | sudo bash

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
sudo useradd -r -s /bin/false -g radarr radarr

# Change ownership of the installation directory
sudo chown -R radarr:radarr "$INSTALL_DIR"

# Create a systemd service file for Radarr
sudo bash -c 'cat << EOF > /etc/systemd/system/radarr.service
[Unit]
Description=Radarr Daemon
After=network.target

[Service]
User=radarr
Group=radarr
Type=simple
ExecStart=/opt/radarr/Radarr
Restart=on-failure
RestartSec=10
PrivateTmp=true

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

# Install JellyFin
curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash