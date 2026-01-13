#! /bin/bash
: '
updates the OQS-BIND code on the container
'
release=v1.01
if [ "$#" -eq 1 ]; then
    release=$1
fi

cd /OQS-bind
git fetch
git checkout $release