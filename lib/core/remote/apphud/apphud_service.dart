import 'dart:convert';
import 'dart:io';

import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_debug_level.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Emergency override: when true, the onboarding/paywall flow is skipped and
/// premium is granted for free on every launch. Use only as a temporary fix
/// if the Store / Apphud integration breaks for a release.
const kForceUnlockedBuild = false;

/// API key from Apphud Console. Fill before first test build.
const _apphudApiKey = 'app_XAc86zbrDtwpRL9xawaPpqjo2bdRPS';

/// Password QA enters to flip on tester premium. Treat as well-known internally
/// — never ship in marketing copy. Rotate per project if needed.
const _testerUnlockPassword = '1221';

class ApphudService {
  static ApphudService? _instance;
  static ApphudService get instance {
    _instance ??= ApphudService._internal();
    return _instance!;
  }

  ApphudService._internal();

  String _userId = '';
  String get userId => _userId;

  List<ApphudPlacement?> _placements = [];
  List<ApphudPlacement?> get placements => _placements;

  /// Tester-only premium override unlocked via the hidden password prompt
  /// on the paywall. Persisted across launches so QA doesn't have to re-enter
  /// the password every cold start. Treated identically to a paid premium
  /// state by every consumer of [isPremium] / [checkPremium].
  bool _testPremium = false;
  static const _testPremiumFile = 'apphud_test_premium.json';

  bool get _bypass => kForceUnlockedBuild || _testPremium;

  /// Reactive premium flag. Gets flipped whenever [checkPremium],
  /// [purchaseProduct], or [restorePurchases] picks up a new state — UI
  /// listeners rebuild automatically when the user buys premium through any
  /// gate, regardless of which screen owns that paywall.
  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(
    kForceUnlockedBuild,
  );

  void _setPremium(bool value) {
    if (isPremium.value != value) isPremium.value = value;
  }

  Future<void> init() async {
    await _loadTestPremium();
    if (_bypass) _setPremium(true);

    if (_apphudApiKey.isEmpty) {
      // No key yet — paywall calls will return empty / fail gracefully. App
      // boots normally, tester unlock and kForceUnlockedBuild still work.
      return;
    }

    try {
      if (!kReleaseMode) {
        await Apphud.enableDebugLogs(level: ApphudDebugLevel.high);
      }
      await Apphud.start(apiKey: _apphudApiKey);
      await getPlacements();
      _userId = await Apphud.userID();
      // Sync the active-subscription state into [isPremium] on every cold
      // start. Without this, `isPremium` defaults to false on launch and the
      // sound / mission pickers gate everything behind the paywall until the
      // user re-purchases or hits the restore button — even though the
      // entitlement is already active in StoreKit / Play Billing.
      await _syncPremiumFromApphud();
    } catch (e, st) {
      if (!kReleaseMode) {
        // ignore: avoid_print
        print('Apphud init failed: $e\n$st');
      }
    }
  }

  /// Polls Apphud for the current active-subscription state and pushes it
  /// into [isPremium]. Safe to call repeatedly; never overrides a tester
  /// bypass (the `_setPremium` setter respects the OR with `_bypass` only
  /// in the bypass-true direction — we never demote a tester to free).
  Future<void> _syncPremiumFromApphud() async {
    if (_bypass) return; // tester / forced unlock — leave premium on.
    try {
      final premium = await Apphud.hasActiveSubscription();
      _setPremium(premium);
    } catch (_) {
      // Best-effort — UI defaults to "not premium" which is the safe
      // pre-purchase state.
    }
  }

  /// Returns true on correct password — flips and persists premium for tester.
  /// Compared case-insensitively and ignoring surrounding whitespace.
  Future<bool> attemptTesterUnlock(String input) async {
    if (input.trim().toLowerCase() != _testerUnlockPassword) return false;
    await unlockTestPremium();
    return true;
  }

