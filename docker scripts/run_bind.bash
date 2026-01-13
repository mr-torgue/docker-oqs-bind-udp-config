#! /bin/bash
: '
restarts bind without making changes to the configuration
'

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <DEBUG>" >&2
    exit 1
fi
DEBUG=$1

pkill named
pkill tcpdump
cd /tmp
if [ "$DEBUG" = "true" ]; then
    echo "DEBUG MODE"
    tcpdump -i any -w /tmp/$ALG-ns-root.pcap &
    gdb --batch -ex "run" -ex "bt" -ex "quit" --args named -g -d 10
else
    named -g -d 3
fi