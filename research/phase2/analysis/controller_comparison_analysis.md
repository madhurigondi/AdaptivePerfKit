# V1 vs V2 Controller Performance Analysis

## Descriptive Statistics

| Configuration | Mean (ms) | Median (ms) | SD (ms) | P95 (ms) | Mean throughput (tasks/s) |
|---|---:|---:|---:|---:|---:|
| fixed4 | 154.382 | 154.112 | 1.887 | 158.213 | 647.837 |
| adaptiveV1 | 161.851 | 161.411 | 2.147 | 165.839 | 617.956 |
| adaptiveV2 | 161.262 | 161.140 | 2.247 | 164.826 | 620.226 |

## Paired Comparisons

Positive savings indicate the candidate completed faster.
Trial numbers are paired by experimental round.

### V2 vs V1

- Mean execution-time improvement: 0.36%
- Mean paired time saving: 0.590 ms
- Approximate 95% CI for paired saving: [-0.380, 1.559] ms

### V2 vs Fixed 4

- Mean execution-time improvement: -4.46%
- Mean paired time saving: -6.880 ms
- Approximate 95% CI for paired saving: [-7.920, -5.839] ms

## Limitations

- Measurements use a synthetic suspension-heavy workload.
- Results are from the current test environment.
- Controller and instrumentation overhead are included.
- Confidence intervals assume approximately independent paired rounds.
- Repeated measurements on one machine may exhibit temporal correlation.
- Physical iPhone validation and additional workloads remain necessary.

