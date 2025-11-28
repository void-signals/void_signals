# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-28

### Added

- Initial stable release of void_signals_lint
- 33+ comprehensive lint rules for void_signals ecosystem

#### Core Rules (Errors & Warnings)

- `avoid_signal_in_build` - Prevents signal creation in build methods
- `avoid_nested_effect_scope` - Warns against nested effect scopes
- `missing_effect_cleanup` - Ensures effects are stored for cleanup
- `avoid_signal_value_in_effect_condition` - Prevents conditional dependency issues
- `avoid_signal_access_in_async` - Warns about signal access after await
- `avoid_mutating_signal_collection` - Prevents direct mutation of collections
- `avoid_signal_creation_in_builder` - Prevents signals in builder callbacks
- `missing_scope_dispose` - Ensures effect scopes are disposed
- `avoid_set_state_with_signals` - Warns setState usage with signals
- `caution_signal_in_init_state` - Cautions signal creation in initState
- `watch_without_signal_access` - Warns Watch without signal access
- `avoid_circular_computed` - Detects circular computed dependencies
- `avoid_async_in_computed` - Warns async operations in computed

#### Best Practice Rules (Suggestions)

- `prefer_watch_over_effect_in_widget` - Suggests Watch over raw effects
- `prefer_batch_for_multiple_updates` - Suggests batching multiple updates
- `prefer_computed_over_derived_signal` - Suggests computed over manual derivation
- `prefer_final_signal` - Suggests final for top-level signals
- `prefer_signal_over_value_notifier` - Migration from ValueNotifier
- `prefer_peek_in_non_reactive` - Suggests peek() outside reactive context
- `avoid_effect_for_ui` - Suggests Watch over effect for UI
- `prefer_signal_scope_for_di` - Suggests SignalScope for DI
- `prefer_signal_with_label` - Suggests adding debug labels
- `unnecessary_untrack` - Removes unnecessary untrack calls

#### Hooks Rules (void_signals_hooks)

- `hooks_outside_hook_widget` - Ensures hooks are in HookWidget.build()
- `conditional_hook_call` - Prevents hooks in conditionals/loops
- `hook_in_callback` - Prevents hooks inside callbacks
- `use_signal_without_watch` - Warns when useSignal is not watched
- `use_select_pure_selector` - Ensures useSelect selector is pure
- `use_debounced_zero_duration` - Warns against zero duration debounce
- `use_effect_without_dependency` - Warns when effect has no signal deps
- `prefer_use_computed_over_effect` - Suggests useComputed for derived values
- `prefer_use_signal_with_label` - Suggests debug labels for hooks
- `unnecessary_use_batch` - Flags unnecessary useBatch
- `unnecessary_use_untrack` - Flags unnecessary useUntrack

### Features

- Quick fixes for most rules (12+ automated fixes)
- Real-time analysis as you code
- Configurable rules per project
- Detailed error messages with suggestions
- CI/CD support with `dart run custom_lint`

