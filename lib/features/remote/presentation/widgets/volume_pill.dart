import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/remote/keys.dart';
import '../remote_controller.dart';
import 'remote_style.dart';

/// Stadium-shaped volume rocker: + on top, − on bottom.
class VolumePill extends ConsumerStatefulWidget {
  const VolumePill({this.width = 88, this.height = 192, super.key});

  final double width;
  final double height;

  @override
  ConsumerState<VolumePill> createState() => _VolumePillState();
}

class _VolumePillState extends ConsumerState<VolumePill> {
  RemoteKey? _pressed;

  @override
  Widget build(BuildContext context) {
    final caps = ref.watch(
      remoteControllerProvider.select((s) => s.capabilities),
    );
    final radius = BorderRadius.circular(widget.width / 2);
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: RemoteStyle.faceGradient(),
        border: RemoteStyle.hairline,
        boxShadow: RemoteStyle.lift,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            _half(
              CupertinoIcons.plus,
              RemoteKey.volumeUp,
              caps.contains(RemoteKey.volumeUp),
            ),
            _half(
              CupertinoIcons.minus,
              RemoteKey.volumeDown,
              caps.contains(RemoteKey.volumeDown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _half(IconData icon, RemoteKey key, bool enabled) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled
            ? (_) {
                setState(() => _pressed = key);
                HapticFeedback.lightImpact();
              }
            : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = null);
                ref.read(remoteControllerProvider.notifier).press(key);
              }
            : null,
        onTapCancel: () => setState(() => _pressed = null),
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            color: _pressed == key ? const Color(0x22000000) : Colors.transparent,
            alignment: Alignment.center,
            child: Icon(icon, color: RemoteStyle.icon, size: 32),
          ),
        ),
      ),
    );
  }
}
