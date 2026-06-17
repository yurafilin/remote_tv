import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'discovered_device.dart';

/// The loaded [SharedPreferences] instance. Overridden in `main()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider in main()'),
);

final remoteStoreProvider = Provider<RemoteStore>(
  (ref) => RemoteStore(ref.watch(sharedPreferencesProvider)),
);

/// Persists the last connected device and per-host Samsung pairing tokens, so
/// the app can reconnect instantly without re-scanning or re-pairing.
class RemoteStore {
  RemoteStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _deviceKey = 'last_device';
  static const String _tokenPrefix = 'samsung_token_';
  static const String _onboardingKey = 'onboarding_done';

  Future<void> saveLastDevice(DiscoveredDevice device) => _prefs.setString(
        _deviceKey,
        jsonEncode({
          'host': device.host,
          'platform': device.platform.name,
          'name': device.name,
        }),
      );

  DiscoveredDevice? loadLastDevice() {
    final raw = _prefs.getString(_deviceKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final platform = DevicePlatform.values.asNameMap()[map['platform']] ??
        DevicePlatform.unknown;
    return DiscoveredDevice(
      host: map['host'] as String,
      platform: platform,
      name: map['name'] as String?,
    );
  }

  Future<void> clearLastDevice() => _prefs.remove(_deviceKey);

  /// Whether the first-launch onboarding has been completed.
  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingDone() => _prefs.setBool(_onboardingKey, true);

  String? token(String host) => _prefs.getString('$_tokenPrefix$host');

  Future<void> saveToken(String host, String token) =>
      _prefs.setString('$_tokenPrefix$host', token);

  static const String _macPrefix = 'mac_';

  String? mac(String host) => _prefs.getString('$_macPrefix$host');

  Future<void> saveMac(String host, String mac) =>
      _prefs.setString('$_macPrefix$host', mac);

  /// Forget a device: drop it as the last device (if it is) and clear its
  /// saved pairing token and MAC.
  Future<void> forget(String host) async {
    if (loadLastDevice()?.host == host) await clearLastDevice();
    await _prefs.remove('$_tokenPrefix$host');
    await _prefs.remove('$_macPrefix$host');
  }
}
