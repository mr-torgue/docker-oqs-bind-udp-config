#! /bin/bash
: '
updates the OQS-BIND code on the container
'
release=v1.0.1
git fetch
git checkout $release