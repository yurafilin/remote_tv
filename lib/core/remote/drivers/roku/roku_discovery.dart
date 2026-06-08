import 'dart:convert';
import 'dart:io';

import '../../discovered_device.dart';

/// SSDP discovery for Roku devices.
///
/// Sends an M-SEARCH for `roku:ecp` and collects responses for [timeout].
/// Direct port of `discover()` in `tools/roku_proof.py`.
class RokuDiscovery {
  static const String _ssdpAddr = '239.255.255.250';
  static const int _ssdpPort = 1900;

  Future<List<DiscoveredDevice>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final message = utf8.encode(
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: $_ssdpAddr:$_ssdpPort\r\n'
      'MAN: "ssdp:discover"\r\n'
      'ST: roku:ecp\r\n'
      'MX: 2\r\n\r\n',
    );

    final found = <String, DiscoveredDevice>{};
    final RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } on SocketException {
      return const [];
    }

    try {
      socket.multicastHops = 2;
      socket.listen(
        (event) {
          if (event != RawSocketEvent.read) return;
          final datagram = socket.receive();
          if (datagram == null) return;
          final text = utf8.decode(datagram.data, allowMalformed: true);
          if (!text.toLowerCase().contains('roku')) return;
          final host = datagram.address.address;
          found.putIfAbsent(
            host,
            () => DiscoveredDevice(
              host: host,
              platform: DevicePlatform.roku,
              location: _header(text, 'LOCATION'),
            ),
          );
        },
        // iOS delivers the blocked-multicast error through the socket stream;
        // swallow it so the scan doesn't crash.
        onError: (Object _) {},
        cancelOnError: false,
      );

      try {
        socket.send(message, InternetAddress(_ssdpAddr), _ssdpPort);
      } catch (_) {
        // iOS blocks LAN multicast without the multicast entitlement.
      }
      await Future<void>.delayed(timeout);
    } catch (_) {
      // Any other discovery failure — return what was collected.
    } finally {
      socket.close();
    }

    return found.values.toList();
  }

  static String? _header(String text, String name) {
    final lower = name.toLowerCase();
    for (final line in text.split('\r\n')) {
      if (line.toLowerCase().startsWith('$lower:')) {
        return line.substring(line.indexOf(':') + 1).trim();
      }
    }
    return null;
  }
}
