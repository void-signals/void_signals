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

| Test | alien_signals | mobx | preact_signals | signals_core | solidart | state_beacon | void_signals |
|------|--------|--------|--------|--------|--------|--------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **205.28ms** 🏆 | 1.25s | 3.10s | 3.14s | 1.12s | 306.08ms | 216.37ms |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **351.73ms** 🏆 | 2.84s | 2.97s | 2.99s | 18.69s | 410.36ms | 356.81ms |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | 178.53ms | 1.24s | 336.73ms | 341.43ms | 1.36s | 223.34ms | **178.49ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **119.28ms** 🏆 | 1.14s | 176.34ms | 182.89ms | 1.20s | 176.12ms | 121.20ms |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **155.93ms** 🏆 | 1.34s | 348.27ms | 364.65ms | 502.63ms | 207.39ms | 159.47ms |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **105.72ms** 🏆 | 752.97ms | 148.55ms | 142.10ms | 324.97ms | 163.20ms | 108.38ms |
| avoidablePropagation (success) | **86.44ms** 🏆 | 1.46s | 141.40ms | 158.11ms | 286.09ms | 130.36ms | 87.96ms |
| broadPropagation (success) | 159.21ms | 2.57s | 303.66ms | 292.89ms | 3.80s | 264.81ms | **157.13ms** 🏆 |
| cellx1000 (first: pass, last: pass) | 3.76ms | 53.06ms | 5.77ms | 6.49ms | 14.09ms | 10.15ms | **3.40ms** 🏆 |
| cellx2500 (first: pass, last: pass) | 12.22ms | 160.37ms | 17.20ms | 15.11ms | 41.24ms | 30.45ms | **9.19ms** 🏆 |
| cellx5000 (first: pass, last: pass) | 40.40ms | 340.76ms | 51.29ms | 55.24ms | 148.92ms | 124.12ms | **31.57ms** 🏆 |
| comp_0to1 | **33μs** 🏆 | 14.87ms | 9.56ms | 13.25ms | 13.94ms | 33.58ms | **33μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 | 11μs | 3μs | 2μs | 11μs | 28μs | **0μs** 🏆 |
| comp_1to1 | **1.72ms** 🏆 | 16.99ms | 8.95ms | 8.14ms | 15.14ms | 34.58ms | 5.04ms |
| comp_1to1000 | **38μs** 🏆 | 11.40ms | 1.99ms | 2.51ms | 10.55ms | 27.51ms | **38μs** 🏆 |
| comp_1to2 | **1.11ms** 🏆 | 24.00ms | 10.72ms | 11.82ms | 19.50ms | 32.12ms | 1.43ms |
| comp_1to4 | 541μs | 15.84ms | 11.92ms | 13.13ms | 16.70ms | 31.67ms | **414μs** 🏆 |
| comp_1to8 | **205μs** 🏆 | 15.43ms | 5.06ms | 4.00ms | 16.13ms | 31.70ms | 206μs |
| comp_2to1 | 2.69ms | 31.57ms | **1.91ms** 🏆 | 7.04ms | 21.23ms | 18.95ms | 2.57ms |
| comp_4to1 | **1.66ms** 🏆 | 9.15ms | 7.79ms | 2.57ms | 7.53ms | 13.19ms | **1.66ms** 🏆 |
| create_signals | 14.10ms | 36.60ms | **5.83ms** 🏆 | 12.98ms | 32.58ms | 39.22ms | 13.29ms |
| deepPropagation (success) | **66.88ms** 🏆 | 960.51ms | 143.83ms | 137.17ms | 166.61ms | 137.07ms | 69.89ms |
| diamond (success) | 127.28ms | 1.47s | 214.93ms | 221.30ms | 698.87ms | 172.54ms | **127.12ms** 🏆 |
| molBench | **342.14ms** 🏆 | 412.57ms | 345.74ms | 349.14ms | 369.55ms | 803.42ms | 343.11ms |
| mux (success) | **248.83ms** 🏆 | 1.21s | 293.67ms | 288.98ms | 5.28s | 302.81ms | 253.58ms |
| repeatedObservers (success) | 22.70ms | 155.54ms | 27.64ms | 36.30ms | 136.25ms | 61.67ms | **20.20ms** 🏆 |
| triangle (success) | **49.74ms** 🏆 | 500.30ms | 78.94ms | 78.67ms | 178.64ms | 66.04ms | 51.20ms |
| unstable (success) | 35.03ms | 222.62ms | 46.57ms | 57.89ms | 224.00ms | 273.74ms | **28.52ms** 🏆 |
| update_1000to1 | **6μs** 🏆 | 35μs | 14μs | 39μs | 46μs | 10μs | **6μs** 🏆 |
| update_1to1 | 2.69ms | 13.89ms | 5.66ms | 15.44ms | 19.01ms | 4.26ms | **2.43ms** 🏆 |
| update_1to1000 | 3μs | 171μs | 19μs | 29μs | 116μs | 281μs | **2μs** 🏆 |
| update_1to2 | 2.20ms | 7.13ms | 2.87ms | 7.76ms | 9.55ms | **2.10ms** 🏆 | 3.11ms |
| update_1to4 | 682μs | 3.99ms | 1.35ms | 3.78ms | 4.81ms | 1.09ms | **606μs** 🏆 |
| update_2to1 | 1.28ms | 7.03ms | 2.84ms | 7.67ms | 9.64ms | 2.11ms | **1.22ms** 🏆 |
| update_4to1 | 651μs | 3.40ms | 1.40ms | 3.82ms | 4.80ms | 1.06ms | **610μs** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 19 | 100% |
| 🥈 | alien_signals | 18 | 100% |
| 🥉 | preact_signals | 2 | 100% |
| 4 | state_beacon | 1 | 100% |
| 5 | mobx | 0 | 100% |
| 6 | signals_core | 0 | 100% |
| 7 | solidart | 0 | 100% |

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
