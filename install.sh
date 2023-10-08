#!/bin/bash

echo "Work in progress. Ignore this file"
exit

# Install system dependencies
sudo apt install tmux git python3 python3-pip python3-redis build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev gcc lib32gcc-s1 ca-certificates python3-distutils python3-dev ioquake3 quake3


# Setup q3

# Setup ioquake3

# Install Steam and Quake Live

    # Clone minqlx and minqlx-plugins

# Setup avahi

# Add hostname to /etc/hosts if not present

# Install dpmaster
git clone https://github.com/kphillisjr/dpmaster/

sudo ln -s quake_servers.service /etc/systemd/system/quake_servers.service
sudo ln -s quake_servers.conf /etc/quake_servers.conf

sudo systemctl daemon-reload
sudo systemctl enable quake_servers.service

read -p "Do you want to start the servers now? [Y/n] " response

# Convertir la respuesta a minúsculas para manejar tanto 'Y' como 'y' como afirmativo.
response=${response,,}

if [[ $response == "" || $response == "y" ]]; then
    sudo systemctl start quake_servers.service
    echo "Service started."
else
    echo "To start the service later, use: sudo systemctl start quake_servers.service"
fi
