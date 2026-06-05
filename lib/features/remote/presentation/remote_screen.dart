import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final name = device?.name ?? device?.host ?? 'Remote';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(remoteControllerProvider.notifier).disconnect();
                  Navigator.of(context).pop();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
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
            const Align(
              alignment: Alignment.centerRight,
              child: RemoteButton(
                icon: CupertinoIcons.power,
                remoteKey: RemoteKey.power,
                size: 60,
                iconSize: 26,
                glow: true,
                tooltip: 'Power',
              ),
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
