import 'dart:convert';
import 'dart:io';

import '../../discovered_device.dart';
import '../../driver.dart';
import '../../keys.dart';

/// Roku External Control Protocol (ECP).
///
/// Connectionless: every command is a plain HTTP POST to port 8060.
/// Direct port of `discover()`/`send_key()` in `tools/roku_proof.py`.
class RokuDriver implements RemoteDriver {
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
  };
}
