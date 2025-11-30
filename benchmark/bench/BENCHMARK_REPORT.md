# Reactivity Benchmark Report

Generated: 2025-11-30T07:14:33.017554

## Results

| Test | alien_signals | mobx | preact_signals | signals_core | solidart | state_beacon | void_signals |
|------|--------|--------|--------|--------|--------|--------|--------|
| 1000x12 - 4 sources - dynamic (large, sum: pass, count: pass) | **256.00ms** 🏆 | 1.78s | 3.65s | 3.50s | 1.68s | 338.29ms | 259.67ms |
| 1000x5 - 25 sources (wide dense, sum: pass, count: pass) | 415.23ms | 3.42s | 3.36s | 3.50s | 21.26s | 498.92ms | **389.25ms** 🏆 |
| 100x15 - 6 sources - dynamic (very dynamic, sum: pass, count: pass) | 229.67ms | 1.66s | 465.49ms | 478.37ms | 1.76s | 257.48ms | **219.65ms** 🏆 |
| 10x10 - 6 sources - dynamic (dynamic, sum: pass, count: pass) | 155.51ms | 1.48s | 291.38ms | 292.32ms | 1.43s | 201.91ms | **139.57ms** 🏆 |
| 10x5 - 2 sources (simple, sum: pass, count: pass) | 184.58ms | 1.90s | 507.30ms | 534.25ms | 753.07ms | 250.85ms | **163.93ms** 🏆 |
| 5x500 - 3 sources (deep, sum: pass, count: pass) | 151.87ms | 1.09s | 234.55ms | 216.78ms | 492.27ms | 202.63ms | **143.42ms** 🏆 |
| avoidablePropagation (success) | 132.76ms | 2.47s | 207.66ms | 247.76ms | 496.51ms | 176.85ms | **119.99ms** 🏆 |
| broadPropagation (success) | 242.92ms | 4.21s | 463.18ms | 457.11ms | 4.77s | 397.17ms | **216.27ms** 🏆 |
| cellx1000 (first: pass, last: pass) | **5.40ms** 🏆 | 66.21ms | 9.70ms | 11.79ms | 20.96ms | 17.82ms | 5.78ms |
| cellx2500 (first: pass, last: pass) | 20.50ms | 255.76ms | 27.23ms | 26.27ms | 52.49ms | 45.68ms | **18.25ms** 🏆 |
| cellx5000 (first: pass, last: pass) | **54.93ms** 🏆 | 551.09ms | 68.89ms | 77.23ms | 252.26ms | 110.71ms | 57.03ms |
| comp_0to1 | **30μs** 🏆 | 16.19ms | 16.43ms | 29.11ms | 20.89ms | 50.79ms | 66μs |
| comp_1000to1 | **0μs** 🏆 | 21μs | 13μs | 6μs | 13μs | 38μs | **0μs** 🏆 |
| comp_1to1 | 946μs | 41.68ms | 28.26ms | 17.52ms | 23.35ms | 47.78ms | **882μs** 🏆 |
| comp_1to1000 | 65μs | 14.45ms | 2.80ms | 4.34ms | 13.80ms | 36.71ms | **42μs** 🏆 |
| comp_1to2 | **439μs** 🏆 | 20.46ms | 21.40ms | 30.26ms | 35.20ms | 43.00ms | 649μs |
| comp_1to4 | **218μs** 🏆 | 28.81ms | 23.33ms | 26.77ms | 20.77ms | 42.75ms | 287μs |
| comp_1to8 | **108μs** 🏆 | 23.58ms | 4.07ms | 5.76ms | 24.29ms | 41.61ms | 112μs |
| comp_2to1 | 2.27ms | 31.74ms | 8.64ms | 12.29ms | 19.37ms | 26.01ms | **1.76ms** 🏆 |
| comp_4to1 | **824μs** 🏆 | 11.56ms | 14.23ms | 1.60ms | 10.15ms | 18.02ms | 2.37ms |
| create_signals | 30.35ms | 61.86ms | **5.18ms** 🏆 | 25.00ms | 52.91ms | 58.38ms | 23.76ms |
| deepPropagation (success) | 78.14ms | 1.49s | 177.94ms | 173.33ms | 267.05ms | 159.99ms | **75.14ms** 🏆 |
| diamond (success) | 154.72ms | 2.30s | 288.43ms | 307.81ms | 995.15ms | 220.67ms | **129.28ms** 🏆 |
| molBench | 486.32ms | 574.63ms | 493.37ms | 487.55ms | 521.25ms | 1.14s | **474.35ms** 🏆 |
| mux (success) | **291.69ms** 🏆 | 1.75s | 388.46ms | 379.85ms | 5.95s | 371.00ms | 293.24ms |
| repeatedObservers (success) | 32.95ms | 223.40ms | 39.76ms | 51.33ms | 198.49ms | 59.14ms | **21.34ms** 🏆 |
| triangle (success) | 63.40ms | 728.27ms | 105.29ms | 108.55ms | 250.35ms | 88.44ms | **58.96ms** 🏆 |
| unstable (success) | 49.75ms | 325.92ms | 70.12ms | 80.64ms | 332.37ms | 343.86ms | **38.77ms** 🏆 |
| update_1000to1 | 27μs | 57μs | 20μs | 65μs | 94μs | 16μs | **8μs** 🏆 |
| update_1to1 | 11.00ms | 21.19ms | 8.15ms | 26.68ms | 38.04ms | **6.65ms** 🏆 | 18.72ms |
| update_1to1000 | 10μs | 149μs | 30μs | 52μs | 152μs | 377μs | **8μs** 🏆 |
| update_1to2 | 4.04ms | 10.44ms | 4.22ms | 13.45ms | 19.59ms | **3.31ms** 🏆 | 4.48ms |
| update_1to4 | 2.77ms | 5.41ms | 2.07ms | 6.61ms | 9.53ms | 1.64ms | **901μs** 🏆 |
| update_2to1 | 5.58ms | 10.64ms | 4.16ms | 13.31ms | 18.98ms | 3.31ms | **1.96ms** 🏆 |
| update_4to1 | 2.75ms | 5.15ms | 2.11ms | 6.75ms | 9.58ms | **1.66ms** 🏆 | 2.45ms |

## Summary

| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 22 | 100% |
| 🥈 | alien_signals | 10 | 100% |
| 🥉 | state_beacon | 3 | 100% |
| 4 | preact_signals | 1 | 100% |
| 5 | mobx | 0 | 100% |
| 6 | signals_core | 0 | 100% |
| 7 | solidart | 0 | 100% |
