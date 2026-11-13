# AdaptivePerfKit — Simulator 360-Trial Statistical Analysis

## Dataset

- 3 synthetic workloads; 4 configurations; 30 trials per combination; 360 executions total.
- Results are from the iOS Simulator, not physical iPhone hardware.
- Trial IDs are paired by experimental round; temporal independence is not established.

## Descriptive statistics

| Workload | Configuration | Mean (ms) | Median (ms) | SD (ms) | P95 (ms) | Mean throughput (tasks/s) |
|---|---|---:|---:|---:|---:|---:|
| cpuIntensive | fixed4 | 2.246 | 1.878 | 1.792 | 2.386 | 50933.73 |
| cpuIntensive | adaptiveV1 | 2.253 | 2.137 | 0.390 | 2.900 | 45220.55 |
| cpuIntensive | adaptiveV2 | 2.257 | 2.144 | 0.326 | 2.947 | 44944.38 |
| cpuIntensive | adaptiveV3 | 1.828 | 1.721 | 0.292 | 2.341 | 55725.71 |
| variableLatency | fixed4 | 94.811 | 95.027 | 1.127 | 96.460 | 1054.87 |
| variableLatency | adaptiveV1 | 116.827 | 114.111 | 10.059 | 140.182 | 861.53 |
| variableLatency | adaptiveV2 | 119.876 | 116.804 | 12.017 | 140.833 | 841.96 |
| variableLatency | adaptiveV3 | 84.760 | 83.811 | 3.484 | 91.151 | 1181.68 |
| mixed | fixed4 | 52.235 | 52.297 | 1.542 | 54.655 | 1916.04 |
| mixed | adaptiveV1 | 55.960 | 55.507 | 2.634 | 59.748 | 1790.52 |
| mixed | adaptiveV2 | 55.167 | 54.623 | 2.297 | 58.782 | 1815.64 |
| mixed | adaptiveV3 | 54.145 | 52.875 | 4.770 | 63.897 | 1860.04 |

## Paired comparisons

Positive saving indicates V3 completed faster. Improvement (%) uses (baseline mean − V3 mean) / baseline mean × 100. Intervals use the Student-t distribution of 30 round-paired differences, without multiplicity adjustment.

| Workload | Comparison | Improvement (%) | Mean saving (ms) | 95% CI lower | 95% CI upper |
|---|---|---:|---:|---:|---:|
| cpuIntensive | V3 vs fixed4 | 18.60 | 0.418 | -0.169 | 1.004 |
| cpuIntensive | V3 vs adaptiveV1 | 18.87 | 0.425 | 0.364 | 0.487 |
| cpuIntensive | V3 vs adaptiveV2 | 19.01 | 0.429 | 0.388 | 0.471 |
| variableLatency | V3 vs fixed4 | 10.60 | 10.051 | 8.580 | 11.521 |
| variableLatency | V3 vs adaptiveV1 | 27.45 | 32.067 | 28.358 | 35.776 |
| variableLatency | V3 vs adaptiveV2 | 29.29 | 35.115 | 30.406 | 39.825 |
| mixed | V3 vs fixed4 | -3.66 | -1.910 | -3.798 | -0.021 |
| mixed | V3 vs adaptiveV1 | 3.24 | 1.815 | -0.089 | 3.719 |
| mixed | V3 vs adaptiveV2 | 1.85 | 1.023 | -0.789 | 2.834 |

## Interpretation and cautions

- A 95% CI excluding zero suggests a difference under the stated paired-round assumptions; it is not proof of generalization to devices or other workloads.
- The CPU-intensive fixed4 distribution contains a high first-trial value (11.697 ms), making its mean sensitive to a possible warm-up effect. Preserve the observation and investigate it in a preregistered repeat rather than silently deleting it.
- Simulator workloads and execution conditions differ from earlier package benchmarks; do not pool them or call them direct replications.
- Simulator results do not establish physical-device energy efficiency, thermal behavior, or iPhone speedups.
- Trial ordering, warm-up, host scheduling, and temporal dependence may affect uncertainty estimates.
- Multiple comparisons are exploratory and have not been adjusted for multiplicity.

## Recommended next step

Preserve raw data and checksum, then generate figures and a reproducibility manifest documenting simulator model, iOS runtime, host Mac, Xcode version, build configuration, source commit, workload code, and trial order.
