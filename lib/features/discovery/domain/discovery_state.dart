import '../../../core/remote/discovered_device.dart';

sealed class DiscoveryState {
  const DiscoveryState();
}

class DiscoveryIdle extends DiscoveryState {
  const DiscoveryIdle();
}

class DiscoveryScanning extends DiscoveryState {
  const DiscoveryScanning();
}

class DiscoveryResults extends DiscoveryState {
  const DiscoveryResults(this.devices);

  final List<DiscoveredDevice> devices;
}
