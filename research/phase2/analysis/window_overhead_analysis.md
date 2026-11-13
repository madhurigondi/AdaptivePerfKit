# AdaptivePerfKit Window Overhead Analysis

## Dataset

- Workloads: 3
- Execution configurations: 3
- Measured trials per combination: 30
- Total measured executions: 270
- Tasks per execution: 100
- Measurement window size: 10

## Descriptive Statistics

| Workload | Configuration | Mean (ms) | Median (ms) | SD (ms) | P95 (ms) |
|---|---|---:|---:|---:|---:|
| cpuIntensive | fixedContinuous | 281.811 | 281.550 | 1.849 | 284.245 |
| cpuIntensive | fixedWindowed | 333.170 | 332.945 | 1.640 | 336.395 |
| cpuIntensive | adaptiveV2 | 291.261 | 291.366 | 1.355 | 293.436 |
| variableLatency | fixedContinuous | 308.093 | 308.337 | 1.340 | 310.239 |
| variableLatency | fixedWindowed | 393.194 | 393.138 | 1.310 | 395.613 |
| variableLatency | adaptiveV2 | 355.472 | 352.684 | 5.849 | 369.453 |
| mixed | fixedContinuous | 450.542 | 450.266 | 2.662 | 456.733 |
| mixed | fixedWindowed | 589.751 | 589.345 | 3.786 | 596.332 |
| mixed | adaptiveV2 | 543.878 | 547.026 | 7.741 | 552.712 |

## Paired Comparisons

Positive savings indicate that the candidate completed faster than the baseline.

| Workload | Comparison | Improvement (%) | Mean saving (ms) | 95% CI lower | 95% CI upper |
|---|---|---:|---:|---:|---:|
| cpuIntensive | fixedWindowed vs fixedContinuous | -18.22 | -51.359 | -52.065 | -50.652 |
| cpuIntensive | adaptiveV2 vs fixedWindowed | 12.58 | 41.909 | 41.370 | 42.448 |
| cpuIntensive | adaptiveV2 vs fixedContinuous | -3.35 | -9.450 | -10.234 | -8.665 |
| variableLatency | fixedWindowed vs fixedContinuous | -27.62 | -85.101 | -85.884 | -84.318 |
| variableLatency | adaptiveV2 vs fixedWindowed | 9.59 | 37.722 | 35.466 | 39.979 |
| variableLatency | adaptiveV2 vs fixedContinuous | -15.38 | -47.379 | -49.603 | -45.155 |
| mixed | fixedWindowed vs fixedContinuous | -30.90 | -139.209 | -140.897 | -137.521 |
| mixed | adaptiveV2 vs fixedWindowed | 7.78 | 45.874 | 43.115 | 48.633 |
| mixed | adaptiveV2 vs fixedContinuous | -20.72 | -93.335 | -96.363 | -90.307 |

## Interpretation Guide

- Positive savings favor the candidate.
- Negative savings favor the baseline.
- A confidence interval containing zero does not establish a reliable difference.
- Fixed-windowed versus fixed-continuous estimates the effect of window boundaries.
- Adaptive V2 versus fixed-windowed combines concurrency adaptation and instrumentation effects.
- Trial pairing uses matching experimental round numbers, not identical runtime conditions.

## Limitations

- Synthetic workloads.
- Single test environment.
- No physical iPhone validation yet.
- Possible scheduling and thermal effects.
- Fixed-windowed execution does not collect identical instrumentation to Adaptive V2.
- Paired intervals assume approximately independent experimental rounds.
- Multiple exploratory comparisons have not been adjusted for multiplicity.

