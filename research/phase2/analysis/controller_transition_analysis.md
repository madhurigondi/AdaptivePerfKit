# AdaptivePerfKit Controller Transition Analysis

## Dataset

- Total measurement windows: 1800
- Workloads: 3
- Controller versions: 2
- Trials per combination: 30
- Windows per trial: 10

## Controller Behavior Summary

| Workload | Version | Mean actual changes | Mean direction reversals | Mean active concurrency | Mean final recommended concurrency |
|---|---|---:|---:|---:|---:|
| cpuIntensive | v1 | 4.00 | 0.00 | 5.00 | 6.00 |
| cpuIntensive | v2 | 4.00 | 0.00 | 5.00 | 6.00 |
| variableLatency | v1 | 5.10 | 0.00 | 5.50 | 7.10 |
| variableLatency | v2 | 5.47 | 0.00 | 5.65 | 7.47 |
| mixed | v1 | 4.10 | 0.00 | 5.05 | 6.10 |
| mixed | v2 | 4.30 | 0.00 | 5.13 | 6.30 |

## Controller Decision Frequencies

### cpuIntensive / v1

- initialExploration: 30
- insufficientImprovement: 180
- throughputImproved: 90

### cpuIntensive / v2

- initialExploration: 30
- insufficientImprovement: 180
- throughputImproved: 90

### variableLatency / v1

- initialExploration: 30
- insufficientImprovement: 133
- throughputImproved: 137

### variableLatency / v2

- concurrencyLimitReached: 19
- initialExploration: 30
- insufficientImprovement: 117
- throughputImproved: 134

### mixed / v1

- initialExploration: 30
- insufficientImprovement: 177
- throughputImproved: 93

### mixed / v2

- concurrencyLimitReached: 1
- initialExploration: 30
- insufficientImprovement: 170
- throughputImproved: 99

## Concurrency Distribution and Throughput

Window share is the fraction of completed measurement windows using each concurrency level.

Elapsed share is the fraction of summed measured window durations at that level.

| Workload | Version | Concurrency | Windows | Window share (%) | Elapsed share (%) | Mean window throughput (tasks/s) |
|---|---|---:|---:|---:|---:|---:|
| cpuIntensive | v1 | 2 | 30 | 10.00 | 18.92 | 179.622 |
| cpuIntensive | v1 | 3 | 30 | 10.00 | 15.11 | 224.827 |
| cpuIntensive | v1 | 4 | 30 | 10.00 | 11.42 | 297.576 |
| cpuIntensive | v1 | 5 | 30 | 10.00 | 7.91 | 429.563 |
| cpuIntensive | v1 | 6 | 180 | 60.00 | 46.64 | 437.038 |
| cpuIntensive | v2 | 2 | 30 | 10.00 | 19.02 | 177.598 |
| cpuIntensive | v2 | 3 | 30 | 10.00 | 15.14 | 223.072 |
| cpuIntensive | v2 | 4 | 30 | 10.00 | 11.44 | 295.182 |
| cpuIntensive | v2 | 5 | 30 | 10.00 | 7.89 | 427.847 |
| cpuIntensive | v2 | 6 | 180 | 60.00 | 46.51 | 435.640 |
| variableLatency | v1 | 2 | 30 | 10.00 | 18.41 | 151.410 |
| variableLatency | v1 | 3 | 30 | 10.00 | 13.68 | 203.852 |
| variableLatency | v1 | 4 | 30 | 10.00 | 10.95 | 254.449 |
| variableLatency | v1 | 5 | 30 | 10.00 | 8.95 | 311.532 |
| variableLatency | v1 | 6 | 90 | 30.00 | 25.42 | 328.895 |
| variableLatency | v1 | 7 | 30 | 10.00 | 7.92 | 351.805 |
| variableLatency | v1 | 8 | 60 | 20.00 | 14.67 | 379.978 |
| variableLatency | v2 | 2 | 30 | 10.00 | 18.66 | 150.394 |
| variableLatency | v2 | 3 | 30 | 10.00 | 13.73 | 204.397 |
| variableLatency | v2 | 4 | 31 | 10.33 | 11.49 | 252.773 |
| variableLatency | v2 | 5 | 30 | 10.00 | 9.06 | 309.760 |
| variableLatency | v2 | 6 | 61 | 20.33 | 17.30 | 329.920 |
| variableLatency | v2 | 7 | 38 | 12.67 | 10.07 | 353.079 |
| variableLatency | v2 | 8 | 80 | 26.67 | 19.70 | 380.013 |
| mixed | v1 | 2 | 30 | 10.00 | 17.98 | 100.837 |
| mixed | v1 | 3 | 30 | 10.00 | 15.08 | 120.259 |
| mixed | v1 | 4 | 30 | 10.00 | 10.91 | 166.230 |
| mixed | v1 | 5 | 30 | 10.00 | 8.27 | 219.181 |
| mixed | v1 | 6 | 165 | 55.00 | 43.92 | 227.056 |
| mixed | v1 | 7 | 15 | 5.00 | 3.84 | 235.771 |
| mixed | v2 | 2 | 30 | 10.00 | 18.03 | 101.190 |
| mixed | v2 | 3 | 30 | 10.00 | 15.01 | 121.558 |
| mixed | v2 | 4 | 30 | 10.00 | 10.93 | 166.872 |
| mixed | v2 | 5 | 30 | 10.00 | 8.35 | 218.366 |
| mixed | v2 | 6 | 145 | 48.33 | 38.79 | 227.297 |
| mixed | v2 | 7 | 31 | 10.33 | 7.95 | 237.076 |
| mixed | v2 | 8 | 4 | 1.33 | 0.94 | 259.463 |

## Interpretation

- Actual changes exclude decisions that retain the same concurrency level.
- Direction reversals count changes in the direction of nonzero concurrency adjustments.
- Mean active concurrency is calculated across executed measurement windows.
- Final recommended concurrency is calculated after the final window and may never be executed.
- Window throughput is observational and should not be interpreted as a causal estimate of optimal concurrency.

## Limitations

- This diagnostic dataset was collected separately from the earlier 270-trial benchmark.
- Workload order and thermal conditions may affect comparisons.
- A direction reversal does not necessarily indicate harmful oscillation.
- Mean window throughput is not equivalent to end-to-end application throughput.
- Measurements are from synthetic workloads.
- Physical-device validation remains pending.

