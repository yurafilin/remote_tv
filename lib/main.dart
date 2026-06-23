import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/monetization_init.dart';
import 'core/remote/remote_store.dart';
import 'core/remote/tracking/idfa_service.dart';
import 'features/discovery/presentation/discovery_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Capture first-run state now, before onboarding flips the flag, so the
  // post-connection "You're all set" screen only shows during the first setup.
  final firstRun = !RemoteStore(prefs).onboardingDone;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firstRunProvider.overrideWithValue(firstRun),
      ],
      child: const RemoteTvApp(),
    ),
  );

  // First-run users start these SDKs from the onboarding "Allow access" step so
  // the iOS local-network prompt (an attribution SDK surfaces it during init)
  // lands there rather than over the first onboarding screen. Returning users
  // have already granted local-network access, so start them now.
  if (!firstRun) startMonetizationSdks();
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
      if (!Platform.isIOS) return; // App Tracking Transparency is iOS-only.
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
      // First launch shows onboarding; once it's been completed, subsequent
      // launches go straight to the discovery screen.
      home: ref.watch(remoteStoreProvider).onboardingDone
          ? const DiscoveryScreen()
          : const OnboardingScreen(),
    );
  }
}
