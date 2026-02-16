#!/bin/bash

INSTALL_MONITORING=false

while getopts "m" opt; do
  case $opt in
    m) INSTALL_MONITORING=true ;;
    *) echo "Usage: $0 [-m]" >&2; exit 1 ;;
  esac
done

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

# Remove resolver and set 8.8.8.8 and 8.8.4.4
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl mask systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf > /dev/null
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null

# Build the image and configure docker
cd docker-oqs-bind-udp-config
sudo docker build -t oqs-bind .

# install monitoring if specified
if [ "$INSTALL_MONITORING" = true ]; then
sudo apt install prometheus prometheus-node-exporter prometheus-bind-exporter -y
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl start bind_exporter
sudo systemctl enable bind_exporter
sudo apt-get install -y apt-transport-https wget gnupg
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana -y
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable grafana-server
sudo /bin/systemctl start grafana-server
fi
