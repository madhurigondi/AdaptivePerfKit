# AdaptivePerfKit — Reproducibility Guide

**Research baseline:** `v3-research-baseline`  
**Scope:** Phase 1 measurement infrastructure and Phase 2 V1/V2/V3 experimental comparison  
**Status:** Instructions based on the repository inventory and reported experiments; independent reproduction has not yet been performed.

## 1. Research scope

AdaptivePerfKit is a Swift research framework for studying workload execution and adaptive concurrency. The Phase 2 comparisons include `fixed4`, `adaptiveV1`, `adaptiveV2`, and `adaptiveV3`, evaluated on `cpuIntensive`, `variableLatency`, and `mixed` synthetic workloads. The four-configuration experiment contains 30 measured trials per workload/configuration (360 executions). Separate datasets capture earlier multi-workload comparisons, controller transitions, window overhead, and iOS Simulator observations.

The results are environment-specific. V3's execution and feedback-window semantics differ from V1/V2; therefore, comparisons assess complete execution strategies rather than only controller decision logic.

## 2. Prerequisites

- macOS with Xcode 26 and the Swift 6.2 toolchain used for the reported development environment (or document any deviations).
- Git, `swift`, `python3`, and macOS `shasum`.
- Python dependencies required by individual scripts (inspect imports before execution). Do not assume a particular third-party package is installed.
- For simulator validation, a compatible iOS Simulator and the separately configured demo application, if available. The Swift Package alone may not include the demo app.

Record machine model, chip, memory, macOS version, Xcode/Swift versions, simulator model/runtime, power state, and background activity.

## 3. Clone and identify the frozen baseline

```bash
git clone https://github.com/madhurigondi/AdaptivePerfKit.git
cd AdaptivePerfKit
git fetch --tags
git checkout v3-research-baseline
git rev-parse HEAD
git status --short
```

**Important:** The baseline tag was created before the later README update. Documentation added to `main` after tagging may not appear when the tag is checked out. For the latest documentation, inspect `main`; for baseline experiments, use the tagged code and record its commit hash. Do not move the baseline tag.

## 4. Build and unit tests

From the repository root:

```bash
swift --version
xcodebuild -version
swift build
swift test
```

Save command output and report test counts, failures, warnings, and environment information. A successful unit-test run validates only the tested behaviors; it does not reproduce the benchmark results.

## 5. Repository evidence map

| Experiment | Raw data | Analysis script | Report |
|---|---|---|---|
| Four-configuration (360 executions) | `research/phase2/evidence/four-configuration/four_configuration_360_trials.csv` | `research/phase2/analysis/analyze_four_configuration.py` | `research/phase2/analysis/four_configuration_analysis.md` |
| Multi-workload (270 executions) | `research/phase2/evidence/multi-workload/multi_workload_270_trials.csv` | `research/phase2/analysis/analyze_multi_workload.py` | `research/phase2/analysis/multi_workload_analysis.md` |
| Controller transitions (1,800 windows) | `research/phase2/evidence/controller-transitions/controller_transitions_1800_windows.csv` | `research/phase2/analysis/analyze_controller_transitions.py` | `research/phase2/analysis/controller_transition_analysis.md` |
| Controller comparison (90 rows plus header reported) | `research/phase2/evidence/controller-comparison/controller_comparison_30_trials.csv` | `research/phase2/analysis/analyze_controller_comparison.py` | `research/phase2/analysis/controller_comparison_analysis.md` |
| Window overhead (270 executions) | `research/phase2/evidence/window-overhead/window_overhead_270_trials.csv` | `research/phase2/analysis/analyze_window_overhead.py` | `research/phase2/analysis/window_overhead_analysis.md` |
| Simulator (360 executions) | `research/phase2/evidence/simulator-validation/simulator_benchmark_360_trials.csv` | `research/phase2/analysis/analyze_simulator.py` | `research/phase2/analysis/simulator_benchmark_analysis.md` |

Phase 1 evidence is under `research/datasets/` and `research/evidence/`. The `research/phase2/analysis/analyze_simulator 2.py` and `simulator_benchmark_analysis 2.md` files should be inspected before deciding whether they are duplicates or alternate versions.

## 6. Verify existing evidence without overwriting reports

Run these commands from the repository root:

```bash
shasum -a 256 -c research/phase2/analysis/four_configuration_analysis.sha256
shasum -a 256 -c research/phase2/analysis/multi_workload_analysis.sha256
shasum -a 256 -c research/phase2/analysis/controller_transition_analysis.sha256
shasum -a 256 -c research/phase2/analysis/window_overhead_analysis.sha256
shasum -a 256 -c research/phase2/analysis/simulator_benchmark_analysis.sha256
```

