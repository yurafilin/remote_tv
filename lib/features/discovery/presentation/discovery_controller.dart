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
    // Android TV is omitted until its driver can actually connect (stage 1);
    // each scan is wrapped so one transport failing never aborts the rest.
    final results = await Future.wait([
      RokuDiscovery().discover().catchError((_) => <DiscoveredDevice>[]),
      SamsungDiscovery().discover().catchError((_) => <DiscoveredDevice>[]),
      SamsungMdnsDiscovery().discover().catchError((_) => <DiscoveredDevice>[]),
    ]);
    final byHost = <String, DiscoveredDevice>{};
    for (final device in results.expand((devices) => devices)) {
      byHost.putIfAbsent(device.host, () => device);
    }
    state = DiscoveryResults(byHost.values.toList());
  }
}
