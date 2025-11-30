# Reactivity Benchmark Report

Generated: 2025-11-30T14:20:53.402258

## Results

| Test | preact_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.69s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **3.33s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **473.05ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **290.91ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **507.92ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **233.75ms** 🏆 |
| avoidablePropagation (success) | **208.49ms** 🏆 |
| broadPropagation (success) | **466.91ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **9.73ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **26.91ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **69.38ms** 🏆 |
| comp_0to1 | **16.67ms** 🏆 |
| comp_1000to1 | **6μs** 🏆 |
| comp_1to1 | **28.68ms** 🏆 |
| comp_1to1000 | **2.91ms** 🏆 |
| comp_1to2 | **24.24ms** 🏆 |
| comp_1to4 | **31.42ms** 🏆 |
| comp_1to8 | **9.32ms** 🏆 |
| comp_2to1 | **14.59ms** 🏆 |
| comp_4to1 | **11.15ms** 🏆 |
| create_signals | **5.46ms** 🏆 |
| deepPropagation (success) | **178.07ms** 🏆 |
| diamond (success) | **283.49ms** 🏆 |
| molBench | **492.29ms** 🏆 |
| mux (success) | **386.15ms** 🏆 |
| repeatedObservers (success) | **39.51ms** 🏆 |
| triangle (success) | **103.65ms** 🏆 |
| unstable (success) | **70.03ms** 🏆 |
| update_1000to1 | **21μs** 🏆 |
| update_1to1 | **8.17ms** 🏆 |
| update_1to1000 | **31μs** 🏆 |
| update_1to2 | **4.20ms** 🏆 |
| update_1to4 | **2.12ms** 🏆 |
| update_2to1 | **4.18ms** 🏆 |
| update_4to1 | **2.10ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | preact_signals | 35 | 100% |

