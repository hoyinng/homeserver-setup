#!/bin/bash
#Sonarr
wget -qO- https://raw.githubusercontent.com/Sonarr/Sonarr/develop/distribution/debian/install.sh | sudo bash


# Install JellyFin
curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash