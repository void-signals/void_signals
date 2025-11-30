# Reactivity Benchmark Report

Generated: 2025-11-30T06:57:09.671110

## Results

| Test | alien_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **256.00ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **415.23ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **229.67ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **155.51ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **184.58ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **151.87ms** 🏆 |
| avoidablePropagation (success) | **132.76ms** 🏆 |
| broadPropagation (success) | **242.92ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **5.40ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **20.50ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **54.93ms** 🏆 |
| comp_0to1 | **30μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 |
| comp_1to1 | **946μs** 🏆 |
| comp_1to1000 | **65μs** 🏆 |
| comp_1to2 | **439μs** 🏆 |
| comp_1to4 | **218μs** 🏆 |
| comp_1to8 | **108μs** 🏆 |
| comp_2to1 | **2.27ms** 🏆 |
| comp_4to1 | **824μs** 🏆 |
| create_signals | **30.35ms** 🏆 |
| deepPropagation (success) | **78.14ms** 🏆 |
| diamond (success) | **154.72ms** 🏆 |
| molBench | **486.32ms** 🏆 |
| mux (success) | **291.69ms** 🏆 |
| repeatedObservers (success) | **32.95ms** 🏆 |
| triangle (success) | **63.40ms** 🏆 |
| unstable (success) | **49.75ms** 🏆 |
| update_1000to1 | **27μs** 🏆 |
| update_1to1 | **11.00ms** 🏆 |
| update_1to1000 | **10μs** 🏆 |
| update_1to2 | **4.04ms** 🏆 |
| update_1to4 | **2.77ms** 🏆 |
| update_2to1 | **5.58ms** 🏆 |
| update_4to1 | **2.75ms** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | alien_signals | 35 | 100% |

