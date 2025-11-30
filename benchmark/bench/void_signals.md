# Reactivity Benchmark Report

Generated: 2025-11-30T14:31:48.288359

## Results

| Test | void_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **255.56ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **382.89ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **221.25ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **140.36ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **164.82ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **143.65ms** 🏆 |
| avoidablePropagation (success) | **119.75ms** 🏆 |
| broadPropagation (success) | **216.53ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **6.26ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **16.08ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **51.73ms** 🏆 |
| comp_0to1 | **66μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 |
| comp_1to1 | **942μs** 🏆 |
| comp_1to1000 | **42μs** 🏆 |
| comp_1to2 | **444μs** 🏆 |
| comp_1to4 | **224μs** 🏆 |
| comp_1to8 | **107μs** 🏆 |
| comp_2to1 | **1.61ms** 🏆 |
| comp_4to1 | **764μs** 🏆 |
| create_signals | **29.80ms** 🏆 |
| deepPropagation (success) | **75.62ms** 🏆 |
| diamond (success) | **128.77ms** 🏆 |
| molBench | **474.57ms** 🏆 |
| mux (success) | **285.43ms** 🏆 |
| repeatedObservers (success) | **21.11ms** 🏆 |
| triangle (success) | **58.00ms** 🏆 |
| unstable (success) | **38.70ms** 🏆 |
| update_1000to1 | **25μs** 🏆 |
| update_1to1 | **9.69ms** 🏆 |
| update_1to1000 | **10μs** 🏆 |
| update_1to2 | **4.85ms** 🏆 |
| update_1to4 | **1.24ms** 🏆 |
| update_2to1 | **1.92ms** 🏆 |
| update_4to1 | **2.44ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 35 | 100% |