Some `.sha256` manifests may contain repository-root-relative paths. If verification fails due to missing paths, check the current directory and manifest contents before concluding a file was altered. A matching hash confirms integrity relative to the manifest, not experimental validity.

For directory-based `SHA256SUMS.txt` manifests, inspect paths before verification:

```bash
cat research/phase2/evidence/four-configuration/SHA256SUMS.txt
```

## 7. Recompute analysis from recorded CSV files

**Before running scripts:** inspect each script's input paths, imported dependencies, and output destinations. Existing scripts may overwrite tracked Markdown reports. Work in a disposable clone or copy if necessary.

Example for the four-configuration experiment:

```bash
python3 research/phase2/analysis/analyze_four_configuration.py
```

Compare regenerated statistics with the committed report. Record exact command, script hash, dataset hash, Python version, any dependencies, and numerical differences. Repeat with other analysis scripts only after inspecting them.

### Previously reported four-configuration results

Mean execution time in milliseconds (lower is better):

| Workload | Fixed 4 | V1 | V2 | V3 |
|---|---:|---:|---:|---:|
| CPU-intensive | 282.127 | 291.742 | 291.588 | 280.520 |
| Variable-latency | 308.485 | 355.431 | 353.898 | 264.970 |
| Mixed | 447.129 | 533.829 | 541.970 | 395.167 |

V3 vs Fixed 4 reported mean improvements were **0.57%** (CPU-intensive; approximate 95% CI for saving −2.186 to 5.401 ms), **14.11%** (variable-latency; 42.339 to 44.690 ms), and **11.62%** (mixed; 50.261 to 53.664 ms). These are reported observations, not newly reproduced findings. The CPU-intensive interval includes zero. Intervals are exploratory and not multiplicity-adjusted.

## 8. Re-running benchmark experiments

Benchmark *execution* is separate from CSV *analysis*. The file inventory does not establish a verified command-line entry point for all benchmark runners. Review the source, tests, experiment methodology, and benchmark logs to identify the exact runner and its arguments before instructing independent evaluators to regenerate the 360 trials.

For each rerun, preserve:

1. Exact Git commit/tag and any local modifications.
2. Hardware, OS, toolchain, simulator/runtime (if applicable), power and thermal conditions.
3. Workload definitions, task count, window size, controller configuration, trial count, warm-up protocol, and ordering/randomization.
4. Raw CSV, logs, error output, timestamps, and checksums.
5. Statistical script versions and resulting analysis.

Do not compare results from different workload definitions or environments as if directly interchangeable.

## 9. Simulator validation

The separate 360-trial simulator summary reported mean times (ms):

| Workload | Fixed 4 | V1 | V2 | V3 |
|---|---:|---:|---:|---:|
| CPU-intensive | 2.25 | 2.25 | 2.26 | 1.83 |
| Variable-latency | 94.81 | 116.83 | 119.88 | 84.76 |
| Mixed | 52.23 | 55.96 | 55.17 | 54.14 |

The simulator mixed-workload result does **not** show a V3 advantage over Fixed 4. Do not pool simulator and package-level results or claim physical-device performance/energy improvements from them.

## 10. Independent evaluator report template

- **Evaluator and affiliation:**
- **Date, exact commit/tag:**
- **Machine/OS/Xcode/Swift/Python versions:**
- **Materials inspected:**
- **Build/test commands and results:**
- **Datasets and checksums verified:**
- **Analysis commands and reproduced numerical findings:**
- **Benchmark execution attempted?** Yes / No; exact method and deviations:
- **Technical strengths and novelty assessment:**
- **Threats to validity / contradictory findings:**
- **Recommendations and supporting artifacts:**

Evaluators should provide independent observations, not a prewritten endorsement. Negative or inconclusive results are valuable research findings and should be retained.

## 11. Known limitations and open validation

Synthetic workloads; single reported package-level environment; possible temporal, scheduling, and thermal confounding; exploratory confidence intervals; differing V3 execution semantics; no direct CPU-energy measurement; and no completed physical-iPhone validation. External reproduction remains pending.

## 12. Additional documentation

- [`README.md`](README.md)
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/EXPERIMENTAL_METHODOLOGY.md`](docs/EXPERIMENTAL_METHODOLOGY.md)
- [`research/evidence/EVIDENCE_INDEX.md`](research/evidence/EVIDENCE_INDEX.md)
- [`research/phase2/analysis/four_configuration_analysis.md`](research/phase2/analysis/four_configuration_analysis.md)
