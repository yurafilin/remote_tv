import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/drivers/androidtv/android_tv_driver.dart';
import 'package:remote_tv/core/remote/drivers/lg/lg_webos_driver.dart';
import 'package:remote_tv/core/remote/drivers/roku/roku_driver.dart';
import 'package:remote_tv/core/remote/drivers/samsung/samsung_driver.dart';
import 'package:remote_tv/core/remote/app_launcher.dart';
import 'package:remote_tv/core/remote/device_info_reporter.dart';
import 'package:remote_tv/core/remote/keys.dart';
import 'package:remote_tv/core/remote/text_input.dart';

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

  test('Android TV exposes D-pad and media keys but no instant replay', () {
    final caps = AndroidTvDriver('192.0.2.1').capabilities;
    expect(
      caps,
      containsAll([RemoteKey.power, RemoteKey.ok, RemoteKey.playPause]),
    );
    expect(caps, isNot(contains(RemoteKey.replay)));
  });

  test('LG webOS exposes pointer + SSAP keys but no instant replay', () {
    final caps = LgWebosDriver('192.0.2.1').capabilities;
    expect(
      caps,
      containsAll([RemoteKey.power, RemoteKey.ok, RemoteKey.volumeUp]),
    );
    expect(caps, isNot(contains(RemoteKey.replay)));
  });

  test('expanded keys: channels + number pad map per platform', () {
    final samsung = SamsungDriver('192.0.2.1').capabilities;
    expect(
      samsung,
      containsAll([
        RemoteKey.channelUp,
        RemoteKey.digit5,
        RemoteKey.menu,
        RemoteKey.guide,
        RemoteKey.input,
      ]),
    );

    final roku = RokuDriver('192.0.2.1').capabilities;
    expect(roku, containsAll([RemoteKey.channelUp, RemoteKey.digit0]));
    // Roku ECP has no menu/guide — stays absent so the UI greys it out.
    expect(roku, isNot(contains(RemoteKey.menu)));
  });

  test('text input: Roku/Samsung/LG can type, Android TV cannot', () {
    expect(RokuDriver('192.0.2.1'), isA<TextInput>());
    expect(SamsungDriver('192.0.2.1'), isA<TextInput>());
    expect(LgWebosDriver('192.0.2.1'), isA<TextInput>());
    expect(AndroidTvDriver('192.0.2.1'), isNot(isA<TextInput>()));
  });

  test('app launching: Roku/Samsung/LG can launch apps, Android TV cannot', () {
    expect(RokuDriver('192.0.2.1'), isA<AppLauncher>());
    expect(
      (RokuDriver('192.0.2.1') as AppLauncher).apps,
      contains(AppShortcut.netflix),
    );
    expect(SamsungDriver('192.0.2.1'), isA<AppLauncher>());
    expect(LgWebosDriver('192.0.2.1'), isA<AppLauncher>());
    expect(AndroidTvDriver('192.0.2.1'), isNot(isA<AppLauncher>()));
  });

  test('device info: Samsung and Roku report name+MAC, LG does not', () {
    expect(SamsungDriver('192.0.2.1'), isA<DeviceInfoReporter>());
    expect(RokuDriver('192.0.2.1'), isA<DeviceInfoReporter>());
    expect(LgWebosDriver('192.0.2.1'), isNot(isA<DeviceInfoReporter>()));
  });
}
