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
