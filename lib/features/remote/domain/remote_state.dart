import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/keys.dart';

class RemoteState {
  const RemoteState({
    this.device,
    this.capabilities = const {},
    this.lastKey,
  });

  final DiscoveredDevice? device;
  final Set<RemoteKey> capabilities;
  final RemoteKey? lastKey;

  bool get isConnected => device != null;

  RemoteState copyWith({
    DiscoveredDevice? device,
    Set<RemoteKey>? capabilities,
    RemoteKey? lastKey,
  }) {
    return RemoteState(
      device: device ?? this.device,
      capabilities: capabilities ?? this.capabilities,
      lastKey: lastKey ?? this.lastKey,
    );
  }
}
