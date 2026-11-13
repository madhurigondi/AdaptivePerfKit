
import csv
import math
import statistics
from collections import defaultdict
from pathlib import Path

root = Path("research/phase2")

source = (
    root / "evidence/four-configuration"
    / "four_configuration_360_trials.csv"
)

output = (
    root / "analysis"
    / "four_configuration_analysis.md"
)

data = defaultdict(dict)

with source.open(newline="") as file:
    for row in csv.DictReader(file):
        key = (row["workload"], row["configuration"])
        trial = int(row["trial"])

        if trial in data[key]:
            raise ValueError(f"Duplicate trial: {key}, {trial}")

        data[key][trial] = float(row["duration_ms"])

workloads = ["cpuIntensive", "variableLatency", "mixed"]
modes = ["fixed4", "adaptiveV1", "adaptiveV2", "adaptiveV3"]

expected_trials = set(range(1, 31))

for workload in workloads:
    for mode in modes:
        trials = set(data[(workload, mode)])
        if trials != expected_trials:
            raise ValueError(
                f"Missing or unexpected trials: {workload}/{mode}"
            )

def percentile(values, fraction):
    values = sorted(values)
    position = (len(values) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)

    return (
        values[lower] * (upper - position)
        + values[upper] * (position - lower)
    ) if lower != upper else values[lower]

def paired_comparison(workload, baseline, candidate):
    a = data[(workload, baseline)]
    b = data[(workload, candidate)]

    differences = [
        a[trial] - b[trial]
        for trial in range(1, 31)
    ]

    mean_difference = statistics.mean(differences)
    sd = statistics.stdev(differences)
    se = sd / math.sqrt(len(differences))

    # Two-sided 95% Student-t critical value, df=29.
    critical = 2.04523

    lower = mean_difference - critical * se
    upper = mean_difference + critical * se

    baseline_mean = statistics.mean(a.values())
    improvement = 100 * mean_difference / baseline_mean

    return improvement, mean_difference, lower, upper

lines = [
    "# AdaptivePerfKit Four-Configuration Analysis",
    "",
    "## Descriptive Statistics",
    "",
    "| Workload | Configuration | Mean (ms) | SD (ms) | P95 (ms) |",
    "|---|---|---:|---:|---:|",
]

for workload in workloads:
    for mode in modes:
        values = list(data[(workload, mode)].values())

        lines.append(
            f"| {workload} | {mode} | "
            f"{statistics.mean(values):.3f} | "
            f"{statistics.stdev(values):.3f} | "
            f"{percentile(values, 0.95):.3f} |"
        )

lines.extend([
    "",
    "## Paired Comparisons",
    "",
    "Positive savings favor the candidate.",
    "",
    "| Workload | Comparison | Improvement (%) | "
    "Saving (ms) | 95% CI lower | 95% CI upper |",
    "|---|---|---:|---:|---:|---:|",
])

comparisons = [
    ("fixed4", "adaptiveV3"),
    ("adaptiveV1", "adaptiveV3"),
    ("adaptiveV2", "adaptiveV3"),
]

for workload in workloads:
    for baseline, candidate in comparisons:
        improvement, saving, lower, upper = paired_comparison(
            workload, baseline, candidate
        )

        lines.append(
            f"| {workload} | {candidate} vs {baseline} | "
            f"{improvement:.2f} | {saving:.3f} | "
            f"{lower:.3f} | {upper:.3f} |"
        )

lines.extend([
    "",
    "## Limitations",
    "",
    "- Synthetic workloads in one test environment.",
    "- Trial pairing is by experimental round.",
    "- Measurements may exhibit temporal correlation.",
    "- Confidence intervals assume approximately independent paired rounds.",
    "- Multiple exploratory comparisons are not multiplicity-adjusted.",
    "- Physical iPhone validation is pending.",
    "- V3 feedback-window semantics differ from V1/V2.",
    "- Performance differences do not establish energy efficiency.",
    "",
])

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text("\n".join(lines) + "\n")

print(output.read_text())
print(f"Analysis saved: {output}")
