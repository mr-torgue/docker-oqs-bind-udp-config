apt update
apt upgrade -y
apt install valgrind nano gdb tcpdump ssh curl cmake gcc pkg-config autoconf automake git build-essential ninja-build libnghttp2-dev libcap-dev libtool libtool-bin libuv1-dev unzip iputils-ping iptables iproute2 liburcu-dev libnetfilter-queue-dev libpcap-dev net-tools netcat traceroute iperf libnl-3-dev libnl-genl-3-dev binutils-dev libreadline6-dev libjemalloc-dev libcmocka-dev libxml2-dev libjson-c-dev -y
# Install binutils 2.45 to get gprofng
cd ~
curl -O https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz
tar xf binutils-2.45.tar.xz
cd binutils-2.45
./configure
make
make install
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
liboqs/build
cmake -GNinja -DBUILD_SHARED_LIBS=ON ..
ninja -j 1
ninja install
# Install oqs-provider 0.10.0
cd ~
git clone https://github.com/open-quantum-safe/oqs-provider.git --branch 0.10.0
oqs-provider
cmake -S . -B _build && cmake --build _build && cmake --install _build
# Install OQS-bind
cd ~
git clone https://github.com/mr-torgue/OQS-bind.git --branch v1.2.1
OQS-bind
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
