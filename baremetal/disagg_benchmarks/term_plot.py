import json
import os

import matplotlib.pyplot as plt
import numpy as np  # Import numpy for bar plot positioning
import pandas as pd
import plotext as plt_term

if __name__ == "__main__":
    # --- Load data from separate directories ---
    data = []
    data_sources = {
        "disagg_prefill": "disagg_results",
        "chunked_prefill": "chunked_results",
    }

    print("Loading data...")
    for name, folder in data_sources.items():
        for qps in [2, 4, 6, 8]:
            file_path = os.path.join(folder, f"{name}-qps-{qps}.json")
            try:
                with open(file_path) as f:
                    x = json.load(f)
                    x["name"] = name
                    x["qps"] = qps
                    data.append(x)
            except FileNotFoundError:
                print(f"Warning: Could not find file {file_path}. Skipping.")

    if not data:
        print(
            "Error: No data was loaded. Please check your 'disagg_results' and 'chunked_results' directories."
        )
        exit()

    print("Data loaded successfully. Generating combined bar plot...")

    df = pd.DataFrame.from_dict(data)
    dis_df = df[df["name"] == "disagg_prefill"]
    chu_df = df[df["name"] == "chunked_prefill"]

    # --- Create a directory for output plots ---
    output_dir = "plots"
    os.makedirs(output_dir, exist_ok=True)

    # Define the metrics to plot
    keys = [
        "mean_ttft_ms",
        "median_ttft_ms",
        "p99_ttft_ms",
        "mean_itl_ms",
        "median_itl_ms",
        "p99_itl_ms",
    ]

    # --- 1. Create a 3x2 subplot layout with BAR PLOTS for the PNG ---
    plt.style.use("bmh")
    fig, axes = plt.subplots(3, 2, figsize=(16, 18))
    axes = axes.flatten()

    labels = dis_df["qps"].unique()
    x = np.arange(len(labels))  # the label locations
    width = 0.35  # the width of the bars

    for ax, key in zip(axes, keys):
        rects1 = ax.bar(
            x - width / 2, dis_df[key], width, label="disagg_prefill"
        )
        rects2 = ax.bar(
            x + width / 2, chu_df[key], width, label="chunked_prefill"
        )

        # Add some text for labels, title and axes ticks
        ax.set_ylabel("ms")
        ax.set_title(key, fontsize=16)
        ax.set_xticks(x)
        ax.set_xticklabels(labels)
        ax.set_xlabel("QPS")
        ax.legend()
        ax.set_ylim(bottom=0)

    fig.tight_layout(pad=3.0)
    png_path = os.path.join(output_dir, "all_metrics_barchart.png")
    fig.savefig(png_path)
    plt.close(fig)
    print(f"\nSaved combined bar chart to {png_path}")

    # --- 2. Create a 3x2 subplot layout with BAR PLOTS for the terminal ---
    print("Displaying combined bar chart in terminal:")
    plt_term.subplots(3, 2)
    plt_term.title("Prefill Performance Comparison (Bar Charts)")
    
    # Get labels for the terminal plot (as strings)
    x_labels = dis_df["qps"].astype(str).tolist()

    for i, key in enumerate(keys):
        row = i // 2 + 1
        col = i % 2 + 1
        plt_term.subplot(row, col)

        # Prepare data for multiple_bar: a list of lists
        bar_data = [dis_df[key].tolist(), chu_df[key].tolist()]
        
        # Use the multiple_bar function with the 'labels' (plural) keyword
        plt_term.multiple_bar(
            x_labels, bar_data, labels=["disagg_prefill", "chunked_prefill"]
        )
        
        plt_term.title(key)
        # xlabel is handled by multiple_bar, but we can set ylabel
        plt_term.ylabel("ms")
        plt_term.ylim(0, None)

    plt_term.show()
