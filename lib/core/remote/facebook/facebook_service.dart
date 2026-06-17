import 'package:facebook_app_events/facebook_app_events.dart';

class FacebookService {
  static FacebookService? _instance;
  static FacebookService get instance {
    _instance ??= FacebookService._internal();
    return _instance!;
  }

  FacebookService._internal();

  late final FacebookAppEvents _facebookAppEvents;
  bool _ready = false;

  Future<void> init() async {
    try {
      _facebookAppEvents = FacebookAppEvents();
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      // Seed advertiser-ID collection ON. On Android this is the final value;
      // on iOS the SDK derives consent from App Tracking Transparency itself.
      await _facebookAppEvents.setAdvertiserIdCollectionEnabled(true);
      _ready = true;
    } catch (_) {/* App ID likely not set yet — log calls become no-ops */}
  }

  /// Toggles advertiser-ID collection to mirror an ATT decision. Optional on
  /// iOS (the SDK already derives consent from ATT); kept for callers that want
  /// to set it explicitly. No-op until the SDK is ready.
  Future<void> setAdvertiserTracking(bool enabled) async {
    if (!_ready) return;
    try {
      await _facebookAppEvents.setAdvertiserIdCollectionEnabled(enabled);
    } catch (_) {}
  }

  Future<void> logEvent(String eventName) async {
    if (!_ready) return;
    try {
      await _facebookAppEvents.logEvent(name: eventName);
    } catch (_) {}
  }

  Future<void> logPurchase({required double amount, required String currency}) async {
    if (!_ready) return;
    try {
      await _facebookAppEvents.logPurchase(amount: amount, currency: currency);
    } catch (_) {}
  }

  Future<void> logSubscribe({
    double? price,
    String? currency,
    required String orderId,
  }) async {
    if (!_ready) return;
    try {
      await _facebookAppEvents.logSubscribe(
        orderId: orderId,
        currency: currency,
        price: price,
      );
    } catch (_) {}
  }
}

abstract final class FacebookEvents {
  static const trialOrSubscription = 'trial_or_subscription';
}
