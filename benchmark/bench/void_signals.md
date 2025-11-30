# Reactivity Benchmark Report

Generated: 2025-11-30T09:46:49.628225

## Results

| Test | void_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **256.80ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **385.35ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **219.71ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **140.66ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **165.44ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **140.85ms** 🏆 |
| avoidablePropagation (success) | **120.06ms** 🏆 |
| broadPropagation (success) | **215.29ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **5.83ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **16.38ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **53.36ms** 🏆 |
| comp_0to1 | **33μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 |
| comp_1to1 | **894μs** 🏆 |
| comp_1to1000 | **42μs** 🏆 |
| comp_1to2 | **939μs** 🏆 |
| comp_1to4 | **378μs** 🏆 |
| comp_1to8 | **120μs** 🏆 |
| comp_2to1 | **7.35ms** 🏆 |
| comp_4to1 | **3.58ms** 🏆 |
| create_signals | **30.54ms** 🏆 |
| deepPropagation (success) | **75.15ms** 🏆 |
| diamond (success) | **128.94ms** 🏆 |
| molBench | **474.20ms** 🏆 |
| mux (success) | **282.82ms** 🏆 |
| repeatedObservers (success) | **21.06ms** 🏆 |
| triangle (success) | **58.78ms** 🏆 |
| unstable (success) | **38.32ms** 🏆 |
| update_1000to1 | **8μs** 🏆 |
| update_1to1 | **15.48ms** 🏆 |
| update_1to1000 | **8μs** 🏆 |
| update_1to2 | **3.26ms** 🏆 |
| update_1to4 | **1.51ms** 🏆 |
| update_2to1 | **2.39ms** 🏆 |
| update_4to1 | **2.39ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 35 | 100% |

