
# AdaptivePerfKit — Technical Architecture

Version: 0.1.0
Platform: iOS 17+
Development: Xcode 26 / Swift 6.2

## 1. Overview

AdaptivePerfKit is a modular Swift Package designed
to support reproducible iOS performance research.

The current implementation provides:
- Execution-time measurement
- Statistical analysis
- Structured benchmark records
- Concurrency-safe data collection
- JSON persistence
- JSON and CSV export

The CAPE adaptive optimization algorithm is planned
for Phase 2 and is not part of version 0.1.0.

## 2. Component Architecture

AdaptivePerfKit.swift
- Defines the SDK version and initialization API.

PerformanceMonitor.swift
- Measures elapsed execution time.
- Returns the workload result and measurement.

BenchmarkStatistics.swift
- Computes average, minimum, maximum,
  median, and P95 execution duration.

BenchmarkRecord.swift
- Defines structured measurement records.
- Includes batch IDs and environment metadata.

BenchmarkDataStore.swift
- Uses a Swift actor to protect record storage.
- Supports insertion, filtering, and deletion.
- Coordinates explicit persistence operations.

BenchmarkPersistence.swift
- Encodes records as JSON.
- Saves snapshots using atomic file writes.
- Restores previously saved records.

BenchmarkExporter.swift
- Exports records as JSON or CSV.
- Provides stable research dataset columns.

## 3. Measurement Data Flow

1. The demo app starts a benchmark batch.
2. PerformanceMonitor measures each workload.
3. BenchmarkStatistics summarizes measurements.
4. BenchmarkRecord captures the measurement
   and associated metadata.
5. BenchmarkDataStore stores the record.
6. BenchmarkPersistence writes records to disk.
7. BenchmarkExporter converts records into
   JSON or CSV for external analysis.

## 4. Concurrency Design

BenchmarkDataStore is implemented as a Swift actor.

Actor isolation protects its internal records array
from unsynchronized concurrent mutation.

The demo application uses asynchronous tasks to
perform benchmark operations.

The current implementation does not dynamically
optimize concurrency levels.

## 5. Persistence Design

Benchmark records are stored in a JSON file inside
the demo application's private Documents directory.

The demo app saves records after benchmark runs
and restores them during application startup.

The persistence implementation writes complete
snapshots rather than appending individual records.

## 6. Statistical Analysis

Supported metrics:
- Arithmetic mean
- Minimum
- Maximum
- Median
- 95th percentile

The current statistics implementation is validated
using deterministic unit-test inputs.

Reported benchmark durations use milliseconds.

## 7. Data Export

JSON exports preserve structured record fields.

CSV exports include:
- record_id
- batch_id
- run_number
- workload_name
- duration_ms
- timestamp
- device_model
- operating_system
- sdk_version
- is_simulator

## 8. Validation Strategy

Automated tests cover:
- Statistics calculations
- Performance measurement behavior
- Record insertion and filtering
- Persistence save/load operations
- Corrupted-file handling
- JSON and CSV export

Tests establish functional behavior against
specified cases, not performance superiority.

## 9. Current Limitations

- Initial experiments use the iOS Simulator.
- Simulator measurements are not substitutes
  for physical-device energy measurements.
- Hardware metadata is limited.
- Fractional-second timestamp preservation
  requires improvement.
- The current workload suite is limited.
- No adaptive optimization algorithm is
  implemented yet.

## 10. Future Architecture

Phase 2 will investigate CAPE:
Context-Aware Performance and Energy optimization.

Planned components include:
- Workload characterization
- Runtime context collection
- Adaptive concurrency selection
- Decision-policy implementation
- Baseline comparison infrastructure

These are proposed research components,
not current SDK capabilities.

