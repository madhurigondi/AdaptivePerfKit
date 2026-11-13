# AdaptivePerfKit — Phase 1 Research Evidence Index

**Project:** AdaptivePerfKit — iOS Performance Intelligence SDK  
**SDK Version:** 0.1.0  
**Research Phase:** Phase 1 — Baseline Performance Monitoring  
**Protocol ID:** APK-CPU-001  
**Evidence Status:** Preliminary Technical Validation

---

## 1. Project Source Code

The AdaptivePerfKit project contains a modular Swift Package designed to measure, record, analyze, and export iOS application performance measurements.

| Component | Location |
|---|---|
| SDK Source Code | `Sources/AdaptivePerfKit/` |
| SDK Unit Tests | `Tests/AdaptivePerfKitTests/` |
| Swift Package Manifest | `Package.swift` |
| Demo Application | `AdaptivePerfDemo/` (separate project) |

### Implemented SDK Components

- `AdaptivePerfKit.swift` — SDK entry point
- `PerformanceMonitor.swift` — Execution-time measurement
- `BenchmarkRecord.swift` — Structured benchmark records
- `BenchmarkStatistics.swift` — Benchmark statistical calculations
- `BenchmarkDataStore.swift` — Benchmark data management
- `BenchmarkPersistence.swift` — Persistent storage
- `BenchmarkExporter.swift` — JSON and CSV export

---

## 2. Raw Benchmark Datasets

The baseline experiment contains 10 CPU benchmark observations across two batches, with five measurements per batch.

| Evidence | Location |
|---|---|
| Original JSON Dataset | `research/datasets/raw/adaptiveperf_phase1_cpu_raw.json` |
| Separately Captured CSV Dataset | `research/datasets/raw/adaptiveperf_phase1_cpu_raw.csv` |

### Data Provenance

The JSON dataset contains the 10 measurements used for the reported baseline statistics.

The separately captured CSV dataset contains five observations from another benchmark batch and must not be described as a direct export of the 10-record JSON dataset.

All raw datasets should be preserved without modification.

---

## 3. Processed Research Data

| Evidence | Location |
|---|---|
| Statistical Analysis Script | `research/datasets/processed/analyze_benchmarks.py` |
| Statistical Results CSV | `research/datasets/processed/benchmark_statistics.csv` |
| Chart Generation Script | `research/datasets/processed/generate_charts.py` |

The statistical analysis script calculates descriptive statistics using the original 10-record JSON dataset.

The chart generation script produces figures from the same source dataset.

---

## 4. Research Performance Figures

| Figure | Location |
|---|---|
| Figure 1 — CPU Execution Time by Run | `research/evidence/reports/figures/01_execution_time_by_run.png` |
| Figure 2 — CPU Batch Performance Comparison | `research/evidence/reports/figures/02_batch_performance_comparison.png` |
| Figure 3 — CPU Execution Time Distribution | `research/evidence/reports/figures/03_execution_time_distribution.png` |

### Original Generated Figures

The original generated charts are also preserved under:

`research/datasets/processed/charts/`

All three figures were generated from the recorded CPU benchmark measurements.

---

## 5. Testing Evidence

| Evidence | Location |
|---|---|
| Unit-Test Screenshot 1 | `research/evidence/test-results/01_unit_tests_passed.png` |
| Unit-Test Screenshot 2 | `research/evidence/test-results/02_unit_tests_passed.png` |
| Checksum Verification Log | `research/evidence/test-results/checksum_verification_log.txt` |
| File Verification Log | `research/evidence/test-results/file_verification_log.txt` |

### Test Evidence Description

The unit-test screenshots document observed automated test execution.

The file verification log records the presence and nonempty status of research evidence files.

The checksum verification log records the results of SHA-256 verification against the checksum manifest available at the time of execution.

These logs support artifact integrity and traceability. They do not independently establish scientific validity or complete unit-test coverage.

---

## 6. Application Screenshots

| Screenshot | Location |
|---|---|
| SDK Initialization | `research/evidence/screenshots/01_sdk_initialization.png` |
| Benchmark Statistics Screenshot 1 | `research/evidence/screenshots/02_BenchMark_Statastics.png` |
| Benchmark Statistics Screenshot 2 | `research/evidence/screenshots/03_BenchMark_Statastics.png` |
| Benchmark Statistics Screenshot 3 | `research/evidence/screenshots/04_BenchMark_Statastics.png` |

These screenshots provide visual evidence of the demonstration application's interface and benchmark statistics display.

The filenames are retained as originally saved to preserve existing references.

---

## 7. Development Environment

| Evidence | Location |
|---|---|
| Environment Documentation | `research/evidence/environment/ENVIRONMENT.md` |
| Original Environment Log | `research/evidence/environment/environment_log.txt` |

### Recorded Environment

| Component | Configuration |
|---|---|
| Host Processor | Apple M4 Pro |
| Architecture | ARM64 |
| Operating System | macOS 26.7 |
| macOS Build | 25G229 |
| Xcode | 26.3 |
| Xcode Build | 17C529 |
| Swift | 6.2.4 |
| Simulator | iPhone 17 |
| Simulator Runtime | iOS 26.3 |
| Benchmark-Reported OS | iOS 26.3.1 |
| SDK Version | 0.1.0 |

The Simulator runtime and benchmark-reported OS versions are documented separately because their reported versions differ.

---

