/// The platforms we can detect and drive over the local network.
enum DevicePlatform { roku, samsung, lg, androidTv, vizio, dlna, unknown }

/// A device found on the local network by a discovery scan.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.host,
    required this.platform,
    this.name,
    this.location,
  });

  final String host;
  final DevicePlatform platform;
  final String? name;

  /// SSDP `LOCATION` / device-description URL, when advertised.
  final String? location;

  @override
  String toString() => '${platform.name}  $host  ${name ?? ''}'.trim();
}
