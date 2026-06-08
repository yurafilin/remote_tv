import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/discovered_device.dart';
import '../../../core/remote/remote_store.dart';
import '../../../core/remote/wake_on_lan.dart';
import '../../remote/presentation/remote_controller.dart';
import '../../remote/presentation/remote_screen.dart';
import '../domain/discovery_state.dart';
import 'discovery_controller.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryControllerProvider);
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
      body: switch (state) {
        DiscoveryIdle() => const _Idle(),
        DiscoveryScanning() => const _Scanning(),
        DiscoveryResults(:final devices) when devices.isEmpty => const _Empty(),
        DiscoveryResults(:final devices) => _DeviceList(devices: devices),
      },
    );
  }
}

class _Idle extends ConsumerWidget {
  const _Idle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(remoteStoreProvider).loadLastDevice();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (last != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.tv),
                  title: Text(last.label),
                  subtitle: Text(last.sublabel),
                  onTap: () => _connect(context, ref, last),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          FilledButton.icon(
            onPressed: () =>
                ref.read(discoveryControllerProvider.notifier).scan(),
            icon: const Icon(Icons.wifi_find),
            label: Text(last == null ? 'Scan network' : 'Scan for other TVs'),
          ),
        ],
      ),
    );
  }
}

class _Scanning extends ConsumerWidget {
  const _Scanning();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Searching for TVs…'),
        ],
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tv_off, size: 48),
          const SizedBox(height: 12),
          const Text('No TVs found on this network'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                ref.read(discoveryControllerProvider.notifier).scan(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.devices});

  final List<DiscoveredDevice> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = devices[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.tv),
            title: Text(device.label),
            subtitle: Text(device.sublabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connect(context, ref, device),
          ),
        );
      },
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
    return const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Connecting…\nIf prompted, allow on your TV.')),
        ],
      ),
    );
  }
}

Future<void> _addByIp(BuildContext context, WidgetRef ref) async {
  final device = await showDialog<DiscoveredDevice>(
    context: context,
    builder: (_) => const _AddByIpDialog(),
  );
  if (device != null && context.mounted) {
    await _connect(context, ref, device);
  }
}

class _AddByIpDialog extends ConsumerStatefulWidget {
  const _AddByIpDialog();

  @override
  ConsumerState<_AddByIpDialog> createState() => _AddByIpDialogState();
}

class _AddByIpDialogState extends ConsumerState<_AddByIpDialog> {
  final _controller = TextEditingController();
  DevicePlatform _platform = DevicePlatform.samsung;

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
    return AlertDialog(
      title: const Text('Add TV by IP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'TV IP address',
              hintText: '192.168.1.42',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          DropdownButton<DevicePlatform>(
            value: _platform,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: DevicePlatform.samsung,
                child: Text('Samsung'),
              ),
              DropdownMenuItem(
                value: DevicePlatform.roku,
                child: Text('Roku'),
              ),
              DropdownMenuItem(
                value: DevicePlatform.lg,
                child: Text('LG'),
              ),
            ],
            onChanged: (value) =>
                setState(() => _platform = value ?? _platform),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Connect')),
      ],
    );
  }
}
