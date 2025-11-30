# Reactivity Benchmark Report

Generated: 2025-11-30T14:14:23.226116

## Results

| Test | alien_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **263.37ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **416.88ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **238.93ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **157.27ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **185.08ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **156.12ms** 🏆 |
| avoidablePropagation (success) | **131.30ms** 🏆 |
| broadPropagation (success) | **242.69ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **5.46ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **15.47ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **48.64ms** 🏆 |
| comp_0to1 | **36μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 |
| comp_1to1 | **892μs** 🏆 |
| comp_1to1000 | **62μs** 🏆 |
| comp_1to2 | **667μs** 🏆 |
| comp_1to4 | **260μs** 🏆 |
| comp_1to8 | **111μs** 🏆 |
| comp_2to1 | **1.40ms** 🏆 |
| comp_4to1 | **1.48ms** 🏆 |
| create_signals | **26.68ms** 🏆 |
| deepPropagation (success) | **78.33ms** 🏆 |
| diamond (success) | **154.38ms** 🏆 |
| molBench | **488.89ms** 🏆 |
| mux (success) | **304.01ms** 🏆 |
| repeatedObservers (success) | **34.03ms** 🏆 |
| triangle (success) | **64.19ms** 🏆 |
| unstable (success) | **49.35ms** 🏆 |
| update_1000to1 | **26μs** 🏆 |
| update_1to1 | **19.72ms** 🏆 |
| update_1to1000 | **10μs** 🏆 |
| update_1to2 | **1.97ms** 🏆 |
| update_1to4 | **2.73ms** 🏆 |
| update_2to1 | **5.42ms** 🏆 |
| update_4to1 | **2.73ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | alien_signals | 35 | 100% |

