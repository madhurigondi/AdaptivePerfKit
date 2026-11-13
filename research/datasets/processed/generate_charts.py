
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")

import matplotlib.pyplot as plt


# AdaptivePerfKit - Phase 1
# Chart 1: CPU Benchmark Execution Time by Run

BASE_DIR = Path(__file__).resolve().parent.parent

INPUT_FILE = (
    BASE_DIR / "raw" / "adaptiveperf_phase1_cpu_raw.json"
)

OUTPUT_DIR = BASE_DIR / "processed" / "charts"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

with open(INPUT_FILE, "r", encoding="utf-8") as file:
    records = json.load(file)

if not records:
    raise ValueError("No benchmark records found")

# Preserve original record order.
durations = [
    float(record["durationMilliseconds"])
    for record in records
]

run_labels = [
    f"Run {index}"
    for index in range(1, len(records) + 1)
]

mean_duration = sum(durations) / len(durations)

fig, ax = plt.subplots(figsize=(11, 6))

ax.plot(
    run_labels,
    durations,
    marker="o",
    linewidth=2,
    markersize=7,
    label="CPU execution time"
)

ax.axhline(
    mean_duration,
    linestyle="--",
    linewidth=1.5,
    label=f"Mean: {mean_duration:.2f} ms"
)

ax.set_title(
    "AdaptivePerfKit - CPU Benchmark Execution Time",
    fontsize=15,
    fontweight="bold",
    pad=18
)

ax.set_xlabel("Benchmark Run")
ax.set_ylabel("Execution Time (ms)")
ax.grid(True, alpha=0.25)
ax.legend()

fig.text(
    0.5,
    0.01,
    "Phase 1 baseline | iOS Simulator | SDK v0.1.0",
    ha="center",
    fontsize=9
)

fig.tight_layout(rect=[0, 0.04, 1, 1])

output_file = (
    OUTPUT_DIR / "01_execution_time_by_run.png"
)

fig.savefig(
    output_file,
    dpi=300,
    bbox_inches="tight"
)

plt.close(fig)

print("Chart generated successfully:")
print(output_file)


# ============================================================
# Chart 2: CPU Benchmark Batch Performance Comparison
# ============================================================

from collections import defaultdict
import statistics

# Group benchmark measurements by batch ID
batch_data = defaultdict(list)

for record in records:
    batch_id = record["batchID"]
    duration = float(record["durationMilliseconds"])

    batch_data[batch_id].append(duration)

# Preserve the order in which batches appear in the dataset
batch_ids = list(batch_data.keys())

batch_labels = [
    f"Batch {index + 1}"
    for index in range(len(batch_ids))
]

batch_means = [
    statistics.mean(batch_data[batch_id])
    for batch_id in batch_ids
]

# Create chart
fig, ax = plt.subplots(figsize=(9, 6))

bars = ax.bar(
    batch_labels,
    batch_means,
    width=0.5
)

# Display average execution time above each bar
for bar, mean_value in zip(bars, batch_means):
    ax.annotate(
        f"{mean_value:.2f} ms",
        xy=(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height()
        ),
        xytext=(0, 5),
        textcoords="offset points",
        ha="center",
        va="bottom",
        fontsize=11
    )

ax.set_title(
    "AdaptivePerfKit - CPU Benchmark Batch Comparison",
    fontsize=15,
    fontweight="bold",
    pad=20
)

ax.set_xlabel("Benchmark Batch")
ax.set_ylabel("Average Execution Time (ms)")
ax.set_ylim(0, max(batch_means) * 1.15)
ax.grid(axis="y", alpha=0.25)

fig.text(
    0.5,
    0.01,
    "Phase 1 baseline | iOS Simulator | SDK v0.1.0",
    ha="center",
    fontsize=9
)

fig.tight_layout(rect=[0, 0.04, 1, 1])

output_file = (
    OUTPUT_DIR / "02_batch_performance_comparison.png"
)

fig.savefig(
    output_file,
    dpi=300,
    bbox_inches="tight"
)

plt.close(fig)

print("Chart 2 generated successfully:")
print(output_file)

# Print batch statistics for verification
for label, batch_id, mean_value in zip(
    batch_labels,
    batch_ids,
    batch_means
):
    print(
        f"{label}: {len(batch_data[batch_id])} runs, "
        f"Mean = {mean_value:.2f} ms"
    )


# ============================================================
# Chart 3: CPU Benchmark Execution Time Distribution
# ============================================================

import statistics

# Use the original benchmark measurements
execution_times = [
    float(record["durationMilliseconds"])
    for record in records
]

mean_time = statistics.mean(execution_times)
median_time = statistics.median(execution_times)

# Create histogram
fig, ax = plt.subplots(figsize=(10, 6))

ax.hist(
    execution_times,
    bins=5,
    edgecolor="black",
    alpha=0.8,
    label="CPU benchmark measurements"
)

# Mean reference line
ax.axvline(
    mean_time,
    linestyle="--",
    linewidth=2,
    label=f"Mean: {mean_time:.2f} ms"
)

# Median reference line
ax.axvline(
    median_time,
    linestyle=":",
    linewidth=2,
    label=f"Median: {median_time:.2f} ms"
)

ax.set_title(
    "AdaptivePerfKit - CPU Execution Time Distribution",
    fontsize=15,
    fontweight="bold",
    pad=20
)

ax.set_xlabel("Execution Time (ms)")
ax.set_ylabel("Number of Benchmark Runs")

ax.grid(axis="y", alpha=0.25)
ax.legend()

fig.text(
    0.5,
    0.01,
    "Phase 1 baseline | 10 runs | iOS Simulator | SDK v0.1.0",
    ha="center",
    fontsize=9
)

fig.tight_layout(rect=[0, 0.04, 1, 1])

output_file = (
    OUTPUT_DIR / "03_execution_time_distribution.png"
)

fig.savefig(
    output_file,
    dpi=300,
    bbox_inches="tight"
)

plt.close(fig)

print("Chart 3 generated successfully:")
print(output_file)

