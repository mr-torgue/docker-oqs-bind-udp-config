import argparse
import json
import pandas as pd

from ripe.atlas.cousteau import (
  AtlasLatestRequest,
  AtlasRequest,
  AtlasResultsRequest,
  Measurement
)
from collections import namedtuple

'''
writes the file to a CSV
'''
def save_to_csv(csv, label, strategy, algorithm):
    filename = ""
    if label != "":
        filename = "%s%s-" % (filename, label)
    if strategy != "":
        filename = "%s%s-" % (filename, strategy)
    if algorithm != "":
        filename = "%s%s-" % (filename, algorithm)
    timestamp = pd.Timestamp.now().strftime("%Y-%m-%d_%H-%M-%S")
    filename = "%s%s.csv" % (filename, timestamp)
    with open(filename, 'w') as f:
        f.write(csv)

'''
parses the description, which should be in format [Hydra DNS] {"algorithm": x, "strategy": y, "label": z}
'''
def parse_description(description):
    # check if algorithm, strategy, and label are set
    algorithm = ""
    strategy = ""
    label = ""

    # Extract JSON part from description
    json_start = description.find('{')
    json_end = description.rfind('}') + 1
    if json_start != -1 and json_end != -1:
        json_str = description[json_start:json_end]
        try:
            metadata = json.loads(json_str)
            algorithm = metadata.get("algorithm", "")
            strategy = metadata.get("strategy", "")
            label = metadata.get("label", "")
        except json.JSONDecodeError:
            pass

    return algorithm, strategy, label


'''
Our experiments can consist of multiple measurements.
We assume that all measurements with the same label belong to the same experiment.
'''
def get_results_from_label(label, write_to_csv=True):
    kwargs = {
        "description__contains": f"\"label\": \"{label}\"",
        "mine": True,
    }
    url_path = "/api/v2/measurements"
    request = AtlasRequest(**{"url_path": url_path})
    (is_success, response) = request.get(**kwargs)
    results = response["results"]
    print("Found %d results for label %s" % (response["count"], label))
    if results == []:
        print("No results for label %s!" % (label))
        return None
    elif is_success:
        df = pd.DataFrame(pd.json_normalize(results))
        df = df.assign(label="%s" % (label))
        csv = df.to_csv(index=False)
        if write_to_csv:
            save_to_csv(csv, "measurements-%s" % (label), "", "")
        ids = df["id"].astype(int).tolist()
        print("Saving results for measurements ids %s" % (ids))
        get_results(ids)
        return csv
    else:
        print("Failed to fetch results")
        return None

'''
same as get_results, but this time we already know the metadata
assumption: all ids have the same label, algorithm, and strategy
'''
def get_results_with_metadata(ids, label, algorithm, strategy, write_to_csv=True):
    dfs = []
    print(ids)
    for id in ids:
        kwargs = {
            "msm_id": id,
        }
        is_success, results = AtlasLatestRequest(**kwargs).create()
        if results == []:
            print("No results for id %d!" % (id))
        elif is_success:
            df = pd.DataFrame(pd.json_normalize(results))
            print(df)
            df = df.assign(algorithm="%s" % (algorithm))
            df = df.assign(strategy="%s" % (strategy))
            df = df.assign(label="%s" % (label))
            dfs.append(df)
        else:
            print("Could not fetch measurement %d" % (id))
    if dfs != []:
        # concate all dataframes
        df = pd.concat([x for x in dfs], ignore_index=True)
        # convert to CSV
        csv = df.to_csv(index=False)
        if write_to_csv:
            save_to_csv(csv, label, algorithm, strategy)
        return csv
    else:
        print("No results!")
        return None

'''
saves measurement information to a CSV
'''
def get_measurements_with_metadata(ids, label, algorithm, strategy, write_to_csv=True):
    kwargs = {
        "id": ", ".join([str(x) for x in ids])
    }
    url_path = "/api/v2/measurements"
    request = AtlasRequest(**{"url_path": url_path})
    (is_success, response) = request.get(**kwargs)
    results = response["results"]
    print("Found %d results for ids %s" % (response["count"], ids))
    if results == []:
        print("No results for ids %s!" % (ids))
        return None
    elif is_success:
        df = pd.DataFrame(pd.json_normalize(results))
        df = df.assign(label="%s" % (label))
        csv = df.to_csv(index=False)
        if write_to_csv:
            save_to_csv(csv, "measurements-%s" % (label), algorithm, strategy)
        return csv
    else:
        print("Failed to fetch results")
        return None

'''
get all the results based on the measurements specified in ids
only works if the description contains a json part with {"algorithm": x, "strategy": y, "label": z}
outputs as a single CSV (no label, strategy, or algorithm)
'''
def get_results(ids, write_to_csv=True):
    dfs = []
    for id in ids:
        kwargs = {
            "msm_id": id,
        }
        is_success, results = AtlasLatestRequest(**kwargs).create()
        if results == []:
            print("No results for id %d!" % (id))
        elif is_success:
            df = pd.DataFrame(pd.json_normalize(results))
            measurement = Measurement(id=id)
            # check if algorithm, strategy, and label are set
            algorithm, strategy, label = parse_description(measurement.description)
            if algorithm == "" or strategy == "":
                print("We expect 'algorithm' and 'strategy' to be set in the tags!")
                return None
            # add columns
            df = df.assign(algorithm="%s" % (algorithm))
            df = df.assign(strategy="%s" % (strategy))
            df = df.assign(label="%s" % (label))
            dfs.append(df)
        else:
            print("Could not fetch measurement %d" % (id))
    if dfs != []:
        # concate all dataframes
        df = pd.concat([x for x in dfs], ignore_index=True)
        # convert to CSV
        csv = df.to_csv(index=False)
        if write_to_csv:
            save_to_csv(csv, "", "", "")
        return csv
    else:
        print("No results!")
        return None

def main():
    parser = argparse.ArgumentParser(description='Fetch and save Atlas measurement results.')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-i', '--ids', type=str, help='Comma-separated list of Measurement IDs to fetch results for')
    group.add_argument('-l', '--label', type=str, help='Label to fetch results for')
    parser.add_argument('-c', '--csv', action='store_true', default=True, help='Save the results as CSV')
    args = parser.parse_args()

    # no check at the moment
    if args.ids:
        ids = [int(x.strip()) for x in args.ids.split(",")]
        csv_data = get_results(ids, args.csv)
    else:
        csv_data = get_results_from_label(args.label, args.csv)

    if not csv_data:
        print("No CSV generated!")

if __name__ == "__main__":
    main()
