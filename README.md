

# AdaptivePerfKit

## iOS Performance Intelligence SDK

**Version:** 0.1.0  
**Platform:** iOS 17+  
**Development:** Xcode 26 / Swift 6.2  
**Current Testing:** iOS Simulator

## Overview

AdaptivePerfKit is a research-oriented Swift SDK
for measuring, analyzing, and collecting performance
data from iOS applications.

The SDK provides a foundation for investigating
adaptive execution strategies and mobile application
performance optimization.

The project is being developed as an original
software engineering research initiative.

## Current Features

### 1. Performance Monitoring
- Asynchronous execution-time measurement
- Workload identification
- Execution duration in milliseconds

### 2. Benchmark Statistics
- Average execution time
- Minimum execution time
- Maximum execution time
- Median execution time
- P95 execution time

### 3. Research Data Collection
- Unique record identifiers
- Benchmark batch identifiers
- Workload names and run numbers
- Execution durations and timestamps
- Device and operating-system metadata

### 4. Persistent Storage
- JSON-based benchmark storage
- Automatic saving after benchmark runs
- Restoration after application restart

### 5. Data Export
- JSON export
- CSV export
- Research-friendly data columns

### 6. Automated Validation
- Performance monitor tests
- Benchmark statistics tests
- Data store tests
- Persistence integrity tests
- JSON and CSV export tests

## SDK Architecture

The SDK contains these main components:

- AdaptivePerfKit
- PerformanceMonitor
- BenchmarkStatistics
- BenchmarkRecord
- BenchmarkDataStore
- BenchmarkPersistence
- BenchmarkExporter

The AdaptivePerfDemo application provides a
SwiftUI interface for running benchmarks.

See [Architecture](docs/ARCHITECTURE.md).

## Installation

AdaptivePerfKit currently uses a local Swift Package.

1. Open your iOS application in Xcode.
2. Select File > Add Package Dependencies.
3. Choose Add Local.
4. Select the AdaptivePerfKit directory.
5. Add the library to your application target.

Import the SDK:

```swift
import AdaptivePerfKit

AdaptivePerfKit.initialize()
```

## Running the Demo

1. Open AdaptivePerfDemo in Xcode 26.
2. Select an iOS Simulator.
3. Build and run the application.
4. Initialize the SDK.
5. Run CPU benchmarks.
6. Review benchmark statistics.
7. Export measurements to JSON or CSV.
8. Restart the app to verify persistence.

## Automated Tests

The SDK includes unit tests for:

- Execution-time monitoring
- Statistical calculations
- Record storage and filtering
- JSON persistence
- JSON and CSV export

Run tests in Xcode using Command + U.

Test results should be recorded and archived
as part of the research evidence.

## Research Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Experimental Methodology](docs/EXPERIMENTAL_METHODOLOGY.md)
- [Evidence Inventory](research/EVIDENCE_INVENTORY.md)

## Research Roadmap

### Phase 1 — Measurement Infrastructure

Performance monitoring, statistics, storage,
export, unit testing, and documentation.

### Phase 2 — CAPE Algorithm

Design and implement the proposed Context-Aware
Performance and Energy optimization algorithm.

### Phase 3 — Controlled Experiments

Compare CAPE against fixed-concurrency and
other relevant baseline strategies.

### Phase 4 — Research Publication

Prepare research manuscripts, experimental
datasets, analysis, and reproducibility materials.

### Phase 5 — Independent Evaluation

Invite independent researchers to reproduce,
evaluate, and critique the SDK and algorithm.

## Current Limitations

- Current performance testing uses iOS Simulator.
- The workload suite is initially CPU-focused.
- Energy consumption is not directly measured.
- CAPE is not implemented in version 0.1.0.
- Simulator performance cannot establish
  physical-device performance improvements.
- Timestamp precision requires further validation.

## Research Integrity

All performance results must come from actual
benchmark executions.

Synthetic unit-test data must not be presented
as experimental measurements.

Claims of performance improvement must be
supported by controlled experiments.

## Project Status

**Version 0.1.0 — Phase 1 Research Prototype**

AdaptivePerfKit currently provides performance
measurement and data collection infrastructure.

Adaptive optimization remains planned work.
