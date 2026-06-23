import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/remote/apphud/apphud_service.dart';
import 'paywall_controller.dart';
import 'subscription_tile.dart';

const String _privacyUrl =
    'https://doc-hosting.flycricket.io/clikr-privacy-policy/e15290cc-9000-4999-8190-77c2aaf2b274/privacy';
const String _termsUrl =
    'https://doc-hosting.flycricket.io/clikr-terms-of-use/64da7ac5-137a-47df-b9d4-4d490ad2b25e/terms';

Future<void> _openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    /* no handler / cannot launch — ignore */
  }
}

/// Monochrome paywall: a hero image, a title, the subscription options from the
/// Apphud `onboarding` placement, a Continue (purchase) button and Restore.
/// Pops `true` once premium becomes active.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  Future<void> _purchase(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok =
        await ref.read(paywallControllerProvider.notifier).purchaseSelected();
    if (ok) {
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Purchase was not completed')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(paywallControllerProvider.notifier).restore();
    if (ApphudService.instance.isPremium.value) {
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nothing to restore')),
      );
    }
  }

  /// Hidden tester unlock: tapping the title 3× opens a password sheet. The
  /// correct password flips premium on and dismisses the paywall — the caller
  /// then lands on the remote.
  Future<void> _showUnlock(BuildContext context) async {
    final navigator = Navigator.of(context);
    final unlocked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _UnlockSheet(),
    );
    if (unlocked == true) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paywallControllerProvider);
    final selected = state.selected < state.options.length
        ? state.options[state.selected].pricing
        : null;
    final trial = selected?.trialLabel;
    final continueLabel = trial != null ? 'Start $trial' : 'Continue';
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const _Hero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    child: Column(
                      children: [
                        _SecretTap(
                          onTriggered: () => _showUnlock(context),
                          child: const Text(
                            'Unlock all features',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Control any TV from your phone — touchpad, keyboard, '
                          'apps and more',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _options(context, ref, state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ContinueButton(
                    label: continueLabel,
                    purchasing: state.purchasing,
                    enabled: state.options.isNotEmpty && !state.purchasing,
                    onPressed: () => _purchase(context, ref),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _LinkButton(
                          label: 'Restore',
                          onPressed: () => _restore(context, ref),
                        ),
                        _LinkButton(
                          label: 'Privacy',
                          onPressed: () => _openUrl(_privacyUrl),
                        ),
                        _LinkButton(
                          label: 'Terms',
                          onPressed: () => _openUrl(_termsUrl),
                        ),
                        _LinkButton(
                          label: 'Skip',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _options(BuildContext context, WidgetRef ref, PaywallState state) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CupertinoActivityIndicator(radius: 14, color: Colors.white54),
      );
    }
    if (state.failed || state.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Text(
              'Could not load subscriptions',
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.read(paywallControllerProvider.notifier).reload(),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < state.options.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          SubscriptionTile(
            pricing: state.options[i].pricing,
            selected: i == state.selected,
            onTap: () =>
                ref.read(paywallControllerProvider.notifier).select(i),
          ),
        ],
      ],
    );
  }
}

/// Full-width hero photo that bleeds behind the status bar and fades into the
/// black screen, with a close button pinned top-right.
class _Hero extends StatelessWidget {
  const _Hero();

  /// How far the content below is pulled up over the image's dark bottom.
  static const double _overlap = 60;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = width * 1048 / 1000;
    return SizedBox(
      width: double.infinity,
      height: imageHeight - _overlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-height image hangs 60px below the reserved box so the content
          // beneath it (painted afterwards) overlaps its darkened bottom.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                Image.asset(
                  'assets/onboarding/paywall_tvpult.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0.55, 0.95],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white54,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: Text(label),
    );
  }
}

/// Counts taps on its child and fires [onTriggered] every [taps]-th tap — the
/// hidden gesture that opens the tester-unlock sheet.
class _SecretTap extends StatefulWidget {
  const _SecretTap({required this.child, required this.onTriggered});

  final Widget child;
  final VoidCallback onTriggered;

  @override
  State<_SecretTap> createState() => _SecretTapState();
}

class _SecretTapState extends State<_SecretTap> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _count++;
        if (_count >= 3) {
          _count = 0;
          widget.onTriggered();
        }
      },
      child: widget.child,
    );
  }
}

/// Tester-unlock password sheet. Pops `true` once the correct password flips
/// premium on.
class _UnlockSheet extends StatefulWidget {
  const _UnlockSheet();

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  final _controller = TextEditingController();
  bool _error = false;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() {
      _error = false;
      _checking = true;
    });
    final ok =
        await ApphudService.instance.attemptTesterUnlock(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter password to unlock premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _activate(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white38),
                  errorText: _error ? 'Password is incorrect' : null,
                  filled: true,
                  fillColor: const Color(0xFF111113),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _checking ? null : _activate,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF2A2A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _checking
                      ? const CupertinoActivityIndicator(color: Colors.black)
                      : const Text('Activate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.label,
    required this.purchasing,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool purchasing;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF2A2A2E),
          disabledForegroundColor: Colors.white38,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: purchasing
            ? const CupertinoActivityIndicator(color: Colors.black)
            : Text(label),
      ),
    );
  }
}
