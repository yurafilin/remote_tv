import 'dart:async';

import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/apphud/apphud_service.dart';
import '../domain/subscription_pricing.dart';

/// One purchasable option: the raw Apphud product plus its display pricing.
class SubscriptionOption {
  const SubscriptionOption({required this.product, required this.pricing});

  final ApphudProduct product;
  final SubscriptionPricing pricing;
}

class PaywallState {
  const PaywallState({
    this.loading = true,
    this.failed = false,
    this.options = const [],
    this.selected = 0,
    this.purchasing = false,
  });

  final bool loading;
  final bool failed;
  final List<SubscriptionOption> options;
  final int selected;
  final bool purchasing;

  PaywallState copyWith({
    bool? loading,
    bool? failed,
    List<SubscriptionOption>? options,
    int? selected,
    bool? purchasing,
  }) {
    return PaywallState(
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      options: options ?? this.options,
      selected: selected ?? this.selected,
      purchasing: purchasing ?? this.purchasing,
    );
  }
}

final paywallControllerProvider =
    NotifierProvider<PaywallController, PaywallState>(PaywallController.new);

class PaywallController extends Notifier<PaywallState> {
  @override
  PaywallState build() {
    unawaited(_load());
    return const PaywallState();
  }

  Future<void> _load() async {
    // The paywall's products can come back empty on the first call, before
    // StoreKit / Play Billing return metadata — retry a few times before
    // showing the error state.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final paywall = await ApphudService.instance
            .fetchPaywall(AppHudPlacementID.onboarding);
        final products = paywall?.products ?? const <ApphudProduct>[];
        if (products.isNotEmpty) {
          final options = <SubscriptionOption>[
            for (final product in products)
              if (SubscriptionPricing.from(product) case final pricing?)
                SubscriptionOption(product: product, pricing: pricing),
          ];
          if (paywall != null) {
            unawaited(ApphudService.instance.paywallShown(paywall));
          }
          state = state.copyWith(
            loading: false,
            failed: options.isEmpty,
            options: options,
            selected: 0,
          );
          return;
        }
      } catch (_) {
        // fall through to retry
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    state = state.copyWith(loading: false, failed: true);
  }

  void select(int index) {
    if (index >= 0 && index < state.options.length) {
      state = state.copyWith(selected: index);
    }
  }

  Future<void> reload() async {
    state = const PaywallState();
    await _load();
  }

  /// Purchases the selected option; returns true when premium becomes active.
  Future<bool> purchaseSelected() async {
    final options = state.options;
    if (options.isEmpty || state.purchasing) return false;
    state = state.copyWith(purchasing: true);
    final ok = await ApphudService.instance
        .purchaseProduct(options[state.selected].product);
    state = state.copyWith(purchasing: false);
    return ok;
  }

  Future<void> restore() => ApphudService.instance.restorePurchases();
}
