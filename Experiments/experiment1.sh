: '
Name: experiment 1
Description: experiment starts by querying test.example.local and ignores the data to make sure the NS is loaded in cache.
After that it iterates over test0.example.local to test9.example.local and stores the RTT and corresponding timestamp.
Before executing it asks the user about which configuration is used on the servers.

Example dig outcome:
;; Query time: 26 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Jan 09 12:08:41 AEDT 2026
;; MSG SIZE  rcvd: 55
'

#resolver=15.134.173.185 # localhost if internal
#resolver=8.8.8.8
resolver=localhost
port=53
domain=test.example.local
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
CSV_FILE="experiment1_${TIMESTAMP}.csv"
# write headers
printf "\"Domain\",\"Timestamp\",\"Resolver\",\"Status\",\"Protocol\",\"Query Time\"\n" >> "$CSV_FILE"

parse_dig_result() {
    local log_line="$1"
    local domain="$2"
    local query_time=""
    local timestamp=""
    local server=""
    local status=""
    local protocol=""

    # Extract query time (e.g., "26 msec")
    if [[ "$log_line" =~ \;\;[[:space:]]Query[[:space:]]time:[[:space:]]([0-9]+)[[:space:]]msec ]]; then
        query_time="${BASH_REMATCH[1]}"
    fi

    # Extract timestamp (e.g., "Fri Jan 09 12:08:41 AEDT 2026")
    if [[ "$log_line" =~ \;\;[[:space:]]WHEN:[[:space:]]([A-Za-z]{3}[[:space:]][A-Za-z]{3}[[:space:]][0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]][A-Za-z]{3,4}[[:space:]][0-9]{4}) ]]; then
        timestamp="${BASH_REMATCH[1]}"
    fi

    # Extract server (e.g., "127.0.0.53#53")
    if [[ "$log_line" =~ \;\;[[:space:]]SERVER:[[:space:]]([0-9\.]+#[0-9]+) ]]; then
        server="${BASH_REMATCH[1]}"
    fi

    # Extract status (e.g., "NOERROR", "NXDOMAIN", "SERVFAIL")
    if [[ "$log_line" =~ \;\;[[:space:]]-\>\>HEADER\<\<-.*status:[[:space:]]([A-Z]+) ]]; then
        status="${BASH_REMATCH[1]}"
    fi

    # Extract UDP or TCP
    if [[ "$log_line" =~ \;\;[[:space:]]SERVER:.*\(([A-Z]+)\) ]]; then
        protocol="${BASH_REMATCH[1]}"
    fi

    # Print results
    echo "Timestamp: $timestamp"
    echo "Query Time: ${query_time}ms"
    echo "Server: $server"
    echo "Status: $status"
    echo "Protocol: $protocol"
    # add to CSV
    printf "\"$domain\",\"$timestamp\",\"$server\",\"$status\",\"$protocol\",\"$query_time\"\n" >> "$CSV_FILE"
}


output=$(dig @$resolver -p $port +timeout=10 +tries=1 $domain)
parse_dig_result "$output" "$domain"
for i in {0..19}; do 
	domain=test$i.example.local
    echo "$domain"
	output=$(dig @$resolver -p $port +timeout=10 +tries=1 $domain)
    parse_dig_result "$output" "$domain"
done
