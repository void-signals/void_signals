# Reactivity Benchmark Report

Generated: 2025-11-30T07:03:42.145717

## Results

| Test | preact_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.65s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **3.36s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **465.49ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **291.38ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **507.30ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **234.55ms** 🏆 |
| avoidablePropagation (success) | **207.66ms** 🏆 |
| broadPropagation (success) | **463.18ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **9.70ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **27.23ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **68.89ms** 🏆 |
| comp_0to1 | **16.43ms** 🏆 |
| comp_1000to1 | **13μs** 🏆 |
| comp_1to1 | **28.26ms** 🏆 |
| comp_1to1000 | **2.80ms** 🏆 |
| comp_1to2 | **21.40ms** 🏆 |
| comp_1to4 | **23.33ms** 🏆 |
| comp_1to8 | **4.07ms** 🏆 |
| comp_2to1 | **8.64ms** 🏆 |
| comp_4to1 | **14.23ms** 🏆 |
| create_signals | **5.18ms** 🏆 |
| deepPropagation (success) | **177.94ms** 🏆 |
| diamond (success) | **288.43ms** 🏆 |
| molBench | **493.37ms** 🏆 |
| mux (success) | **388.46ms** 🏆 |
| repeatedObservers (success) | **39.76ms** 🏆 |
| triangle (success) | **105.29ms** 🏆 |
| unstable (success) | **70.12ms** 🏆 |
| update_1000to1 | **20μs** 🏆 |
| update_1to1 | **8.15ms** 🏆 |
| update_1to1000 | **30μs** 🏆 |
| update_1to2 | **4.22ms** 🏆 |
| update_1to4 | **2.07ms** 🏆 |
| update_2to1 | **4.16ms** 🏆 |
| update_4to1 | **2.11ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | preact_signals | 35 | 100% |

