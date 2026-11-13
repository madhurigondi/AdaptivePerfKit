
#!/usr/bin/env python3

import csv
import math
import statistics
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[3]

INPUT = (
    ROOT / "research/phase2/evidence/diagnostics"
    / "adaptive_window_diagnostics.csv"
)

OUTPUT = ROOT / "research/phase2/analysis"
FIGURES = OUTPUT / "figures"

REQUIRED = [
    "window_number",
    "concurrency_limit",
    "completed_tasks",
    "elapsed_ms",
    "throughput_tasks_per_second",
    "mean_latency_ms",
    "decision",
    "next_concurrency_limit",
]


def load_data():
    with INPUT.open(newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file)

        if not set(REQUIRED).issubset(reader.fieldnames or []):
            raise ValueError("Missing required CSV columns")

        records = []

        for row in reader:
            record = {
                "window": int(row["window_number"]),
                "concurrency": int(row["concurrency_limit"]),
                "tasks": int(row["completed_tasks"]),
                "elapsed": float(row["elapsed_ms"]),
                "throughput": float(
                    row["throughput_tasks_per_second"]
                ),
                "latency": float(row["mean_latency_ms"]),
                "decision": row["decision"],
                "next": int(row["next_concurrency_limit"]),
            }

            if (
                record["tasks"] <= 0
                or record["concurrency"] <= 0
                or record["next"] <= 0
                or record["elapsed"] <= 0
                or not all(
                    math.isfinite(record[key])
                    for key in ("elapsed", "throughput", "latency")
                )
                or record["throughput"] < 0
                or record["latency"] < 0
            ):
                raise ValueError(
                    f"Invalid measurement in window {record['window']}"
                )

            expected = record["tasks"] * 1000 / record["elapsed"]

            if not math.isclose(
                record["throughput"],
                expected,
                rel_tol=0.0001
            ):
                raise ValueError(
                    f"Throughput mismatch in window {record['window']}"
                )

            records.append(record)

    if not records:
        raise ValueError("CSV contains no diagnostic records")

    records.sort(key=lambda item: item["window"])

    if [r["window"] for r in records] != list(
        range(1, len(records) + 1)
    ):
        raise ValueError("Window numbers are not sequential")

    for previous, current in zip(records, records[1:]):
        if previous["next"] != current["concurrency"]:
            raise ValueError(
                "Concurrency transition mismatch between "
                f"windows {previous['window']} and {current['window']}"
            )

    return records


def write_summary(records):
    grouped = defaultdict(list)

    for record in records:
        grouped[record["concurrency"]].append(record)

    path = OUTPUT / "concurrency_performance_summary.csv"

    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)

        writer.writerow([
            "concurrency",
            "window_count",
            "total_tasks",
            "total_elapsed_ms",
            "aggregate_throughput_tasks_per_sec",
            "mean_window_throughput",
            "mean_task_latency_ms",
        ])

        for concurrency, items in sorted(grouped.items()):
            tasks = sum(item["tasks"] for item in items)
            elapsed = sum(item["elapsed"] for item in items)

            writer.writerow([
                concurrency,
                len(items),
                tasks,
                f"{elapsed:.6f}",
                f"{tasks * 1000 / elapsed:.6f}",
                f"{statistics.mean(i['throughput'] for i in items):.6f}",
                f"{statistics.mean(i['latency'] for i in items):.6f}",
            ])

    return grouped


