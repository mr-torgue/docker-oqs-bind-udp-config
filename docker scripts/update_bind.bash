#! /bin/bash
: '
updates the OQS-BIND code on the container
'
release=v1.2.1
debug=false
if [ "$#" -eq 2 ]; then
    release=$1
    if [ "$2" == "--debug" ]; then
        debug=true
    fi
fi
if [ "$#" -eq 1 ]; then
    if [ "$1" == "--debug" ]; then
        debug=true
    else
        release=$1
    fi
fi

cd /OQS-bind
git fetch
git checkout $release
git pull
autoreconf -fi
if [ "$debug" = true ]; then
    RUN CFLAGS="$CFLAGS -O0 -g -pg" ./configure
else
    RUN CFLAGS="$CFLAGS" ./configure
fi
make
make install
