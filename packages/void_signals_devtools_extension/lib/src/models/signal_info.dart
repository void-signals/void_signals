/// Model classes for signal information.
///
/// These models represent the reactive primitives tracked by the
/// void_signals DevTools extension.

import 'package:flutter/material.dart';

/// Source of signal creation.
enum SignalSource {
  /// Created via direct signal() call
  direct('Direct'),

  /// Created via useSignal hook
  useSignal('useSignal'),

  /// Created via useComputed hook
  useComputed('useComputed'),

  /// Created via useReactive hook
  useReactive('useReactive'),

  /// Created via useDebounced hook
  useDebounced('useDebounced'),

  /// Created via useThrottled hook
  useThrottled('useThrottled'),

  /// Created via useCombine2/3 hook
  useCombine('useCombine'),

  /// Created via usePrevious hook
  usePrevious('usePrevious'),

  /// Created via useSignalFromStream hook
  useSignalFromStream('useSignalFromStream'),

  /// Created via useSignalFromFuture hook
  useSignalFromFuture('useSignalFromFuture'),

  /// Created via useSignalList hook
  useSignalList('useSignalList'),

  /// Created via useSignalMap hook
  useSignalMap('useSignalMap'),

  /// Created via useSignalSet hook
  useSignalSet('useSignalSet'),

  /// Unknown source
  unknown('Unknown');

  const SignalSource(this.displayName);
  final String displayName;

  /// Whether this signal was created by a hook
  bool get isHook => this != direct && this != unknown;

  /// Get icon for source
  IconData get icon {
    if (isHook) return Icons.anchor;
    return Icons.radio_button_checked;
  }

  /// Get color for source
  Color get color {
    if (isHook) return Colors.purple;
    return Colors.blue;
  }

  static SignalSource fromString(String? value) {
    if (value == null) return unknown;
    return SignalSource.values.firstWhere(
      (e) => e.name == value || e.displayName == value,
      orElse: () => unknown,
    );
  }
}

/// Base class for all reactive primitives.
abstract class ReactiveInfo {
  String get id;
  String get name;
  String? get label;
  String get displayName => label ?? name;
  Color get color;
  IconData get icon;
}

/// Information about a Signal.
class SignalInfo implements ReactiveInfo {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? label;
  final String value;
  final String type;
  final int subscriberCount;
  final List<String> dependencyIds;
  final DateTime? lastUpdated;
  final String? stackTrace;
  final int updateCount;
  final bool isEditable;

  /// Source of signal creation (hook or direct)
  final SignalSource source;

  /// Widget name if created by a hook
  final String? widgetName;

  /// Hook widget instance ID for grouping
  final String? hookWidgetId;

  SignalInfo({
    required this.id,
    required this.name,
    this.label,
    required this.value,
    required this.type,
    required this.subscriberCount,
    this.dependencyIds = const [],
    this.lastUpdated,
    this.stackTrace,
    this.updateCount = 0,
    this.isEditable = true,
    this.source = SignalSource.direct,
    this.widgetName,
    this.hookWidgetId,
  });

  @override
  String get displayName => label ?? name;

  @override
  Color get color => source.color;

  @override
  IconData get icon => source.icon;

  /// Whether this signal was created by a hook
  bool get isFromHook => source.isHook;

  factory SignalInfo.fromJson(Map<String, dynamic> json) {
    return SignalInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      label: json['label'] as String?,
      value: json['value'] as String,
      type: json['type'] as String,
      subscriberCount: json['subscriberCount'] as int? ?? 0,
      dependencyIds:
          (json['dependencyIds'] as List<dynamic>?)?.cast<String>() ?? [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
      stackTrace: json['stackTrace'] as String?,
      updateCount: json['updateCount'] as int? ?? 0,
      isEditable: json['isEditable'] as bool? ?? true,
      source: SignalSource.fromString(json['source'] as String?),
      widgetName: json['widgetName'] as String?,
      hookWidgetId: json['hookWidgetId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'value': value,
        'type': type,
        'subscriberCount': subscriberCount,
        'dependencyIds': dependencyIds,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'stackTrace': stackTrace,
        'updateCount': updateCount,
        'isEditable': isEditable,
        'source': source.name,
        'widgetName': widgetName,
        'hookWidgetId': hookWidgetId,
      };

  SignalInfo copyWith({
    String? id,
    String? name,
    String? label,
    String? value,
    String? type,
    int? subscriberCount,
    List<String>? dependencyIds,
    DateTime? lastUpdated,
    String? stackTrace,
    int? updateCount,
    bool? isEditable,
    SignalSource? source,
    String? widgetName,
    String? hookWidgetId,
  }) {
    return SignalInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      value: value ?? this.value,
      type: type ?? this.type,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      dependencyIds: dependencyIds ?? this.dependencyIds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      stackTrace: stackTrace ?? this.stackTrace,
      updateCount: updateCount ?? this.updateCount,
      isEditable: isEditable ?? this.isEditable,
      source: source ?? this.source,
      widgetName: widgetName ?? this.widgetName,
      hookWidgetId: hookWidgetId ?? this.hookWidgetId,
    );
  }
}

/// Information about a Computed.
class ComputedInfo implements ReactiveInfo {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? label;
  final String value;
  final String type;
  final int subscriberCount;
  final List<String> dependencyIds;
  final bool isDirty;
  final DateTime? lastComputed;
  final int computeCount;
  final Duration? lastComputeDuration;

