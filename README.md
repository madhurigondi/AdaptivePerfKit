# AdaptivePerfKit

**Research framework for adaptive concurrency optimization in Swift and iOS applications**

**Research baseline:** `v3-research-baseline`  
**Implementation:** Swift Package; iOS simulator research application  
**Development environment:** Xcode 26 / Swift 6.2 (reported project environment)  
**Research status:** Phase 1 measurement infrastructure and Phase 2 V1–V3 controller experiments completed; independent evaluation pending

## Overview

AdaptivePerfKit is a research-oriented Swift framework for measuring workload execution and investigating feedback-driven concurrency control. It combines performance monitoring, benchmark storage and export, fixed-concurrency execution, and successive adaptive controller implementations.

The research investigates whether dynamically selecting task concurrency can reduce completion time relative to fixed-concurrency execution under different workload characteristics. Results are specific to the tested implementations and environments; they do not establish general superiority across devices or workloads.

## Research contributions

- **Measurement infrastructure:** Execution timing, summary statistics, benchmark records, JSON persistence, and CSV/JSON export.
- **Controller evolution:** V1 and V2 feedback-based controllers and a V3 continuous adaptive executor, preserved for comparative analysis.
- **Controlled benchmarking:** Fixed concurrency of four compared with V1, V2, and V3 on CPU-intensive, variable-latency, and mixed synthetic workloads.
- **Research evidence:** Trial-level datasets, controller diagnostics, paired comparisons, and analysis reports retained under `research/`.
- **Reproducibility:** Swift Package source and tests, versioned research baseline, and methodology documentation.

## Architecture

```text
                    Workload / Benchmark Runner
                               |
                    +----------+----------+
                    |                     |
           FixedConcurrencyExecutor    Adaptive execution
                    |                     |
                    |         +-----------+-----------+
                    |         |           |           |
                    |        V1          V2          V3
                    |         |           |           |
                    +---------+-----------+-----------+
                               |
                     Performance measurement
                               |
                    Benchmark records / stats
                               |
                       JSON / CSV export
                               |
                       Research analysis
```

The diagram is a conceptual overview rather than a precise call graph. See [architecture documentation](docs/ARCHITECTURE.md) and the source code for implementation details.

## Controller versions

| Configuration | Research role |
|---|---|
| `fixed4` | Fixed concurrency of four; reference baseline |
| `adaptiveV1` | Initial feedback-based controller |
| `adaptiveV2` | Experimental controller refinement |
| `adaptiveV3` | Continuous adaptive execution design evaluated in Phase 2 |

V3 changes execution/feedback-window semantics relative to V1 and V2. Comparisons therefore evaluate the implemented execution strategies as a whole, not solely an isolated controller decision rule.

## Experimental methodology

The reported four-configuration experiment measured three synthetic workloads under four execution configurations, with 30 measured trials per combination (**360 measured executions**). The earlier multi-workload experiment used three configurations and 30 trials per combination (**270 measured executions**). Separate diagnostics examined controller transitions and window overhead.

Workloads:

- **CPU-intensive:** Synthetic compute-focused tasks.
- **Variable-latency:** Synthetic tasks with varying completion latency.
- **Mixed:** Synthetic workload combining task characteristics.

The analysis uses descriptive statistics and paired differences by experimental round. Pairing by round does not guarantee identical runtime conditions; confidence intervals assume approximately independent paired rounds and are exploratory.

## Four-configuration benchmark results

**Mean end-to-end execution time (milliseconds; lower is better)**

| Workload | Fixed 4 | Adaptive V1 | Adaptive V2 | Adaptive V3 |
|---|---:|---:|---:|---:|
| CPU-intensive | 282.127 | 291.742 | 291.588 | **280.520** |
| Variable-latency | 308.485 | 355.431 | 353.898 | **264.970** |
| Mixed | 447.129 | 533.829 | 541.970 | **395.167** |

**V3 compared with Fixed 4**

| Workload | Mean improvement | Mean saving | Approximate 95% CI for saving |
|---|---:|---:|---:|
| CPU-intensive | +0.57% | 1.607 ms | −2.186 to 5.401 ms |
| Variable-latency | +14.11% | 43.515 ms | 42.339 to 44.690 ms |
| Mixed | +11.62% | 51.962 ms | 50.261 to 53.664 ms |

