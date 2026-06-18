import 'package:flutter/material.dart';

import '../../../core/remote/apphud/apphud_service.dart';
import '../../paywall/presentation/paywall_screen.dart';
import '../../remote/presentation/remote_screen.dart';

/// Shown right after a TV connects: a "You're all set" confirmation in the same
/// monochrome, full-bleed style as the onboarding. Continue opens the remote.
class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key});

  Future<void> _continue(BuildContext context) async {
    final navigator = Navigator.of(context);
    // Non-premium users see the paywall first; either way, land on the remote.
    if (!ApphudService.instance.isPremium.value) {
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
      );
    }
    if (!context.mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RemoteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-width illustration pinned to the top, fading into black so the
          // title above and the text + button below read cleanly.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                Image.asset(
                  'assets/onboarding/onboarding_you_all_set.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0.72, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "You're all set",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'You can now control your TV and use all the remote '
                        'features right from your phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 56),
                  child: SizedBox(
                    height: 72,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _continue(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
