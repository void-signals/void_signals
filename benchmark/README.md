# Reactivity Benchmark

A comprehensive benchmark suite for comparing Dart reactive/signals frameworks.

## Frameworks Tested

| Framework | Description |
|-----------|-------------|
| **void_signals** | High-performance reactive signals library |
| **alien_signals** | Dart port of alien-signals |
| **preact_signals** | Dart port of Preact Signals |
| **signals_core** | Core signals library |
| **solidart** | Dart port of SolidJS reactivity |
| **state_beacon** | State management with beacons |
| **mobx** | MobX for Dart |

## Benchmark Categories

### Kairo Benchmarks
Performance tests from the Kairo benchmark suite:
- **avoidablePropagation** - Tests lazy evaluation optimization
- **broadPropagation** - Wide dependency graph propagation
- **deepPropagation** - Deep dependency chain propagation
- **diamond** - Diamond-shaped dependency resolution
- **mux** - Multiplexer pattern performance
- **repeatedObservers** - Multiple observer handling
- **triangle** - Triangle dependency pattern
- **unstable** - Unstable dependency graph handling

### S-Bench (Signal Operations)
Signal creation and update micro-benchmarks:
- **create_signals** - Signal creation overhead
- **comp_XtoY** - Computed creation with X inputs to Y outputs
- **update_XtoY** - Update propagation patterns

### CellX Benchmarks
Stress tests with varying graph sizes:
- **cellx1000** - 1000 reactive cells
- **cellx2500** - 2500 reactive cells
- **cellx5000** - 5000 reactive cells

### Mol Benchmark
Complex molecular simulation benchmark:
- **molBench** - Molecule state propagation

### Dynamic Graph Benchmarks
Tests with dynamic dependency graphs:
- **simple** - 10x5, 2 sources
- **dynamic** - 10x10, 6 sources, dynamic dependencies
- **large** - 1000x12, 4 sources, mostly static
- **wide dense** - 1000x5, 25 sources
- **deep** - 5x500, 3 sources
- **very dynamic** - 100x15, 6 sources, highly dynamic

## Running Benchmarks

```bash
# Run all benchmarks
./bench.sh

# Or run individual framework benchmark
cd frameworks/void_signals
dart run main.dart
```

## Output

Benchmark results are saved to:
- `bench/BENCHMARK_REPORT.md` - Combined markdown report
- `bench/benchmark_results.json` - JSON format for programmatic access
- `bench/<framework>.md` - Individual framework results

---

<!-- BENCHMARK_RESULTS_START -->
## Latest Benchmark Results

