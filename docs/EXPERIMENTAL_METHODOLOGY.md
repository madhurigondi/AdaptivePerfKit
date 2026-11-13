
# AdaptivePerfKit — Experimental Methodology

Version: 0.1.0
Research Stage: Phase 1
Platform: iOS 17+
Development Environment: Xcode 26

## 1. Research Objective

AdaptivePerfKit investigates reproducible
performance measurement and, in future phases,
adaptive execution optimization for iOS applications.

Phase 1 establishes the measurement infrastructure.

Phase 2 will introduce the proposed Context-Aware
Performance and Energy (CAPE) algorithm.

Phase 3 will evaluate CAPE against baseline strategies.

No CAPE performance improvement is claimed at this stage.

## 2. Research Questions

RQ1: Can the SDK collect and preserve execution-time
measurements consistently across repeated workloads?

RQ2: How much variability exists between repeated
benchmark executions under controlled conditions?

RQ3: Does the proposed CAPE algorithm reduce execution
latency compared with fixed-concurrency baselines?

RQ4: How does CAPE affect responsiveness and energy
consumption under different workload conditions?

RQ1 and RQ2 concern the measurement infrastructure.
RQ3 and RQ4 require future experimental implementation.

## 3. Experimental Environment

Current development platform:
- Xcode 26
- Swift 6.2
- iOS Simulator
- AdaptivePerfKit SDK 0.1.0

For every experiment, record:
- Mac model and processor
- macOS version
- Xcode build version
- Simulator device and runtime
- SDK version and Git commit
- Build configuration
- Benchmark workload configuration
- Date and time of execution

Simulator results are influenced by host-machine
activity and should not be interpreted as physical
iPhone hardware performance.

## 4. Benchmark Workloads

### W1: CPU Computation

The initial benchmark computes a deterministic
numerical workload using repeated square-root
operations.

The current demo uses 5,000,000 iterations.

The result is checked for finiteness.

### W2: JSON Processing (Planned)

Encode and decode datasets of controlled sizes.

### W3: Concurrent Task Execution (Planned)

Execute independent tasks at different concurrency
levels.

### W4: Memory-Intensive Processing (Planned)

Evaluate workloads with controlled memory demands.

Planned workloads must not be reported as implemented
until their code and validation are complete.

## 5. Experimental Procedure

The initial protocol is:

1. Record the experiment environment.
2. Select a benchmark workload.
3. Fix the workload input and configuration.
4. Perform warm-up executions.
5. Run repeated measured executions.
6. Store each measurement with a unique record ID.
7. Group measurements using a batch ID.
8. Export the raw data as JSON and CSV.
9. Verify data integrity.
10. Calculate descriptive statistics.

The current demo executes five measured runs per batch.

For future formal experiments, the proposed starting
protocol is 10 warm-up runs followed by 30 measured
runs per configuration.

The final sample size must be justified based on
observed variability and the intended comparison.

## 6. Controlled Variables

Control or document:
- Workload size
- Input data
- Concurrency level
- Build configuration
- Simulator runtime
- Host-machine activity
- Background applications
- Thermal and power conditions when measurable

Use identical workload inputs for baseline and
experimental configurations.

Randomize or counterbalance execution order where
appropriate to reduce time-dependent bias.

## 7. Performance Metrics

Primary metric:
- Execution duration in milliseconds

Descriptive statistics:
- Mean
- Minimum
- Maximum
- Median
- P95 latency

Future metrics:
- Throughput
- Main-thread responsiveness
- Memory usage
- CPU utilization
- Energy consumption on supported physical devices

The current SDK does not directly measure energy
consumption.

## 8. Statistical Analysis

Preserve raw observations.

Calculate descriptive statistics for each configuration.

For future comparisons:
- Report absolute and relative differences.
- Calculate confidence intervals.
- Evaluate measurement variability.
- Use paired comparisons when experimental design
  supports pairing.
- Report effect sizes where appropriate.
- Avoid treating repeated measurements from one
  environment as independent hardware replications.

P95 calculations must document the percentile method.

## 9. Data Collection

Each record contains:
- Unique record ID
- Batch ID
- Run number
- Workload name
- Execution duration
- Timestamp
- Environment metadata

Records are stored locally and exported in JSON
and CSV formats.

Exported files should be retained unchanged
as raw research artifacts.

## 10. Data Integrity

Validate:
- Total record count
- Unique record identifiers
- Batch associations
- Execution duration values
- Timestamps
- Environment metadata
- JSON and CSV consistency

Record file hashes when archiving research datasets.

## 11. Reproducibility

An independent evaluator should receive:
- Source code
- Exact Git commit or release tag
- Build instructions
- Benchmark configurations
- Raw measurement data
- Analysis scripts
- Test reports
- Known limitations

Results must be clearly labeled as Simulator-based
or physical-device-based.

## 12. Threats to Validity

Internal validity:
- Host activity may affect Simulator timings.
- Warm-up and scheduling can influence measurements.
- Compiler optimization may affect workload execution.

External validity:
- Simulator performance does not represent all
  physical iPhone models.
- One numerical workload does not represent all apps.

Construct validity:
- Execution latency alone does not measure
  energy efficiency or user experience.

Statistical conclusion validity:
- Small sample sizes limit inference.
- Correlated measurements may overstate precision.

## 13. Independent Evaluation

Independent researchers should reproduce the
measurement procedure and document deviations.

Evaluators should be encouraged to report:
- Successful and unsuccessful reproductions
- Observed performance results
- Methodological limitations
- Technical improvements
- Evidence of subsequent use or extension

## 14. Research Integrity

Synthetic unit-test inputs must remain separate
from real benchmark measurements.

No fabricated measurements, citations, or
independent evaluation results may be used.

Future CAPE claims must be supported by actual
controlled experiments.
