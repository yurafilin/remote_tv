// Runs on your laptop with the Dart VM — the SAME code the app will use:
//   dart run bin/roku_demo.dart discover
//   dart run bin/roku_demo.dart info <ip>
//   dart run bin/roku_demo.dart key  <ip> home
import 'dart:io';

import 'package:remote_tv/core/remote/drivers/roku/roku_discovery.dart';
import 'package:remote_tv/core/remote/drivers/roku/roku_driver.dart';
import 'package:remote_tv/core/remote/keys.dart';

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'discover' : args.first;

  switch (command) {
    case 'discover':
      final devices = await RokuDiscovery().discover();
      if (devices.isEmpty) {
        stdout.writeln('No Roku found on this network (or SSDP blocked).');
      }
      for (final device in devices) {
        stdout.writeln('${device.host}\t${device.location ?? ''}');
      }

    case 'info' when args.length >= 2:
      final driver = RokuDriver(args[1]);
      stdout.writeln(await driver.deviceInfo());
      await driver.disconnect();

    case 'key' when args.length >= 3:
      final driver = RokuDriver(args[1]);
      final key = RemoteKey.values.byName(args[2]);
      await driver.sendKey(key);
      await driver.disconnect();
      stdout.writeln('sent ${key.name} -> ${args[1]}');

    default:
      stdout.writeln('usage: discover | info <ip> | key <ip> <name>');
  }
}
