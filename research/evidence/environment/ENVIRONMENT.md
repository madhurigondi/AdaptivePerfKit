# AdaptivePerfKit — Research Environment

## 1. Project Information

- **Project:** AdaptivePerfKit — iOS Performance Intelligence SDK
- **SDK Version:** 0.1.0
- **Development Language:** Swift
- **Research Phase:** Phase 1 — Baseline Performance Monitoring
- **Test Application:** AdaptivePerfDemo

## 2. Development Hardware

| Property | Value |
|---|---|
| Processor | Apple M4 Pro |
| Architecture | ARM64 |
| Operating System | macOS 26.7 |
| macOS Build | 25G229 |

## 3. Development Software

| Component | Version |
|---|---|
| Xcode | 26.3 |
| Xcode Build | 17C529 |
| Swift | 6.2.4 |
| Swift Package Tools | 6.2 |
| SDK Minimum iOS Deployment | iOS 17.0 |

## 4. Simulator Configuration

- **Device:** iPhone 17 Simulator
- **Simulator Runtime:** iOS 26.3
- **OS reported by benchmark records:** iOS 26.3.1
- **Physical Device:** Not used
- **Execution Environment:** Apple Silicon Mac

The difference between the Simulator runtime label and the OS version recorded by the application is retained as reported and should be verified before final publication.

## 5. Benchmark Configuration

- **Workload:** CPU Benchmark
- **Recorded Executions:** 10
- **Benchmark Batches:** 2
- **Executions per Batch:** 5
- **Measurement Unit:** Milliseconds
- **Data Collection:** AdaptivePerfKit SDK v0.1.0

## 6. Baseline Performance Results

| Metric | Result |
|---|---:|
| Mean | 623.05 ms |
| Median | 613.45 ms |
| Minimum | 607.99 ms |
| Maximum | 676.78 ms |
| P95 | 658.75 ms |
| Sample Standard Deviation | 21.04 ms |
| Coefficient of Variation | 3.38% |

P95 was calculated using linear interpolation between adjacent sorted observations.

## 7. Research Limitations

All current performance measurements were collected using an iOS Simulator.

Simulator measurements may be affected by host CPU scheduling, background processes, thermal conditions, and other host-system activities.

These results establish an initial baseline only. They do not establish performance improvements from adaptive optimization, nor do they demonstrate performance on physical iOS devices.

Additional controlled experiments and independent evaluation will be required to validate future optimization claims.

## 8. Reproducibility Artifacts

- `research/datasets/raw/adaptiveperf_phase1_cpu_raw.json`
- `research/datasets/raw/adaptiveperf_phase1_cpu_raw.csv`
- `research/datasets/processed/analyze_benchmarks.py`
- `research/datasets/processed/benchmark_statistics.csv`
- `research/datasets/processed/generate_charts.py`
- `research/datasets/processed/charts/`

The JSON dataset contains the 10 observations used for the reported statistics. The separately captured CSV dataset must be checked for record correspondence before combining datasets.

## 9. Evidence Status

- SDK initialization: Completed
- CPU benchmark execution: Completed
- Benchmark statistics: Completed
- Raw dataset preservation: Completed
- Research charts: Completed
- Environment documentation: Prepared
- Physical-device validation: Pending
- Independent evaluation: Pending
