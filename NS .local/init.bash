#! /bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ALGORITHM>" >&2
    exit 1
fi

ALG=$1

# copy the config files so that we can edit them
cp /named.conf /usr/local/etc/named.conf
cp /db.local /usr/local/etc/bind/zones/db.local

# remove old keys and generate new ones 
cd /usr/local/etc/bind/zones
rm -rf *.key
rm -rf *.private
dnssec-keygen -a $ALG -n ZONE local
dnssec-keygen -a $ALG -n ZONE -f KSK local

# add DS record from example.local.
if [[ ! -f /dsset-example.local. ]]; then
    echo "Could not find DS record dsset-example.local.!"
    exit 1
fi
DSREC=$(cat /dsset-example.local.)
egrep "$(echo -n $DSREC)" "/usr/local/etc/bind/zones/db.local" > /dev/null
if [[ $? != 0 ]]
then
    echo "" >> "/usr/local/etc/bind/zones/db.local"
    echo $DSREC >> "/usr/local/etc/bind/zones/db.local"
fi
# sign the zone and export DS record
cd /usr/local/etc/bind/zones/
dnssec-signzone -o local -N INCREMENT -t -S -K /usr/local/etc/bind/zones db.local
cp /usr/local/etc/bind/zones/dsset-local. /tmp/

# print some info
cat /usr/local/etc/named.conf
ifconfig
cat /usr/local/etc/bind/zones/dsset-local.
sha256sum /usr/local/etc/bind/zones/dsset-local.
/bin/bash
