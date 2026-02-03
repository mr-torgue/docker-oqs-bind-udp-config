'''
Sends 25 requests for test%d.example.local
'''

import os
import argparse

from time import sleep
from dotenv import load_dotenv
from datetime import datetime, timedelta
from ripe.atlas.cousteau import (
  Dns,
  AtlasSource,
  AtlasCreateRequest,
  AtlasLatestRequest
)
from get_ripe_results import get_results_with_metadata, get_measurements_with_metadata

load_dotenv()
ATLAS_API_KEY = os.getenv("ATLAS_API_KEY")

def run_experiment(nr_sources, nr_queries, resolver, domain, description, label, algorithm, strategy, country):
    description = "%s {\"algorithm\": \"%s\", \"strategy\": \"%s\", \"label\": \"%s\"}" % (description, algorithm, strategy, label)
    if country == "WW":
        source = AtlasSource(
            type="area",
            value="WW",
            requested=nr_sources,
            tags={"include":["system-ipv4-works"]}
        )
    else:
        source = AtlasSource(
            type="country",
            value=country,
            requested=nr_sources,
            tags={"include":["system-ipv4-works"]}
        )
    prefix, suffix = domain.split(".", 1)
    measurements=[]
    for i in range(nr_queries):
        newdomain = "%s%d.%s" % (prefix, i, suffix)
        measurements.append(Dns(
            af=4,
            description=description,
            query_class="IN",
            query_type="A",
            query_argument=newdomain,
            target=resolver,
            use_probe_resolver=False,
            udp_payload_size=1232,
        ))

    atlas_request = AtlasCreateRequest(
        key=ATLAS_API_KEY,
        measurements=measurements,
        sources=[source],
        is_oneoff=True
    )

    (is_success, response) = atlas_request.create()
    if is_success:
        ids = response["measurements"]
        print("Success! Saving ids %s to CSV!" % (ids))
        get_measurements_with_metadata(ids, label, algorithm, strategy)
        sleep(10)
        get_results_with_metadata(ids, label, algorithm, strategy)
    else:
        print("Request failed: %s" % (response))
        


def main():

    parser = argparse.ArgumentParser(description="Executes Experiments for Hydra DNS on RIPE Atlas")

    # Required arguments
    parser.add_argument("-r", "--resolver", required=True, help="DNS resolver IP or hostname")
    parser.add_argument("-p", "--port", type=int, default=53, help="Port number (default: 53)")
    parser.add_argument("-l", "--label", required=True, help="Label for the query")
    parser.add_argument("-a", "--algorithm", required=True, help="Algorithm to use")
    parser.add_argument("-s", "--strategy", required=True, help="Strategy to use")
    parser.add_argument("--domain", required=True, help="Domain to query")

    # Optional arguments
    parser.add_argument("-d", "--description", help="Description for the query (default: [Hydra DNS])", default="[Hydra DNS]")
    parser.add_argument("-c", "--country", help="Country code (default: WW)", default="WW")
    parser.add_argument("-n", "--nr_sources", type=int, help="Number of sources (default: 5)", default=5)
    parser.add_argument("-q", "--nr_queries", type=int, help="Number of queries (default: 20)", default=20)
    parser.add_argument("-f", "--frequency", type=int, help="Frequency in seconds (default: 0)", default=0)
    parser.add_argument("--start_date", help="Start date (default: now)", default=datetime.now().isoformat())
    parser.add_argument("--end_date", help="End date (default: now + 1 day)", default=(datetime.now() + timedelta(days=1)).isoformat())

    args = parser.parse_args()

    # Print configuration
    print("Configuration:")
    print(f"  Resolver:    {args.resolver}")
    print(f"  Port:        {args.port}")
    print(f"  Label:       {args.label}")
    print(f"  Description: {args.description}")
    print(f"  Algorithm:   {args.algorithm}")
    print(f"  Strategy:    {args.strategy}")
    print(f"  Domain:      {args.domain}")
    print(f"  Country:     {args.country}")
    print(f"  Nr. Sources: {args.nr_sources}")
    print(f"  Nr. Queries: {args.nr_queries}")
    if args.frequency > 0:
        print(f"  Frequency:   {args.frequency}")
        print(f"  Start Date:  {args.start_date}")
        print(f"  End Date:    {args.end_date}")
    else:
        print(f"  Frequency:   One-off")
    # Ask user to confirm
    user_input = input("Press Y/y to confirm and run the experiment: ")
    if user_input.lower() == 'y':
        run_experiment(
            nr_sources=args.nr_sources,
            nr_queries=args.nr_queries,
            resolver=args.resolver,
            domain=args.domain,
            description=args.description,
            label=args.label,
            algorithm=args.algorithm,
            strategy=args.strategy,
            country=args.country
        )
    else:
        print("Experiment cancelled by user")

if __name__ == "__main__":
    main()
