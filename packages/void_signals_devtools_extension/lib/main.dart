import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/void_signals_extension.dart';

void main() {
  runApp(const VoidSignalsDevToolsExtension());
}

class VoidSignalsDevToolsExtension extends StatelessWidget {
  const VoidSignalsDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: VoidSignalsExtensionPanel(),
    );
  }
}
