#! /bin/bash

for container in $(docker ps --format '{{.Names}}'); do
    echo "Resetting container $container"
    docker exec $container tc qdisc del dev eth0 root
done
