import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import 'src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize VoidSignals DevTools extension
  VoidSignalsDebugService.initialize();

  // Add logging observer in debug mode (similar to Riverpod's ProviderObserver)
  if (kDebugMode) {
    VoidSignalsDebugService.addObserver(
      LoggingSignalObserver(
        logAdded: true,
        logUpdated: true,
        logDisposed: true,
        logEffectRuns: false, // Can be noisy, enable if needed
        logErrors: true,
      ),
    );
  }

  runApp(const PubDevExplorerApp());
}