Positive savings favor V3. The CPU-intensive interval includes zero and does **not** establish a reliable advantage. The variable-latency and mixed intervals exclude zero under the analysis assumptions; they are not adjusted for multiple comparisons.

The full analysis is recorded in `research/phase2/analysis/four_configuration_analysis.md` (when present in the repository).

### Simulator benchmark observations

A separate 360-trial iOS Simulator run reported the following displayed mean times (ms):

| Workload | Fixed 4 | V1 | V2 | V3 |
|---|---:|---:|---:|---:|
| CPU-intensive | 2.25 | 2.25 | 2.26 | 1.83 |
| Variable-latency | 94.81 | 116.83 | 119.88 | 84.76 |
| Mixed | 52.23 | 55.96 | 55.17 | 54.14 |

These simulator observations differ from the package-level experiment in absolute timing and relative behavior. In particular, V3 was slower than Fixed 4 for the simulator mixed workload. The datasets should not be pooled or interpreted as measurements from identical conditions. Consult exported trial-level CSV files and environment metadata before making inferential claims from simulator results.

## Source layout

```text
AdaptivePerfKit/
├── Package.swift
├── Sources/AdaptivePerfKit/
├── Tests/
├── docs/
├── research/
└── README.md
```

Key source components include performance monitoring, benchmark records/statistics/persistence/export, fixed and adaptive executors, controller implementations, and research workloads. Exact file names and available experiments are defined by the tagged source tree.

## Build and test

Clone the repository and check out the frozen evaluation tag:

```bash
git clone https://github.com/madhurigondi/AdaptivePerfKit.git
cd AdaptivePerfKit
git checkout v3-research-baseline
swift test
```

Use a compatible Apple development environment. Some simulator-specific activities require Xcode and the separate demo application, if distributed. The Swift Package test command does not by itself reproduce every benchmark result.

To inspect the existing analysis scripts and datasets:

```bash
find research -type f | sort
```

For the four-configuration analysis, if the corresponding script and input CSV are included:

```bash
python3 research/phase2/analysis/analyze_four_configuration.py
```

Before running any script, inspect its inputs, outputs, dependencies, and whether it overwrites tracked analysis files. Follow [experimental methodology](docs/EXPERIMENTAL_METHODOLOGY.md) for the intended benchmark procedure. A complete external reproduction requires matching workload definitions, execution configuration, trial count, hardware/software metadata, and analysis methods.

## Data integrity

Original experimental measurements should be preserved separately from synthetic unit-test fixtures. Analysis reports and associated SHA-256 files, where available, allow integrity checking from the repository root, for example:

```bash
shasum -a 256 -c research/phase2/analysis/four_configuration_analysis.sha256
```

A checksum validates file integrity against the recorded hash; it does not independently validate the experimental methodology or results.

## Limitations

- Workloads are synthetic and may not represent production applications.
- Package-level results come from the reported test environment; broader device generalization is not established.
- Simulator execution is not equivalent to physical iPhone validation.
- V3 uses different execution/feedback-window semantics from V1/V2, affecting causal interpretation.
- Trial pairing by round does not eliminate temporal, scheduling, or thermal confounding.
- Reported confidence intervals assume approximately independent paired rounds; multiple comparisons are exploratory.
- CPU energy consumption and battery-life improvements were not directly measured.
- The displayed simulator summary alone is insufficient for independent statistical validation without raw measurements.

## Independent academic evaluation

Researchers are invited to examine the tagged implementation, assess the experimental design, reproduce results where feasible, identify limitations, and report both supporting and contradictory findings. Independent reproduction or technical critique should document environment details, exact source version, commands, raw outputs, and deviations from the published procedure.

The repository being public does not imply that its results have been independently reproduced or peer reviewed.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Experimental methodology](docs/EXPERIMENTAL_METHODOLOGY.md)
- [Evidence inventory](research/EVIDENCE_INVENTORY.md)
- [Four-configuration analysis](research/phase2/analysis/four_configuration_analysis.md)

## Research integrity and citation

Only actual benchmark measurements should be presented as experimental findings. Preserve raw datasets and report null or contradictory results alongside improvements. If you use this framework in research, reference the repository URL and the exact Git tag or commit hash. A formal citation and license can be added after the project owner selects the appropriate terms.

## Project status

**Frozen research implementation: V3 (`v3-research-baseline`).** Phase 1 and Phase 2 development and internal experiments are complete. External reproduction, independent academic assessment, and physical-device validation remain future work.
