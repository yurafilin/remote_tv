import 'dart:io';

/// Wake-on-LAN: turn a fully-off TV back on with a magic packet to its MAC.
///
/// iOS blocks UDP broadcast without the multicast entitlement, so we send a
/// unicast packet to the last-known IP (works for a recently-off TV whose
/// ARP/switch entry persists) and attempt a broadcast best-effort (Android /
/// desktop).
class WakeOnLan {
  static const int _port = 9;

  static Future<void> send(String mac, {String? ip}) async {
    final bytes = magicPacket(mac);
    if (bytes == null) return;

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    try {
      if (ip != null) {
        socket.send(bytes, InternetAddress(ip), _port);
      }
      try {
        socket.send(bytes, InternetAddress('255.255.255.255'), _port);
      } on SocketException {
        // Broadcast is blocked on iOS without the multicast entitlement.
      }
    } finally {
      socket.close();
    }
  }

  /// 6×0xFF followed by the MAC repeated 16 times (102 bytes), or null when the
  /// MAC isn't 12 hex digits.
  static List<int>? magicPacket(String mac) {
    final clean = mac.replaceAll(RegExp('[^0-9a-fA-F]'), '');
    if (clean.length != 12) return null;
    final macBytes = [
      for (var i = 0; i < 12; i += 2)
        int.parse(clean.substring(i, i + 2), radix: 16),
    ];
    return [
      ...List<int>.filled(6, 0xFF),
      for (var i = 0; i < 16; i++) ...macBytes,
    ];
  }
}
