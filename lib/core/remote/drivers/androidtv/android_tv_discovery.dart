import 'package:bonsoir/bonsoir.dart';

import '../../discovered_device.dart';

/// mDNS / Bonjour discovery for Android TV / Google TV devices
/// (`_androidtvremote2._tcp`) — Sony, Philips, TCL, Hisense, Nvidia Shield,
/// Chromecast with Google TV. Entitlement-free via the system Bonjour stack.
class AndroidTvDiscovery {
  static const String _serviceType = '_androidtvremote2._tcp';

  Future<List<DiscoveredDevice>> discover({
    Duration timeout = const Duration(seconds: 4),
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
              found.putIfAbsent(
                host,
                () => DiscoveredDevice(
                  host: host,
                  platform: DevicePlatform.androidTv,
                  name: service.name,
                ),
              );
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
