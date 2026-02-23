import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import os
import csv
import argparse

from collections import defaultdict
from scipy.stats import f_oneway, kruskal
from scikit_posthocs import posthoc_dunn

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
    try:
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
        df = df.assign(strategy="%s" % (metadata["strategy"]))
        df = df.assign(algorithm="%s" % (metadata["algorithm"]))
        df = df.assign(group="%s-%s-%s" % (metadata["label"], metadata["strategy"], metadata["algorithm"]))
        return {"df": df, "label": metadata["label"] }
    except Exception as e:
        print(f"An error occurred: {e}")

'''
CSV file from a RIPE Atlas measurement has the following format:
fw,mver,lts,dst_addr,dst_port,af,src_addr,proto,result,msm_id,prb_id,timestamp,msm_name,from,type,group_id,stored_timestamp

Each result is a JSON object
'''
def csv_to_df_ripe_atlas(csv_file, skip_first=False):
    
    # read csv and add some rows
    df = pd.read_csv(csv_file)
    df["group"] = df.apply(lambda row: f"{row['label']}-{row['strategy']}-{row['algorithm']}", axis=1)
    df = df.rename(columns={'result.rt': 'Query Time'})
    return {"df": df}
'''
Converts all CSV files in a folder to an array of dataframes
'''
def all_csv_to_df(filenames, skip_first=False, _type="AWS"):
    dfs = []
    for filename in filenames:
        if _type == "AWS":
            result = csv_to_df_aws(filename, skip_first)
        elif _type == "RIPE":
            result = csv_to_df_ripe_atlas(filename, skip_first)
        else:
            print("%s is not an accepted value for type!" % (_type))
            return None
        dfs.append(result["df"])
    if dfs == []:
        return None
    df = pd.concat([x for x in dfs], ignore_index=True)
    return df

def print_statistics(df):
    mean = df["Query Time"].mean()
    std = df["Query Time"].std()

    print(f"Average: {mean:.2f}")
    print(f"Standard Deviation: {std:.2f}")

def boxplots(df):

    # Set the style for better aesthetics
    sns.set(style="whitegrid")

    # Create the figure and axis
    plt.figure(figsize=(20, 12))

    # Generate boxplots
    sns.boxplot(x='group', y='Query Time', data=df, palette='Set2', native_scale=True)

    # Customize the plot
    plt.title('Sequence of Boxplots by Group', fontsize=20, fontweight='bold')
    plt.xlabel('Group', fontsize=16, fontweight='bold')
    plt.ylabel('ms', fontsize=16, fontweight='bold')
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    # Save the plot to file
    plt.savefig('boxplot.png', dpi=300, bbox_inches='tight')

    # Show the plot
    plt.show()

'''
dist test on df with levels either strategy, algorithm, or both
we assume df is already filtered (e.g. if you want to do a test on algorithm within TCP, we assume TCP data has been provided)
'''
def dist_test(df, levels="both"):
    alpha = 0.05
    if levels not in ["strategy", "algorithm", "both"]:
        print("Invalid levels parameter. Must be 'strategy', 'algorithm', or both")
        return

    # split into groups
    groups = defaultdict(list)
    if levels is None:
        for _, row in df.iterrows():
            group_key = f"{row['strategy']}-{row['algorithm']}"
            if isinstance(row['Query Time'], (int, float)) and not np.isnan(row['Query Time']):
                groups[group_key].append(row['Query Time'])
    else:
        for _, row in df.iterrows():
            group_key = row[levels]
            if isinstance(row['Query Time'], (int, float)) and not np.isnan(row['Query Time']):
                groups[group_key].append(row['Query Time'])

    print(f"Performing ANOVA and Kruskal-Wallis tests grouped by '{levels}':")
    print(f"Found {len(groups)} groups: {list(groups.keys())}")

    data = list(groups.values())
    if len(data) < 2:
        print(f"\nData '{levels}' has only {len(data)} dataset(s) - ANOVA and Kruskal-Wallis require at least 2")
        return
    try:
        f_stat, p_value = f_oneway(*data)
        print(f"\nANOVA results for level var '{levels}':")
        print(f"  F-statistic: {f_stat:.4f}")
        print(f"  p-value: {p_value:.4f}")
        if p_value < alpha:
            print("  Conclusion: Reject null hypothesis - significant differences exist")
        else:
            print("  Conclusion: Fail to reject null hypothesis - no significant differences")
    except Exception as e:
        print(f"\nError processing ANOVA for level var '{levels}': {str(e)}")

    try:
        h_stat, p_value_kruskal = kruskal(*data)
        print(f"\nKruskal-Wallis results for level var '{levels}':")
        print(f"  H-statistic: {h_stat:.4f}")
        print(f"  p-value: {p_value_kruskal:.4f}")
        if p_value_kruskal < alpha:
            print("  Conclusion: Reject null hypothesis - significant differences exist")
        else:
            print("  Conclusion: Fail to reject null hypothesis - no significant differences")

        # Post-hoc tests if Kruskal-Wallis is significant
        if p_value_kruskal < alpha:
            print("\nPerforming post-hoc tests (Dunn's test):")
            posthoc_results = posthoc_dunn(data, p_adjust='bonferroni')
            print(posthoc_results)
    except Exception as e:
        print(f"\nError processing Kruskal-Wallis for level var '{levels}': {str(e)}")



def main():
    parser = argparse.ArgumentParser(
        description="Process CSV files in a directory, with an option to skip the first row."
    )
    parser.add_argument(
        "filenames",
        type=str,
        nargs='+',
        help="List of CSV filenames to process"
    )
    parser.add_argument(
        "--skip-first-row",
        action="store_true",
        default=False,
        help="Skip the first row of each CSV file (default: False)"
    )
    parser.add_argument(
        "--type",
        type=str,
        default="AWS",
        help="Indicates if we use AWS (local client) or RIPE Atlas (external clients). Options: AWS, RIPE (default: AWS)"
    )

    args = parser.parse_args()
    # load the CSV into a set of dataframes
    df = all_csv_to_df(args.filenames, args.skip_first_row, args.type)
    try:
        print("General Statistics:")
        print_statistics(df)
        boxplots(df)
        for algorithm in df["algorithm"].unique():
            print("Analyzing strategy for algorithm %s" % (algorithm))
            df_filtered = df[df["algorithm"] == algorithm]
            dist_test(df_filtered, levels="strategy")
        for strategy in df["strategy"].unique():
            print("Analyzing algorithm for strategy %s" % (strategy))
            df_filtered = df[df["strategy"] == strategy]
            dist_test(df_filtered, levels="algorithm") 
            print("StatiStatistics for strategy %s:" % (strategy))
            print_statistics(df_filtered)
    except Exception as e:
        print("error: %s" % e)



if __name__ == "__main__":
    main()
