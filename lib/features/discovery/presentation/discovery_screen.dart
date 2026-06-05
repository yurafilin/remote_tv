import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/discovered_device.dart';
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
      appBar: AppBar(title: const Text('Find your TV')),
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
    return Center(
      child: FilledButton.icon(
        onPressed: () => ref.read(discoveryControllerProvider.notifier).scan(),
        icon: const Icon(Icons.wifi_find),
        label: const Text('Scan network'),
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
            title: Text(device.name ?? _platformLabel(device.platform)),
            subtitle: Text(device.host),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connect(context, ref, device),
          ),
        );
      },
    );
  }
}

String _platformLabel(DevicePlatform platform) => switch (platform) {
      DevicePlatform.roku => 'Roku',
      DevicePlatform.samsung => 'Samsung TV',
      DevicePlatform.lg => 'LG TV',
      DevicePlatform.androidTv => 'Android TV',
      DevicePlatform.vizio => 'Vizio',
      DevicePlatform.dlna => 'Media device',
      DevicePlatform.unknown => 'TV',
    };

Future<void> _connect(
  BuildContext context,
  WidgetRef ref,
  DiscoveredDevice device,
) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ConnectingDialog(),
  );
  try {
    await ref.read(remoteControllerProvider.notifier).connect(device);
  } catch (_) {
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not connect to the TV')),
    );
    return;
  }
  navigator.pop();
  navigator.push(
    MaterialPageRoute<void>(builder: (_) => const RemoteScreen()),
  );
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
