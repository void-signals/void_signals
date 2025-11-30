# Reactivity Benchmark Report

Generated: 2025-11-30T14:22:57.372690

## Results

| Test | signals_core |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.76s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **3.52s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **479.16ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **292.72ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **542.72ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **223.43ms** 🏆 |
| avoidablePropagation (success) | **246.93ms** 🏆 |
| broadPropagation (success) | **444.17ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **11.64ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **26.19ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **67.00ms** 🏆 |
| comp_0to1 | **27.34ms** 🏆 |
| comp_1000to1 | **3μs** 🏆 |
| comp_1to1 | **22.36ms** 🏆 |
| comp_1to1000 | **4.95ms** 🏆 |
| comp_1to2 | **26.82ms** 🏆 |
| comp_1to4 | **19.85ms** 🏆 |
| comp_1to8 | **2.89ms** 🏆 |
| comp_2to1 | **24.64ms** 🏆 |
| comp_4to1 | **1.73ms** 🏆 |
| create_signals | **24.32ms** 🏆 |
| deepPropagation (success) | **174.79ms** 🏆 |
| diamond (success) | **302.25ms** 🏆 |
| molBench | **485.74ms** 🏆 |
| mux (success) | **379.26ms** 🏆 |
| repeatedObservers (success) | **51.03ms** 🏆 |
| triangle (success) | **106.78ms** 🏆 |
| unstable (success) | **79.88ms** 🏆 |
| update_1000to1 | **64μs** 🏆 |
| update_1to1 | **26.54ms** 🏆 |
| update_1to1000 | **51μs** 🏆 |
| update_1to2 | **13.27ms** 🏆 |
| update_1to4 | **6.63ms** 🏆 |
| update_2to1 | **13.12ms** 🏆 |
| update_4to1 | **6.66ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | signals_core | 35 | 100% |

