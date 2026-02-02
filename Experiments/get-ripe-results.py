import argparse
import pandas as pd
from ripe.atlas.cousteau import (
  AtlasLatestRequest
  AtlasResultsRequest
)

'''
parses the tags and adds it to the df as a column
'''
def parse_tags(tags, df):
    # check if algorithm, strategy, and label are set
    algorithm = ""
    strategy = ""
    label = ""
    for tag in measurement.tags:
        if tag.startswith("algorithm:"):
            algorithm = tag.split(":")[1].strip()
        if tag.startswith("strategy:"):
            strategy = tag.split(":")[1].strip()
        if tag.startswith("label:"):
            label = tag.split(":")[1].strip()
    if algorithm == "" or strategy == "":
        print("We expect 'algorithm' and 'strategy' to be set in the tags!")
        return None
    # add columns
    df = df.assign(algorithm="%s" % (metadata["algorithm"]))
    df = df.assign(strategy="%s" % (metadata["strategy"]))
    df = df.assign(label="%s" % (metadata["label"]))

'''
Our experiments can consist of multiple measurements.
We assume that all measurements with the same label belong to the same experiment.
'''
def get_results_from_label(label):
    kwargs = {
        "search": f"tags={label}",
        "is_oneoff": False,
        "status": 2,
        "mine": True,
        "participated": True
    }
    is_success, results = AtlasResultsRequest(**kwargs).create()
    if is_success:
        df = pd.DataFrame(results)
        df['result'] = df['result'].apply(lambda x: eval(x) if isinstance(x, str) else x)
        df = pd.json_normalize(df['result'])

        csv = df.to_csv(index=False)
        return csv
    else:
        print("Failed to fetch results")
        return None


'''

'''
def get_results(id):
    kwargs = {
        "msm_id": id,
    }
    is_success, results = AtlasLatestRequest(**kwargs).create()
    if is_success:
        df = pd.DataFrame(results)
        measurement = Measurement(id=id)
        # check if algorithm, strategy, and label are set
        algorithm = ""
        strategy = ""
        label = ""
        for tag in measurement.tags:
            if tag.startswith("algorithm:"):
                algorithm = tag.split(":")[1].strip()
            if tag.startswith("strategy:"):
                strategy = tag.split(":")[1].strip()
            if tag.startswith("label:"):
                label = tag.split(":")[1].strip()
        if algorithm == "" or strategy == "":
            print("We expect 'algorithm' and 'strategy' to be set in the tags!")
            return None
        # add columns
        df = df.assign(algorithm="%s" % (metadata["algorithm"]))
        df = df.assign(strategy="%s" % (metadata["strategy"]))
        df = df.assign(label="%s" % (metadata["label"]))
        csv = df.to_csv(index=False)
        return csv
    else:
        print("Failed to fetch results")
        return None

from ripe.atlas.cousteau import Measurement

measurement = Measurement(id=1000002)
print(measurement.protocol)
print(measurement.description)
print(measurement.is_oneoff)
print(measurement.is_public)
print(measurement.target_ip)
print(measurement.target_asn)
print(measurement.type)
print(measurement.interval)
print(dir(measurement)) # Full list of properties

def main():
    parser = argparse.ArgumentParser(description='Fetch and save Atlas measurement results.')
    parser.add_argument('-m', '--msm_id', type=int, required=True, help='Measurement ID to fetch results for')
    args = parser.parse_args()

    csv_data = get_results(args.msm_id)
    if csv_data:
        print(csv_data)

if __name__ == "__main__":
    main()
