# Reactivity Benchmark Report

Generated: 2025-11-30T07:05:45.090390

## Results

| Test | signals_core |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.50s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **3.50s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **478.37ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **292.32ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **534.25ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **216.78ms** 🏆 |
| avoidablePropagation (success) | **247.76ms** 🏆 |
| broadPropagation (success) | **457.11ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **11.79ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **26.27ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **77.23ms** 🏆 |
| comp_0to1 | **29.11ms** 🏆 |
| comp_1000to1 | **6μs** 🏆 |
| comp_1to1 | **17.52ms** 🏆 |
| comp_1to1000 | **4.34ms** 🏆 |
| comp_1to2 | **30.26ms** 🏆 |
| comp_1to4 | **26.77ms** 🏆 |
| comp_1to8 | **5.76ms** 🏆 |
| comp_2to1 | **12.29ms** 🏆 |
| comp_4to1 | **1.60ms** 🏆 |
| create_signals | **25.00ms** 🏆 |
| deepPropagation (success) | **173.33ms** 🏆 |
| diamond (success) | **307.81ms** 🏆 |
| molBench | **487.55ms** 🏆 |
| mux (success) | **379.85ms** 🏆 |
| repeatedObservers (success) | **51.33ms** 🏆 |
| triangle (success) | **108.55ms** 🏆 |
| unstable (success) | **80.64ms** 🏆 |
| update_1000to1 | **65μs** 🏆 |
| update_1to1 | **26.68ms** 🏆 |
| update_1to1000 | **52μs** 🏆 |
| update_1to2 | **13.45ms** 🏆 |
| update_1to4 | **6.61ms** 🏆 |
| update_2to1 | **13.31ms** 🏆 |
| update_4to1 | **6.75ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | signals_core | 35 | 100% |

