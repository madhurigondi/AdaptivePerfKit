# Phase 2 Adaptive Controller Diagnostic Analysis

Generated (UTC): 2026-11-13T18:41:30.235375+00:00

## Dataset

- Measurement windows: 10
- Completed tasks: 100
- Sum of window durations: 450.592 ms
- Aggregate window throughput: 221.930 tasks/sec

The summed window durations exclude any execution overhead outside the measured windows.

## Window Observations

- Highest throughput: window 6, 317.629 tasks/sec
- Lowest throughput: window 1, 150.647 tasks/sec

## Concurrency Performance

| Concurrency | Windows | Aggregate throughput (tasks/sec) |
|---|---:|---:|
| 2 | 1 | 150.647 |
| 3 | 1 | 186.078 |
| 4 | 2 | 243.317 |
| 5 | 4 | 285.329 |
| 6 | 2 | 185.041 |

## Controller Decisions

- initialExploration: 1
- throughputDegraded: 3
- throughputImproved: 6

## Interpretation

The controller changes concurrency between measurement windows based on observed throughput and latency.

These measurements can identify candidate instability and concurrency limits worth further testing.

The observations are from one preliminary run. They do not establish that a specific concurrency limit is optimal across devices or workloads.

## Research Limitations

- Preliminary simulator measurements
- One diagnostic execution
- Concurrency levels were selected adaptively, not randomly
- Workload order and thermal effects may influence results
- No independent repeated-run confidence intervals
- Fixed and adaptive end-to-end results require separate controlled comparison

## Next Experiment

Repeat controlled fixed-versus-adaptive experiments using matched workloads and device conditions. Retain the original baseline before changing the controller.
