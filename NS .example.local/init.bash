#! /bin/bash
: '
runs when the container is started
generates a key and signs the zone according to the provided algorithm
'

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ALGORITHM> <TYPE>" >&2
    echo "TYPE can be either AWS or docker" >&2
    exit 1
fi

ALG=$1
TYPE=$2

if [ "$TYPE" != "AWS" ] && [ "$TYPE" != "docker" ]; then
    echo "Error: TYPE must be either AWS or docker" >&2
    exit 1
elif [ "$TYPE" == "AWS" ]; then
    DB_NAME=db.example.local-aws
elif [ "$TYPE" == "docker" ]; then
    DB_NAME=db.example.local-docker
fi

# copy the config files so that we can edit them
cp named.conf /usr/local/etc/named.conf
cp $DB_NAME /usr/local/etc/bind/zones/db.example.local

# remove old keys and generate new ones 
ORIGINAL_DIR=$(pwd)
cd /usr/local/etc/bind/zones
rm -rf *.key
rm -rf *.private
dnssec-keygen -a $ALG -n ZONE example.local
dnssec-keygen -a $ALG -n ZONE -f KSK example.local

# sign the zone and export DS record
dnssec-signzone -o example.local -N INCREMENT -t -S -K /usr/local/etc/bind/zones db.example.local
cd "$ORIGINAL_DIR"

# print some info
cat /usr/local/etc/named.conf
ifconfig
cat /usr/local/etc/bind/zones/db.example.local
cat /usr/local/etc/bind/zones/dsset-example.local.
sha256sum /usr/local/etc/bind/zones/dsset-example.local.