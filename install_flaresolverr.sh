#!/bin/bash

# Update package list and install dependencies
echo "Updating package list..."
sudo apt update

echo "Installing dependencies..."
sudo apt install -y git python3 python3-pip

# Create a directory for FlareSolverr
INSTALL_DIR="/opt/FlareSolverr"
echo "Creating installation directory at $INSTALL_DIR..."
sudo mkdir -p $INSTALL_DIR
sudo chown $USER:$USER $INSTALL_DIR

# Clone the FlareSolver repository
echo "Cloning FlareSolver repository..."
git clone https://github.com/FlareSolverr/FlareSolverr.git $INSTALL_DIR

# Navigate to the FlareSolverr directory
cd $INSTALL_DIR

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

# Create a script to run FlareSolverr
START_SCRIPT="$INSTALL_DIR/start_flaresolverr.sh"
echo "Creating startup script at $START_SCRIPT..."
cat <<EOL | sudo tee $START_SCRIPT
#!/bin/bash
cd $INSTALL_DIR
python3 FlareSolverr.py
EOL

# Make the startup script executable
sudo chmod +x $START_SCRIPT

# Add the startup script to the superuser crontab
echo "Adding FlareSolverr to crontab for automatic startup..."
(sudo crontab -l; echo "@reboot $START_SCRIPT >> /var/log/flaresolverr.log 2>&1") | sudo crontab -

# Provide instructions to run FlareSolver
echo "FlareSolver installation complete!"
echo "To run FlareSolver manually, you can use the following command:"
echo "bash $START_SCRIPT"
