: '
Name: experiment 1
Description: experiment starts by querying test.example.local and ignores the data to make sure the NS is loaded in cache.
After that it iterates over test0.example.local to test9.example.local and stores the RTT and corresponding timestamp.
Before executing it asks the user about which configuration is used on the servers.
'
resolver=15.134.173.185 # localhost if internal
# dig @localhost -p 4053 +timeout=10 +tries=1 test.example.local
