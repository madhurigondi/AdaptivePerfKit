import csv
import math
import statistics
from pathlib import Path

source = Path(
    "research/phase2/evidence/controller-comparison/"
    "controller_comparison_30_trials.csv"
)

with source.open(newline="") as file:
    rows = list(csv.DictReader(file))

modes = ["fixed4", "adaptiveV1", "adaptiveV2"]

groups = {
    mode: sorted(
        [r for r in rows if r["configuration"] == mode],
        key=lambda r: int(r["trial"])
    )
    for mode in modes
}

assert len(rows) == 90, "Expected 90 measurements"

for mode in modes:
    trials = [int(r["trial"]) for r in groups[mode]]
    assert trials == list(range(1, 31)), (
        f"Missing or duplicate trials for {mode}"
    )

def percentile(values, probability):
    ordered = sorted(values)
    index = math.ceil(len(ordered) * probability) - 1
    return ordered[index]

def durations(mode):
    return [
        float(r["duration_ms"])
        for r in groups[mode]
    ]

def mean_ci(values):
    n = len(values)
    mean = statistics.mean(values)
    sd = statistics.stdev(values)

    # Two-sided 95% Student-t critical value, df=29.
    t_critical = 2.04523
    margin = t_critical * sd / math.sqrt(n)

    return mean, mean - margin, mean + margin

lines = [
    "# V1 vs V2 Controller Performance Analysis",
    "",
    "## Descriptive Statistics",
    "",
    "| Configuration | Mean (ms) | Median (ms) | SD (ms) | P95 (ms) | Mean throughput (tasks/s) |",
    "|---|---:|---:|---:|---:|---:|"
]

for mode in modes:
    values = durations(mode)
    throughputs = [
        float(r["throughput_tasks_per_second"])
        for r in groups[mode]
    ]

    lines.append(
        f"| {mode} | "
        f"{statistics.mean(values):.3f} | "
        f"{statistics.median(values):.3f} | "
        f"{statistics.stdev(values):.3f} | "
        f"{percentile(values, 0.95):.3f} | "
        f"{statistics.mean(throughputs):.3f} |"
    )

v1 = durations("adaptiveV1")
v2 = durations("adaptiveV2")
fixed = durations("fixed4")

def comparison(name, baseline, candidate):
    differences = [
        a - b for a, b in zip(baseline, candidate)
    ]

    mean, lower, upper = mean_ci(differences)

    improvement = (
        (statistics.mean(baseline) - statistics.mean(candidate))
        / statistics.mean(baseline)
        * 100
    )

    return [
        f"### {name}",
        "",
        f"- Mean execution-time improvement: {improvement:.2f}%",
        f"- Mean paired time saving: {mean:.3f} ms",
        f"- Approximate 95% CI for paired saving: "
        f"[{lower:.3f}, {upper:.3f}] ms",
        ""
    ]

lines.extend([
    "",
    "## Paired Comparisons",
    "",
    "Positive savings indicate the candidate completed faster.",
    "Trial numbers are paired by experimental round.",
    ""
])

lines.extend(comparison("V2 vs V1", v1, v2))
lines.extend(comparison("V2 vs Fixed 4", fixed, v2))

lines.extend([
    "## Limitations",
    "",
    "- Measurements use a synthetic suspension-heavy workload.",
    "- Results are from the current test environment.",
    "- Controller and instrumentation overhead are included.",
    "- Confidence intervals assume approximately independent paired rounds.",
    "- Repeated measurements on one machine may exhibit temporal correlation.",
    "- Physical iPhone validation and additional workloads remain necessary.",
    ""
])

output = Path(
    "research/phase2/analysis/"
    "controller_comparison_analysis.md"
)

output.write_text("\n".join(lines) + "\n")

print(output.read_text())
print(f"\nAnalysis saved to: {output}")
