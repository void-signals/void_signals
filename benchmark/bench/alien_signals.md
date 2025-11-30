# Reactivity Benchmark Report

Generated: 2025-11-30T09:29:23.759299

## Results

| Test | alien_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **261.82ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **407.34ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **235.47ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **155.18ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **184.60ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **150.40ms** 🏆 |
| avoidablePropagation (success) | **131.58ms** 🏆 |
| broadPropagation (success) | **243.72ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **6.31ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **19.33ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **53.60ms** 🏆 |
| comp_0to1 | **30μs** 🏆 |
| comp_1000to1 | **1μs** 🏆 |
| comp_1to1 | **3.85ms** 🏆 |
| comp_1to1000 | **62μs** 🏆 |
| comp_1to2 | **616μs** 🏆 |
| comp_1to4 | **280μs** 🏆 |
| comp_1to8 | **133μs** 🏆 |
| comp_2to1 | **1.72ms** 🏆 |
| comp_4to1 | **929μs** 🏆 |
| create_signals | **27.29ms** 🏆 |
| deepPropagation (success) | **78.94ms** 🏆 |
| diamond (success) | **153.19ms** 🏆 |
| molBench | **488.85ms** 🏆 |
| mux (success) | **301.36ms** 🏆 |
| repeatedObservers (success) | **32.98ms** 🏆 |
| triangle (success) | **65.48ms** 🏆 |
| unstable (success) | **49.21ms** 🏆 |
| update_1000to1 | **26μs** 🏆 |
| update_1to1 | **11.03ms** 🏆 |
| update_1to1000 | **10μs** 🏆 |
| update_1to2 | **1.94ms** 🏆 |
| update_1to4 | **2.73ms** 🏆 |
| update_2to1 | **5.50ms** 🏆 |
| update_4to1 | **2.69ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | alien_signals | 35 | 100% |

