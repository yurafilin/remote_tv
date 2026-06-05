import 'discovered_device.dart';
import 'keys.dart';

/// Contract every brand driver implements.
///
/// The remote UI is rendered from [capabilities], so one screen adapts to
/// whatever the connected TV actually supports (Roku has no colour buttons,
/// LG has a pointer, Apple TV has a touchpad, ...).
abstract interface class RemoteDriver {
  DevicePlatform get platform;

  /// Keys this device actually supports.
  Set<RemoteKey> get capabilities;

  /// Establish a session / pair if needed. No-op for connectionless protocols.
  Future<void> connect();

  /// Send a single key. Throws [UnsupportedKeyError] if not in [capabilities].
  Future<void> sendKey(RemoteKey key);

  /// Release any session resources.
  Future<void> disconnect();
}

class UnsupportedKeyError extends Error {
  UnsupportedKeyError(this.key, this.platform);

  final RemoteKey key;
  final DevicePlatform platform;

  @override
  String toString() => 'Key ${key.name} not supported by ${platform.name}';
}
