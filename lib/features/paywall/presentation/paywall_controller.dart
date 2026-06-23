import 'dart:async';

import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/apphud/apphud_service.dart';
import '../../../core/remote/facebook/facebook_service.dart';
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
  /// Whether the Apphud `paywallShown` impression has been reported this run.
  bool _shown = false;

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
        // Report the impression to Apphud as soon as the paywall is available —
        // even while its products are still loading — and only once per run.
        if (paywall != null && !_shown) {
          _shown = true;
          unawaited(ApphudService.instance.paywallShown(paywall));
        }
        final products = paywall?.products ?? const <ApphudProduct>[];
        if (products.isNotEmpty) {
          _logProducts(products);
          final options = <SubscriptionOption>[
            for (final product in products)
              if (SubscriptionPricing.from(product) case final pricing?)
                SubscriptionOption(product: product, pricing: pricing),
          ];
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

  /// Debug-only: dumps each product's store offers and pricing phases so you
  /// can verify in logcat whether Google Play returns the free-trial offer
  /// (look for `offerId=3-days-free` with a `P3D=0` phase).
  void _logProducts(List<ApphudProduct> products) {
    if (!kDebugMode) return;
    for (final p in products) {
      final pd = p.productDetails;
      if (pd == null) {
        debugPrint('[paywall] ${p.productId}: iOS (skProduct)');
        continue;
      }
      final offers = pd.subscriptionOfferDetails ?? const [];
      debugPrint('[paywall] ${p.productId}: ${offers.length} offer(s)');
      for (final o in offers) {
        final phases = o.pricingPhases
            .map((ph) => '${ph.billingPeriod}=${ph.priceAmountMicros}')
            .join(', ');
        debugPrint('  offerId=${o.offerId} basePlan=${o.basePlanId} [$phases]');
      }
    }
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
    final option = options[state.selected];
    final ok = await ApphudService.instance.purchaseProduct(option.product);
    if (ok) _reportPurchase(option);
    state = state.copyWith(purchasing: false);
    return ok;
  }

  /// Forwards a successful purchase to Facebook: a custom
  /// `trial_or_subscription` event plus the standard Purchase and Subscribe
  /// events carrying the product's price and currency.
  void _reportPurchase(SubscriptionOption option) {
    final pricing = option.pricing;
    final fb = FacebookService.instance;
    unawaited(fb.logEvent(FacebookEvents.trialOrSubscription));
    unawaited(
      fb.logPurchase(amount: pricing.amount, currency: pricing.currency),
    );
    unawaited(
      fb.logSubscribe(
        price: pricing.amount,
        currency: pricing.currency,
        orderId: option.product.productId,
      ),
    );
  }

  Future<void> restore() => ApphudService.instance.restorePurchases();
}
