# Reactivity Benchmark Report

Generated: 2025-11-30T09:37:56.477491

## Results

| Test | signals_core |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **3.57s** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **3.32s** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **482.80ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **291.89ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **534.82ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **218.77ms** 🏆 |
| avoidablePropagation (success) | **246.76ms** 🏆 |
| broadPropagation (success) | **447.53ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **12.47ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **26.84ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **75.02ms** 🏆 |
| comp_0to1 | **26.48ms** 🏆 |
| comp_1000to1 | **3μs** 🏆 |
| comp_1to1 | **19.99ms** 🏆 |
| comp_1to1000 | **3.83ms** 🏆 |
| comp_1to2 | **21.71ms** 🏆 |
| comp_1to4 | **26.23ms** 🏆 |
| comp_1to8 | **2.67ms** 🏆 |
| comp_2to1 | **24.83ms** 🏆 |
| comp_4to1 | **1.70ms** 🏆 |
| create_signals | **23.54ms** 🏆 |
| deepPropagation (success) | **175.83ms** 🏆 |
| diamond (success) | **302.27ms** 🏆 |
| molBench | **485.69ms** 🏆 |
| mux (success) | **381.33ms** 🏆 |
| repeatedObservers (success) | **50.92ms** 🏆 |
| triangle (success) | **109.18ms** 🏆 |
| unstable (success) | **78.18ms** 🏆 |
| update_1000to1 | **64μs** 🏆 |
| update_1to1 | **26.46ms** 🏆 |
| update_1to1000 | **53μs** 🏆 |
| update_1to2 | **13.10ms** 🏆 |
| update_1to4 | **6.51ms** 🏆 |
| update_2to1 | **13.12ms** 🏆 |
| update_4to1 | **6.67ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | signals_core | 35 | 100% |

