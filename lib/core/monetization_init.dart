import 'dart:async';

import 'remote/adjust/adjust.dart';
import 'remote/apphud/apphud_service.dart';
import 'remote/facebook/facebook_service.dart';

/// Kicks off the monetization + attribution SDKs (Apphud, Adjust, Facebook) in
/// the background. They must never block the first frame, so every call is
/// `unawaited` and each `init()` degrades to a no-op on failure.
///
/// Started from the onboarding "Allow access" step on first run (not at app
/// launch): an attribution SDK enumerates network interfaces during init, which
/// surfaces the iOS local-network permission prompt — we want that to land on
/// the "Allow access" screen, not over the very first onboarding screen.
/// Returning users (who already granted local-network access during their
/// first-run onboarding) start them at launch instead.
void startMonetizationSdks() {
  unawaited(ApphudService.instance.init());
  unawaited(AdjustService.instance.init());
  unawaited(FacebookService.instance.init());
}
