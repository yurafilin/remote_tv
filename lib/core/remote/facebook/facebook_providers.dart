import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'facebook_service.dart';

final facebookServiceProvider = Provider<FacebookService>((ref) {
  return FacebookService.instance;
});
