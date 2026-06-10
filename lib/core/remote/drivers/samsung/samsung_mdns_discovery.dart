import 'package:bonsoir/bonsoir.dart';

import '../../discovered_device.dart';

/// mDNS / Bonjour discovery for Samsung TVs (`_samsungmsf._tcp`).
///
/// Uses the system Bonjour stack (NWBrowser on iOS, NsdManager on Android), so
/// it works without the multicast entitlement that raw SSDP needs on iOS.
class SamsungMdnsDiscovery {
  static const String _serviceType = '_samsungmsf._tcp';

  Future<List<DiscoveredDevice>> discover({
    Duration timeout = const Duration(seconds: 4),
    void Function(DiscoveredDevice)? onDevice,
  }) async {
    final found = <String, DiscoveredDevice>{};
    final discovery = BonsoirDiscovery(type: _serviceType);

    try {
      await discovery.initialize();
      final subscription = discovery.eventStream!.listen((event) {
        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent(:final service):
            discovery.serviceResolver.resolveService(service);
          case BonsoirDiscoveryServiceResolvedEvent(:final service):
            final host = service.hostAddress ?? service.hostname;
            if (host != null) {
              found.putIfAbsent(host, () {
                final device = DiscoveredDevice(
                  host: host,
                  platform: DevicePlatform.samsung,
                  name: 'Samsung TV',
                );
                onDevice?.call(device);
                return device;
              });
            }
          default:
            break;
        }
      });

      await discovery.start();
      await Future<void>.delayed(timeout);
      await subscription.cancel();
    } catch (_) {
      // mDNS unavailable or Local Network denied — return whatever resolved.
    } finally {
      try {
        await discovery.stop();
      } catch (_) {
        // Discovery may never have started.
      }
    }

    return found.values.toList();
  }
}
