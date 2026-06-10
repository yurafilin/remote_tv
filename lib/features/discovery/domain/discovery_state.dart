import '../../../core/remote/discovered_device.dart';

class DiscoveryState {
  const DiscoveryState({this.devices = const [], this.scanning = false});

  final List<DiscoveredDevice> devices;
  final bool scanning;

  DiscoveryState copyWith({List<DiscoveredDevice>? devices, bool? scanning}) {
    return DiscoveryState(
      devices: devices ?? this.devices,
      scanning: scanning ?? this.scanning,
    );
  }
}
