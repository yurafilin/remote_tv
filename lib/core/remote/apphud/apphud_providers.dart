import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apphud_service.dart';

final apphudServiceProvider = Provider<ApphudService>((ref) {
  return ApphudService.instance;
});

/// Reactive premium flag. UI listens to this, never to the singleton directly.
final isPremiumProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(apphudServiceProvider);
  final controller = StreamController<bool>();
  controller.add(service.isPremium.value);
  void listener() => controller.add(service.isPremium.value);
  service.isPremium.addListener(listener);
  ref.onDispose(() {
    service.isPremium.removeListener(listener);
    controller.close();
  });
  return controller.stream;
});
