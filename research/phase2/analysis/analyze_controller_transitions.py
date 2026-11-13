
import csv
import math
import statistics
from collections import Counter, defaultdict
from pathlib import Path

SOURCE = Path(
    "research/phase2/evidence/controller-transitions/"
    "controller_transitions_1800_windows.csv"
)

OUTPUT = Path(
    "research/phase2/analysis/"
    "controller_transition_analysis.md"
)

WORKLOADS = [
    "cpuIntensive",
    "variableLatency",
    "mixed"
]

VERSIONS = ["v1", "v2"]

with SOURCE.open(newline="") as file:
    rows = list(csv.DictReader(file))

assert len(rows) == 1800, (
    f"Expected 1800 windows, found {len(rows)}"
)

groups = defaultdict(list)

for row in rows:
    key = (
        row["workload"],
        row["version"],
        int(row["trial"])
    )
    groups[key].append(row)

assert len(groups) == 180, (
    f"Expected 180 trial groups, found {len(groups)}"
)

expected_keys = {
    (workload, version, trial)
    for workload in WORKLOADS
    for version in VERSIONS
    for trial in range(1, 31)
}

assert set(groups) == expected_keys, (
    "Unexpected or missing workload/version/trial groups"
)

for key, group in groups.items():
    group.sort(key=lambda r: int(r["window"]))

    windows = [int(r["window"]) for r in group]

    assert windows == list(range(1, 11)), (
        f"Invalid window sequence: {key}"
    )

    for index, row in enumerate(group):
        previous = int(row["previous_concurrency"])
        following = int(row["next_concurrency"])
        changed = int(row["changed"])

        assert 1 <= previous <= 8
        assert 1 <= following <= 8
        assert changed in (0, 1)
        assert changed == int(previous != following)

        assert int(row["completed_tasks"]) == 10

        for column in [
            "throughput_tasks_per_second",
            "mean_latency_ms",
            "elapsed_ms"
        ]:
            assert math.isfinite(float(row[column]))

        assert float(row["elapsed_ms"]) > 0

        if index > 0:
            prior = group[index - 1]
            assert previous == int(
                prior["next_concurrency"]
            ), f"Transition discontinuity: {key}"


def mean(values):
    return statistics.mean(values)


def summarize(workload, version):
    trials = [
        groups[(workload, version, trial)]
        for trial in range(1, 31)
    ]

    all_rows = [
        row for trial in trials for row in trial
    ]

    changes = []
    reversals = []
    final_levels = []
    mean_concurrency = []

    for trial in trials:
        actual_changes = [
            int(row["next_concurrency"])
            - int(row["previous_concurrency"])
            for row in trial
        ]

        changes.append(
            sum(delta != 0 for delta in actual_changes)
        )

        directions = [
            1 if delta > 0 else -1
            for delta in actual_changes
            if delta != 0
        ]

        reversals.append(
            sum(
                directions[i] != directions[i - 1]
                for i in range(1, len(directions))
            )
        )

        final_levels.append(
            int(trial[-1]["next_concurrency"])
        )

        mean_concurrency.append(
            mean([
                int(row["previous_concurrency"])
                for row in trial
            ])
        )

    decisions = Counter(
        row["decision"] for row in all_rows
    )

    levels = Counter(
        int(row["previous_concurrency"])
        for row in all_rows
    )

    elapsed_by_level = defaultdict(float)
    throughput_by_level = defaultdict(list)

    for row in all_rows:
        level = int(row["previous_concurrency"])

        elapsed_by_level[level] += float(
            row["elapsed_ms"]
        )

        throughput_by_level[level].append(
            float(row["throughput_tasks_per_second"])
        )

    return {
        "changes": mean(changes),
        "reversals": mean(reversals),
        "final": mean(final_levels),
        "concurrency": mean(mean_concurrency),
        "decisions": decisions,
        "levels": levels,
        "elapsed": elapsed_by_level,
        "throughput": throughput_by_level
    }


lines = [
    "# AdaptivePerfKit Controller Transition Analysis",
    "",
    "## Dataset",
    "",
    "- Total measurement windows: 1800",
    "- Workloads: 3",
    "- Controller versions: 2",
    "- Trials per combination: 30",
    "- Windows per trial: 10",
    "",
    "## Controller Behavior Summary",
    "",
    "| Workload | Version | Mean actual changes | "
    "Mean direction reversals | Mean active concurrency | "
    "Mean final recommended concurrency |",
    "|---|---|---:|---:|---:|---:|"
]

summaries = {}

for workload in WORKLOADS:
    for version in VERSIONS:
        result = summarize(workload, version)
        summaries[(workload, version)] = result

        lines.append(
            f"| {workload} | {version} | "
            f"{result['changes']:.2f} | "
            f"{result['reversals']:.2f} | "
            f"{result['concurrency']:.2f} | "
            f"{result['final']:.2f} |"
        )

lines.extend([
    "",
    "## Controller Decision Frequencies",
    ""
])

for workload in WORKLOADS:
    for version in VERSIONS:
        result = summaries[(workload, version)]

        lines.append(f"### {workload} / {version}")
        lines.append("")

        for decision, count in sorted(
            result["decisions"].items()
        ):
            lines.append(f"- {decision}: {count}")

        lines.append("")

lines.extend([
    "## Concurrency Distribution and Throughput",
    "",
    "Window share is the fraction of completed measurement "
    "windows using each concurrency level.",
    "",
    "Elapsed share is the fraction of summed measured "
    "window durations at that level.",
    "",
    "| Workload | Version | Concurrency | "
    "Windows | Window share (%) | Elapsed share (%) | "
    "Mean window throughput (tasks/s) |",
    "|---|---|---:|---:|---:|---:|---:|"
])

for workload in WORKLOADS:
    for version in VERSIONS:
        result = summaries[(workload, version)]

        total_windows = sum(
            result["levels"].values()
        )

        total_elapsed = sum(
            result["elapsed"].values()
        )

        for level in sorted(result["levels"]):
            count = result["levels"][level]

            window_share = (
                count / total_windows * 100
            )

            elapsed_share = (
                result["elapsed"][level]
                / total_elapsed * 100
            )

            throughput = mean(
                result["throughput"][level]
            )

            lines.append(
                f"| {workload} | {version} | "
                f"{level} | {count} | "
                f"{window_share:.2f} | "
                f"{elapsed_share:.2f} | "
                f"{throughput:.3f} |"
            )

lines.extend([
    "",
    "## Interpretation",
    "",
    "- Actual changes exclude decisions that retain "
    "the same concurrency level.",
    "- Direction reversals count changes in the "
    "direction of nonzero concurrency adjustments.",
    "- Mean active concurrency is calculated across "
    "executed measurement windows.",
    "- Final recommended concurrency is calculated "
    "after the final window and may never be executed.",
    "- Window throughput is observational and should "
    "not be interpreted as a causal estimate of "
    "optimal concurrency.",
    "",
    "## Limitations",
    "",
    "- This diagnostic dataset was collected separately "
    "from the earlier 270-trial benchmark.",
    "- Workload order and thermal conditions may "
    "affect comparisons.",
    "- A direction reversal does not necessarily "
    "indicate harmful oscillation.",
    "- Mean window throughput is not equivalent to "
    "end-to-end application throughput.",
    "- Measurements are from synthetic workloads.",
    "- Physical-device validation remains pending.",
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

print(
    "\nAnalysis saved:",
    OUTPUT
)
