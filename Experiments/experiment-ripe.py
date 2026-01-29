'''
Sends 25 requests for test%d.example.local
'''

import os
import argparse

from dotenv import load_dotenv
from datetime import datetime
from ripe.atlas.cousteau import (
  Dns,
  AtlasSource,
  AtlasCreateRequest,
  AtlasLatestRequest
)


load_dotenv()
ATLAS_API_KEY = os.getenv("API_KEY")


ATLAS_API_KEY = "a225f49e-03d7-41ca-9a94-926720b4f7cb"
DESCRIPTION = "[Hydra DNS] FALCON512 SP"
RESOLVER = "15.134.173.185"
NR=20


def run_experiment(nr_sources, nr_queries, resolver, domain, description):
    source = AtlasSource(
        type="area",
        value="WW",
        requested=nr_sources,
        tags={"include":["system-ipv4-works"]}
    )
    prefix, suffix = domain.split(".", 1)
    for i in range(nr_queries):
        newdomain = "%s%d.%s" % (prefix, i, suffix)
        print("sending query %s to resolver %s" % (newdomain, resolver))
        dns = Dns(
            af=4,
            description=description,
            query_class="IN",
            query_type="A",
            query_argument=newdomain,
            target=resolver,
            use_probe_resolver=false,
            udp_payload_size=1232,
        )

        atlas_request = AtlasCreateRequest(
            key=ATLAS_API_KEY,
            measurements=[dns],
            sources=[source],
            is_oneoff=True
        )

        (is_success, response) = atlas_request.create()

# returns the results in csv format
def get_results(id):

    kwargs = {
        "msm_id": id,
    }

    is_success, results = AtlasLatestRequest(**kwargs).create()
    df = pd.read_json()
    csv = df.to_csv() 


def main():
    parser = argparse.ArgumentParser(description="DNS Query Tool for DNSSEC/Merkle Tree Research")

    # Required arguments
    parser.add_argument("-r", "--resolver", required=True, help="DNS resolver IP or hostname")
    parser.add_argument("-p", "--port", type=int, default=53, help="Port number (default: 53)")
    parser.add_argument("-l", "--label", required=True, help="Label for the query")
    parser.add_argument("-a", "--algorithm", required=True, help="Algorithm to use")
    parser.add_argument("-s", "--strategy", required=True, help="Strategy to use")
    parser.add_argument("--domain", required=True, help="Domain to query")

    # Optional arguments
    parser.add_argument("-d", "--description", help="Description for the query")

    args = parser.parse_args()

    # Print configuration (replace with your logic)
    print("Configuration:")
    print(f"  Resolver:    {args.resolver}")
    print(f"  Port:        {args.port}")
    print(f"  Label:       {args.label}")
    print(f"  Description: {args.description if args.description else 'Not provided'}")
    print(f"  Algorithm:   {args.algorithm}")
    print(f"  Strategy:    {args.strategy}")
    print(f"  Domain:      {args.domain}")