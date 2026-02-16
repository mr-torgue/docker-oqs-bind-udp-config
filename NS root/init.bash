#! /bin/bash

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
    DB_NAME=db.root-aws
elif [ "$TYPE" == "docker" ]; then
    DB_NAME=db.root-docker
fi

# copy the config files so that we can edit them
cp named.conf /usr/local/etc/named.conf
cp $DB_NAME /usr/local/etc/bind/zones/db.root

# generate new keys
ORIGINAL_DIR=$(pwd)
cd /usr/local/etc/bind/zones
rm -rf *.key
rm -rf *.private
dnssec-keygen -a $ALG -n ZONE .
dnssec-keygen -a $ALG -n ZONE -f KSK .
cd "$ORIGINAL_DIR"

# add DS record from local.
if [[ ! -f dsset-local. ]]; then
    echo "Could not find DS record dsset-local.!"
    exit 1
fi
DSREC=$(cat dsset-local.)
egrep "$(echo -n $DSREC)" "/usr/local/etc/bind/zones/db.root" > /dev/null
if [[ $? != 0 ]]
then
    echo "" >> "/usr/local/etc/bind/zones/db.root"
    echo $DSREC >> "/usr/local/etc/bind/zones/db.root"
fi
# sign the zone and export DS record
cd /usr/local/etc/bind/zones
dnssec-signzone -o . -N INCREMENT -t -S -K /usr/local/etc/bind/zones db.root;  
cd "$ORIGINAL_DIR"

# print some info
cat /usr/local/etc/named.conf
ifconfig  
cat /usr/local/etc/bind/zones/db.root
cat /usr/local/etc/bind/zones/dsset-.
sha256sum /usr/local/etc/bind/zones/dsset-.
sha256sum /dsset-local.
/bin/bash
