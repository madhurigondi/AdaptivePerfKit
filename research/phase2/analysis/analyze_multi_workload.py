import csv
import math
import statistics
from pathlib import Path

SOURCE = Path(
    "research/phase2/evidence/multi-workload/"
    "multi_workload_270_trials.csv"
)

OUTPUT = Path(
    "research/phase2/analysis/"
    "multi_workload_analysis.md"
)

WORKLOADS = [
    "cpuIntensive",
    "variableLatency",
    "mixed"
]

MODES = [
    "fixed4",
    "adaptiveV1",
    "adaptiveV2"
]

with SOURCE.open(newline="") as file:
    rows = list(csv.DictReader(file))

assert len(rows) == 270, (
    f"Expected 270 records, found {len(rows)}"
)

groups = {}

for workload in WORKLOADS:
    for mode in MODES:
        subset = sorted(
            [
                row for row in rows
                if row["workload"] == workload
                and row["configuration"] == mode
            ],
            key=lambda row: int(row["trial"])
        )

        trials = [int(row["trial"]) for row in subset]

        assert trials == list(range(1, 31)), (
            f"Invalid trial sequence: {workload}/{mode}"
        )

        groups[(workload, mode)] = subset


def durations(workload, mode):
    return [
        float(row["duration_ms"])
        for row in groups[(workload, mode)]
    ]


def percentile(values, probability):
    ordered = sorted(values)
    index = math.ceil(len(ordered) * probability) - 1
    return ordered[index]


def confidence_interval(values):
    n = len(values)
    mean = statistics.mean(values)
    sd = statistics.stdev(values)

    # Student-t critical value for df=29.
    t = 2.04523
    margin = t * sd / math.sqrt(n)

    return mean, mean - margin, mean + margin


def compare(workload, baseline, candidate):
    a = durations(workload, baseline)
    b = durations(workload, candidate)

    differences = [
        x - y for x, y in zip(a, b)
    ]

    saving, lower, upper = confidence_interval(differences)

    improvement = (
        (statistics.mean(a) - statistics.mean(b))
        / statistics.mean(a)
        * 100
    )

    return improvement, saving, lower, upper


lines = [
    "# AdaptivePerfKit Multi-Workload Analysis",
    "",
    "## Experiment",
    "",
    "- 3 workload types",
    "- 3 concurrency configurations",
    "- 30 measured trials per combination",
    "- 270 total measured executions",
    "",
    "## Descriptive Statistics",
    "",
    "| Workload | Configuration | Mean (ms) | "
    "Median (ms) | SD (ms) | P95 (ms) | "
    "Mean throughput (tasks/s) |",
    "|---|---|---:|---:|---:|---:|---:|"
]

for workload in WORKLOADS:
    for mode in MODES:
        values = durations(workload, mode)

        throughputs = [
            float(row["throughput_tasks_per_second"])
            for row in groups[(workload, mode)]
        ]

        lines.append(
            f"| {workload} | {mode} | "
            f"{statistics.mean(values):.3f} | "
            f"{statistics.median(values):.3f} | "
            f"{statistics.stdev(values):.3f} | "
            f"{percentile(values, 0.95):.3f} | "
            f"{statistics.mean(throughputs):.3f} |"
        )

lines.extend([
    "",
    "## Paired Comparisons",
    "",
    "Positive improvements indicate lower execution "
    "time for the candidate.",
    "",
    "| Workload | Comparison | Improvement (%) | "
    "Mean saving (ms) | 95% CI lower | 95% CI upper |",
    "|---|---|---:|---:|---:|---:|"
])

for workload in WORKLOADS:
    for baseline, candidate in [
        ("adaptiveV1", "adaptiveV2"),
        ("fixed4", "adaptiveV2")
    ]:
        improvement, saving, lower, upper = compare(
            workload, baseline, candidate
        )

        lines.append(
            f"| {workload} | {candidate} vs {baseline} | "
            f"{improvement:.2f} | "
            f"{saving:.3f} | "
            f"{lower:.3f} | "
            f"{upper:.3f} |"
        )

lines.extend([
    "",
    "## Interpretation Notes",
    "",
    "- Positive mean savings favor the candidate.",
    "- Negative mean savings favor the baseline.",
    "- A confidence interval containing zero does "
    "not establish a reliable difference.",
    "- Paired intervals assume approximately "
    "independent experimental rounds.",
    "- These results are preliminary and "
    "specific to the measured environment.",
    "",
    "## Research Limitations",
    "",
    "- Synthetic workloads",
    "- Single test environment",
    "- No physical-device validation yet",
    "- Possible thermal and scheduling effects",
    "- Deterministic variable-latency workload",
    "- No direct CPU-energy measurements",
    "- Multiple comparisons are exploratory",
    ""
])

OUTPUT.write_text("\n".join(lines) + "\n")

print(OUTPUT.read_text())
print(f"\nAnalysis saved: {OUTPUT}")
