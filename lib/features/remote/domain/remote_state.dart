import '../../../core/remote/app_launcher.dart';
import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/keys.dart';

class RemoteState {
  const RemoteState({
    this.device,
    this.capabilities = const {},
    this.canType = false,
    this.apps = const {},
    this.lastKey,
  });

  final DiscoveredDevice? device;
  final Set<RemoteKey> capabilities;
  final bool canType;
  final Set<AppShortcut> apps;
  final RemoteKey? lastKey;

  bool get isConnected => device != null;

  RemoteState copyWith({
    DiscoveredDevice? device,
    Set<RemoteKey>? capabilities,
    bool? canType,
    Set<AppShortcut>? apps,
    RemoteKey? lastKey,
  }) {
    return RemoteState(
      device: device ?? this.device,
      capabilities: capabilities ?? this.capabilities,
      canType: canType ?? this.canType,
      apps: apps ?? this.apps,
      lastKey: lastKey ?? this.lastKey,
    );
  }
}
