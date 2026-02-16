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
    DB_NAME=db.local-aws
elif [ "$TYPE" == "docker" ]; then
    DB_NAME=db.local-docker
fi

# copy the config files so that we can edit them
cp named.conf /usr/local/etc/named.conf
cp $DB_NAME /usr/local/etc/bind/zones/db.local

# remove old keys and generate new ones 
ORIGINAL_DIR=$(pwd)
cd /usr/local/etc/bind/zones
rm -rf *.key
rm -rf *.private
dnssec-keygen -a $ALG -n ZONE local
dnssec-keygen -a $ALG -n ZONE -f KSK local
cd "$ORIGINAL_DIR"

# add DS record from example.local.
if [[ ! -f dsset-example.local. ]]; then
    echo "Could not find DS record dsset-example.local.!"
    exit 1
fi
DSREC=$(cat dsset-example.local.)
egrep "$(echo -n $DSREC)" "/usr/local/etc/bind/zones/db.local" > /dev/null
if [[ $? != 0 ]]
then
    echo "" >> "/usr/local/etc/bind/zones/db.local"
    echo $DSREC >> "/usr/local/etc/bind/zones/db.local"
fi
# sign the zone and export DS record
cd /usr/local/etc/bind/zones/
dnssec-signzone -o local -N INCREMENT -t -S -K /usr/local/etc/bind/zones db.local
cd "$ORIGINAL_DIR"

# print some info
cat /usr/local/etc/named.conf
ifconfig
cat /usr/local/etc/bind/zones/db.local
cat /usr/local/etc/bind/zones/dsset-local.
sha256sum /usr/local/etc/bind/zones/dsset-local.
sha256sum /dsset-example.local. 
/bin/bash
