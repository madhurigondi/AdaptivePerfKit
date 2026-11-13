from pathlib import Path
import pandas as pd
import numpy as np
from scipy.stats import t
import hashlib

root=Path(__file__).resolve().parent
source=root/'simulator_benchmark_360_trials.csv'
df=pd.read_csv(source)
required={'workload','configuration','trial','duration_ms','throughput'}
assert required.issubset(df.columns)
assert len(df)==360 and not df.duplicated(['workload','configuration','trial']).any()
assert df[list(required)].notna().all().all()
assert (df.duration_ms>0).all()
workloads=['cpuIntensive','variableLatency','mixed']
modes=['fixed4','adaptiveV1','adaptiveV2','adaptiveV3']
for w in workloads:
    for m in modes:
        s=df[(df.workload==w)&(df.configuration==m)]
        assert sorted(s.trial.tolist())==list(range(1,31))
lines=['# AdaptivePerfKit — Simulator 360-Trial Statistical Analysis','','## Dataset','', '- 3 synthetic workloads; 4 configurations; 30 trials per combination; 360 executions total.', '- Results are from the iOS Simulator, not physical iPhone hardware.', '- Trial IDs are paired by experimental round; temporal independence is not established.', '', '## Descriptive statistics','', '| Workload | Configuration | Mean (ms) | Median (ms) | SD (ms) | P95 (ms) | Mean throughput (tasks/s) |','|---|---|---:|---:|---:|---:|---:|']
for w in workloads:
 for m in modes:
  s=df[(df.workload==w)&(df.configuration==m)]
  lines.append(f'| {w} | {m} | {s.duration_ms.mean():.3f} | {s.duration_ms.median():.3f} | {s.duration_ms.std(ddof=1):.3f} | {np.percentile(s.duration_ms,95):.3f} | {s.throughput.mean():.2f} |')
lines+=['','## Paired comparisons','', 'Positive saving indicates V3 completed faster. Improvement (%) uses (baseline mean − V3 mean) / baseline mean × 100. Intervals use the Student-t distribution of 30 round-paired differences, without multiplicity adjustment.','', '| Workload | Comparison | Improvement (%) | Mean saving (ms) | 95% CI lower | 95% CI upper |','|---|---|---:|---:|---:|---:|']
for w in workloads:
 v=df[(df.workload==w)&(df.configuration=='adaptiveV3')].set_index('trial').duration_ms
 for m in ['fixed4','adaptiveV1','adaptiveV2']:
  b=df[(df.workload==w)&(df.configuration==m)].set_index('trial').duration_ms
  diff=(b-v).sort_index(); n=len(diff); mean=diff.mean(); half=t.ppf(.975,n-1)*diff.std(ddof=1)/np.sqrt(n)
  lines.append(f'| {w} | V3 vs {m} | {100*(b.mean()-v.mean())/b.mean():.2f} | {mean:.3f} | {mean-half:.3f} | {mean+half:.3f} |')
lines+=['','## Interpretation and cautions','', '- A 95% CI excluding zero suggests a difference under the stated paired-round assumptions; it is not proof of generalization to devices or other workloads.', '- The CPU-intensive fixed4 distribution contains a high first-trial value (11.697 ms), making its mean sensitive to a possible warm-up effect. Preserve the observation and investigate it in a preregistered repeat rather than silently deleting it.', '- Simulator workloads and execution conditions differ from earlier package benchmarks; do not pool them or call them direct replications.', '- Simulator results do not establish physical-device energy efficiency, thermal behavior, or iPhone speedups.', '- Trial ordering, warm-up, host scheduling, and temporal dependence may affect uncertainty estimates.', '- Multiple comparisons are exploratory and have not been adjusted for multiplicity.', '', '## Recommended next step','', 'Preserve raw data and checksum, then generate figures and a reproducibility manifest documenting simulator model, iOS runtime, host Mac, Xcode version, build configuration, source commit, workload code, and trial order.', '']
report=root/'simulator_benchmark_analysis.md';report.write_text('\n'.join(lines))
for f in [source,report]:
 digest=hashlib.sha256(f.read_bytes()).hexdigest()
 (root/(f.stem+'.sha256')).write_text(f'{digest}  {f.name}\n')
print(report.read_text())
