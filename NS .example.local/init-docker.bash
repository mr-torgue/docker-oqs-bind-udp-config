#! /bin/bash
: '
runs when the container is started
generates a key and signs the zone according to the provided algorithm
'

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ALGORITHM>" >&2
    exit 1
fi

ALG=$1

# copy the config files so that we can edit them
cp /named.conf /usr/local/etc/named.conf
cp /db.example.local /usr/local/etc/bind/zones/db.example.local

# remove old keys and generate new ones 
cd /usr/local/etc/bind/zones
rm -rf *.key
rm -rf *.private
dnssec-keygen -a $ALG -n ZONE example.local
dnssec-keygen -a $ALG -n ZONE -f KSK example.local

# sign the zone and export DS record
dnssec-signzone -o example.local -N INCREMENT -t -S -K /usr/local/etc/bind/zones db.example.local
cp /usr/local/etc/bind/zones/dsset-example.local. /tmp/

# print some info
cat /usr/local/etc/named.conf
ifconfig
cat /usr/local/etc/bind/zones/db.example.local
cat /usr/local/etc/bind/zones/dsset-example.local.
sha256sum /usr/local/etc/bind/zones/dsset-example.local.
/bin/bash
