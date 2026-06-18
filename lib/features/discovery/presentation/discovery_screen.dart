import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/apphud/apphud_service.dart';
import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/remote_store.dart';
import '../../../core/remote/wake_on_lan.dart';
import '../../onboarding/presentation/all_set_screen.dart';
import '../../paywall/presentation/paywall_screen.dart';
import '../../remote/presentation/remote_controller.dart';
import '../../remote/presentation/remote_screen.dart';
import 'discovery_controller.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryControllerProvider);
    final last = ref.watch(remoteStoreProvider).loadLastDevice();
    final devices = <DiscoveredDevice>[
      ?last,
      ...state.devices.where((d) => d.host != last?.host),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Connect your TV',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To continue please select your Smart TV from the list below',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 17, height: 1.4),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _DeviceListCard(
                  devices: devices,
                  scanning: state.scanning,
                  lastHost: last?.host,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _addByIp(context, ref),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Add TV by IP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceListCard extends ConsumerWidget {
  const _DeviceListCard({
    required this.devices,
    required this.scanning,
    required this.lastHost,
  });

  final List<DiscoveredDevice> devices;
  final bool scanning;
  final String? lastHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const line = Divider(
      height: 1,
      thickness: 1,
      color: Color(0x14FFFFFF),
      indent: 24,
      endIndent: 24,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF26262B), Color(0xFF141416)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              'Make sure your device is active and connected to the same WiFi '
              'network as your phone or tablet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.4),
            ),
          ),
          line,
          Expanded(
            child: devices.isEmpty
                ? _EmptyState(scanning: scanning)
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => line,
                    itemBuilder: (_, i) => _DeviceRow(
                      device: devices[i],
                      isLast: devices[i].host == lastHost,
                    ),
                  ),
          ),
          line,
          const _RefreshButton(),
        ],
      ),
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({required this.device, required this.isLast});

  final DiscoveredDevice device;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connecting = ref.watch(_connectingHostProvider) == device.host;
    return InkWell(
      onTap: connecting ? null : () => _connect(context, ref, device),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    device.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLast ? 'Last used' : 'New',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ),
            connecting
                ? const SizedBox.square(
                    dimension: 24,
                    child: Center(
                      child: CupertinoActivityIndicator(
                        radius: 10,
                        color: Colors.white38,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scanning) ...[
            const CupertinoActivityIndicator(radius: 12, color: Colors.white38),
            const SizedBox(height: 12),
            const Text(
              'Searching for TVs…',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ] else
            const Text(
              'No TVs found on this network',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
        ],
      ),
    );
  }
}

class _RefreshButton extends ConsumerWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref.read(discoveryControllerProvider.notifier).scan(),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Refresh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Host of the device currently being connected to (null when idle). Drives the
/// per-row spinner that replaces the chevron while a connection is in progress.
final _connectingHostProvider =
    NotifierProvider<_ConnectingHostNotifier, String?>(
  _ConnectingHostNotifier.new,
);

class _ConnectingHostNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setHost(String? host) => state = host;
}