  /// Whether this is an async computed (AsyncComputed or StreamComputed)
  final bool isAsync;

  /// The async state type: 'loading', 'data', 'error', or null if not async
  final String? asyncState;

  /// Error message if asyncState is 'error'
  final String? asyncError;

  /// Whether this is a StreamComputed
  final bool isStream;

  ComputedInfo({
    required this.id,
    required this.name,
    this.label,
    required this.value,
    required this.type,
    required this.subscriberCount,
    this.dependencyIds = const [],
    this.isDirty = false,
    this.lastComputed,
    this.computeCount = 0,
    this.lastComputeDuration,
    this.isAsync = false,
    this.asyncState,
    this.asyncError,
    this.isStream = false,
  });

  @override
  String get displayName => label ?? name;

  @override
  Color get color =>
      isAsync ? (isStream ? Colors.cyan : Colors.teal) : Colors.green;

  @override
  IconData get icon =>
      isAsync ? (isStream ? Icons.stream : Icons.cloud_sync) : Icons.functions;

  factory ComputedInfo.fromJson(Map<String, dynamic> json) {
    return ComputedInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      label: json['label'] as String?,
      value: json['value'] as String,
      type: json['type'] as String,
      subscriberCount: json['subscriberCount'] as int? ?? 0,
      dependencyIds:
          (json['dependencyIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isDirty: json['isDirty'] as bool? ?? false,
      lastComputed: json['lastComputed'] != null
          ? DateTime.tryParse(json['lastComputed'] as String)
          : null,
      computeCount: json['computeCount'] as int? ?? 0,
      lastComputeDuration: json['lastComputeDurationUs'] != null
          ? Duration(microseconds: json['lastComputeDurationUs'] as int)
          : null,
      isAsync: json['isAsync'] as bool? ?? false,
      asyncState: json['asyncState'] as String?,
      asyncError: json['asyncError'] as String?,
      isStream: json['isStream'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'value': value,
        'type': type,
        'subscriberCount': subscriberCount,
        'dependencyIds': dependencyIds,
        'isDirty': isDirty,
        'lastComputed': lastComputed?.toIso8601String(),
        'computeCount': computeCount,
        'lastComputeDurationUs': lastComputeDuration?.inMicroseconds,
        'isAsync': isAsync,
        'asyncState': asyncState,
        'asyncError': asyncError,
        'isStream': isStream,
      };
}

/// Information about an Effect.
class EffectInfo implements ReactiveInfo {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? label;
  final List<String> dependencyIds;
  final int runCount;
  final bool isActive;
  final DateTime? lastRun;
  final Duration? lastRunDuration;
  final String? error;

  EffectInfo({
    required this.id,
    required this.name,
    this.label,
    this.dependencyIds = const [],
    this.runCount = 0,
    this.isActive = true,
    this.lastRun,
    this.lastRunDuration,
    this.error,
  });

  @override
  String get displayName => label ?? name;

  @override
  Color get color => Colors.orange;

  @override
  IconData get icon => Icons.bolt;

  factory EffectInfo.fromJson(Map<String, dynamic> json) {
    return EffectInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      label: json['label'] as String?,
      dependencyIds:
          (json['dependencyIds'] as List<dynamic>?)?.cast<String>() ?? [],
      runCount: json['runCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      lastRun: json['lastRun'] != null
          ? DateTime.tryParse(json['lastRun'] as String)
          : null,
      lastRunDuration: json['lastRunDurationUs'] != null
          ? Duration(microseconds: json['lastRunDurationUs'] as int)
          : null,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'dependencyIds': dependencyIds,
        'runCount': runCount,
        'isActive': isActive,
        'lastRun': lastRun?.toIso8601String(),
        'lastRunDurationUs': lastRunDuration?.inMicroseconds,
        'error': error,
      };
}

/// Information about an EffectScope.
class ScopeInfo implements ReactiveInfo {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? label;
  final List<String> effectIds;
  final List<String> childScopeIds;
  final bool isActive;
  final DateTime? createdAt;

  ScopeInfo({
    required this.id,
    required this.name,
    this.label,
    this.effectIds = const [],
    this.childScopeIds = const [],
    this.isActive = true,
    this.createdAt,
  });

  @override
  String get displayName => label ?? name;

  @override
  Color get color => Colors.purple;

  @override
  IconData get icon => Icons.folder_outlined;

  factory ScopeInfo.fromJson(Map<String, dynamic> json) {
    return ScopeInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      label: json['label'] as String?,
      effectIds: (json['effectIds'] as List<dynamic>?)?.cast<String>() ?? [],
      childScopeIds:
          (json['childScopeIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'effectIds': effectIds,
        'childScopeIds': childScopeIds,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };
}

/// Information about a dependency relationship.
class DependencyLink {
  final String sourceId;
  final String targetId;
  final String sourceType;
  final String targetType;

  DependencyLink({
    required this.sourceId,
    required this.targetId,
    required this.sourceType,
    required this.targetType,
  });

  factory DependencyLink.fromJson(Map<String, dynamic> json) {
    return DependencyLink(
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      sourceType: json['sourceType'] as String,
      targetType: json['targetType'] as String,
    );
  }
}

/// Value history entry for timeline view.
class ValueHistoryEntry {
  final String signalId;
  final String oldValue;
  final String newValue;
  final DateTime timestamp;
  final String? triggerSource;

  ValueHistoryEntry({
    required this.signalId,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    this.triggerSource,
  });

  factory ValueHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ValueHistoryEntry(
      signalId: json['signalId'] as String,
      oldValue: json['oldValue'] as String,
      newValue: json['newValue'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      triggerSource: json['triggerSource'] as String?,
    );
  }
}

/// Statistics about the reactive system.
class ReactiveStats {
  final int totalSignals;
  final int totalComputeds;
  final int totalEffects;
  final int totalScopes;
  final int activeEffects;
  final int dirtyComputeds;
  final int totalUpdates;
  final int totalComputations;
  final int totalEffectRuns;
  final Duration? avgComputeTime;
  final Duration? avgEffectTime;

  /// Number of AsyncComputed instances
  final int totalAsyncComputeds;

  /// Number of StreamComputed instances
  final int totalStreamComputeds;

  /// Number of async computeds currently loading
  final int loadingAsyncComputeds;

  /// Number of async computeds with errors
  final int errorAsyncComputeds;

  ReactiveStats({
    required this.totalSignals,
    required this.totalComputeds,
    required this.totalEffects,
    required this.totalScopes,
    required this.activeEffects,
    required this.dirtyComputeds,
    required this.totalUpdates,
    required this.totalComputations,
    required this.totalEffectRuns,
    this.avgComputeTime,
    this.avgEffectTime,
    this.totalAsyncComputeds = 0,
    this.totalStreamComputeds = 0,
    this.loadingAsyncComputeds = 0,
    this.errorAsyncComputeds = 0,
  });

  factory ReactiveStats.empty() => ReactiveStats(
        totalSignals: 0,
        totalComputeds: 0,
        totalEffects: 0,
        totalScopes: 0,
        activeEffects: 0,
        dirtyComputeds: 0,
        totalUpdates: 0,
        totalComputations: 0,
        totalEffectRuns: 0,
      );

  factory ReactiveStats.fromJson(Map<String, dynamic> json) {
    return ReactiveStats(
      totalSignals: json['totalSignals'] as int? ?? 0,
      totalComputeds: json['totalComputeds'] as int? ?? 0,
      totalEffects: json['totalEffects'] as int? ?? 0,
      totalScopes: json['totalScopes'] as int? ?? 0,
      activeEffects: json['activeEffects'] as int? ?? 0,
      dirtyComputeds: json['dirtyComputeds'] as int? ?? 0,
      totalUpdates: json['totalUpdates'] as int? ?? 0,
      totalComputations: json['totalComputations'] as int? ?? 0,
      totalEffectRuns: json['totalEffectRuns'] as int? ?? 0,
      avgComputeTime: json['avgComputeTimeUs'] != null
          ? Duration(microseconds: json['avgComputeTimeUs'] as int)
          : null,
      avgEffectTime: json['avgEffectTimeUs'] != null
          ? Duration(microseconds: json['avgEffectTimeUs'] as int)
          : null,
      totalAsyncComputeds: json['totalAsyncComputeds'] as int? ?? 0,
      totalStreamComputeds: json['totalStreamComputeds'] as int? ?? 0,
      loadingAsyncComputeds: json['loadingAsyncComputeds'] as int? ?? 0,
      errorAsyncComputeds: json['errorAsyncComputeds'] as int? ?? 0,
    );
  }
}

/// Filter options for the signal list.
class SignalFilter {
  final String searchQuery;
  final Set<String>
      types; // 'signal', 'computed', 'effect', 'scope', 'asyncComputed', 'streamComputed'
  final bool showOnlyDirty;
  final bool showOnlyActive;
  final SortOption sortBy;
  final bool sortDescending;

  /// Filter by signal source
  final Set<SignalSource>? sourceFilter;

  /// Group by widget when showing hooks
  final bool groupByWidget;

  /// Filter by async state
  final Set<String>? asyncStateFilter; // 'loading', 'data', 'error'

  const SignalFilter({
    this.searchQuery = '',
    this.types = const {
      'signal',
      'computed',
      'effect',
      'asyncComputed',
      'streamComputed'
    },
    this.showOnlyDirty = false,
    this.showOnlyActive = false,
    this.sortBy = SortOption.name,
    this.sortDescending = false,
    this.sourceFilter,
    this.groupByWidget = false,
    this.asyncStateFilter,
  });

  /// Filter signals based on current filter settings.
  List<SignalInfo> filterSignals(List<SignalInfo> signals) {
    return signals.where((signal) {
      // Type filter
      if (!types.contains('signal')) return false;

      // Search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!signal.displayName.toLowerCase().contains(query) &&
            !signal.value.toLowerCase().contains(query) &&
            !signal.type.toLowerCase().contains(query) &&
            !(signal.widgetName?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Source filter
      if (sourceFilter != null && sourceFilter!.isNotEmpty) {
        if (!sourceFilter!.contains(signal.source)) return false;
      }

      return true;
    }).toList();
  }

  /// Filter computeds based on current filter settings.
  List<ComputedInfo> filterComputeds(List<ComputedInfo> computeds) {
    return computeds.where((computed) {
      // Type filter - now handles async and stream computeds separately
      if (computed.isAsync) {
        if (computed.isStream) {
          if (!types.contains('streamComputed') && !types.contains('computed'))
            return false;
        } else {
          if (!types.contains('asyncComputed') && !types.contains('computed'))
            return false;
        }
      } else {
        if (!types.contains('computed')) return false;
      }

      // Search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!computed.displayName.toLowerCase().contains(query) &&
            !computed.value.toLowerCase().contains(query) &&
            !computed.type.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Dirty filter
      if (showOnlyDirty && !computed.isDirty) return false;

      // Async state filter
      if (asyncStateFilter != null &&
          asyncStateFilter!.isNotEmpty &&
          computed.isAsync) {
        if (computed.asyncState != null &&
            !asyncStateFilter!.contains(computed.asyncState)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Filter effects based on current filter settings.
  List<EffectInfo> filterEffects(List<EffectInfo> effects) {
    return effects.where((effect) {
      // Type filter
      if (!types.contains('effect')) return false;

      // Search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!effect.displayName.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Active filter
      if (showOnlyActive && !effect.isActive) return false;

      return true;
    }).toList();
  }

  /// Group signals by widget name.
  Map<String?, List<SignalInfo>> groupSignalsByWidget(
      List<SignalInfo> signals) {
    final groups = <String?, List<SignalInfo>>{};
    for (final signal in signals) {
      final key = signal.isFromHook ? signal.widgetName : null;
      groups.putIfAbsent(key, () => []).add(signal);
    }
    return groups;
  }

  SignalFilter copyWith({
    String? searchQuery,
    Set<String>? types,
    bool? showOnlyDirty,
    bool? showOnlyActive,
    SortOption? sortBy,
    bool? sortDescending,
    Set<SignalSource>? sourceFilter,
    bool? groupByWidget,
    Set<String>? asyncStateFilter,
  }) {
    return SignalFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      types: types ?? this.types,
      showOnlyDirty: showOnlyDirty ?? this.showOnlyDirty,
      showOnlyActive: showOnlyActive ?? this.showOnlyActive,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      groupByWidget: groupByWidget ?? this.groupByWidget,
      asyncStateFilter: asyncStateFilter ?? this.asyncStateFilter,
    );
  }
}

/// Sort options for signals.
enum SortOption {
  name,
  type,
  lastUpdated,
  subscriberCount,
  updateCount,
}
