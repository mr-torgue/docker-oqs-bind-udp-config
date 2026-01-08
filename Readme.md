# Description
Contains the docker files to set up our modified version of OQS-BIND in a docker container.
Installation: `curl -sSL https://raw.githubusercontent.com/mr-torgue/docker-oqs-bind-udp-config/refs/heads/main/setup.sh | bash`


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

# BIND9 Configuration
BIND9 can be run with `docker compose up -d`.
Make sure to select the right folder: resolver, ns, or root.
BIND9 can be configured through the `.env` file:
- ALG: Specifies the supported signature algorithms.
- DEBUG: Specifies if BIND9 is executed in debug mode. When running in debug mode, it will capture network traffic and use GDB.
- FRAG_MODE: Either QBF or RAW, or, if not specified, it defaults to TCP.
- DB: Specifies the DB file to use.
Note that there is no centralization, so make sure that all the components run in a configuration that is compatible with each other.
