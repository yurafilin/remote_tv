import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../app_launcher.dart';
import '../../discovered_device.dart';
import '../../driver.dart';
import '../../keys.dart';
import '../../text_input.dart';

/// LG webOS (SSAP) driver.
///
/// Two channels over WebSocket: the main SSAP socket (:3001, self-signed) for
/// registration + volume/power/media `ssap://` requests, and a secondary
/// "pointer input" socket for D-pad/navigation buttons. First connect shows an
/// accept prompt on the TV and returns a [clientKey] to skip it next time.
///
/// Protocol ported from public SSAP implementations; the pointer-socket path
/// is not yet verified against real hardware.
class LgWebosDriver implements RemoteDriver, TextInput, AppLauncher {
  LgWebosDriver(this.host, {this.clientKey});

  static const int wssPort = 3001;

  final String host;
  String? clientKey;

  WebSocket? _ssap;
  WebSocket? _pointer;
  int _id = 0;
  bool _muted = false;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

  @override
  DevicePlatform get platform => DevicePlatform.lg;

  @override
  Set<RemoteKey> get capabilities =>
      _pointerButtons.keys.toSet().union(_ssapUris.keys.toSet());

  @override
  Future<void> connect() async {
    if (_ssap != null) return;

    final client = HttpClient()..badCertificateCallback = (_, _, _) => true;
    final socket = await WebSocket.connect('wss://$host:$wssPort', customClient: client);
    _ssap = socket;

    final registered = Completer<void>();
    socket.listen(
      (dynamic raw) {
        if (raw is! String) return;
        final Map<String, dynamic> msg;
        try {
          msg = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          return;
        }
        final id = msg['id'];
        if (msg['type'] == 'registered') {
          final key = (msg['payload'] as Map<String, dynamic>?)?['client-key'];
          if (key != null) clientKey = key.toString();
          if (!registered.isCompleted) registered.complete();
        } else if (id is String && _pending.containsKey(id)) {
          _pending.remove(id)!.complete(msg);
        }
      },
      onError: (Object e) {
        if (!registered.isCompleted) registered.completeError(e);
      },
      onDone: () {
        _ssap = null;
        if (!registered.isCompleted) {
          registered.completeError(StateError('LG TV closed the connection'));
        }
      },
    );

    socket.add(
      jsonEncode({
        'type': 'register',
        'id': 'register_0',
        'payload': {
          'forcePairing': false,
          'pairingType': 'PROMPT',
          if (clientKey != null) 'client-key': clientKey,
          'manifest': _manifest,
        },
      }),
    );

    final timer = Timer(const Duration(seconds: 30), () {
      if (!registered.isCompleted) {
        registered.completeError(TimeoutException('LG pairing timed out'));
      }
    });
    try {
      await registered.future;
    } catch (_) {
      await socket.close();
      _ssap = null;
      rethrow;
    } finally {
      timer.cancel();
    }
  }

  @override
  Future<void> sendKey(RemoteKey key) async {
    final button = _pointerButtons[key];
    if (button != null) {
      await _sendButton(button);
      return;
    }
    final uri = _ssapUris[key];
    if (uri == null) throw UnsupportedKeyError(key, platform);
    if (key == RemoteKey.mute) {
      _muted = !_muted;
      _request(uri, {'mute': _muted});
    } else {
      _request(uri, const {});
    }
  }

  @override
  Future<void> disconnect() async {
    await _pointer?.close();
    _pointer = null;
    await _ssap?.close();
    _ssap = null;
  }

  @override
  Future<void> sendText(String text) async {
    _request('ssap://com.webos.service.ime/insertText', {
      'text': text,
      'replace': false,
    });
  }

  @override
  Future<void> submit() async {
    _request('ssap://com.webos.service.ime/sendEnterKey', const {});
  }

  @override
  Set<AppShortcut> get apps => _appIds.keys.toSet();

  @override
  Future<void> launchApp(AppShortcut app) async {
    final id = _appIds[app];
    if (id == null) return;
    _request('ssap://system.launcher/launch', {'id': id});
  }

  static const Map<AppShortcut, String> _appIds = {
    AppShortcut.netflix: 'netflix',
    AppShortcut.youtube: 'youtube.leanback.v4',
    AppShortcut.primeVideo: 'amazon',
    AppShortcut.disneyPlus: 'com.disney.disneyplus-prod',
    AppShortcut.spotify: 'spotify-beehive',
  };

  void _request(String uri, Map<String, dynamic> payload) {
    final socket = _ssap;
    if (socket == null) throw StateError('LG TV is not connected');
    _id += 1;
    socket.add(
      jsonEncode({'type': 'request', 'id': 'req_$_id', 'uri': uri, 'payload': payload}),
    );
  }

  Future<void> _sendButton(String name) async {
    final pointer = _pointer ??= await _openPointerSocket();
    pointer.add('type:button\nname:$name\n\n');
  }

  Future<WebSocket> _openPointerSocket() async {
    final socket = _ssap;
    if (socket == null) throw StateError('LG TV is not connected');
    _id += 1;
    final id = 'ptr_$_id';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    socket.add(
      jsonEncode({
        'type': 'request',
        'id': id,
        'uri': 'ssap://com.webos.service.networkinput/getPointerInputSocket',
        'payload': const <String, dynamic>{},
      }),
    );
    final response = await completer.future.timeout(const Duration(seconds: 5));
    final path = (response['payload'] as Map<String, dynamic>?)?['socketPath'];
    if (path is! String) {
      throw StateError('LG TV did not return a pointer socket');
    }
    final client = HttpClient()..badCertificateCallback = (_, _, _) => true;
    return WebSocket.connect(path, customClient: client);
  }

  static const Map<RemoteKey, String> _pointerButtons = {
    RemoteKey.up: 'UP',
    RemoteKey.down: 'DOWN',
    RemoteKey.left: 'LEFT',
    RemoteKey.right: 'RIGHT',
    RemoteKey.ok: 'ENTER',
    RemoteKey.back: 'BACK',
    RemoteKey.home: 'HOME',
    RemoteKey.info: 'INFO',
    RemoteKey.exit: 'EXIT',
  };

  static const Map<RemoteKey, String> _ssapUris = {
    RemoteKey.power: 'ssap://system/turnOff',
    RemoteKey.volumeUp: 'ssap://audio/volumeUp',
    RemoteKey.volumeDown: 'ssap://audio/volumeDown',
    RemoteKey.mute: 'ssap://audio/setMute',
    RemoteKey.playPause: 'ssap://media.controls/play',
    RemoteKey.rewind: 'ssap://media.controls/rewind',
    RemoteKey.fastForward: 'ssap://media.controls/fastForward',
    RemoteKey.stop: 'ssap://media.controls/stop',
    RemoteKey.channelUp: 'ssap://tv/channelUp',
    RemoteKey.channelDown: 'ssap://tv/channelDown',
  };

  static const Map<String, dynamic> _manifest = {
    'manifestVersion': 1,
    'permissions': [
      'CONTROL_POWER',
      'CONTROL_AUDIO',
      'CONTROL_INPUT_MEDIA_PLAYBACK',
      'CONTROL_INPUT_TV',
      'CONTROL_DISPLAY',
      'CONTROL_INPUT_JOYSTICK',
      'CONTROL_INPUT_TEXT',
      'READ_INPUT_DEVICE_LIST',
      'READ_TV_CURRENT_CHANNEL',
    ],
  };
}
