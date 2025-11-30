# Reactivity Benchmark Report

Generated: 2025-11-29T22:54:35.489654

## Results

| Test | alien_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **205.28ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **351.73ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **178.53ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **119.28ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **155.93ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **105.72ms** 🏆 |
| avoidablePropagation (success) | **86.44ms** 🏆 |
| broadPropagation (success) | **159.21ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **3.76ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **12.22ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **40.40ms** 🏆 |
| comp_0to1 | **33μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 |
| comp_1to1 | **1.72ms** 🏆 |
| comp_1to1000 | **38μs** 🏆 |
| comp_1to2 | **1.11ms** 🏆 |
| comp_1to4 | **541μs** 🏆 |
| comp_1to8 | **205μs** 🏆 |
| comp_2to1 | **2.69ms** 🏆 |
| comp_4to1 | **1.66ms** 🏆 |
| create_signals | **14.10ms** 🏆 |
| deepPropagation (success) | **66.88ms** 🏆 |
| diamond (success) | **127.28ms** 🏆 |
| molBench | **342.14ms** 🏆 |
| mux (success) | **248.83ms** 🏆 |
| repeatedObservers (success) | **22.70ms** 🏆 |
| triangle (success) | **49.74ms** 🏆 |
| unstable (success) | **35.03ms** 🏆 |
| update_1000to1 | **6μs** 🏆 |
| update_1to1 | **2.69ms** 🏆 |
| update_1to1000 | **3μs** 🏆 |
| update_1to2 | **2.20ms** 🏆 |
| update_1to4 | **682μs** 🏆 |
| update_2to1 | **1.28ms** 🏆 |
| update_4to1 | **651μs** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | alien_signals | 35 | 100% |

