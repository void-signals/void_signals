# Reactivity Benchmark Report

Generated: 2025-11-30T14:31:17.633095

## Results

| Test | state_beacon |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **340.39ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **504.42ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **259.09ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **201.16ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **255.94ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **202.15ms** 🏆 |
| avoidablePropagation (success) | **180.64ms** 🏆 |
| broadPropagation (success) | **402.67ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **15.75ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **42.71ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **106.63ms** 🏆 |
| comp_0to1 | **51.86ms** 🏆 |
| comp_1000to1 | **38μs** 🏆 |
| comp_1to1 | **48.22ms** 🏆 |
| comp_1to1000 | **36.94ms** 🏆 |
| comp_1to2 | **43.56ms** 🏆 |
| comp_1to4 | **42.13ms** 🏆 |
| comp_1to8 | **42.46ms** 🏆 |
| comp_2to1 | **26.35ms** 🏆 |
| comp_4to1 | **18.49ms** 🏆 |
| create_signals | **59.83ms** 🏆 |
| deepPropagation (success) | **159.60ms** 🏆 |
| diamond (success) | **230.07ms** 🏆 |
| molBench | **1.14s** 🏆 |
| mux (success) | **369.52ms** 🏆 |
| repeatedObservers (success) | **59.67ms** 🏆 |
| triangle (success) | **88.25ms** 🏆 |
| unstable (success) | **347.40ms** 🏆 |
| update_1000to1 | **17μs** 🏆 |
| update_1to1 | **6.66ms** 🏆 |
| update_1to1000 | **374μs** 🏆 |
| update_1to2 | **3.29ms** 🏆 |
| update_1to4 | **1.66ms** 🏆 |
| update_2to1 | **3.31ms** 🏆 |
| update_4to1 | **1.66ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | state_beacon | 35 | 100% |

