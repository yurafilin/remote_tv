import 'dart:developer';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_attribution.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_session_failure.dart';
import 'package:adjust_sdk/adjust_session_success.dart';
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';

class AdjustService {
  static AdjustService? _instance;
  static AdjustService get instance {
    _instance ??= AdjustService._internal();
    return _instance!;
  }

  AdjustService._internal();

  static const _key = 'ywthxapxrnr4';

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      final config = AdjustConfig(_key, AdjustEnvironment.sandbox);
      config.logLevel = AdjustLogLevel.verbose;

      config.attributionCallback = _attributionCallback;
      config.sessionFailureCallback = _sessionFailureCallback;
      config.sessionSuccessCallback = _sessionSuccessCallback;

      Adjust.initSdk(config);
      _ready = true;
    } catch (_) {
      /* token / native setup missing — callbacks become no-ops */
    }
  }

  Future<void> _attributionCallback(AdjustAttribution adjustData) async {
    final apphudData = <String, dynamic>{};
    if (adjustData.trackerToken != null) {
      apphudData['trackerToken'] = adjustData.trackerToken!;
    }
    if (adjustData.campaign != null) {
      apphudData['campaign'] = adjustData.campaign!;
    }
    if (adjustData.trackerName != null) {
      apphudData['trackerName'] = adjustData.trackerName!;
    }
    if (adjustData.network != null) {
      apphudData['network'] = adjustData.network!;
    }
    if (adjustData.adgroup != null) {
      apphudData['adgroup'] = adjustData.adgroup!;
    }
    if (adjustData.creative != null) {
      apphudData['creative'] = adjustData.creative!;
    }
    if (adjustData.clickLabel != null) {
      apphudData['clickLabel'] = adjustData.clickLabel!;
    }
    if (adjustData.fbInstallReferrer != null) {
      apphudData['fbInstallReferrer'] = adjustData.fbInstallReferrer!;
    }
    if (adjustData.costAmount != null) {
      apphudData['costAmount'] = adjustData.costAmount!;
    }
    if (adjustData.costCurrency != null) {
      apphudData['costCurrency'] = adjustData.costCurrency!;
    }
    if (adjustData.costType != null) {
      apphudData['costType'] = adjustData.costType!;
    }
    if (adjustData.creative != null) {
      apphudData['creative'] = adjustData.creative!;
    }

    final adid = await Adjust.getAdid();
    if (adid != null) {
      apphudData['adid'] = adid;
    }

    log('Adjust Attribution: ${apphudData.toString()}');

    final isAttributionAdded = await _forwardToApphud(apphudData);
    log('$isAttributionAdded');
  }

  void _sessionFailureCallback(AdjustSessionFailure sessionFailureData) {
    if (sessionFailureData.adid != null) {
      _forwardToApphud({'adid': sessionFailureData.adid});
    }
    log(
      {
        '[Adjust]': 'Session tracking failure!',
        'Message': sessionFailureData.message,
        'Timestamp': sessionFailureData.timestamp,
        'Adid': sessionFailureData.adid,
        'Will retry': sessionFailureData.willRetry,
        'JSON response': sessionFailureData.jsonResponse,
      }.toString(),
    );
  }

  void _sessionSuccessCallback(AdjustSessionSuccess sessionSuccessData) {
    if (sessionSuccessData.adid != null) {
      _forwardToApphud({'adid': sessionSuccessData.adid});
    }
    log(
      {
        '[Adjust]': 'Session tracking success!',
        'Message': sessionSuccessData.message,
        'Timestamp': sessionSuccessData.timestamp,
        'Adid': sessionSuccessData.adid,
        'JSON response': sessionSuccessData.jsonResponse,
      }.toString(),
    );
  }

  Future<bool> _forwardToApphud(Map<String, dynamic> data) {
    return Apphud.setAttribution(
      provider: ApphudAttributionProvider.adjust,
      data: ApphudAttributionData(
        rawData: data,
        adNetwork: data['network'] as String?,
        channel: data['trackerName'] as String?,
        campaign: data['campaign'] as String?,
        adSet: data['adgroup'] as String?,
        creative: data['creative'] as String?,
      ),
    );
  }
}
