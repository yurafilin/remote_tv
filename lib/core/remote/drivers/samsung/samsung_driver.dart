import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../discovered_device.dart';
import '../../driver.dart';
import '../../keys.dart';

/// Samsung Tizen (2016+) WebSocket remote control.
///
/// Unlike Roku this is connection-oriented: [connect] opens a wss socket
/// (self-signed cert on :8002) and, on first use, the TV shows an Allow/Deny
/// popup and hands back a [token] to skip the popup next time.
class SamsungDriver implements RemoteDriver {
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
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

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
  };
}
