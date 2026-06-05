import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/drivers/roku/roku_driver.dart';
import 'package:remote_tv/core/remote/drivers/samsung/samsung_driver.dart';
import 'package:remote_tv/core/remote/keys.dart';

void main() {
  test('Roku exposes media keys including instant replay', () {
    final caps = RokuDriver('192.0.2.1').capabilities;
    expect(caps, containsAll([RemoteKey.power, RemoteKey.ok, RemoteKey.replay]));
  });

  test('Samsung exposes common keys but has no instant replay', () {
    final caps = SamsungDriver('192.0.2.1').capabilities;
    expect(caps, containsAll([RemoteKey.power, RemoteKey.ok, RemoteKey.mute]));
    expect(caps, isNot(contains(RemoteKey.replay)));
  });
}
