import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/product_details/pricing_phase_wrapper.dart';
import 'package:apphud/models/product_details/product_details_wrapper.dart';
import 'package:apphud/models/product_details/subscription_offer_details.dart';
import 'package:apphud/models/sk_product/discount_payment_mode_wrapper.dart';
import 'package:apphud/models/sk_product/discount_wrapper.dart';
import 'package:apphud/models/sk_product/sk_product_wrapper.dart';
import 'package:apphud/models/sk_product/subscription_period_wrapper.dart';
import 'package:apphud/models/sk_product/subscription_period_time_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/features/paywall/domain/subscription_pricing.dart';

ApphudProduct _ios({
  required double price,
  required SKSubscriptionPeriodTime unit,
  int count = 1,
  String? name,
  SKProductDiscountWrapper? intro,
}) {
  return ApphudProduct(
    productId: 'p',
    store: 'app_store',
    name: name,
    skProduct: SKProductWrapper(
      productIdentifier: 'p',
      localizedTitle: 'Title',
      localizedDescription: 'Desc',
      price: price,
      priceLocale: SKPriceLocaleWrapper(currencySymbol: r'$', currencyCode: 'USD'),
      subscriptionPeriod: SKProductSubscriptionPeriodWrapper(
        numberOfUnits: count,
        unit: unit,
      ),
      introductoryPrice: intro,
    ),
  );
}

SKProductDiscountWrapper _trial(SKSubscriptionPeriodTime unit, int n) =>
    SKProductDiscountWrapper(
      price: 0,
      numberOfPeriods: 1,
      paymentMode: SKProductDiscountPaymentMode.freeTrail,
      priceLocale: SKPriceLocaleWrapper(currencySymbol: r'$', currencyCode: 'USD'),
      subscriptionPeriod:
          SKProductSubscriptionPeriodWrapper(numberOfUnits: n, unit: unit),
    );

ApphudProduct _android({
  required List<PricingPhaseWrapper> phases,
  String? name,
}) {
  return ApphudProduct(
    productId: 'm',
    store: 'play_store',
    name: name,
    productDetails: ProductDetailsWrapper(
      description: 'd',
      name: name ?? 'Monthly',
      productId: 'm',
      productType: 'subs',
      title: 't',
      subscriptionOfferDetails: [
        SubscriptionOfferDetailsWrapper(
          basePlanId: 'base',
          offerTags: const [],
          offerToken: 'tok',
          pricingPhases: phases,
        ),
      ],
    ),
  );
}

PricingPhaseWrapper _phase({
  required String period,
  required String formatted,
  required int micros,
  int cycles = 0,
}) =>
    PricingPhaseWrapper(
      billingCycleCount: cycles,
      billingPeriod: period,
      formattedPrice: formatted,
      priceAmountMicros: micros,
      priceCurrencyCode: 'USD',
      recurrenceMode: micros == 0 ? 2 : 1,
    );

void main() {
  test('iOS weekly with a 3-day trial', () {
    final p = SubscriptionPricing.from(
      _ios(
        price: 9.99,
        unit: SKSubscriptionPeriodTime.week,
        intro: _trial(SKSubscriptionPeriodTime.day, 3),
      ),
    )!;
    expect(p.hasTrial, true);
    expect(p.trialLabel, '3 days free trial');
    expect(p.priceText, r'$9.99');
    expect(p.periodLabel, 'week');
    expect(p.perMonthText, r'$43.44'); // 9.99 * 30.4375 / 7
    expect(p.amount, 9.99);
    expect(p.currency, 'USD');
  });

  test('iOS yearly without trial derives the monthly price', () {
    final p = SubscriptionPricing.from(
      _ios(price: 59.99, unit: SKSubscriptionPeriodTime.year),
    )!;
    expect(p.hasTrial, false);
    expect(p.priceText, r'$59.99');
    expect(p.periodLabel, 'year');
    expect(p.perMonthText, r'$5.00'); // 59.99 / 12
  });

  test('Android monthly with a 1-week trial via pricing phases', () {
    final p = SubscriptionPricing.from(
      _android(
        name: 'Monthly',
        phases: [
          _phase(period: 'P1W', formatted: 'Free', micros: 0, cycles: 1),
          _phase(period: 'P1M', formatted: r'$4.99', micros: 4990000),
        ],
      ),
    )!;
    expect(p.hasTrial, true);
    expect(p.trialLabel, '1 week free trial');
    expect(p.priceText, r'$4.99');
    expect(p.periodLabel, 'month');
    expect(p.perMonthText, r'$4.99');
    expect(p.amount, 4.99);
    expect(p.currency, 'USD');
  });

  test('Android weekly without trial keeps the formatted price', () {
    final p = SubscriptionPricing.from(
      _android(
        name: 'Weekly',
        phases: [_phase(period: 'P1W', formatted: r'$2.99', micros: 2990000)],
      ),
    )!;
    expect(p.hasTrial, false);
    expect(p.priceText, r'$2.99');
    expect(p.periodLabel, 'week');
    expect(p.perMonthText, r'$13.00'); // 2.99 * 30.4375 / 7
  });

  test('7-day period and trial normalise to a week', () {
    final p = SubscriptionPricing.from(
      _ios(
        price: 4.99,
        unit: SKSubscriptionPeriodTime.day,
        count: 7,
        intro: _trial(SKSubscriptionPeriodTime.day, 7),
      ),
    )!;
    expect(p.periodLabel, 'week');
    expect(p.trialLabel, '1 week free trial');
  });
}