| Test | void_signals ([1.0.0](https://pub.dev/packages/void_signals/versions/1.0.0)) | alien_signals ([2.0.1](https://pub.dev/packages/alien_signals/versions/2.0.1)) | state_beacon ([1.0.2](https://pub.dev/packages/state_beacon_core/versions/1.0.2)) | preact_signals ([1.9.3](https://pub.dev/packages/preact_signals/versions/1.9.3)) | mobx ([2.5.0](https://pub.dev/packages/mobx/versions/2.5.0)) | signals_core ([6.2.0](https://pub.dev/packages/signals_core/versions/6.2.0)) | solidart ([2.8.3](https://pub.dev/packages/solidart/versions/2.8.3)) |
|------|--------|--------|--------|--------|--------|--------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **255.56ms** 🏆 | 263.37ms | 340.39ms | 3.69s | 1.73s | 3.76s | 1.68s |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **382.89ms** 🏆 | 416.88ms | 504.42ms | 3.33s | 3.25s | 3.52s | 21.05s |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **221.25ms** 🏆 | 238.93ms | 259.09ms | 473.05ms | 1.60s | 479.16ms | 1.77s |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **140.36ms** 🏆 | 157.27ms | 201.16ms | 290.91ms | 1.43s | 292.72ms | 1.47s |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **164.82ms** 🏆 | 185.08ms | 255.94ms | 507.92ms | 1.92s | 542.72ms | 755.39ms |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **143.65ms** 🏆 | 156.12ms | 202.15ms | 233.75ms | 1.08s | 223.43ms | 498.46ms |
| avoidablePropagation (success) | **119.75ms** 🏆 | 131.30ms | 180.64ms | 208.49ms | 2.37s | 246.93ms | 476.75ms |
| broadPropagation (success) | **216.53ms** 🏆 | 242.69ms | 402.67ms | 466.91ms | 4.30s | 444.17ms | 4.71s |
| cellx1000 (first: pass, last: pass) | 6.26ms | **5.46ms** 🏆 | 15.75ms | 9.73ms | 75.91ms | 11.64ms | 19.52ms |
| cellx2500 (first: pass, last: pass) | 16.08ms | **15.47ms** 🏆 | 42.71ms | 26.91ms | 263.75ms | 26.19ms | 52.76ms |
| cellx5000 (first: pass, last: pass) | 51.73ms | **48.64ms** 🏆 | 106.63ms | 69.38ms | 573.65ms | 67.00ms | 255.47ms |
| comp_0to1 | 66μs | **36μs** 🏆 | 51.86ms | 16.67ms | 16.89ms | 27.34ms | 20.73ms |
| comp_1000to1 | **0μs** 🏆 | **0μs** 🏆 | 38μs | 6μs | 15μs | 3μs | 13μs |
| comp_1to1 | 942μs | **892μs** 🏆 | 48.22ms | 28.68ms | 32.74ms | 22.36ms | 34.29ms |
| comp_1to1000 | **42μs** 🏆 | 62μs | 36.94ms | 2.91ms | 13.95ms | 4.95ms | 12.90ms |
| comp_1to2 | **444μs** 🏆 | 667μs | 43.56ms | 24.24ms | 28.00ms | 26.82ms | 27.03ms |
| comp_1to4 | **224μs** 🏆 | 260μs | 42.13ms | 31.42ms | 25.92ms | 19.85ms | 20.65ms |
| comp_1to8 | **107μs** 🏆 | 111μs | 42.46ms | 9.32ms | 24.72ms | 2.89ms | 25.32ms |
| comp_2to1 | 1.61ms | **1.40ms** 🏆 | 26.35ms | 14.59ms | 15.90ms | 24.64ms | 26.41ms |
| comp_4to1 | **764μs** 🏆 | 1.48ms | 18.49ms | 11.15ms | 12.80ms | 1.73ms | 4.17ms |
| create_signals | 29.80ms | 26.68ms | 59.83ms | **5.46ms** 🏆 | 83.63ms | 24.32ms | 69.61ms |
| deepPropagation (success) | **75.62ms** 🏆 | 78.33ms | 159.60ms | 178.07ms | 1.47s | 174.79ms | 263.03ms |
| diamond (success) | **128.77ms** 🏆 | 154.38ms | 230.07ms | 283.49ms | 2.36s | 302.25ms | 959.38ms |
| molBench | **474.57ms** 🏆 | 488.89ms | 1.14s | 492.29ms | 576.07ms | 485.74ms | 517.21ms |
| mux (success) | **285.43ms** 🏆 | 304.01ms | 369.52ms | 386.15ms | 1.77s | 379.26ms | 6.25s |
| repeatedObservers (success) | **21.11ms** 🏆 | 34.03ms | 59.67ms | 39.51ms | 233.23ms | 51.03ms | 201.00ms |
| triangle (success) | **58.00ms** 🏆 | 64.19ms | 88.25ms | 103.65ms | 735.16ms | 106.78ms | 248.52ms |
| unstable (success) | **38.70ms** 🏆 | 49.35ms | 347.40ms | 70.03ms | 346.41ms | 79.88ms | 329.50ms |
| update_1000to1 | 25μs | 26μs | **17μs** 🏆 | 21μs | 67μs | 64μs | 82μs |
| update_1to1 | 9.69ms | 19.72ms | **6.66ms** 🏆 | 8.17ms | 22.66ms | 26.54ms | 33.07ms |
| update_1to1000 | **10μs** 🏆 | **10μs** 🏆 | 374μs | 31μs | 145μs | 51μs | 149μs |
| update_1to2 | 4.85ms | **1.97ms** 🏆 | 3.29ms | 4.20ms | 10.91ms | 13.27ms | 16.71ms |
| update_1to4 | **1.24ms** 🏆 | 2.73ms | 1.66ms | 2.12ms | 5.24ms | 6.63ms | 8.21ms |
| update_2to1 | **1.92ms** 🏆 | 5.42ms | 3.31ms | 4.18ms | 11.51ms | 13.12ms | 16.43ms |
| update_4to1 | 2.44ms | 2.73ms | **1.66ms** 🏆 | 2.10ms | 5.62ms | 6.66ms | 8.24ms |

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 24 | 100% |
| 🥈 | alien_signals | 9 | 100% |
| 🥉 | state_beacon | 3 | 100% |
| 4 | preact_signals | 1 | 100% |
| 5 | solidart | 0 | 100% |
| 6 | mobx | 0 | 100% |
| 7 | signals_core | 0 | 100% |
<!-- BENCHMARK_RESULTS_END -->

---

## Environment

Benchmarks are run with:
- Dart SDK: 3.10+
- Compilation: Native AOT (`dart compile exe`)
- Platform: macOS/Linux

## Contributing

To add a new framework:

1. Create a directory under `frameworks/<name>/`
2. Add `pubspec.yaml` with the framework dependency
3. Implement `main.dart` using the `ReactiveFramework` interface
4. Run `./bench.sh` to include in benchmarks

## License

MIT License - See [LICENSE](../LICENSE) for details.
