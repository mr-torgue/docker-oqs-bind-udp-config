#! /bin/bash
rate=50
delay=10

for container in $(docker ps --format '{{.Names}}'); do
    echo "Setting delay to $delay and rate to $rate for container $container"
    docker exec $container tc qdisc add dev eth0 root netem delay ${delay}ms rate ${rate}mbps
done
