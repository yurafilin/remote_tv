import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv/core/remote/wake_on_lan.dart';

void main() {
  test('magic packet is 6x0xFF followed by the MAC repeated 16 times', () {
    final packet = WakeOnLan.magicPacket('AA:BB:CC:DD:EE:FF')!;
    expect(packet.length, 102);
    expect(packet.sublist(0, 6), List.filled(6, 0xFF));
    expect(packet.sublist(6, 12), [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
    expect(packet.sublist(96, 102), [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
  });

  test('rejects a malformed MAC', () {
    expect(WakeOnLan.magicPacket('not-a-mac'), isNull);
  });
}
