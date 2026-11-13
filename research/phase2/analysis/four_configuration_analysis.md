# AdaptivePerfKit Four-Configuration Analysis

## Descriptive Statistics

| Workload | Configuration | Mean (ms) | SD (ms) | P95 (ms) |
|---|---|---:|---:|---:|
| cpuIntensive | fixed4 | 282.127 | 2.000 | 284.885 |
| cpuIntensive | adaptiveV1 | 291.742 | 1.318 | 294.298 |
| cpuIntensive | adaptiveV2 | 291.588 | 1.728 | 294.475 |
| cpuIntensive | adaptiveV3 | 280.520 | 9.776 | 286.962 |
| variableLatency | fixed4 | 308.485 | 1.354 | 310.531 |
| variableLatency | adaptiveV1 | 355.431 | 6.472 | 370.193 |
| variableLatency | adaptiveV2 | 353.898 | 5.704 | 366.982 |
| variableLatency | adaptiveV3 | 264.970 | 2.894 | 270.594 |
| mixed | fixed4 | 447.129 | 3.165 | 453.158 |
| mixed | adaptiveV1 | 533.829 | 9.974 | 544.606 |
| mixed | adaptiveV2 | 541.970 | 10.243 | 553.781 |
| mixed | adaptiveV3 | 395.167 | 3.657 | 400.953 |

## Paired Comparisons

Positive savings favor the candidate.

| Workload | Comparison | Improvement (%) | Saving (ms) | 95% CI lower | 95% CI upper |
|---|---|---:|---:|---:|---:|
| cpuIntensive | adaptiveV3 vs fixed4 | 0.57 | 1.607 | -2.186 | 5.401 |
| cpuIntensive | adaptiveV3 vs adaptiveV1 | 3.85 | 11.222 | 7.512 | 14.932 |
| cpuIntensive | adaptiveV3 vs adaptiveV2 | 3.80 | 11.068 | 7.445 | 14.690 |
| variableLatency | adaptiveV3 vs fixed4 | 14.11 | 43.515 | 42.339 | 44.690 |
| variableLatency | adaptiveV3 vs adaptiveV1 | 25.45 | 90.460 | 87.900 | 93.020 |
| variableLatency | adaptiveV3 vs adaptiveV2 | 25.13 | 88.928 | 86.370 | 91.486 |
| mixed | adaptiveV3 vs fixed4 | 11.62 | 51.962 | 50.261 | 53.664 |
| mixed | adaptiveV3 vs adaptiveV1 | 25.98 | 138.662 | 135.331 | 141.994 |
| mixed | adaptiveV3 vs adaptiveV2 | 27.09 | 146.803 | 143.163 | 150.443 |

## Limitations

- Synthetic workloads in one test environment.
- Trial pairing is by experimental round.
- Measurements may exhibit temporal correlation.
- Confidence intervals assume approximately independent paired rounds.
- Multiple exploratory comparisons are not multiplicity-adjusted.
- Physical iPhone validation is pending.
- V3 feedback-window semantics differ from V1/V2.
- Performance differences do not establish energy efficiency.

