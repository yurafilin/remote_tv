import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/remote/app_launcher.dart';
import '../../../core/remote/keys.dart';
import 'remote_controller.dart';
import 'widgets/remote_button.dart';

const Color _border = Color(0x14FFFFFF);

/// Top-lit face gradient: a bright rim along the top edge fading into a dark
/// body, so the round keys read as physically raised.
const LinearGradient _keyFace = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF3A3A3C), Color(0xFF1E1E20), Color(0xFF141416)],
  stops: [0.0, 0.32, 1.0],
);
const LinearGradient _keyFacePressed = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF242426), Color(0xFF0E0E10)],
);

/// Gradient outline: a crisp highlight along the top edge fading down the
/// sides. Painted as a 1px rim peeking out under the face — a lit bevel that
/// Flutter's uniform [Border] can't do with a rounded shape.
const LinearGradient _keyStroke = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x4DFFFFFF), Color(0x0FFFFFFF), Color(0x05FFFFFF)],
  stops: [0.0, 0.35, 1.0],
);

/// Soft drop shadow beneath a key, for lift against lighter surfaces.
const List<BoxShadow> _keyShadow = [
  BoxShadow(color: Color(0x73000000), blurRadius: 9, offset: Offset(0, 4)),
];

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(remoteControllerProvider.notifier).disconnect();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: const [
                _Header(),
                SizedBox(height: 16),
                _TopGrid(),
                SizedBox(height: 16),
                Expanded(child: _TouchPad()),
                SizedBox(height: 16),
                _BottomBar(),
              ],
            ),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device?.label ?? 'Remote',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              const Text(
                'TV is connected',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Key(
          remoteKey: RemoteKey.power,
          width: 64,
          height: 64,
          child: const Icon(
            CupertinoIcons.power,
            color: Color(0xFFE53935),
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _TopGrid extends ConsumerWidget {
  const _TopGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Rocker(
            topKey: RemoteKey.volumeUp,
            bottomKey: RemoteKey.volumeDown,
            top: Icon(CupertinoIcons.plus, color: Colors.white, size: 22),
            bottom: Icon(CupertinoIcons.minus, color: Colors.white, size: 22),
            label: 'Vol',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Key(
                    remoteKey: RemoteKey.input,
                    child: const Icon(
                      CupertinoIcons.square_arrow_right,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _Key(
                    onTap: () => _showMore(context),
                    child: const Text(
                      '123',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Key(
                    onTap: () => _showTextInput(context),
                    child: const Icon(
                      Icons.keyboard,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _Key(
                    remoteKey: RemoteKey.mute,
                    child: const Icon(
                      CupertinoIcons.speaker_slash_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const _Rocker(
            topKey: RemoteKey.channelUp,
            bottomKey: RemoteKey.channelDown,
            top: Icon(CupertinoIcons.chevron_up, color: Colors.white, size: 22),
            bottom: Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white,
              size: 22,
            ),
            label: 'Ch',
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _Key(
                remoteKey: RemoteKey.back,
                height: 56,
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Key(
                remoteKey: RemoteKey.home,
                height: 56,
                child: const Icon(
                  CupertinoIcons.home,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Key(
              remoteKey: RemoteKey.menu,
              width: 72,
              height: 56,
              child: const _ColoredDots(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Key(
                onTap: () => _showApps(context),
                height: 56,
                child: const Text(
                  'Apps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Key(
              remoteKey: RemoteKey.playPause,
              width: 72,
              height: 56,
              child: const Icon(
                CupertinoIcons.playpause_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColoredDots extends ConsumerWidget {
  const _ColoredDots();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget dot(Color color) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [dot(const Color(0xFFEA4335)), dot(const Color(0xFF34A853))],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [dot(const Color(0xFF4285F4)), dot(const Color(0xFFFBBC05))],
        ),
      ],
    );
  }
}

/// A raised, top-lit surface: a gradient outline (bright top rim) wrapping a
/// face gradient, plus a drop shadow. Shared by every round key and rocker.
class _RaisedSurface extends ConsumerWidget {
  const _RaisedSurface({
    required this.borderRadius,
    required this.child,
    this.pressed = false,
    this.width,
    this.height,
  });

  final double borderRadius;
  final Widget child;
  final bool pressed;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: _keyStroke,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _keyShadow,
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          gradient: pressed ? _keyFacePressed : _keyFace,
          borderRadius: BorderRadius.circular(borderRadius - 2),
        ),
        child: child,
      ),
    );
  }
}

/// Generic rounded-rect key. With [remoteKey] it sends that key and dims when
/// the device lacks the capability; with [onTap] it runs a custom action.
class _Key extends ConsumerStatefulWidget {
  const _Key({
    required this.child,
    this.remoteKey,
    this.onTap,
    this.width,
    this.height,
  }) : assert(remoteKey != null || onTap != null, 'Provide a key or onTap');

  final Widget child;
  final RemoteKey? remoteKey;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  ConsumerState<_Key> createState() => _KeyState();
}

class _KeyState extends ConsumerState<_Key> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final remoteKey = widget.remoteKey;
    final enabled = remoteKey == null
        ? true
        : ref.watch(
            remoteControllerProvider
                .select((s) => s.capabilities.contains(remoteKey)),
          );

    void handleTap() {
      HapticFeedback.lightImpact();
      if (remoteKey != null) {
        ref.read(remoteControllerProvider.notifier).press(remoteKey);
      } else {
        widget.onTap?.call();
      }
    }

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              handleTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: _RaisedSurface(
            width: widget.width,
            height: widget.height,
            borderRadius: 100,
            pressed: _pressed,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _Rocker extends ConsumerStatefulWidget {
  const _Rocker({
    required this.topKey,
    required this.bottomKey,
    required this.top,
    required this.bottom,
    required this.label,
  });

  final RemoteKey topKey;
  final RemoteKey bottomKey;
  final Widget top;
  final Widget bottom;
  final String label;

  @override
  ConsumerState<_Rocker> createState() => _RockerState();
}

class _RockerState extends ConsumerState<_Rocker> {
  RemoteKey? _pressed;

  @override
  Widget build(BuildContext context) {
    final caps = ref.watch(
      remoteControllerProvider.select((s) => s.capabilities),
    );
    return _RaisedSurface(
      width: 64,
      borderRadius: 32,
      child: Column(
        children: [
          _half(widget.topKey, widget.top, caps.contains(widget.topKey)),
          Text(
            widget.label,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          _half(widget.bottomKey, widget.bottom, caps.contains(widget.bottomKey)),
        ],
      ),
    );
  }

  Widget _half(RemoteKey key, Widget child, bool enabled) {
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
          opacity: enabled ? (_pressed == key ? 0.5 : 1) : 0.35,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _TouchPad extends ConsumerStatefulWidget {
  const _TouchPad();

  @override
  ConsumerState<_TouchPad> createState() => _TouchPadState();
}

class _TouchPadState extends ConsumerState<_TouchPad> {
  RemoteKey? _active;

  RemoteKey _hit(Offset local, Size size) {
    final v = Offset(local.dx - size.width / 2, local.dy - size.height / 2);
    if (v.distance <= math.min(size.width, size.height) * 0.21) {
      return RemoteKey.ok;
    }
    final angle = math.atan2(v.dy, v.dx);
    if (angle >= -math.pi / 4 && angle < math.pi / 4) return RemoteKey.right;
    if (angle >= math.pi / 4 && angle < 3 * math.pi / 4) return RemoteKey.down;
    if (angle >= -3 * math.pi / 4 && angle < -math.pi / 4) return RemoteKey.up;
    return RemoteKey.left;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final ring = math.min(size.width, size.height) * 0.66;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            setState(() => _active = _hit(d.localPosition, size));
            HapticFeedback.lightImpact();
          },
          onTapUp: (d) {
            final key = _hit(d.localPosition, size);
            setState(() => _active = null);
            ref.read(remoteControllerProvider.notifier).press(key);
          },
          onTapCancel: () => setState(() => _active = null),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161618),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
            ),
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: ring,
                    height: ring,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0x1FFFFFFF)),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0, -0.98),
                          child: _chevron(
                            CupertinoIcons.chevron_up,
                            _active == RemoteKey.up,
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0, 0.98),
                          child: _chevron(
                            CupertinoIcons.chevron_down,
                            _active == RemoteKey.down,
                          ),
                        ),
                        Align(
                          alignment: const Alignment(-0.98, 0),
                          child: _chevron(
                            CupertinoIcons.chevron_left,
                            _active == RemoteKey.left,
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0.98, 0),
                          child: _chevron(
                            CupertinoIcons.chevron_right,
                            _active == RemoteKey.right,
                          ),
                        ),
                        AnimatedScale(
                          scale: _active == RemoteKey.ok ? 0.9 : 1,
                          duration: const Duration(milliseconds: 90),
                          child: Container(
                            width: ring * 0.55,
                            height: ring * 0.55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x0DFFFFFF),
                              border: Border.all(color: const Color(0x22FFFFFF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chevron(IconData icon, bool active) =>
      Icon(icon, color: active ? Colors.white : Colors.white38, size: 26);
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

void _showApps(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF101012),
    showDragHandle: true,
    builder: (_) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _AppRow(),
      ),
    ),
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
          icon: Icons.fast_rewind_rounded,
          remoteKey: RemoteKey.rewind,
          tooltip: 'Rewind',
          size: 56,
          iconSize: 24,
        ),
        RemoteButton(
          icon: Icons.fast_forward_rounded,
          remoteKey: RemoteKey.fastForward,
          tooltip: 'Fast forward',
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
    if (apps.isEmpty) {
      return const Text(
        'This device has no app shortcuts.',
        style: TextStyle(color: Colors.white38),
      );
    }
    return Column(
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
