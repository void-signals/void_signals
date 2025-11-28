/// Constants and patterns used across lint rules.
library;

/// Signal creation functions.
const signalCreators = {
  'signal',
  'computed',
  'computedFrom',
};

/// Hooks that create signals.
const hookSignalCreators = {
  'useSignal',
  'useComputed',
  'useReactive',
  'useSignalFromStream',
  'useSignalFromFuture',
  'useDebounced',
  'useThrottled',
  'useCombine2',
  'useCombine3',
  'usePrevious',
};

/// Hooks that create collections.
const hookCollectionCreators = {
  'useSignalList',
  'useSignalMap',
  'useSignalSet',
};

/// Hooks that create effects.
const hookEffectCreators = {
  'useSignalEffect',
  'useWatch',
  'useSelect',
};

/// Hooks that manage scopes.
const hookScopeCreators = {
  'useEffectScope',
};

/// Utility hooks.
const hookUtilityCreators = {
  'useBatch',
  'useUntrack',
};

/// All hooks.
const allHooks = {
  ...hookSignalCreators,
  ...hookCollectionCreators,
  ...hookEffectCreators,
  ...hookScopeCreators,
  ...hookUtilityCreators,
};

/// Signal access patterns.
const signalAccessors = {
  'value',
  'peek',
};

/// Flutter widget base classes.
const flutterWidgetBases = {
  'StatelessWidget',
  'StatefulWidget',
  'State',
  'HookWidget',
  'HookConsumerWidget',
};

/// Known Flutter widgets (for code assists).
const knownFlutterWidgets = {
  'Text',
  'Container',
  'Row',
  'Column',
  'Scaffold',
  'AppBar',
  'Center',
  'Padding',
  'SizedBox',
  'Card',
  'ListTile',
  'Icon',
  'Image',
  'TextField',
  'Button',
  'ElevatedButton',
  'TextButton',
  'IconButton',
  'FloatingActionButton',
  'Wrap',
  'Stack',
  'Positioned',
  'Expanded',
  'Flexible',
  'ListView',
  'GridView',
  'SingleChildScrollView',
  'CustomScrollView',
  'AnimatedContainer',
  'AnimatedOpacity',
  'FadeTransition',
  'SlideTransition',
};
