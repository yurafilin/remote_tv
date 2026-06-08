import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/app_launcher.dart';
import '../../../core/remote/keys.dart';
import 'remote_controller.dart';
import 'widgets/dpad.dart';
import 'widgets/remote_button.dart';
import 'widgets/volume_pill.dart';

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: const [
              _Header(),
              SizedBox(height: 8),
              DPad(),
              SizedBox(height: 40),
              _ControlGrid(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(remoteControllerProvider.select((s) => s.device));
    final canType = ref.watch(
      remoteControllerProvider.select((s) => s.canType),
    );
    final name = device?.label ?? 'Remote';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            if (canType)
              IconButton(
                icon: const Icon(Icons.keyboard, color: Colors.white70),
                tooltip: 'Keyboard',
                onPressed: () => _showTextInput(context),
              ),
            IconButton(
              icon: const Icon(Icons.dialpad, color: Colors.white70),
              tooltip: 'More buttons',
              onPressed: () => _showMore(context),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(remoteControllerProvider.notifier).disconnect();
                  Navigator.of(context).pop();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const RemoteButton(
              icon: CupertinoIcons.power,
              remoteKey: RemoteKey.power,
              size: 60,
              iconSize: 26,
              glow: true,
              tooltip: 'Power',
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlGrid extends ConsumerWidget {
  const _ControlGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RemoteButton(
                icon: CupertinoIcons.back,
                remoteKey: RemoteKey.back,
                tooltip: 'Back',
              ),
              SizedBox(height: 16),
              RemoteButton(
                icon: CupertinoIcons.playpause_fill,
                remoteKey: RemoteKey.playPause,
                tooltip: 'Play / Pause',
                iconSize: 30,
              ),
              SizedBox(height: 16),
              RemoteButton(
                icon: CupertinoIcons.speaker_slash_fill,
                remoteKey: RemoteKey.mute,
                tooltip: 'Mute',
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RemoteButton(
                icon: CupertinoIcons.tv,
                remoteKey: RemoteKey.home,
                tooltip: 'Home',
              ),
              SizedBox(height: 16),
              VolumePill(),
            ],
          ),
        ],
      ),
    );
  }
}

void _showMore(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF101012),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _MoreSheet(),
  );
}

class _MoreSheet extends ConsumerWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _AppRow(),
              _NumberPad(),
              SizedBox(height: 20),
              _ChannelRow(),
              SizedBox(height: 20),
              _FunctionRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberPad extends ConsumerWidget {
  const _NumberPad();

  static const List<List<RemoteKey?>> _rows = [
    [RemoteKey.digit1, RemoteKey.digit2, RemoteKey.digit3],
    [RemoteKey.digit4, RemoteKey.digit5, RemoteKey.digit6],
    [RemoteKey.digit7, RemoteKey.digit8, RemoteKey.digit9],
    [null, RemoteKey.digit0, null],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final key in row)
                if (key == null)
                  const SizedBox(width: 64)
                else
                  RemoteButton(label: key.name.substring(5), remoteKey: key, size: 64),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ChannelRow extends ConsumerWidget {
  const _ChannelRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Channel', style: TextStyle(color: Colors.white54, fontSize: 12)),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RemoteButton(
              label: '−',
              remoteKey: RemoteKey.channelDown,
              size: 64,
              tooltip: 'Channel down',
            ),
            SizedBox(width: 28),
            RemoteButton(
              label: '+',
              remoteKey: RemoteKey.channelUp,
              size: 64,
              tooltip: 'Channel up',
            ),
          ],
        ),
      ],
    );
  }
}

class _FunctionRow extends ConsumerWidget {
  const _FunctionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButton(
          icon: Icons.input,
          remoteKey: RemoteKey.input,
          tooltip: 'Input',
          size: 56,
          iconSize: 24,
        ),
        RemoteButton(
          icon: Icons.menu,
          remoteKey: RemoteKey.menu,
          tooltip: 'Menu',
          size: 56,
          iconSize: 24,
        ),
        RemoteButton(
          icon: Icons.grid_view_rounded,
          remoteKey: RemoteKey.guide,
          tooltip: 'Guide',
          size: 56,
          iconSize: 24,
        ),
        RemoteButton(
          icon: Icons.stop_rounded,
          remoteKey: RemoteKey.stop,
          tooltip: 'Stop',
          size: 56,
          iconSize: 24,
        ),
        RemoteButton(
          icon: Icons.close_rounded,
          remoteKey: RemoteKey.exit,
          tooltip: 'Exit',
          size: 56,
          iconSize: 24,
        ),
      ],
    );
  }
}

void _showTextInput(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => const _TextInputDialog(),
  );
}

class _TextInputDialog extends ConsumerStatefulWidget {
  const _TextInputDialog();

  @override
  ConsumerState<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends ConsumerState<_TextInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final navigator = Navigator.of(context);
    final text = _controller.text;
    if (text.isNotEmpty) {
      final notifier = ref.read(remoteControllerProvider.notifier);
      await notifier.sendText(text);
      await notifier.submit();
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Type on TV'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _send(),
        decoration: const InputDecoration(hintText: 'Type, then Send'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _send, child: const Text('Send')),
      ],
    );
  }
}

class _AppRow extends ConsumerWidget {
  const _AppRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(remoteControllerProvider.select((s) => s.apps));
    if (apps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apps',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final app in AppShortcut.values)
                if (apps.contains(app)) _AppChip(app: app),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppChip extends ConsumerWidget {
  const _AppChip({required this.app});

  final AppShortcut app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      label: Text(_appLabel(app)),
      onPressed: () =>
          ref.read(remoteControllerProvider.notifier).launchApp(app),
    );
  }
}

String _appLabel(AppShortcut app) => switch (app) {
      AppShortcut.netflix => 'Netflix',
      AppShortcut.youtube => 'YouTube',
      AppShortcut.primeVideo => 'Prime Video',
      AppShortcut.disneyPlus => 'Disney+',
      AppShortcut.spotify => 'Spotify',
    };
