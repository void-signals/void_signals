# Reactivity Benchmark Report

Generated: 2025-11-30T07:14:32.655927

## Results

| Test | void_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **259.67ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **389.25ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **219.65ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **139.57ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **163.93ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **143.42ms** 🏆 |
| avoidablePropagation (success) | **119.99ms** 🏆 |
| broadPropagation (success) | **216.27ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **5.78ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **18.25ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **57.03ms** 🏆 |
| comp_0to1 | **66μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 |
| comp_1to1 | **882μs** 🏆 |
| comp_1to1000 | **42μs** 🏆 |
| comp_1to2 | **649μs** 🏆 |
| comp_1to4 | **287μs** 🏆 |
| comp_1to8 | **112μs** 🏆 |
| comp_2to1 | **1.76ms** 🏆 |
| comp_4to1 | **2.37ms** 🏆 |
| create_signals | **23.76ms** 🏆 |
| deepPropagation (success) | **75.14ms** 🏆 |
| diamond (success) | **129.28ms** 🏆 |
| molBench | **474.35ms** 🏆 |
| mux (success) | **293.24ms** 🏆 |
| repeatedObservers (success) | **21.34ms** 🏆 |
| triangle (success) | **58.96ms** 🏆 |
| unstable (success) | **38.77ms** 🏆 |
| update_1000to1 | **8μs** 🏆 |
| update_1to1 | **18.72ms** 🏆 |
| update_1to1000 | **8μs** 🏆 |
| update_1to2 | **4.48ms** 🏆 |
| update_1to4 | **901μs** 🏆 |
| update_2to1 | **1.96ms** 🏆 |
| update_4to1 | **2.45ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 35 | 100% |

