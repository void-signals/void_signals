# Reactivity Benchmark Report

Generated: 2025-11-29T22:59:21.772314

## Results

| Test | preact_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.10s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **2.97s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **336.73ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **176.34ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **348.27ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **148.55ms** 🏆 |
| avoidablePropagation (success) | **141.40ms** 🏆 |
| broadPropagation (success) | **303.66ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **5.77ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **17.20ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **51.29ms** 🏆 |
| comp_0to1 | **9.56ms** 🏆 |
| comp_1000to1 | **3μs** 🏆 |
| comp_1to1 | **8.95ms** 🏆 |
| comp_1to1000 | **1.99ms** 🏆 |
| comp_1to2 | **10.72ms** 🏆 |
| comp_1to4 | **11.92ms** 🏆 |
| comp_1to8 | **5.06ms** 🏆 |
| comp_2to1 | **1.91ms** 🏆 |
| comp_4to1 | **7.79ms** 🏆 |
| create_signals | **5.83ms** 🏆 |
| deepPropagation (success) | **143.83ms** 🏆 |
| diamond (success) | **214.93ms** 🏆 |
| molBench | **345.74ms** 🏆 |
| mux (success) | **293.67ms** 🏆 |
| repeatedObservers (success) | **27.64ms** 🏆 |
| triangle (success) | **78.94ms** 🏆 |
| unstable (success) | **46.57ms** 🏆 |
| update_1000to1 | **14μs** 🏆 |
| update_1to1 | **5.66ms** 🏆 |
| update_1to1000 | **19μs** 🏆 |
| update_1to2 | **2.87ms** 🏆 |
| update_1to4 | **1.35ms** 🏆 |
| update_2to1 | **2.84ms** 🏆 |
| update_4to1 | **1.40ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | preact_signals | 35 | 100% |

