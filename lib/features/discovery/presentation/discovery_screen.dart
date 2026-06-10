import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/remote_store.dart';
import '../../../core/remote/wake_on_lan.dart';
import '../../remote/presentation/remote_controller.dart';
import '../../remote/presentation/remote_screen.dart';
import 'discovery_controller.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryControllerProvider);
    final last = ref.watch(remoteStoreProvider).loadLastDevice();
    final discovered =
        state.devices.where((d) => d.host != last?.host).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find your TV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Add by IP',
            onPressed: () => _addByIp(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          if (last != null) ...[
            const _SectionHeader('Last connection'),
            Dismissible(
              key: ValueKey('forget:${last.host}'),
              direction: DismissDirection.endToStart,
              background: const _ForgetBackground(),
              onDismissed: (_) =>
                  ref.read(remoteStoreProvider).forget(last.host),
              child: _DeviceCard(device: last),
            ),
          ],
          _SectionHeader('Devices', busy: state.scanning),
          for (final device in discovered) _DeviceCard(device: device),
          if (discovered.isEmpty && !state.scanning)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'No other TVs found on this network.',
                style: TextStyle(color: Colors.white38),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  const _SectionHeader(this.title, {this.busy = false});

  final String title;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          if (busy) ...[
            const SizedBox(width: 10),
            const CupertinoActivityIndicator(radius: 8, color: Colors.white54),
          ],
        ],
      ),
    );
  }
}

class _ForgetBackground extends ConsumerWidget {
  const _ForgetBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Forget',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device});

  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _connect(context, ref, device),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.tv_outlined, color: Colors.white, size: 30),
                const SizedBox(width: 16),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.sublabel,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _connect(
  BuildContext context,
  WidgetRef ref,
  DiscoveredDevice device,
) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(remoteControllerProvider.notifier);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => const _ConnectingDialog(),
  );
  try {
    await notifier.connect(device);
  } catch (_) {
    // The TV may be off — try Wake-on-LAN with a saved MAC, then retry once.
    final mac = ref.read(remoteStoreProvider).mac(device.host);
    if (mac == null || !await _wakeAndRetry(notifier, device, mac)) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not connect to the TV')),
      );
      return;
    }
  }
  navigator.pop();
  navigator.push(
    MaterialPageRoute<void>(builder: (_) => const RemoteScreen()),
  );
}

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

class _ConnectingDialog extends ConsumerWidget {
  const _ConnectingDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(radius: 15, color: Colors.white),
          SizedBox(height: 20),
          Text(
            'Connecting…',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'If prompted, allow on your TV',
            style: TextStyle(color: Colors.white60, fontSize: 15),
          ),
        ],
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
