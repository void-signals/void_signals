# Reactivity Benchmark Report

Generated: 2025-11-29T23:08:22.676962

## Results

| Test | void_signals |
|------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **216.37ms** 🏆 |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | **356.81ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | **178.49ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | **121.20ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | **159.47ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | **108.38ms** 🏆 |
| avoidablePropagation (success) | **87.96ms** 🏆 |
| broadPropagation (success) | **157.13ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **3.40ms** 🏆 |
| cellx2500 (first: pass, last: pass) | **9.19ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **31.57ms** 🏆 |
| comp_0to1 | **33μs** 🏆 |
| comp_1000to1 | **0μs** 🏆 |
| comp_1to1 | **5.04ms** 🏆 |
| comp_1to1000 | **38μs** 🏆 |
| comp_1to2 | **1.43ms** 🏆 |
| comp_1to4 | **414μs** 🏆 |
| comp_1to8 | **206μs** 🏆 |
| comp_2to1 | **2.57ms** 🏆 |
| comp_4to1 | **1.66ms** 🏆 |
| create_signals | **13.29ms** 🏆 |
| deepPropagation (success) | **69.89ms** 🏆 |
| diamond (success) | **127.12ms** 🏆 |
| molBench | **343.11ms** 🏆 |
| mux (success) | **253.58ms** 🏆 |
| repeatedObservers (success) | **20.20ms** 🏆 |
| triangle (success) | **51.20ms** 🏆 |
| unstable (success) | **28.52ms** 🏆 |
| update_1000to1 | **6μs** 🏆 |
| update_1to1 | **2.43ms** 🏆 |
| update_1to1000 | **2μs** 🏆 |
| update_1to2 | **3.11ms** 🏆 |
| update_1to4 | **606μs** 🏆 |
| update_2to1 | **1.22ms** 🏆 |
| update_4to1 | **610μs** 🏆 |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 35 | 100% |

