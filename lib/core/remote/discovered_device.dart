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

  /// Whether [name] is a meaningful, user-facing name (not empty or a
  /// placeholder mDNS id like `uuid:...`).
  bool get _hasName {
    final n = name;
    return n != null && n.isNotEmpty && !n.toLowerCase().startsWith('uuid:');
  }

  /// Brand/type label, always derived from the platform.
  String get brand => switch (platform) {
        DevicePlatform.roku => 'Roku',
        DevicePlatform.samsung => 'Samsung TV',
        DevicePlatform.lg => 'LG TV',
        DevicePlatform.androidTv => 'Android TV',
        DevicePlatform.vizio => 'Vizio',
        DevicePlatform.dlna => 'Media device',
        DevicePlatform.unknown => 'TV',
      };

  /// Primary line: the real [name] when meaningful, otherwise the [brand].
  /// Samsung returns names HTML-escaped (e.g. `75&quot; The Frame`), so decode.
  String get label => _hasName ? _unescapeHtml(name!) : brand;

  /// Secondary line: the [brand] when there's a distinct name, else the host.
  String get sublabel => (_hasName && name != brand) ? brand : host;

  @override
  String toString() => '${platform.name}  $host  ${name ?? ''}'.trim();
}

String _unescapeHtml(String input) => input
    .replaceAll('&quot;', '"')
    .replaceAll('&#34;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&');
