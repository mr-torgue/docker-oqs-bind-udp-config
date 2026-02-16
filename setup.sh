#!/bin/bash

INSTALL_MONITORING=false

while getopts "m" opt; do
  case $opt in
    m) INSTALL_MONITORING=true ;;
    *) echo "Usage: $0 [-m]" >&2; exit 1 ;;
  esac
done

apt update
apt upgrade -y
apt install valgrind nano gdb tcpdump ssh curl cmake gcc pkg-config autoconf automake git build-essential ninja-build libnghttp2-dev libcap-dev libtool libtool-bin libuv1-dev unzip iputils-ping iptables iproute2 liburcu-dev libnetfilter-queue-dev libpcap-dev net-tools netcat traceroute iperf libnl-3-dev libnl-genl-3-dev binutils-dev libreadline6-dev libjemalloc-dev libcmocka-dev libxml2-dev libjson-c-dev binutils -y
# Remove resolver and set 8.8.8.8 and 8.8.4.4 to ensure that we can still use DNS
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl mask systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf > /dev/null
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
# Install OpenSSL 3.2.5
cd ~
curl -L -O https://github.com/openssl/openssl/releases/download/openssl-3.2.5/openssl-3.2.5.tar.gz
tar -xzvf openssl-3.2.5.tar.gz
rm openssl-3.2.5.tar.gz
cd openssl-3.2.5
./Configure
make
make install
sed -i 's/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/' /usr/local/ssl/openssl.cnf
echo -e "[oqsprovider_sect]\nactivate = 1" >> /usr/local/ssl/openssl.cnf
echo "/usr/local/lib64" > /etc/ld.so.conf.d/openssl.conf
ln -s /usr/local/lib64/libcrypto.so /usr/lib/x86_64-linux-gnu/libcrypto.so
ldconfig 
# Install liboqs 0.14.0
cd ~
git clone https://github.com/open-quantum-safe/liboqs.git --branch 0.14.0
mkdir liboqs/build
cd liboqs/build
cmake -GNinja -DBUILD_SHARED_LIBS=ON ..
ninja -j 1
ninja install
# Install oqs-provider 0.10.0
cd ~
git clone https://github.com/open-quantum-safe/oqs-provider.git --branch 0.10.0
cd oqs-provider
cmake -S . -B _build && cmake --build _build && cmake --install _build
# Install OQS-bind
cd ~
git clone https://github.com/mr-torgue/OQS-bind.git --branch v1.2.1
cd OQS-bind
autoreconf -fi
# For debugging: remove in production
CFLAGS="$CFLAGS -O0 -g" ./configure
make
make install
mkdir /usr/local/etc/bind
mkdir /usr/local/etc/bind/zones
mkdir /var/cache/bind
mkdir -p /usr/local/etc/bind/root/hints/
ldconfig 

# install monitoring if specified
if [ "$INSTALL_MONITORING" = true ]; then
sudo apt install prometheus prometheus-node-exporter prometheus-bind-exporter
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
sudo apt-get install grafana
fi
