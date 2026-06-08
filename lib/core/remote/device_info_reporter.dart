/// Device metadata a driver can fetch on connect: the user-set friendly name
/// and the MAC address (for Wake-on-LAN).
typedef DeviceInfo = ({String? name, String? mac});

/// Capability interface for drivers that can report device metadata.
abstract interface class DeviceInfoReporter {
  /// Best-effort name + MAC of the TV, or null if unavailable.
  Future<DeviceInfo?> info();
}
