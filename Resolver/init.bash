#! /bin/bash

# copy the config files so that we can edit them
cp /named.conf /usr/local/etc/named.conf
cp /root.hints /usr/local/etc/bind/root/hints/root.hints

# functions for installing the trust anchor
function trust_anchor_installed() {
	egrep "trust-anchors" /usr/local/etc/named.conf > /dev/null
	if [[ $? != 0 ]]
	then
		echo 1
	else
		echo 0
	fi
}

function remove_all_trust_anchors() {
	if [[ $(trust_anchor_installed) = 0 ]]
	then
		LINENUM=$(egrep -n "trust-anchors" /usr/local/etc/named.conf | cut -d ':' -f 1 | head -n 1)
		LINENUM=$(expr $LINENUM - 1 )
		head -n $LINENUM /usr/local/etc/named.conf >| /usr/local/etc/named.conf.tmp
		mv /usr/local/etc/named.conf.tmp /usr/local/etc/named.conf
	fi
}

function install_trust_anchor() {
	remove_all_trust_anchors

    if [[ ! -f /dsset-. ]]; then
        echo "Trust Anchor file /dsset-. does not exist!"
        exit 1
    fi
	DSROOT=$(cat /dsset-. | awk -F'DS' '{print $2}' | awk -F ' ' '{print $1" "$2" "$3" \""$4" "$5"\";"}')
	echo "" >> /usr/local/etc/named.conf
	echo "trust-anchors {" >> /usr/local/etc/named.conf
	echo "	. static-ds "$DSROOT >> /usr/local/etc/named.conf
	echo "};" >> /usr/local/etc/named.conf
}

# add the DS record of the root NS
install_trust_anchor

# print some information
cat /usr/local/etc/named.conf
ifconfig 
/bin/bash