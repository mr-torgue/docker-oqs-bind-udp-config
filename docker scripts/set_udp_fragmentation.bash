#! /bin/bash
: '
sets the UDP fragmentation mode in named.conf
overwrites if already exists
supported:
1. QBF
2. RAW
'

FRAG_MODE=NONE
if [ "$#" -eq 1 ]; then
    FRAG_MODE=$1
fi

namedconf_file="/usr/local/etc/named.conf"

# check if namedconf_file exists
if [ ! -f "$namedconf_file" ]; then
    echo "could not find $namedconf_file!"
    exit 1
fi

# remove old fragmentation mode
sed -i '/.*udp_fragmentation.*;/d' $namedconf_file

# set fragmentation mode
if [ "$FRAG_MODE" = "QBF" ]; then
    sed -i '/^options {/a\    udp-fragmentation QBF;' $namedconf_file
elif [ "$FRAG_MODE" = "RAW" ]; then
    sed -i '/^options {/a\    udp-fragmentation RAW;' $namedconf_file
fi