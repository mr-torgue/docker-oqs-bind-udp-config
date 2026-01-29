: '
Name: experiment
Description: experiment starts by querying test.example.local and ignores the data to make sure the NS is loaded in cache.
After that it iterates over test0.example.local to test19.example.local and stores the RTT and corresponding timestamp.

Variables can be set trough the CLI.

It generates two files:
    1. [label]-[strategy]-[algorithm]-[timestamp].csv : contains the data in csv format
    2. [label]-[strategy]-[algorithm]-[timestamp].txt : contains the raw output from the dig command

Example dig outcome:
;; Query time: 26 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Jan 09 12:08:41 AEDT 2026
;; MSG SIZE  rcvd: 55
'


#!/bin/bash

# Default values
RESOLVER=localhost
PORT=53
LABEL=""
DESCRIPTION=""
DOMAIN="test.example.local"
COUNT=20
RATE=0
DELAY=0
REPEAT=1

# Help function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -r, --resolver   DNS resolver IP or hostname (default: localhost)"
    echo "  -p, --port       Port number (default: 53)"
    echo "  -l, --label      Label for the filename (default: \"\")"
    echo "  -d, --description Description for the query (default: \"\")"
    echo "  -a, --algorithm  Algorithm that is used (required)"
    echo "  -s, --strategy   Strategy that is used (required)"
    echo "  --domain         Domain to query (default: test.example.local)"
    echo "  --count          number of queries (default: 20)"
    echo "  --rate           Rate limit, docker only (default: 0)"
    echo "  --delay          Network delay, docker only (default: 0)"
    echo "  --repeat         The number of times this experiment is repeated (default: 1)"
    echo "  -h, --help       Show this help message"
    exit 1
}

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--resolver) RESOLVER="$2"; shift ;;
        -p|--port) PORT="$2"; shift ;;
        -l|--label) LABEL="$2"; shift ;;
        -d|--description) DESCRIPTION="$2"; shift ;;
        -a|--algorithm) ALGORITHM="$2"; shift ;;
        -s|--strategy) STRATEGY="$2"; shift ;;
        --domain) DOMAIN="$2"; shift ;;
        --count) COUNT="$2"; shift ;;
        --rate) RATE="$2"; shift ;;
        --delay) DELAY="$2"; shift ;;
        --repeat) REPEAT="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Validate required parameters
if [[ -z "$RESOLVER" || -z "$ALGORITHM" || -z "$STRATEGY" || -z "$DOMAIN" ]]; then
    echo "Error: Missing required parameter(s)."
    usage
fi

# Print configuration
echo "Configuration:"
echo "  Resolver:    $RESOLVER"
echo "  Port:        $PORT"
echo "  Label:       $LABEL"
echo "  Description: $DESCRIPTION"
echo "  Algorithm:   $ALGORITHM"
echo "  Strategy:    $STRATEGY"
echo "  Domain:      $DOMAIN"
echo "  Count:       $COUNT"
echo "  Rate:        $RATE"
echo "  Delay:       $DELAY"
echo "  Repeat:      $REPEAT"

read -p "do you want to run the experiment with these settings? (Y/N): " choice

# Check the user's input
if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo "Stopping..."
    exit 1
fi



TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="${LABEL}-${STRATEGY}-${ALGORITHM}-${TIMESTAMP}"
CSV_FILE="${FILENAME}.csv"
TXT_FILE="${FILENAME}.txt"


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
    printf "Timestamp: $timestamp\n" >> "$TXT_FILE"
    printf "Query Time: ${query_time}ms\n" >> "$TXT_FILE"
    printf "Server: $server\n" >> "$TXT_FILE"
    printf "Status: $status\n" >> "$TXT_FILE"
    # add to CSV
    printf "\"$domain\",\"$timestamp\",\"$server\",\"$status\",\"$query_time\"\n" >> "$CSV_FILE"
}

# write the info to file
printf "\"label\",\"description\",\"algorithm\",\"strategy\",\"delay\",\"rate\"\n" >> "$CSV_FILE"
printf "\"$LABEL\",\"$DESCRIPTION\",\"$ALGORITHM\",\"$STRATEGY\",\"$DELAY\",\"$RATE\"\n" >> "$CSV_FILE"
# write headers
printf "\"Domain\",\"Timestamp\",\"Resolver\",\"Status\",\"Query Time\"\n" >> "$CSV_FILE"
output=$((time dig @$RESOLVER -p $PORT +timeout=10 +tries=1 $DOMAIN) 2>&1)
printf "$output\n" >> "$TXT_FILE"
parse_dig_result "$output" "$DOMAIN"
for ((r = 0; r < REPEAT; r++)); do
    for ((i = 0; i < COUNT; i++)); do 
        prefix="${DOMAIN%%.*}${i}"
        newdomain=$(echo "$prefix.${DOMAIN#*.}")
        output=$((time dig @$RESOLVER -p $PORT +timeout=10 +tries=1 $newdomain) 2>&1)
        printf "$output\n" >> "$TXT_FILE"
        parse_dig_result "$output" "$newdomain"
    done
done
