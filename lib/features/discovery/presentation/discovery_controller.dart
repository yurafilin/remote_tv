import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/drivers/roku/roku_discovery.dart';
import '../../../core/remote/drivers/samsung/samsung_discovery.dart';
import '../../../core/remote/drivers/samsung/samsung_mdns_discovery.dart';
import '../domain/discovery_state.dart';

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
  DiscoveryController.new,
);

class DiscoveryController extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() => const DiscoveryIdle();

  Future<void> scan() async {
    state = const DiscoveryScanning();
    final results = await Future.wait([
      RokuDiscovery().discover(),
      SamsungDiscovery().discover(),
      SamsungMdnsDiscovery().discover(),
    ]);
    final byHost = <String, DiscoveredDevice>{};
    for (final device in results.expand((devices) => devices)) {
      byHost.putIfAbsent(device.host, () => device);
    }
    state = DiscoveryResults(byHost.values.toList());
  }
}
