# Description
Contains the docker files to set up our modified version of OQS-BIND in a docker container.

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