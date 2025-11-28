import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'pages/home_page.dart';

/// The main app widget for Pub.dev Explorer
class PubDevExplorerApp extends StatelessWidget {
  const PubDevExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pub.dev Explorer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
