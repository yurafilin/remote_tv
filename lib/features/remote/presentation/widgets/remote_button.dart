import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/remote/keys.dart';
import '../remote_controller.dart';
import 'remote_style.dart';

/// A round, Apple-remote-style key showing an [icon] or a text [label].
/// Dimmed and inert when the connected device doesn't advertise [remoteKey].
class RemoteButton extends ConsumerStatefulWidget {
  const RemoteButton({
    required this.remoteKey,
    this.icon,
    this.label,
    this.size = 88,
    this.iconSize = 32,
    this.glow = false,
    this.tooltip,
    super.key,
  }) : assert(icon != null || label != null, 'Provide an icon or a label');

  final IconData? icon;
  final String? label;
  final RemoteKey remoteKey;
  final double size;
  final double iconSize;
  final bool glow;
  final String? tooltip;

  @override
  ConsumerState<RemoteButton> createState() => _RemoteButtonState();
}

class _RemoteButtonState extends ConsumerState<RemoteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      remoteControllerProvider
          .select((s) => s.capabilities.contains(widget.remoteKey)),
    );

    void setPressed(bool value) {
      if (enabled && value != _pressed) setState(() => _pressed = value);
    }

    final label = widget.label;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip ?? widget.remoteKey.name,
      child: GestureDetector(
        onTapDown: enabled
            ? (_) {
                setPressed(true);
                HapticFeedback.lightImpact();
              }
            : null,
        onTapUp: enabled
            ? (_) {
                setPressed(false);
                ref
                    .read(remoteControllerProvider.notifier)
                    .press(widget.remoteKey);
              }
            : null,
        onTapCancel: () => setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 90),
          child: Opacity(
            opacity: enabled ? 1 : 0.35,
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RemoteStyle.faceGradient(pressed: _pressed),
                border: RemoteStyle.hairline,
                boxShadow: widget.glow ? RemoteStyle.glow : RemoteStyle.lift,
              ),
              child: label != null
                  ? Text(
                      label,
                      style: TextStyle(
                        color: RemoteStyle.icon,
                        fontSize: widget.size * 0.36,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      color: RemoteStyle.icon,
                      size: widget.iconSize,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
