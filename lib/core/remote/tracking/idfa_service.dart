import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import '../apphud/apphud_service.dart';

/// Requests App Tracking Transparency and, once authorized, forwards the IDFA
/// to Apphud. iOS-only in effect.
class IDFAService {
  static final IDFAService _instance = IDFAService._internal();

  factory IDFAService() => _instance;

  IDFAService._internal();

  Future<void> getIdfa() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;

    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    if (status == TrackingStatus.authorized) {
      final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      await ApphudService.instance.setIDFA(idfa);
    }
  }
}
