# Reactivity Benchmark Report

Generated: 2025-11-29T23:01:00.017662

## Results

| Test | signals_core |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.14s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **2.99s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **341.43ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **182.89ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **364.65ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **142.10ms** 🏆 |
| avoidablePropagation (success) | **158.11ms** 🏆 |
| broadPropagation (success) | **292.89ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **6.49ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **15.11ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **55.24ms** 🏆 |
| comp_0to1 | **13.25ms** 🏆 |
| comp_1000to1 | **2μs** 🏆 |
| comp_1to1 | **8.14ms** 🏆 |
| comp_1to1000 | **2.51ms** 🏆 |
| comp_1to2 | **11.82ms** 🏆 |
| comp_1to4 | **13.13ms** 🏆 |
| comp_1to8 | **4.00ms** 🏆 |
| comp_2to1 | **7.04ms** 🏆 |
| comp_4to1 | **2.57ms** 🏆 |
| create_signals | **12.98ms** 🏆 |
| deepPropagation (success) | **137.17ms** 🏆 |
| diamond (success) | **221.30ms** 🏆 |
| molBench | **349.14ms** 🏆 |
| mux (success) | **288.98ms** 🏆 |
| repeatedObservers (success) | **36.30ms** 🏆 |
| triangle (success) | **78.67ms** 🏆 |
| unstable (success) | **57.89ms** 🏆 |
| update_1000to1 | **39μs** 🏆 |
| update_1to1 | **15.44ms** 🏆 |
| update_1to1000 | **29μs** 🏆 |
| update_1to2 | **7.76ms** 🏆 |
| update_1to4 | **3.78ms** 🏆 |
| update_2to1 | **7.67ms** 🏆 |
| update_4to1 | **3.82ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | signals_core | 35 | 100% |

