
import csv
import json
import statistics
from pathlib import Path


# ============================================================
# AdaptivePerfKit - Phase 1 Research Benchmark Analysis
# SDK Version: 0.1.0
#
# Purpose:
# Analyze CPU benchmark execution times collected from
# the AdaptivePerfKit iOS Simulator research application.
#
# Outputs:
# 1. Benchmark statistics in Terminal
# 2. Processed benchmark_statistics.csv
# ============================================================


# MARK: - File Paths

BASE_DIR = Path(__file__).resolve().parent.parent

INPUT_FILE = (
    BASE_DIR
    / "raw"
    / "adaptiveperf_phase1_cpu_raw.json"
)

OUTPUT_FILE = (
    BASE_DIR
    / "processed"
    / "benchmark_statistics.csv"
)


# MARK: - Load Benchmark Data

def load_benchmark_data():

    if not INPUT_FILE.exists():
        raise FileNotFoundError(
            f"Benchmark JSON file not found: {INPUT_FILE}"
        )

    with open(INPUT_FILE, "r", encoding="utf-8") as file:
        records = json.load(file)

    if not isinstance(records, list) or not records:
        raise ValueError("Benchmark dataset is empty or invalid")

    durations = []

    for record in records:
        duration = float(record["durationMilliseconds"])

        if duration < 0:
            raise ValueError("Negative execution time detected")

        durations.append(duration)

    return records, durations


# MARK: - Percentile Calculation

def calculate_percentile(values, percentile):

    sorted_values = sorted(values)

    position = (len(sorted_values) - 1) * percentile

    lower = int(position)
    upper = min(lower + 1, len(sorted_values) - 1)

    fraction = position - lower

    return (
        sorted_values[lower]
        + (sorted_values[upper] - sorted_values[lower])
        * fraction
    )


# MARK: - Calculate Statistics

def calculate_statistics(records, durations):

    mean = statistics.mean(durations)
    median = statistics.median(durations)

    minimum = min(durations)
    maximum = max(durations)

    p95 = calculate_percentile(durations, 0.95)

    standard_deviation = (
        statistics.stdev(durations)
        if len(durations) > 1
        else 0.0
    )

    coefficient_of_variation = (
        (standard_deviation / mean) * 100
        if mean != 0
        else 0.0
    )

    batch_ids = {
        record["batchID"]
        for record in records
    }

    return {
        "Total Runs": len(durations),
        "Total Batches": len(batch_ids),
        "Mean": mean,
        "Median": median,
        "Minimum": minimum,
        "Maximum": maximum,
        "P95": p95,
        "Standard Deviation": standard_deviation,
        "Coefficient of Variation": coefficient_of_variation
    }


# MARK: - Display Results

def display_statistics(results):

    print()
    print("=" * 55)
    print("AdaptivePerfKit - Phase 1 Benchmark Analysis")
    print("=" * 55)

    print(f"Total Runs: {results['Total Runs']}")
    print(f"Total Batches: {results['Total Batches']}")

    print("-" * 55)

    print(f"Mean: {results['Mean']:.2f} ms")
    print(f"Median: {results['Median']:.2f} ms")
    print(f"Minimum: {results['Minimum']:.2f} ms")
    print(f"Maximum: {results['Maximum']:.2f} ms")
    print(f"P95: {results['P95']:.2f} ms")

    print(
        "Standard Deviation: "
        f"{results['Standard Deviation']:.2f} ms"
    )

    print(
        "Coefficient of Variation: "
        f"{results['Coefficient of Variation']:.2f}%"
    )

    print("=" * 55)
    print()


# MARK: - Export Statistics CSV

def export_statistics_csv(results):

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with open(
        OUTPUT_FILE,
        "w",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.writer(file)

        writer.writerow([
            "Metric",
            "Value",
            "Unit"
        ])

        for metric, value in results.items():

            if metric in ["Total Runs", "Total Batches"]:
                unit = "count"
            elif metric == "Coefficient of Variation":
                unit = "%"
            else:
                unit = "ms"

            formatted_value = (
                value
                if isinstance(value, int)
                else round(value, 4)
            )

            writer.writerow([
                metric,
                formatted_value,
                unit
            ])

    print(f"Statistics CSV saved successfully:")
    print(OUTPUT_FILE)


# MARK: - Main Execution

def main():

    try:

        records, durations = load_benchmark_data()

        results = calculate_statistics(
            records,
            durations
        )

        display_statistics(results)

        export_statistics_csv(results)

        print()
        print("Benchmark analysis completed successfully.")

    except (OSError, ValueError, KeyError, TypeError) as error:

        print(f"Benchmark analysis failed: {error}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
