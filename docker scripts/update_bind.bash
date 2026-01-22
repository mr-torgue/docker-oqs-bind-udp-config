#! /bin/bash
: '
updates the OQS-BIND code on the container
'
release=v1.2.1
if [ "$#" -eq 1 ]; then
    release=$1
fi

cd /OQS-bind
git fetch
git checkout $release
git pull
autoreconf -fi
RUN CFLAGS="$CFLAGS -O0 -g" ./configure 
make
make install