def generate_charts(records, grouped):
    windows = [r["window"] for r in records]

    # Figure 1: Concurrency transitions
    plt.figure(figsize=(10, 5))
    plt.step(
        windows,
        [r["concurrency"] for r in records],
        where="mid",
        marker="o"
    )
    plt.xlabel("Measurement window")
    plt.ylabel("Active concurrency limit")
    plt.title("Adaptive Concurrency by Window")
    plt.xticks(windows)
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(
        FIGURES / "01_concurrency_adjustments.png",
        dpi=200
    )
    plt.close()

    # Figure 2: Throughput
    plt.figure(figsize=(10, 5))
    plt.plot(
        windows,
        [r["throughput"] for r in records],
        marker="o"
    )
    plt.xlabel("Measurement window")
    plt.ylabel("Completed tasks per second")
    plt.title("Adaptive Execution Throughput")
    plt.xticks(windows)
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(
        FIGURES / "02_window_throughput.png",
        dpi=200
    )
    plt.close()

    # Figure 3: Task latency
    plt.figure(figsize=(10, 5))
    plt.plot(
        windows,
        [r["latency"] for r in records],
        marker="o"
    )
    plt.xlabel("Measurement window")
    plt.ylabel("Mean task latency (ms)")
    plt.title("Adaptive Execution Task Latency")
    plt.xticks(windows)
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(
        FIGURES / "03_window_latency.png",
        dpi=200
    )
    plt.close()

    # Figure 4: Aggregate throughput by concurrency
    levels = sorted(grouped)

    rates = [
        sum(r["tasks"] for r in grouped[level]) * 1000
        / sum(r["elapsed"] for r in grouped[level])
        for level in levels
    ]

    plt.figure(figsize=(9, 5))
    plt.bar([str(level) for level in levels], rates)
    plt.xlabel("Concurrency limit")
    plt.ylabel("Aggregate tasks per second")
    plt.title("Observed Throughput by Concurrency")
    plt.grid(axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(
        FIGURES / "04_throughput_by_concurrency.png",
        dpi=200
    )
    plt.close()


def generate_report(records, grouped):
    decisions = Counter(r["decision"] for r in records)

    total_tasks = sum(r["tasks"] for r in records)
    total_elapsed = sum(r["elapsed"] for r in records)

    best_window = max(records, key=lambda r: r["throughput"])
    worst_window = min(records, key=lambda r: r["throughput"])

    lines = [
        "# Phase 2 Adaptive Controller Diagnostic Analysis",
        "",
        f"Generated (UTC): {datetime.now(timezone.utc).isoformat()}",
        "",
        "## Dataset",
        "",
        f"- Measurement windows: {len(records)}",
        f"- Completed tasks: {total_tasks}",
        f"- Sum of window durations: {total_elapsed:.3f} ms",
        f"- Aggregate window throughput: "
        f"{total_tasks * 1000 / total_elapsed:.3f} tasks/sec",
        "",
        "The summed window durations exclude any execution "
        "overhead outside the measured windows.",
        "",
        "## Window Observations",
        "",
        f"- Highest throughput: window {best_window['window']}, "
        f"{best_window['throughput']:.3f} tasks/sec",
        f"- Lowest throughput: window {worst_window['window']}, "
        f"{worst_window['throughput']:.3f} tasks/sec",
        "",
        "## Concurrency Performance",
        "",
        "| Concurrency | Windows | Aggregate throughput (tasks/sec) |",
        "|---|---:|---:|",
    ]

    for level, items in sorted(grouped.items()):
        tasks = sum(r["tasks"] for r in items)
        elapsed = sum(r["elapsed"] for r in items)

        lines.append(
            f"| {level} | {len(items)} | "
            f"{tasks * 1000 / elapsed:.3f} |"
        )

    lines.extend([
        "",
        "## Controller Decisions",
        "",
    ])

    for decision, count in sorted(decisions.items()):
        lines.append(f"- {decision}: {count}")

    lines.extend([
        "",
        "## Interpretation",
        "",
        "The controller changes concurrency between measurement "
        "windows based on observed throughput and latency.",
        "",
        "These measurements can identify candidate instability "
        "and concurrency limits worth further testing.",
        "",
        "The observations are from one preliminary run. "
        "They do not establish that a specific concurrency "
        "limit is optimal across devices or workloads.",
        "",
        "## Research Limitations",
        "",
        "- Preliminary simulator measurements",
        "- One diagnostic execution",
        "- Concurrency levels were selected adaptively, not randomly",
        "- Workload order and thermal effects may influence results",
        "- No independent repeated-run confidence intervals",
        "- Fixed and adaptive end-to-end results require "
        "separate controlled comparison",
        "",
        "## Next Experiment",
        "",
        "Repeat controlled fixed-versus-adaptive experiments "
        "using matched workloads and device conditions. "
        "Retain the original baseline before changing the controller.",
        "",
    ])

    (OUTPUT / "ADAPTIVE_CONTROLLER_ANALYSIS.md").write_text(
        "\n".join(lines),
        encoding="utf-8"
    )


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    FIGURES.mkdir(parents=True, exist_ok=True)

    records = load_data()
    grouped = write_summary(records)

    generate_charts(records, grouped)
    generate_report(records, grouped)

    print("PASS: Diagnostic CSV validated")
    print(f"PASS: {len(records)} windows analyzed")
    print("PASS: Concurrency summary generated")
    print("PASS: Four charts generated")
    print("PASS: Analysis report generated")


if __name__ == "__main__":
    main()
