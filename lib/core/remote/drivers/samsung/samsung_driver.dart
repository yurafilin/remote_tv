import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../app_launcher.dart';
import '../../discovered_device.dart';
import '../../driver.dart';
import '../../device_info_reporter.dart';
import '../../keys.dart';
import '../../text_input.dart';

/// Samsung Tizen (2016+) WebSocket remote control.
///
/// Unlike Roku this is connection-oriented: [connect] opens a wss socket
/// (self-signed cert on :8002) and, on first use, the TV shows an Allow/Deny
/// popup and hands back a [token] to skip the popup next time.
class SamsungDriver
    implements RemoteDriver, TextInput, AppLauncher, DeviceInfoReporter {
  SamsungDriver(this.host, {this.appName = 'Remote TV', this.token});

  static const int wssPort = 8002;

  final String host;
  final String appName;

  /// Pairing token negotiated with the TV; persist it to avoid re-pairing.
  String? token;

  WebSocket? _socket;

  @override
  DevicePlatform get platform => DevicePlatform.samsung;

  @override
  Set<RemoteKey> get capabilities => _keyMap.keys.toSet();

  @override
  Future<void> connect() async {
    if (_socket != null) return;

    final name = base64.encode(utf8.encode(appName));
    final tokenParam = token == null ? '' : '&token=$token';
    final url = 'wss://$host:$wssPort/api/v2/channels/samsung.remote.control'
        '?name=$name$tokenParam';

    final client = HttpClient()..badCertificateCallback = (_, _, _) => true;
    final socket = await WebSocket.connect(url, customClient: client);
    _socket = socket;

    final ready = Completer<void>();
    final timer = Timer(const Duration(seconds: 30), () {
      if (!ready.isCompleted) {
        ready.completeError(TimeoutException('Samsung pairing timed out'));
      }
    });

    socket.listen(
      (dynamic message) {
        if (message is! String) return;
        final Map<String, dynamic> data;
        try {
          data = jsonDecode(message) as Map<String, dynamic>;
        } catch (_) {
          return;
        }
        switch (data['event']) {
          case 'ms.channel.connect':
            {
              final newToken = (data['data'] as Map<String, dynamic>?)?['token'];
              if (newToken != null) token = newToken.toString();
              if (!ready.isCompleted) ready.complete();
            }
          case 'ms.channel.unauthorized':
            if (!ready.isCompleted) {
              ready.completeError(
                StateError('Samsung TV denied the connection'),
              );
            }
        }
      },
      onError: (Object e) {
        if (!ready.isCompleted) ready.completeError(e);
      },
      onDone: () {
        if (!ready.isCompleted) {
          ready.completeError(StateError('Samsung TV closed the connection'));
        }
      },
    );

    try {
      await ready.future;
    } catch (_) {
      await socket.close();
      _socket = null;
      rethrow;
    } finally {
      timer.cancel();
    }
  }

  @override
  Future<void> sendKey(RemoteKey key) async {
    final samsungKey = _keyMap[key];
    if (samsungKey == null) throw UnsupportedKeyError(key, platform);
    final socket = _socket;
    if (socket == null) throw StateError('Samsung TV is not connected');
    socket.add(
      jsonEncode({
        'method': 'ms.remote.control',
        'params': {
          'Cmd': 'Click',
          'DataOfCmd': samsungKey,
          'Option': 'false',
          'TypeOfRemote': 'SendRemoteKey',
        },
      }),
    );
  }

  @override
  Future<void> sendText(String text) async {
    final socket = _socket;
    if (socket == null) throw StateError('Samsung TV is not connected');
    socket.add(
      jsonEncode({
        'method': 'ms.remote.control',
        'params': {
          'Cmd': base64.encode(utf8.encode(text)),
          'DataOfCmd': 'base64',
          'TypeOfRemote': 'SendInputString',
        },
      }),
    );
  }

  @override
  Future<void> submit() => sendKey(RemoteKey.ok);

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  @override
  Set<AppShortcut> get apps => _appIds.keys.toSet();

  @override
  Future<void> launchApp(AppShortcut app) async {
    final id = _appIds[app];
    if (id == null) return;

    // Primary: REST POST — the reliable method used by Home Assistant.
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://$host:8001/api/v2/applications/$id'),
      );
      final response = await request.close();
      await response.drain<void>();
      client.close();
      if (response.statusCode >= 200 && response.statusCode < 300) return;
    } catch (_) {
      // Fall through to the WebSocket method below.
    }

    // Fallback: WebSocket emit (older Tizen models).
    final socket = _socket;
    if (socket == null) return;
    socket.add(
      jsonEncode({
        'method': 'ms.channel.emit',
        'params': {
          'event': 'ed.apps.launch',
          'to': 'host',
          'data': {'appId': id, 'action_type': 'DEEP_LINK'},
        },
      }),
    );
  }

  @override
  Future<DeviceInfo?> info() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://$host:8001/api/v2/'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      final device =
          (jsonDecode(body) as Map<String, dynamic>)['device']
              as Map<String, dynamic>?;
      return (
        name: device?['name'] as String?,
        mac: device?['wifiMac'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static const Map<AppShortcut, String> _appIds = {
    AppShortcut.netflix: '11101200001',
    AppShortcut.youtube: '111299001912',
    AppShortcut.primeVideo: '3201910019365',
    AppShortcut.disneyPlus: '3201901017640',
    AppShortcut.spotify: '3201606009684',
  };

  // No 'replay' entry: Samsung has no instant-replay key, so that button
  // auto-disables on the remote screen (capabilities-driven UI).
  static const Map<RemoteKey, String> _keyMap = {
    RemoteKey.power: 'KEY_POWER',
    RemoteKey.home: 'KEY_HOME',
    RemoteKey.back: 'KEY_RETURN',
    RemoteKey.up: 'KEY_UP',
    RemoteKey.down: 'KEY_DOWN',
    RemoteKey.left: 'KEY_LEFT',
    RemoteKey.right: 'KEY_RIGHT',
    RemoteKey.ok: 'KEY_ENTER',
    RemoteKey.volumeUp: 'KEY_VOLUP',
    RemoteKey.volumeDown: 'KEY_VOLDOWN',
    RemoteKey.mute: 'KEY_MUTE',
    RemoteKey.playPause: 'KEY_PLAY',
    RemoteKey.rewind: 'KEY_REWIND',
    RemoteKey.fastForward: 'KEY_FF',
    RemoteKey.info: 'KEY_INFO',
    RemoteKey.stop: 'KEY_STOP',
    RemoteKey.channelUp: 'KEY_CHUP',
    RemoteKey.channelDown: 'KEY_CHDOWN',
    RemoteKey.menu: 'KEY_MENU',
    RemoteKey.guide: 'KEY_GUIDE',
    RemoteKey.input: 'KEY_SOURCE',
    RemoteKey.exit: 'KEY_EXIT',
    RemoteKey.digit0: 'KEY_0',
    RemoteKey.digit1: 'KEY_1',
    RemoteKey.digit2: 'KEY_2',
    RemoteKey.digit3: 'KEY_3',
    RemoteKey.digit4: 'KEY_4',
    RemoteKey.digit5: 'KEY_5',
    RemoteKey.digit6: 'KEY_6',
    RemoteKey.digit7: 'KEY_7',
    RemoteKey.digit8: 'KEY_8',
    RemoteKey.digit9: 'KEY_9',
  };
}
