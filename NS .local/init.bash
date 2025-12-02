#! /bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <ALGORITHM> <FRAG_MODE> <DEBUG>" >&2
    exit 1
fi

ALG=$1
FRAG_MODE=$2
DEBUG=$3

# copy the config files so that we can edit them
cp /named.conf /usr/local/etc/named.conf
cp /db.local /usr/local/etc/bind/zones/db.local

# sometimes daemon and bind9 use different names for the same sig scheme
if [ "$ALG" = "SPHINCS+" ]; then
    BIND_ALG=SPHINCS+-SHA256-128S
else
    BIND_ALG=$ALG
fi

# remove old keys and generate new ones 
cd /usr/local/etc/bind/zones
rm -rf *.key
rm -rf *.private
dnssec-keygen -a $BIND_ALG -n ZONE local
dnssec-keygen -a $BIND_ALG -n ZONE -f KSK local
rndc-confgen -a > /usr/local/etc/bind/rndc.key
rndc flush

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
dnssec-signzone -o local -N INCREMENT -t -S -K /usr/local/etc/bind/zones db.local
cp /usr/local/etc/bind/zones/dsset-local. /tmp/

# set fragmentation mode
if [ "$FRAG_MODE" = "QBF" ]; then
    sed -i '/^options {/a\    udp-fragmentation QBF;' /usr/local/etc/named.conf
elif [ "$FRAG_MODE" = "RAW" ]; then
    sed -i '/^options {/a\    udp-fragmentation RAW;' /usr/local/etc/named.conf
fi

# print some info
cat /usr/local/etc/named.conf
ifconfig

cd /tmp
if [ "$DEBUG" = "true" ]; then
    echo "DEBUG MODE"
    tcpdump -i any -w /tmp/$ALG-ns-local.pcap &
    #gdb --batch -ex "run" -ex "bt" -ex "quit" --args named -g -d 10
else
    named -g -d 3
fi
/bin/bash