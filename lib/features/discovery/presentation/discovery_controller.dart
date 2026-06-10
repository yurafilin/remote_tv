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
  /// Pause between scan rounds.
  static const Duration _interval = Duration(seconds: 3);

  bool _active = false;

  @override
  DiscoveryState build() {
    _active = true;
    ref.onDispose(() => _active = false);
    Future.microtask(_loop);
    // Spinner stays on for the whole continuous-discovery loop.
    return const DiscoveryState(scanning: true);
  }

  /// Scan, wait [_interval], scan again — forever, until disposed.
  Future<void> _loop() async {
    while (_active) {
      await _scanOnce();
      if (!_active) break;
      await Future<void>.delayed(_interval);
    }
  }

  /// One pass over all transports. New devices stream in via [add]; devices
  /// that no longer respond drop out when the pass finishes.
  Future<void> _scanOnce() async {
    final found = <String, DiscoveredDevice>{};

    void add(DiscoveredDevice device) {
      if (!_active || found.containsKey(device.host)) return;
      found[device.host] = device;
      final merged = {for (final d in state.devices) d.host: d, ...found};
      state = state.copyWith(devices: merged.values.toList());
    }

    await Future.wait([
      RokuDiscovery()
          .discover(onDevice: add)
          .catchError((_) => <DiscoveredDevice>[]),
      SamsungDiscovery()
          .discover(onDevice: add)
          .catchError((_) => <DiscoveredDevice>[]),
      SamsungMdnsDiscovery()
          .discover(onDevice: add)
          .catchError((_) => <DiscoveredDevice>[]),
    ]);

    if (!_active) return;
    state = state.copyWith(devices: found.values.toList());
  }

  /// Manual re-scan trigger (the loop also runs continuously).
  Future<void> scan() => _scanOnce();
}