Future<void> _connect(
  BuildContext context,
  WidgetRef ref,
  DiscoveredDevice device,
) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final store = ref.read(remoteStoreProvider);
  final notifier = ref.read(remoteControllerProvider.notifier);
  final connecting = ref.read(_connectingHostProvider.notifier);
  final firstRun = ref.read(firstRunProvider);

  connecting.setHost(device.host);

  // Show the "Grant access" sheet only when the TV will actually prompt for
  // approval — i.e. it hasn't been paired before. An already-paired Samsung
  // (saved token) or a Roku (no pairing at all) connects without a prompt, so
  // the sheet must never appear for them, no matter how long connecting takes.
  // The short delay also avoids a flash if pairing resolves or fails instantly.
  var sheetOpen = false;
  final sheetTimer = _needsApproval(store, device)
      ? Timer(const Duration(milliseconds: 300), () {
          if (!context.mounted) return;
          sheetOpen = true;
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: const Color(0xFF1C1C1E),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (_) => const _GrantAccessSheet(),
          );
        })
      : null;

  var connected = false;
  try {
    await notifier.connect(device);
    connected = true;
  } catch (_) {
    // The TV may be off — try Wake-on-LAN with a saved MAC, then retry once.
    final mac = store.mac(device.host);
    connected = mac != null && await _wakeAndRetry(notifier, device, mac);
  } finally {
    connecting.setHost(null);
  }

  sheetTimer?.cancel();
  if (sheetOpen) navigator.pop();

  if (!connected) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not connect to the TV')),
    );
    return;
  }
  // First-run setup ends on the "You're all set" screen. Afterwards, go to the
  // remote — through the paywall first when the user isn't premium.
  if (firstRun) {
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const AllSetScreen()),
    );
    return;
  }
  if (!ApphudService.instance.isPremium.value) {
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
    );
  }
  navigator.push(
    MaterialPageRoute<void>(builder: (_) => const RemoteScreen()),
  );
}

/// Whether connecting to [device] will trigger an allow/deny prompt on the TV.
/// Samsung and LG prompt only until their pairing credential (token /
/// client-key) is saved. Roku needs no pairing at all.
bool _needsApproval(RemoteStore store, DiscoveredDevice device) =>
    switch (device.platform) {
      DevicePlatform.samsung => store.token(device.host) == null,
      DevicePlatform.lg => store.lgKey(device.host) == null,
      _ => false,
    };

Future<bool> _wakeAndRetry(
  RemoteController notifier,
  DiscoveredDevice device,
  String mac,
) async {
  await WakeOnLan.send(mac, ip: device.host);
  await Future<void>.delayed(const Duration(seconds: 5));
  try {
    await notifier.connect(device);
    return true;
  } catch (_) {
    return false;
  }
}

class _GrantAccessSheet extends StatelessWidget {
  const _GrantAccessSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Grant access',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/onboarding/allow_tv.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const Text.rich(
              TextSpan(
                text: 'Please check the confirmation dialog ',
                children: [
                  TextSpan(
                    text: 'on your TV',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: '. You need to allow access to connect the app.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.45),
            ),
            const SizedBox(height: 26),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_remote, color: Colors.white54, size: 20),
                SizedBox(width: 10),
                Text(
                  'Waiting for permission...',
                  style: TextStyle(color: Colors.white54, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _addByIp(BuildContext context, WidgetRef ref) async {
  final device = await showModalBottomSheet<DiscoveredDevice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AddByIpSheet(),
  );
  if (device != null && context.mounted) {
    await _connect(context, ref, device);
  }
}

class _AddByIpSheet extends ConsumerStatefulWidget {
  const _AddByIpSheet();

  @override
  ConsumerState<_AddByIpSheet> createState() => _AddByIpSheetState();
}

class _AddByIpSheetState extends ConsumerState<_AddByIpSheet> {
  static const Map<DevicePlatform, String> _brands = {
    DevicePlatform.samsung: 'Samsung',
    DevicePlatform.roku: 'Roku',
    DevicePlatform.lg: 'LG',
  };

  final _controller = TextEditingController();
  DevicePlatform _platform = DevicePlatform.samsung;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final host = _controller.text.trim();
    if (host.isEmpty) return;
    Navigator.pop(context, DiscoveredDevice(host: host, platform: _platform));
  }

  @override
  Widget build(BuildContext context) {
    final hasIp = _controller.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        'Add TV by IP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: true,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'TV IP address',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _brands.entries)
                      _BrandChip(
                        label: entry.value,
                        selected: _platform == entry.key,
                        onTap: () => setState(() => _platform = entry.key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton(
                  onPressed: hasIp ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF2C2C2E),
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Connect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandChip extends ConsumerWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: selected ? Colors.white : const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded, size: 18, color: Colors.black),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
