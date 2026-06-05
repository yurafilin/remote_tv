import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/discovery/presentation/discovery_screen.dart';

void main() => runApp(const ProviderScope(child: RemoteTvApp()));

class RemoteTvApp extends ConsumerWidget {
  const RemoteTvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Remote TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C4DF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const DiscoveryScreen(),
    );
  }
}
