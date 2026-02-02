import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import os
import csv
import argparse

from collections import defaultdict
from scipy.stats import f_oneway

'''
CSV format for the AWS experiments with local client:
"label","description","algorithm","strategy","delay","rate"
"unique label","We run this experiment locally using docker!","FALCON512","QBF","0","0"
"Domain","Timestamp","Resolver","Status","Query Time"
"test.example.local","Thu Jan 29 12:43:30 AEDT 2026","127.0.0.1#53","NOERROR","1"

We convert the first part to metadata (label, description, algorithm, and strategy)
After that we conver the data into a dataframe
Optionally, we skip the first row
'''
def csv_to_df_aws(csv_file, skip_first=False):
    if not os.path.exists(csv_file):
        print(f"File '{csv_file}' does not exist.")
        return
    with open(csv_file, mode ='r') as file:

        # parse the metadata
        reader = csv.reader(file)
        header = next(reader)  
        first_row = next(reader)  
        metadata = dict(zip(header, first_row))
        if "label" not in metadata.keys() or "algorithm" not in metadata.keys() or "strategy" not in metadata.keys():
            print("metadata incomplete!")
            exit()

    # read csv and add some rows
    df = pd.read_csv(csv_file, skiprows=2)
    df = df.assign(group="%s-%s-%s" % (metadata["label"], metadata["strategy"], metadata["algorithm"]))
    return {"df": df, "label": metadata["label"], "description": metadata["description"], "algorithm": metadata["algorithm"], "strategy": metadata["strategy"] }

'''
CSV file from a RIPE Atlas measurement has the following format:
fw,mver,lts,dst_addr,dst_port,af,src_addr,proto,result,msm_id,prb_id,timestamp,msm_name,from,type,group_id,stored_timestamp

Each result is a JSON object
'''
def csv_to_df_ripe_atlas(csv_file, skip_first=False):
    
    if not os.path.exists(csv_file):
        print(f"File '{csv_file}' does not exist.")
        return
    # read csv and add some rows
    df = pd.read_csv(csv_file, skiprows=skip_first)
    df['result'] = df['result'].apply(lambda x: eval(x) if isinstance(x, str) else x)
    df = pd.json_normalize(df['result'])

    

    df = df.assign(group="%s-%s-%s" % (df["label"], df["strategy"], df["algorithm"]))
    return {"df": df, "label": df["label"], "description": df["description"], "algorithm": df["algorithm"], "strategy": df["strategy"]}

'''
Converts all CSV files in a folder to an array of dataframes
'''
def all_csv_to_df(folder_path, skip_first=False, _type="AWS"):
    if not os.path.exists(folder_path):
        print(f"Error: The folder '{folder_path}' does not exist.")
        return
    # List all files in the folder
    files = sorted(os.listdir(folder_path))
    csv_files = [file for file in files if file.endswith('.csv')]

    if not csv_files:
        print(f"No CSV files found in '{folder_path}'.")
        return
    print("Found %d csv files" % (len(csv_files)))
    results = []
    for csv_file in csv_files:
        file_path = os.path.join(folder_path, csv_file)
        if _type == "AWS":
            results.append(csv_to_df_aws(file_path, skip_first))
        elif _type == "RIPE":
            results.append(csv_to_df_ripe_atlas(file_path, skip_first))
        else
            print("%s is not an accepted value for type!" % (_type))
    return results

def print_statistics(df_desc_dict):
    for df_desc in df_desc_dict:
        df = df_desc["df"]
        description = df_desc["description"]
        mean = df["Query Time"].mean()
        std = df["Query Time"].std()

        print(f"Average: {mean:.2f}")
        print(f"Standard Deviation: {std:.2f}")

def boxplots(df_desc_dict):
    # combine all in one df
    concatenated_df = pd.concat([df_desc["df"] for df_desc in df_desc_dict], axis=0, ignore_index=True)

    # Set the style for better aesthetics
    sns.set(style="whitegrid")

    # Create the figure and axis
    plt.figure(figsize=(10, 6))

    # Generate boxplots
    sns.boxplot(x='group', y='Query Time', data=concatenated_df, palette='Set2', native_scale=True)

    # Customize the plot
    plt.title('Sequence of Boxplots by Group', fontsize=16)
    plt.xlabel('Group', fontsize=12)
    plt.ylabel('ms', fontsize=12)

    # Show the plot
    plt.show()

'''
tests if experiments can come from the same distribution
group_by splits the dataframes in distinct groups (often TCP/QBF)
by default it compares if the different algorithms within a strategy could have come from the same distribution
'''
def dist_test(df_desc_dict, group_by="strategy"):
    # do the group by, set to default if not strategy or algorithm
    groups = defaultdict(list)
    for df_desc in df_desc_dict:
        df = df_desc["df"]
        description = df_desc["description"]
        try:
            group_by_val = df_desc[group_by]
        except:
            group_by_val = "default"
        groups[group_by_val].append(df)
        print(group_by_val)
    print("found %d groups: %s" % (len(groups), list(groups.keys())))

    # Perform ANOVA for each 'a'
    for group_by_val, dfs in groups.items():
        group_data = [df["Query Time"] for df in dfs]
        try:
            f_stat, p_value = f_oneway(*group_data)

            print(f"ANOVA for a={group_by_val}:")
            print(f"  F-statistic: {f_stat:.4f}")
            print(f"  p-value: {p_value:.4f}")
        except TypeError as e:
            print("Error: %s" % (e))



def main():
    parser = argparse.ArgumentParser(
        description="Process CSV files in a directory, with an option to skip the first row."
    )
    parser.add_argument(
        "directory",
        type=str,
        help="Path to the directory containing CSV files"
    )
    parser.add_argument(
        "--skip-first-row",
        action="store_true",
        default=False,
        help="Skip the first row of each CSV file (default: False)"
    )
    parser.add_argument(
        "--type",
        action="store_true",
        default="AWS",
        help="Indicates if we use AWS (local client) or RIPE Atlas (external clients). Options: AWS, RIPE (default: AWS)"
    )

    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"Error: {args.directory} is not a valid directory.")
        return

    if args.type == "AWS":
    dfs = all_csv_to_df(args.directory, args.skip_first_row)
    print_statistics(dfs)
    boxplots(dfs)
    dist_test(dfs, group_by="strategy") 
    dist_test(dfs, group_by="algorithm") 
    #dist_test(dfs, group_by=None) 



if __name__ == "__main__":
    main()
