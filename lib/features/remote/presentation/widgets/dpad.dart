import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/remote/keys.dart';
import '../remote_controller.dart';
import 'remote_style.dart';

/// Apple-style clickpad: tap the rim for a direction, the centre for OK.
class DPad extends ConsumerStatefulWidget {
  const DPad({this.size = 260, super.key});

  final double size;

  @override
  ConsumerState<DPad> createState() => _DPadState();
}

class _DPadState extends ConsumerState<DPad> {
  RemoteKey? _active;

  RemoteKey _hitTest(Offset local) {
    final centre = widget.size / 2;
    final v = Offset(local.dx - centre, local.dy - centre);
    if (v.distance <= widget.size * 0.27) return RemoteKey.ok;
    final angle = atan2(v.dy, v.dx);
    if (angle >= -pi / 4 && angle < pi / 4) return RemoteKey.right;
    if (angle >= pi / 4 && angle < 3 * pi / 4) return RemoteKey.down;
    if (angle >= -3 * pi / 4 && angle < -pi / 4) return RemoteKey.up;
    return RemoteKey.left;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final dot = size * 0.034;
    final margin = size * 0.05;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        setState(() => _active = _hitTest(d.localPosition));
        HapticFeedback.lightImpact();
      },
      onTapUp: (d) {
        final key = _hitTest(d.localPosition);
        setState(() => _active = null);
        ref.read(remoteControllerProvider.notifier).press(key);
      },
      onTapCancel: () => setState(() => _active = null),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -size * 0.34,
              left: -size * 0.18,
              right: -size * 0.18,
              bottom: -size * 0.06,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 0.6,
                      colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E2E30), Color(0xFF131315)],
                ),
                border: RemoteStyle.hairline,
                boxShadow: RemoteStyle.lift,
              ),
            ),
            AnimatedScale(
              scale: _active == RemoteKey.ok ? 0.95 : 1,
              duration: const Duration(milliseconds: 90),
              child: Container(
                width: size * 0.54,
                height: size * 0.54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF242426), Color(0xFF0E0E10)],
                  ),
                  border: RemoteStyle.hairline,
                ),
              ),
            ),
            _dot(Alignment.topCenter, dot, margin, _active == RemoteKey.up),
            _dot(Alignment.bottomCenter, dot, margin, _active == RemoteKey.down),
            _dot(Alignment.centerLeft, dot, margin, _active == RemoteKey.left),
            _dot(Alignment.centerRight, dot, margin, _active == RemoteKey.right),
          ],
        ),
      ),
    );
  }

  Widget _dot(Alignment alignment, double diameter, double margin, bool active) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(margin),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : RemoteStyle.dot,
          ),
        ),
      ),
    );
  }
}
