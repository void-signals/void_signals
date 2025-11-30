# Reactivity Benchmark Report

Generated: 2025-11-30T09:35:53.948765

## Results

| Test | preact_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.64s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **3.33s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **472.33ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **291.87ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **510.68ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **228.77ms** 🏆 |
| avoidablePropagation (success) | **206.34ms** 🏆 |
| broadPropagation (success) | **462.47ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **12.06ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **27.59ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **77.91ms** 🏆 |
| comp_0to1 | **19.48ms** 🏆 |
| comp_1000to1 | **13μs** 🏆 |
| comp_1to1 | **18.14ms** 🏆 |
| comp_1to1000 | **2.86ms** 🏆 |
| comp_1to2 | **35.75ms** 🏆 |
| comp_1to4 | **20.62ms** 🏆 |
| comp_1to8 | **5.78ms** 🏆 |
| comp_2to1 | **2.32ms** 🏆 |
| comp_4to1 | **19.32ms** 🏆 |
| create_signals | **12.46ms** 🏆 |
| deepPropagation (success) | **179.08ms** 🏆 |
| diamond (success) | **284.89ms** 🏆 |
| molBench | **489.27ms** 🏆 |
| mux (success) | **384.98ms** 🏆 |
| repeatedObservers (success) | **39.97ms** 🏆 |
| triangle (success) | **103.24ms** 🏆 |
| unstable (success) | **70.87ms** 🏆 |
| update_1000to1 | **39μs** 🏆 |
| update_1to1 | **8.23ms** 🏆 |
| update_1to1000 | **29μs** 🏆 |
| update_1to2 | **4.55ms** 🏆 |
| update_1to4 | **2.07ms** 🏆 |
| update_2to1 | **4.16ms** 🏆 |
| update_4to1 | **2.25ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | preact_signals | 35 | 100% |

