import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/remote/adjust/adjust.dart';
import 'core/remote/apphud/apphud_service.dart';
import 'core/remote/facebook/facebook_service.dart';
import 'core/remote/remote_store.dart';
import 'core/remote/tracking/idfa_service.dart';
// ignore: unused_import, kept for the temporarily-disabled gated home (see build()).
import 'features/discovery/presentation/discovery_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const RemoteTvApp(),
    ),
  );

  // Monetization + attribution SDKs init in the BACKGROUND — they must never
  // block the first frame. Their network calls can hang for seconds (e.g.
  // Facebook is unreachable in some regions); the UI renders regardless. Each
  // init() is guarded internally so failures degrade to no-ops.
  unawaited(ApphudService.instance.init());
  unawaited(AdjustService.instance.init());
  unawaited(FacebookService.instance.init());
}

class RemoteTvApp extends ConsumerStatefulWidget {
  const RemoteTvApp({super.key});

  @override
  ConsumerState<RemoteTvApp> createState() => _RemoteTvAppState();
}

class _RemoteTvAppState extends ConsumerState<RemoteTvApp> {
  @override
  void initState() {
    super.initState();
    // Ask for App Tracking Transparency once the first frame is on screen — iOS
    // only shows the prompt while the app is active. A short delay lets the app
    // settle into the active state before the prompt; on authorize the IDFA is
    // forwarded to Apphud.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await IDFAService().getIdfa();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C4DF6),
          brightness: Brightness.dark,
        ),
      ),
      // TEMP (dev): always show onboarding on every launch so it's easy to
      // iterate on. Before release restore the gated version:
      //   home: ref.watch(remoteStoreProvider).onboardingDone
      //       ? const DiscoveryScreen()
      //       : const OnboardingScreen(),
      home: const OnboardingScreen(),
    );
  }
}
