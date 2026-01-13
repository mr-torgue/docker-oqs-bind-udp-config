#! /bin/bash
: '
restarts bind without making changes to the configuration
'

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <DEBUG>" >&2
    exit 1
fi
DEBUG=$1

# print information before running
version_file=/OQS-bind/VERSION
version=0
if [[ -f $version_file ]]; then
    version=$(<$version_file)
fi
echo "bind version: $version"

namedconf_file="/usr/local/etc/named.conf"
udp_mode=NONE
if [[ -f $namedconf_file ]]; then
    udp_mode=$(sed -n 's/.*udp-fragmentation\s\+\([^;]*\).*/\1/p' $namedconf_file)
fi
echo "udp fragmentation: $udp_mode"

dir=/usr/local/etc/bind/zones/
echo -e "---------------------------\n"
echo -e "|     Available Keys      |\n"
echo -e "---------------------------\n"
while read -r file; do
    FILE_ALG=$(sed -n '2p' "$file" | awk -F'[()]' '{print $2}') 
    # check if key file exists
    key_file="${file%.private}.key"
    if [ ! -f "$key_file" ]; then
        echo "Error: Cannot find '$key_file'"
        exit 1
    fi
    # read keyfile
    first_line=$(sed -n '1p' "$key_file")
    if [[ "$first_line" == *"This is a key-signing key"* ]]; then
        echo "KSK Algorithm: $FILE_ALG"
    elif [[ "$first_line" == *"This is a zone-signing key"* ]]; then
        echo "ZSK Algorithm: $FILE_ALG"
    else
        echo "Error: '$key_file' is neither a KSK or ZSK"
        exit 1
    fi
done < <(find "$dir" -type f -name "K*.private")
echo -e "---------------------------\n"
read -p "do you want to run bind with these settings? (Y/N): " choice

# Check the user's input
if [[ "$choice" =~ ^[Yy]$ ]]; then
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
else
    echo "aborting..."
    exit 1
fi
