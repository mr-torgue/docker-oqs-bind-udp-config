#!/bin/bash
sudo apt update
sudo apt upgrade -y

# Install docker
# Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl uidmap
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Clone the git repositories
git clone https://github.com/mr-torgue/docker-oqs-bind-udp-config.git

# Build the image and configure docker
cd docker-oqs-bind-udp-config
dockerd-rootless-setuptool.sh install
setcap cap_net_bind_service=ep /usr/bin/rootlesskit
docker build -t oqs-bind .
docker network create --subnet=172.20.0.0/16 bind9_net
