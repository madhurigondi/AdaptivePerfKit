# AdaptivePerfKit — CPU Benchmark Experimental Protocol

**Protocol ID:** APK-CPU-001  
**Version:** 1.0  
**SDK Version:** 0.1.0  
**Research Phase:** Phase 1 — Baseline Performance Monitoring  
**Status:** Preliminary reproducibility protocol

## 1. Research Objective

To measure and characterize CPU workload execution times using AdaptivePerfKit on an iOS Simulator.

The experiment evaluates the operation of the SDK's execution-time measurement and data collection capabilities.

This phase does not evaluate adaptive optimization improvements.

## 2. Research Questions

**RQ1:** Can AdaptivePerfKit measure and record CPU benchmark execution times?

**RQ2:** What variation is observed across repeated CPU benchmark executions?

**RQ3:** Can benchmark measurements be exported and analyzed reproducibly?

## 3. Experimental Environment

| Component | Configuration |
|---|---|
| Host Processor | Apple M4 Pro |
| Architecture | ARM64 |
| macOS | 26.7 |
| Xcode | 26.3 |
| Swift | 6.2.4 |
| Simulator | iPhone 17 |
| Simulator Runtime | iOS 26.3 |
| Benchmark-Reported OS | iOS 26.3.1 |
| SDK | AdaptivePerfKit 0.1.0 |
| Application | AdaptivePerfDemo |

The Simulator runtime label and benchmark-reported OS version are retained separately because they differ.

## 4. Experimental Workload

The workload is identified as `CPU Benchmark` in the exported records.

The precise workload implementation, including iteration count, computational operations, concurrency configuration, and compiler optimization settings, must be documented from the source code before exact workload reproducibility can be claimed.

## 5. Benchmark Execution Procedure

The recorded baseline dataset was collected using two batches containing five executions each.

For a reproduction attempt:

1. Open AdaptivePerfDemo in Xcode.
2. Select the iPhone 17 Simulator.
3. Build and launch the application.
4. Initialize AdaptivePerfKit.
5. Navigate to the CPU benchmark section.
6. Execute one batch of five CPU benchmarks.
7. Record the resulting measurements.
8. Execute a second batch of five benchmarks.
9. Export the recorded benchmark dataset as JSON.
10. Preserve the original exported file without modification.

Record any changes to this procedure, including warm-up runs, application restarts, background workload conditions, and delays between batches.

## 6. Data Collection

Each benchmark record should contain:

- Unique record identifier
- Batch identifier
- Run number
- Workload name
- Execution duration in milliseconds
- Execution timestamp
- Device model
- Operating system version
- Simulator indicator
- SDK version

The baseline JSON dataset contains 10 observations across two batches.

A separately captured CSV dataset contains another batch of five observations. It should not be treated as a direct CSV representation of the 10-record JSON dataset.

## 7. Statistical Analysis

The benchmark data is analyzed using:

`research/datasets/processed/analyze_benchmarks.py`

The following descriptive statistics are calculated:

| Metric | Method |
|---|---|
| Mean | Arithmetic average |
| Median | Median of execution times |
| Minimum | Smallest execution time |
| Maximum | Largest execution time |
| P95 | Linearly interpolated 95th percentile |
| Standard Deviation | Sample standard deviation |
| Coefficient of Variation | Standard deviation divided by mean, multiplied by 100 |

## 8. Baseline Results

| Metric | Result |
|---|---:|
| Total Runs | 10 |
| Total Batches | 2 |
| Mean | 623.05 ms |
| Median | 613.45 ms |
| Minimum | 607.99 ms |
| Maximum | 676.78 ms |
| P95 | 658.75 ms |
| Standard Deviation | 21.04 ms |
| Coefficient of Variation | 3.38% |

These are descriptive results from the recorded Simulator measurements.

## 9. Research Figures

Three charts are generated using `generate_charts.py`:

1. Execution Time by Run
2. Batch Performance Comparison
3. Execution Time Distribution

The figures are stored in:

`research/datasets/processed/charts/`

## 10. Reproducibility Procedure

An independent evaluator should:

1. Obtain the AdaptivePerfKit source code and record its Git commit.
2. Verify the supplied evidence checksums.
3. Confirm the development environment.
4. Inspect the CPU workload implementation.
5. Execute the benchmark using the documented procedure.
6. Export and preserve the newly generated measurements.
7. Run the statistical analysis script.
8. Compare results with the published baseline.
9. Record any deviations and explain possible causes.

Exact numerical agreement is not required because execution times may vary across systems and experimental conditions.

## 11. Experimental Limitations

- Measurements were collected on an iOS Simulator.
- Only 10 observations were included in the analyzed baseline.
- Host CPU scheduling and background activity were not controlled or recorded.
- Warm-up behavior and thermal conditions were not documented.
- No physical-device measurements were collected.
- No adaptive-versus-non-adaptive comparison was performed.
- The current experiment does not establish improved energy efficiency or application responsiveness.

## 12. Validation Criteria

The reproduction should demonstrate that:

- The SDK initializes successfully.
- CPU benchmark