## 8. Baseline Benchmark Statistics

The following results were calculated from 10 CPU benchmark observations across two batches.

| Metric | Result |
|---|---:|
| Total Runs | 10 |
| Total Batches | 2 |
| Mean Execution Time | 623.05 ms |
| Median Execution Time | 613.45 ms |
| Minimum Execution Time | 607.99 ms |
| Maximum Execution Time | 676.78 ms |
| P95 Execution Time | 658.75 ms |
| Sample Standard Deviation | 21.04 ms |
| Coefficient of Variation | 3.38% |

### Statistical Methodology

- Arithmetic mean for average execution time
- Median for central tendency
- Minimum and maximum for observed range
- Linearly interpolated 95th percentile
- Sample standard deviation for variability
- Coefficient of variation for relative variability

These measurements establish a preliminary Simulator-based performance baseline.

---

## 9. Research Validation Report

**File:** `research/evidence/reports/PHASE1_VALIDATION_REPORT.md`

The report documents:

- Research objectives
- SDK implementation components
- Baseline experimental methodology
- Benchmark measurements
- Statistical results
- Development environment
- Testing evidence
- Research limitations
- Future validation activities

**Validation Status:** Preliminary technical validation.

The report does not claim independent verification or demonstrated adaptive performance improvements.

---

## 10. Research Evidence Integrity

**Checksum Manifest:**

`research/evidence/SHA256SUMS.txt`

### Integrity Verification

The initial checksum verification successfully checked 23 files.

All entries in the earlier verification output returned `OK`.

The manifest and verification logs provide evidence of file integrity at the time of verification.

### Final Manifest Preparation

Before releasing the Phase 1 research package:

1. Exclude unnecessary macOS metadata files such as `.DS_Store`.
2. Include the completed experimental protocol.
3. Include the updated evidence index.
4. Include the final validation report, datasets, scripts, figures, and screenshots.
5. Regenerate SHA-256 checksums after finalizing the package.
6. Verify the regenerated manifest.
7. Preserve the final manifest and verification results.

The final checksum manifest should exclude itself and generated verification logs to avoid circular dependencies.

---

## 11. Experimental Protocol

**Protocol ID:** APK-CPU-001  
**Protocol Version:** 1.0

**File:** `research/evidence/protocols/CPU_BENCHMARK_PROTOCOL.md`

### Protocol Contents

The experimental protocol documents:

- Research objectives and research questions
- Development and execution environment
- CPU benchmark workload identification
- Benchmark execution procedure
- Data collection requirements
- Statistical analysis methodology
- Reproducibility instructions
- Validation criteria
- Experimental limitations
- Future experimental work

### Protocol Status

Preliminary reproducibility protocol prepared.

Exact CPU workload parameters, compiler optimization settings, and experimental controls still require source-code verification before full independent reproducibility can be claimed.

---

## 12. Research Limitations

The following limitations apply to the current Phase 1 evidence:

1. Benchmark measurements were collected using an iOS Simulator rather than a physical iPhone.
2. The analyzed baseline contains only 10 observations.
3. Host-system background activity and thermal conditions were not controlled or recorded.
4. No adaptive-versus-non-adaptive performance comparison has been completed.
5. Energy consumption and application responsiveness improvements have not been demonstrated.
6. Independent experimental reproduction has not yet been completed.
7. The exact benchmark workload implementation requires further documentation.

These limitations must be considered when interpreting or publishing the research results.

---

## 13. Independent Research Reproducibility

An independent evaluator should be able to:

1. Obtain the AdaptivePerfKit source code.
2. Inspect the CPU benchmark implementation.
3. Record the source-code Git commit.
4. Verify the research evidence checksums.
5. Configure the documented development environment.
6. Execute the benchmark protocol.
7. Export the resulting measurements.
8. Recalculate benchmark statistics.
9. Regenerate the research charts.
10. Compare findings with the original baseline and document any deviations.

Independent reproduction has not yet been performed.

---

## 14. Phase 1 Research Evidence Status

| Research Activity | Status |
|---|---|
| SDK Implementation | Completed |
| Demo Application | Completed |
| CPU Benchmark Collection | Completed |
| Raw Dataset Preservation | Completed |
| Statistical Analysis | Completed |
| Research Charts | Completed |
| Unit-Test Screenshot Collection | Completed |
| Environment Documentation | Completed |
| Preliminary Validation Report | Completed |
| Evidence Index | Completed |
| Initial SHA-256 Verification | Completed |
| Experimental Protocol | Completed |
| Final Checksum Manifest | Pending |
| Final Reproducibility Package | Pending |
| Independent Evaluation | Pending |
| Physical-Device Validation | Pending |

---

## 15. Next Research Activities

The immediate next activities are:

1. Generate and verify the final SHA-256 manifest.
2. Prepare a versioned Phase 1 research evidence package.
3. Record the corresponding Git commit and source-code version.
4. Verify that the benchmark workload and execution instructions are fully documented.
5. Conduct independent reproduction using the published protocol.
6. Begin controlled experiments evaluating adaptive performance optimization.

**Conclusion:** AdaptivePerfKit Phase 1 has established a preliminary CPU performance monitoring baseline with supporting datasets, analysis scripts, charts, screenshots, environment documentation, and research evidence records.

The available evidence supports initial technical validation and reproducibility preparation, but does not yet demonstrate a novel adaptive performance improvement or independent adoption.