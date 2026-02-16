# Description
Contains the files to set up our modified version of OQS-BIND in a docker container.
Initially, it installed bind9 into a docker container, but the latest verion can also install bind9 directly.
It also installs grafana and prometheus for monitoring.

# Installation
We have three installation options:
1. Docker rootless: `curl -sSL https://raw.githubusercontent.com/mr-torgue/docker-oqs-bind-udp-config/refs/heads/main/setup_docker_rootless.sh | bash -s -- -m`
2. Docker: `curl -sSL https://raw.githubusercontent.com/mr-torgue/docker-oqs-bind-udp-config/refs/heads/main/setup_docker.sh | bash -s -- -m`
3. Directly on host: `curl -sSL https://raw.githubusercontent.com/mr-torgue/docker-oqs-bind-udp-config/refs/heads/main/setup.sh | bash -s -- -m`
Remove the `-m` part if monitoring is not needed.

# Configuration
TBD


# Limitations

## Manual Setup
The containers generate new keys everytime it is restarted.
This means it also resigns its zone every restart.
At the moment, the DS record needs to be manually copied.
The way this works is as follows:
1. Deploy the authoritative name server and generate the DS record
    1. This record will be automatically generated in the data folder, look for the dsset file.
2. Deploy the TLD name server, give it the DS record (from 1) and generate a DS record
3. Deploy the root name server, give it the DS record (from 2) and generate a DS record
4. Deploy the resolver, provide it with the DS record and add it to the configuration


## Limited Flexibility
At the moment, we assume the following set up:
1. One root name server
2. One TLD name server for the .local domain
3. One authoritative name server for the .example.local domain
4. One recursive resolver
Changing this configuration requires some effort. 
I included two configurations: one for docker (internal) and one for amazon (external).
However, IP addresses might change over time.

## Running Multiple Containers on the Same Host
Not recommended, however, it should be possible as long as the ports are not reused and the containers are not using the `host` network.

# Running BIND9
The container can be run with `docker compose up -d` (rootless) or `sudo docker compose up -d` (root).
Make sure to select the right folder: resolver, ns, or root.
BIND9 can be configured through the `.env` file:
- ALG: Specifies the supported signature algorithms.
- DB: Specifies the DB file to use.
Note that there is no centralization, so make sure that all the components run in a configuration that is compatible with each other.
Docker compose will output the `dsset` file, which has to be copied to the next server.
Running the container, generates the keys and sets up the container, but does not start bind9 itself.

The mode can be set using `set_udp_fragmentation.bash [MODE]`
MODE: Either QBF or RAW, or, if not specified, it defaults to TCP.
In case of docker, look at `run.sh` to see how to run it on the container.

BIND9 can be updated using `update_bind.bash [BRANCH] [--debug]`.
If debug is set, it will compile with `-g` to enable debugging.
BRANCH specifies the branch to use.

BIND9 can be run with `run_bind.bash [DEBUG]`
The DEBUG flag specifies if BIND9 is executed in debug mode. When running in debug mode, it will capture network traffic and use GDB.

# Troubleshooting

## Port in Use
Docker containers forward 53, meaning that port 53 should be unused.
Make sure to disable the default linux stub resolver and set an external DNS or use our bind implementation.
Also, make sure that when running two components on the same machine that they use different ports.

## Unauthorized Port
By default we use docker in rootless mode. To prevent problems, you can run docker as root.
However, if you want to run BIND9 in a rootless container, make sure to set the permissions for port 53 with `setcap cap_net_bind_service=ep /usr/bin/rootlesskit`.
Check if the permissions have been set before building the image with `getcap /usr/bin/rootlesskit`.

## Network does not Exist
Make sure that the `bind9_net` network exists:
`docker network create --subnet=172.20.0.0/16 bind9_net`

## Port not Exposed
The host network does not work in rootless mode.
So, make sure that docker is run as root in case the host network is used.

## It is not Working!
Many things can go wrong:
1. Ports are not exposed
2. Port blocked by (host) firewall
3. IP addresses in db zone file are incorrect
4. BIND9 uses the docker zone files instead of AWS
