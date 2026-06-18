import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/product_details/pricing_phase_wrapper.dart';
import 'package:apphud/models/product_details/product_details_wrapper.dart';
import 'package:apphud/models/sk_product/discount_payment_mode_wrapper.dart';
import 'package:apphud/models/sk_product/sk_product_wrapper.dart';
import 'package:apphud/models/sk_product/subscription_period_time_wrapper.dart';

/// Average calendar lengths, used to normalise any billing period to a monthly
/// price for the "only … per month" line.
const double _daysInMonth = 30.4375;
const double _daysInYear = 365.25;

/// A billing-period unit, unified across StoreKit and Play Billing.
enum _Unit {
  day(1, 'day'),
  week(7, 'week'),
  month(_daysInMonth, 'month'),
  year(_daysInYear, 'year');

  const _Unit(this.days, this.word);

  /// Length of one unit in days.
  final double days;

  /// Singular lower-case word ("day", "week", "month", "year").
  final String word;
}

/// Display-ready pricing for one subscription option, derived from an
/// [ApphudProduct] across StoreKit (iOS) and Play Billing (Android).
class SubscriptionPricing {
  const SubscriptionPricing({
    required this.priceText,
    required this.periodLabel,
    required this.perMonthText,
    this.trialLabel,
  });

  /// Localised price for one billing period (e.g. "$9.99").
  final String priceText;

  /// Singular period for the "price / period" line (e.g. "week").
  final String periodLabel;

  /// Localised price normalised to one month (e.g. "$3.33").
  final String perMonthText;

  /// Trial headline (e.g. "3 days free trial"), or null when there's no trial.
  final String? trialLabel;

  bool get hasTrial => trialLabel != null;

  /// Builds pricing from a product, or null if it carries no store metadata.
  static SubscriptionPricing? from(ApphudProduct product) {
    final sk = product.skProduct;
    if (sk != null) return _fromStoreKit(sk);
    final pd = product.productDetails;
    if (pd != null) return _fromPlayBilling(pd);
    return null;
  }

  // ---------------------------------------------------------------- iOS ----

  static SubscriptionPricing _fromStoreKit(SKProductWrapper sk) {
    final symbol =
        sk.priceLocale.currencySymbol ?? sk.priceLocale.currencyCode ?? '';
    final period = sk.subscriptionPeriod;
    final unit = _fromSk(period?.unit ?? SKSubscriptionPeriodTime.week);
    final count = period?.numberOfUnits ?? 1;

    final intro = sk.introductoryPrice;
    final hasTrial = intro != null &&
        intro.paymentMode == SKProductDiscountPaymentMode.freeTrail;

    return SubscriptionPricing(
      priceText: _money(symbol, sk.price),
      periodLabel: _periodLabel(unit, count),
      perMonthText:
          _money(symbol, sk.price * _daysInMonth / (unit.days * count)),
      trialLabel: hasTrial
          ? _trialLabel(
              _fromSk(intro.subscriptionPeriod.unit),
              intro.subscriptionPeriod.numberOfUnits * intro.numberOfPeriods,
            )
          : null,
    );
  }

  static _Unit _fromSk(SKSubscriptionPeriodTime t) => switch (t) {
        SKSubscriptionPeriodTime.day => _Unit.day,
        SKSubscriptionPeriodTime.week => _Unit.week,
        SKSubscriptionPeriodTime.month => _Unit.month,
        SKSubscriptionPeriodTime.year => _Unit.year,
      };

  // ------------------------------------------------------------ Android ----

  static SubscriptionPricing? _fromPlayBilling(ProductDetailsWrapper pd) {
    final offers = pd.subscriptionOfferDetails;
    if (offers == null || offers.isEmpty) return null;

    // Prefer an offer that includes a free-trial (zero-price) phase.
    final offer = offers.firstWhere(
      (o) => o.pricingPhases.any((p) => p.priceAmountMicros == 0),
      orElse: () => offers.first,
    );
    final phases = offer.pricingPhases;
    if (phases.isEmpty) return null;

    // The recurring price is the last non-free phase.
    final paid = phases.lastWhere(
      (p) => p.priceAmountMicros > 0,
      orElse: () => phases.last,
    );
    PricingPhaseWrapper? trial;
    for (final p in phases) {
      if (p.priceAmountMicros == 0) {
        trial = p;
        break;
      }
    }

    final (unit, count) = _parseIso(paid.billingPeriod);
    final price = paid.priceAmountMicros / 1e6;

    return SubscriptionPricing(
      priceText: paid.formattedPrice,
      periodLabel: _periodLabel(unit, count),
      perMonthText: _formatLike(
        paid.formattedPrice,
        price * _daysInMonth / (unit.days * count),
      ),
      trialLabel: trial == null ? null : _trialLabelIso(trial),
    );
  }

  /// Parses an ISO-8601 billing period like "P1W", "P3D", "P1M", "P1Y".
  static (_Unit, int) _parseIso(String period) {
    final m = RegExp(r'P(\d+)([DWMY])').firstMatch(period);
    if (m == null) return (_Unit.week, 1);
    final count = int.tryParse(m.group(1)!) ?? 1;
    final unit = switch (m.group(2)) {
      'D' => _Unit.day,
      'W' => _Unit.week,
      'M' => _Unit.month,
      'Y' => _Unit.year,
      _ => _Unit.week,
    };
    return (unit, count);
  }

  static String _trialLabelIso(PricingPhaseWrapper phase) {
    final (unit, count) = _parseIso(phase.billingPeriod);
    final cycles = phase.billingCycleCount <= 0 ? 1 : phase.billingCycleCount;
    return _trialLabel(unit, count * cycles);
  }

  // -------------------------------------------------------------- shared ----

  /// A 7-day period reads better as a week ("week", not "7 days").
  static (_Unit, int) _norm(_Unit unit, int count) =>
      (unit == _Unit.day && count % 7 == 0)
          ? (_Unit.week, count ~/ 7)
          : (unit, count);

  static String _periodLabel(_Unit unit, int count) {
    final (u, c) = _norm(unit, count);
    return c == 1 ? u.word : '$c ${u.word}s';
  }

  static String _trialLabel(_Unit unit, int count) {
    final (u, c) = _norm(unit, count);
    final word = c == 1 ? u.word : '${u.word}s';
    return '$c $word free trial';
  }

  /// Formats an amount with the currency [symbol] prefixed (iOS).
  static String _money(String symbol, double amount) =>
      '$symbol${amount.toStringAsFixed(2)}';

  /// Reformats [amount] using the symbol and position of a reference localised
  /// price (Android): "$9.99" → "$3.33", "9,99 €" → "3.33 €".
  static String _formatLike(String formatted, double amount) {
    final m = RegExp(r'[0-9][0-9.,]*').firstMatch(formatted);
    final value = amount.toStringAsFixed(2);
    if (m == null) return value;
    final prefix = formatted.substring(0, m.start).trim();
    final suffix = formatted.substring(m.end).trim();
    if (prefix.isNotEmpty) return '$prefix$value';
    if (suffix.isNotEmpty) return '$value $suffix';
    return value;
  }
}
