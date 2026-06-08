import 'dart:convert';
import 'dart:io';

import '../../app_launcher.dart';
import '../../discovered_device.dart';
import '../../driver.dart';
import '../../device_info_reporter.dart';
import '../../keys.dart';
import '../../text_input.dart';

/// Roku External Control Protocol (ECP).
///
/// Connectionless: every command is a plain HTTP POST to port 8060.
/// Direct port of `discover()`/`send_key()` in `tools/roku_proof.py`.
class RokuDriver
    implements RemoteDriver, TextInput, AppLauncher, DeviceInfoReporter {
  RokuDriver(this.host, {HttpClient? client}) : _client = client ?? HttpClient();

  static const int ecpPort = 8060;

  final String host;
  final HttpClient _client;

  @override
  DevicePlatform get platform => DevicePlatform.roku;

  @override
  Set<RemoteKey> get capabilities => _keyMap.keys.toSet();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async => _client.close();

  @override
  Future<void> sendKey(RemoteKey key) async {
    final rokuKey = _keyMap[key];
    if (rokuKey == null) throw UnsupportedKeyError(key, platform);
    await _press(rokuKey);
  }

  @override
  Future<void> sendText(String text) async {
    for (final rune in text.runes) {
      await _press('Lit_${Uri.encodeComponent(String.fromCharCode(rune))}');
    }
  }

  @override
  Future<void> submit() => _press('Enter');

  Future<void> _press(String rokuKey) async {
    final request = await _client.postUrl(
      Uri.parse('http://$host:$ecpPort/keypress/$rokuKey'),
    );
    final response = await request.close();
    await response.drain<void>();
  }

  /// `GET /query/device-info` — the raw XML the TV reports about itself.
  Future<String> deviceInfo() async {
    final request = await _client.getUrl(
      Uri.parse('http://$host:$ecpPort/query/device-info'),
    );
    final response = await request.close();
    return response.transform(utf8.decoder).join();
  }

  @override
  Set<AppShortcut> get apps => _appIds.keys.toSet();

  @override
  Future<void> launchApp(AppShortcut app) async {
    final id = _appIds[app];
    if (id == null) return;
    final request = await _client.postUrl(
      Uri.parse('http://$host:$ecpPort/launch/$id'),
    );
    await (await request.close()).drain<void>();
  }

  @override
  Future<DeviceInfo?> info() async {
    try {
      final xml = await deviceInfo();
      String? tag(String t) => RegExp('<$t>(.*?)</$t>').firstMatch(xml)?.group(1);
      return (
        name: tag('user-device-name') ?? tag('friendly-device-name'),
        mac: tag('wifi-mac') ?? tag('ethernet-mac'),
      );
    } catch (_) {
      return null;
    }
  }

  static const Map<AppShortcut, String> _appIds = {
    AppShortcut.netflix: '12',
    AppShortcut.youtube: '837',
    AppShortcut.primeVideo: '13',
    AppShortcut.disneyPlus: '291097',
    AppShortcut.spotify: '22297',
  };

  static const Map<RemoteKey, String> _keyMap = {
    RemoteKey.power: 'Power',
    RemoteKey.home: 'Home',
    RemoteKey.back: 'Back',
    RemoteKey.up: 'Up',
    RemoteKey.down: 'Down',
    RemoteKey.left: 'Left',
    RemoteKey.right: 'Right',
    RemoteKey.ok: 'Select',
    RemoteKey.volumeUp: 'VolumeUp',
    RemoteKey.volumeDown: 'VolumeDown',
    RemoteKey.mute: 'VolumeMute',
    RemoteKey.playPause: 'Play',
    RemoteKey.rewind: 'Rev',
    RemoteKey.fastForward: 'Fwd',
    RemoteKey.replay: 'InstantReplay',
    RemoteKey.info: 'Info',
    RemoteKey.channelUp: 'ChannelUp',
    RemoteKey.channelDown: 'ChannelDown',
    RemoteKey.digit0: 'Lit_0',
    RemoteKey.digit1: 'Lit_1',
    RemoteKey.digit2: 'Lit_2',
    RemoteKey.digit3: 'Lit_3',
    RemoteKey.digit4: 'Lit_4',
    RemoteKey.digit5: 'Lit_5',
    RemoteKey.digit6: 'Lit_6',
    RemoteKey.digit7: 'Lit_7',
    RemoteKey.digit8: 'Lit_8',
    RemoteKey.digit9: 'Lit_9',
  };
}
