
import csv
import math
import statistics
from collections import defaultdict
from pathlib import Path

SOURCE = Path(
    "research/phase2/evidence/window-overhead/"
    "window_overhead_270_trials.csv"
)

OUTPUT = Path(
    "research/phase2/analysis/"
    "window_overhead_analysis.md"
)

WORKLOADS = [
    "cpuIntensive",
    "variableLatency",
    "mixed"
]

MODES = [
    "fixedContinuous",
    "fixedWindowed",
    "adaptiveV2"
]

TRIALS = 30

with SOURCE.open(newline="") as file:
    rows = list(csv.DictReader(file))

assert len(rows) == 270, (
    f"Expected 270 records, found {len(rows)}"
)

groups = defaultdict(dict)

for row in rows:
    workload = row["workload"]
    mode = row["configuration"]
    trial = int(row["trial"])

    assert workload in WORKLOADS
    assert mode in MODES
    assert 1 <= trial <= TRIALS

    key = (workload, mode)

    assert trial not in groups[key], (
        f"Duplicate trial: {key}, {trial}"
    )

    duration = float(row["duration_ms"])

    assert math.isfinite(duration)
    assert duration > 0
    assert int(row["completed_tasks"]) == 100

    expected_windows = (
        1 if mode == "fixedContinuous" else 10
    )

    assert int(row["window_count"]) == expected_windows

    if mode != "adaptiveV2":
        assert int(row["adjustment_count"]) == 0
        assert int(row["actual_change_count"]) == 0
    else:
        assert int(row["adjustment_count"]) == 10
        assert 0 <= int(row["actual_change_count"]) <= 10

    groups[key][trial] = duration

for workload in WORKLOADS:
    for mode in MODES:
        assert set(groups[(workload, mode)]) == set(
            range(1, TRIALS + 1)
        )

def descriptive(values):
    ordered = sorted(values)
    return {
        "mean": statistics.mean(values),
        "median": statistics.median(values),
        "sd": statistics.stdev(values),
        "p95": ordered[
            math.ceil(0.95 * len(ordered)) - 1
        ]
    }

def comparison(workload, baseline, candidate):
    baseline_values = groups[(workload, baseline)]
    candidate_values = groups[(workload, candidate)]

    differences = [
        baseline_values[trial] - candidate_values[trial]
        for trial in range(1, TRIALS + 1)
    ]

    mean_difference = statistics.mean(differences)
    sd_difference = statistics.stdev(differences)

    # Two-sided t-based interval for 29 degrees
    # of freedom, with t critical approximately 2.045.
    margin = (
        2.04523 * sd_difference / math.sqrt(TRIALS)
    )

    baseline_mean = statistics.mean(
        baseline_values.values()
    )

    candidate_mean = statistics.mean(
        candidate_values.values()
    )

    improvement = (
        (baseline_mean - candidate_mean)
        / baseline_mean * 100
    )

    return {
        "improvement": improvement,
        "saving": mean_difference,
        "lower": mean_difference - margin,
        "upper": mean_difference + margin
    }

lines = [
    "# AdaptivePerfKit Window Overhead Analysis",
    "",
    "## Dataset",
    "",
    "- Workloads: 3",
    "- Execution configurations: 3",
    "- Measured trials per combination: 30",
    "- Total measured executions: 270",
    "- Tasks per execution: 100",
    "- Measurement window size: 10",
    "",
    "## Descriptive Statistics",
    "",
    "| Workload | Configuration | Mean (ms) | "
    "Median (ms) | SD (ms) | P95 (ms) |",
    "|---|---|---:|---:|---:|---:|"
]

for workload in WORKLOADS:
    for mode in MODES:
        values = list(groups[(workload, mode)].values())
        result = descriptive(values)

        lines.append(
            f"| {workload} | {mode} | "
            f"{result['mean']:.3f} | "
            f"{result['median']:.3f} | "
            f"{result['sd']:.3f} | "
            f"{result['p95']:.3f} |"
        )

lines.extend([
    "",
    "## Paired Comparisons",
    "",
    "Positive savings indicate that the candidate "
    "completed faster than the baseline.",
    "",
    "| Workload | Comparison | Improvement (%) | "
    "Mean saving (ms) | 95% CI lower | 95% CI upper |",
    "|---|---|---:|---:|---:|---:|"
])

COMPARISONS = [
    ("fixedContinuous", "fixedWindowed"),
    ("fixedWindowed", "adaptiveV2"),
    ("fixedContinuous", "adaptiveV2")
]

for workload in WORKLOADS:
    for baseline, candidate in COMPARISONS:

        result = comparison(
            workload,
            baseline,
            candidate
        )

        lines.append(
            f"| {workload} | "
            f"{candidate} vs {baseline} | "
            f"{result['improvement']:.2f} | "
            f"{result['saving']:.3f} | "
            f"{result['lower']:.3f} | "
            f"{result['upper']:.3f} |"
        )

lines.extend([
    "",
    "## Interpretation Guide",
    "",
    "- Positive savings favor the candidate.",
    "- Negative savings favor the baseline.",
    "- A confidence interval containing zero "
    "does not establish a reliable difference.",
    "- Fixed-windowed versus fixed-continuous "
    "estimates the effect of window boundaries.",
    "- Adaptive V2 versus fixed-windowed combines "
    "concurrency adaptation and instrumentation effects.",
    "- Trial pairing uses matching experimental "
    "round numbers, not identical runtime conditions.",
    "",
    "## Limitations",
    "",
    "- Synthetic workloads.",
    "- Single test environment.",
    "- No physical iPhone validation yet.",
    "- Possible scheduling and thermal effects.",
    "- Fixed-windowed execution does not collect "
    "identical instrumentation to Adaptive V2.",
    "- Paired intervals assume approximately "
    "independent experimental rounds.",
    "- Multiple exploratory comparisons have "
    "not been adjusted for multiplicity.",
    ""
])

OUTPUT.parent.mkdir(
    parents=True,
    exist_ok=True
)

OUTPUT.write_text(
    "\n".join(lines) + "\n",
    encoding="utf-8"
)

print(OUTPUT.read_text())

print("\nAnalysis saved:", OUTPUT)
