import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'features/home/home_page.dart';

void main() {
  runApp(const ProviderScope(child: DeviceInspectorApp()));
}

class DeviceInspectorApp extends StatelessWidget {
  const DeviceInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeviceInspector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomePage(),
    );
  }
}