  /// Hidden tester unlock: called when the correct password is entered in
  /// the paywall's secret bottom sheet. Flips premium on and persists so
  /// every subsequent launch starts unlocked.
  Future<void> unlockTestPremium() => setTesterPremium(true);

  /// Returns the current value of the tester-premium flag. Useful when the
  /// in-app developer panel wants to render a stateful toggle.
  bool get isTesterPremium => _testPremium;

  /// Explicitly flips the tester-premium flag and persists to disk so the
  /// state survives cold starts. Drives the "Premium access" toggle in the
  /// developer settings section.
  Future<void> setTesterPremium(bool value) async {
    _testPremium = value;
    _setPremium(_bypass);
    try {
      final file = await _testPremiumStateFile();
      if (value) {
        await file.writeAsString(jsonEncode({'unlocked': true}));
      } else if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      /* persistence is best-effort */
    }
  }

  Future<void> _loadTestPremium() async {
    try {
      final file = await _testPremiumStateFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _testPremium = data['unlocked'] == true;
      }
    } catch (_) {
      /* corrupted file — treat as locked */
    }
  }

  Future<File> _testPremiumStateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_testPremiumFile');
  }

  Future<void> setIDFA(String idfa) async {
    await Apphud.setAdvertisingIdentifier(idfa);
  }

  Future<bool> purchaseProduct(ApphudProduct apphudProduct) async {
    if (_bypass) {
      _setPremium(true);
      return true;
    }
    try {
      await Apphud.purchase(product: apphudProduct);
      final premium = await Apphud.hasActiveSubscription();
      _setPremium(premium);
      return premium;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkPremium() async {
    if (_bypass) {
      _setPremium(true);
      return true;
    }
    if (_apphudApiKey.isEmpty) return false;
    try {
      final premium = await Apphud.hasActiveSubscription();
      _setPremium(premium);
      return premium;
    } catch (_) {
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (_bypass) {
      _setPremium(true);
      return;
    }
    if (_apphudApiKey.isEmpty) return;
    try {
      await Apphud.restorePurchases();
      final premium = await Apphud.hasActiveSubscription();
      _setPremium(premium);
    } catch (_) {
      /* fail silently — UI shows "no premium" */
    }
  }

  Future<void> getPlacements() async {
    try {
      _placements = await Apphud.placements();
    } catch (_) {
      _placements = const [];
    }
  }

  Future<void> paywallShown(ApphudPaywall paywall) async {
    try {
      await Apphud.paywallShown(paywall);
    } catch (_) {
      /* analytics failures must not bubble up */
    }
  }

  /// Always refetches placements from Apphud. Products inside a paywall may
  /// be empty on the very first call because StoreKit / Google Play haven't
  /// returned product metadata yet — callers should retry on empty.
  Future<ApphudPaywall?> fetchPaywall(AppHudPlacementID placementID) async {
    await getPlacements();
    final placement = _placements.firstWhereOrNull(
      (element) => element?.identifier == placementID.value,
    );
    return placement?.paywall;
  }

  Future<Map<String, dynamic>> fetchOnboardingConfig() async {
    final paywall = await fetchPaywall(AppHudPlacementID.onboarding);
    final rawJson = paywall?.json;
    if (rawJson == null || rawJson.isEmpty) return <String, dynamic>{};
    return rawJson;
  }
}

/// Apphud placement identifiers — must match the Apphud Console exactly. The
/// app currently ships a single paywall placement.
enum AppHudPlacementID {
  onboarding;

  String get value => switch (this) {
        AppHudPlacementID.onboarding => 'onboarding',
      };
}

/// Reactive premium flag, bridged from [ApphudService.isPremium] so widgets can
/// `ref.watch` it and rebuild on purchase / restore / launch sync. Overridable
/// in tests via `overrideWithValue`.
final premiumProvider = Provider<bool>((ref) {
  final flag = ApphudService.instance.isPremium;
  void listener() => ref.invalidateSelf();
  flag.addListener(listener);
  ref.onDispose(() => flag.removeListener(listener));
  return flag.value;
});
