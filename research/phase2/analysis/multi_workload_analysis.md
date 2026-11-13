# AdaptivePerfKit Multi-Workload Analysis

## Experiment

- 3 workload types
- 3 concurrency configurations
- 30 measured trials per combination
- 270 total measured executions

## Descriptive Statistics

| Workload | Configuration | Mean (ms) | Median (ms) | SD (ms) | P95 (ms) | Mean throughput (tasks/s) |
|---|---|---:|---:|---:|---:|---:|
| cpuIntensive | fixed4 | 283.504 | 282.588 | 2.626 | 289.471 | 352.758 |
| cpuIntensive | adaptiveV1 | 293.257 | 292.385 | 2.640 | 299.144 | 341.025 |
| cpuIntensive | adaptiveV2 | 293.035 | 292.581 | 2.184 | 297.226 | 341.275 |
| variableLatency | fixed4 | 307.459 | 307.147 | 1.654 | 310.155 | 325.255 |
| variableLatency | adaptiveV1 | 356.416 | 352.971 | 7.364 | 371.084 | 280.684 |
| variableLatency | adaptiveV2 | 355.167 | 351.443 | 6.872 | 368.539 | 281.657 |
| mixed | fixed4 | 452.469 | 451.854 | 2.168 | 456.298 | 221.014 |
| mixed | adaptiveV1 | 542.990 | 544.889 | 7.677 | 554.396 | 184.202 |
| mixed | adaptiveV2 | 545.237 | 546.348 | 6.580 | 554.264 | 183.433 |

## Paired Comparisons

Positive improvements indicate lower execution time for the candidate.

| Workload | Comparison | Improvement (%) | Mean saving (ms) | 95% CI lower | 95% CI upper |
|---|---|---:|---:|---:|---:|
| cpuIntensive | adaptiveV2 vs adaptiveV1 | 0.08 | 0.222 | -0.441 | 0.885 |
| cpuIntensive | adaptiveV2 vs fixed4 | -3.36 | -9.531 | -10.638 | -8.423 |
| variableLatency | adaptiveV2 vs adaptiveV1 | 0.35 | 1.249 | -2.307 | 4.804 |
| variableLatency | adaptiveV2 vs fixed4 | -15.52 | -47.708 | -50.581 | -44.835 |
| mixed | adaptiveV2 vs adaptiveV1 | -0.41 | -2.247 | -5.791 | 1.298 |
| mixed | adaptiveV2 vs fixed4 | -20.50 | -92.768 | -95.667 | -89.868 |

## Interpretation Notes

- Positive mean savings favor the candidate.
- Negative mean savings favor the baseline.
- A confidence interval containing zero does not establish a reliable difference.
- Paired intervals assume approximately independent experimental rounds.
- These results are preliminary and specific to the measured environment.

## Research Limitations

- Synthetic workloads
- Single test environment
- No physical-device validation yet
- Possible thermal and scheduling effects
- Deterministic variable-latency workload
- No direct CPU-energy measurements
- Multiple comparisons are exploratory

