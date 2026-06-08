import '../../discovered_device.dart';
import '../../driver.dart';
import '../../keys.dart';

/// Android TV Remote protocol v2 (Sony, Philips, TCL, Hisense, Nvidia Shield,
/// Chromecast with Google TV).
///
/// Two TLS sockets: pairing on [pairingPort] (the TV shows a PIN code) and
/// control on [controlPort] (protobuf key injection), both authenticated with
/// a persisted self-signed client certificate.
///
/// Stage 1: key map + capabilities. Pairing and control (protobuf) land next.
class AndroidTvDriver implements RemoteDriver {
  AndroidTvDriver(this.host);

  static const int pairingPort = 6467;
  static const int controlPort = 6466;

  final String host;

  @override
  DevicePlatform get platform => DevicePlatform.androidTv;

  @override
  Set<RemoteKey> get capabilities => keyCodes.keys.toSet();

  @override
  Future<void> connect() async {
    throw UnimplementedError(
      'Android TV pairing is not implemented yet (next step).',
    );
  }

  @override
  Future<void> sendKey(RemoteKey key) async {
    throw UnimplementedError('Android TV control is not implemented yet.');
  }

  @override
  Future<void> disconnect() async {}

  /// Brand-independent key → Android `KEYCODE_*` value injected over the
  /// remote channel. No `replay`: Android TV has no instant-replay key.
  static const Map<RemoteKey, int> keyCodes = {
    RemoteKey.power: 26, // KEYCODE_POWER
    RemoteKey.home: 3, // KEYCODE_HOME
    RemoteKey.back: 4, // KEYCODE_BACK
    RemoteKey.up: 19, // KEYCODE_DPAD_UP
    RemoteKey.down: 20, // KEYCODE_DPAD_DOWN
    RemoteKey.left: 21, // KEYCODE_DPAD_LEFT
    RemoteKey.right: 22, // KEYCODE_DPAD_RIGHT
    RemoteKey.ok: 23, // KEYCODE_DPAD_CENTER
    RemoteKey.volumeUp: 24, // KEYCODE_VOLUME_UP
    RemoteKey.volumeDown: 25, // KEYCODE_VOLUME_DOWN
    RemoteKey.mute: 164, // KEYCODE_VOLUME_MUTE
    RemoteKey.playPause: 85, // KEYCODE_MEDIA_PLAY_PAUSE
    RemoteKey.rewind: 89, // KEYCODE_MEDIA_REWIND
    RemoteKey.fastForward: 90, // KEYCODE_MEDIA_FAST_FORWARD
    RemoteKey.info: 165, // KEYCODE_INFO
    RemoteKey.stop: 86, // KEYCODE_MEDIA_STOP
    RemoteKey.channelUp: 166, // KEYCODE_CHANNEL_UP
    RemoteKey.channelDown: 167, // KEYCODE_CHANNEL_DOWN
    RemoteKey.menu: 82, // KEYCODE_MENU
    RemoteKey.guide: 172, // KEYCODE_GUIDE
    RemoteKey.input: 178, // KEYCODE_TV_INPUT
    RemoteKey.digit0: 7, // KEYCODE_0
    RemoteKey.digit1: 8,
    RemoteKey.digit2: 9,
    RemoteKey.digit3: 10,
    RemoteKey.digit4: 11,
    RemoteKey.digit5: 12,
    RemoteKey.digit6: 13,
    RemoteKey.digit7: 14,
    RemoteKey.digit8: 15,
    RemoteKey.digit9: 16,
  };
}
