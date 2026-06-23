import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../core/monetization_init.dart';
import '../../../core/remote/remote_store.dart';
import '../../discovery/presentation/discovery_controller.dart';
import '../../discovery/presentation/discovery_screen.dart';

/// Monochrome onboarding shown on first launch: a short intro, the local-network
/// access explainer, and a "turn on your TV" reminder before the user lands on
/// the discovery screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();

  /// Drives the "Setting up" progress bar; the onboarding ends when it fills.
  late final AnimationController _setup;

  @override
  void initState() {
    super.initState();
    _setup = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        // When the bar fills, move on to the discovery screen.
        if (status == AnimationStatus.completed) _finish();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _setup.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );

  /// Go to the final "Setting up" step and start its progress animation.
  void _goToSetup() {
    _next();
    _setup.forward(from: 0);
  }

  /// Starting discovery kicks off a Bonjour/mDNS browse, which is what makes iOS
  /// show the "find devices on local networks" permission prompt. Fire it, then
  /// continue to the next step (discovery also warms up so TVs appear sooner).
  void _requestLocalNetworkAccess() {
    // Trigger local-network access (the discovery scan) and start the
    // attribution SDKs here, so the iOS prompts land on this "Allow access"
    // step rather than at app launch.
    ref.read(discoveryControllerProvider.notifier).scan();
    startMonetizationSdks();
    _next();
  }

  Future<void> _finish() async {
    // Mark onboarding complete so it's skipped on subsequent launches.
    await ref.read(remoteStoreProvider).setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DiscoveryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _OnboardingPage(
            image: 'assets/onboarding/onboarding_welcome_screen.png',
            title: 'Welcome!',
            subtitle:
                'Remote Control will help you control any TV. Complete a few '
                'steps to take full advantage of your TV!',
            actions: _OnboardingButton(label: 'Get Started', onPressed: _next),
          ),
          _OnboardingPage(
            image: 'assets/onboarding/onboarding_allow_access.png',
            title: 'Allow access',
            subtitle:
                'Enable access to the local network to discover TVs connected '
                'to your Wi-Fi',
            layout: _HeroLayout.textTop,
            actions: _OnboardingButton(
              label: 'Continue',
              onPressed: _requestLocalNetworkAccess,
            ),
          ),
          _OnboardingPage(
            image: 'assets/onboarding/onboarding_turn_on_tv.png',
            title: 'Turn on the TV',
            subtitle:
                'Please make sure your TV is turned on and connected to WiFi '
                'network',
            layout: _HeroLayout.overlay,
            actions: _OnboardingButton(
              label: 'Continue',
              // Android shows a "Rate the app" step before setup; iOS jumps
              // straight to the setup progress.
              onPressed: Platform.isAndroid ? _next : _goToSetup,
            ),
          ),
          if (Platform.isAndroid) _RatePage(onContinue: _goToSetup),
          _OnboardingPage(
            image: 'assets/onboarding/onboarding_setting_up.png',
            title: 'Setting up',
            subtitle:
                'Please wait while the application finish the configuration '
                'process',
            layout: _HeroLayout.overlay,
            glow: true,
            centerImage: true,
            imageBackground: const _RadarPulse(),
            imageForeground: const _SearchingLabel(),
            actions: AnimatedBuilder(
              animation: _setup,
              builder: (_, _) => _ProgressBar(progress: _setup.value),
            ),
          ),
        ],
      ),
    );
  }
}

/// How the hero image relates to the title and subtitle on an onboarding page.
enum _HeroLayout {
  /// Image fills the top; title, subtitle and buttons sit below it (Welcome).
  imageTop,

  /// Title and subtitle on top, image fitted in the middle (Allow access).
  textTop,

  /// Image fills the whole screen with the text overlaid on top (Turn on TV).
  overlay,
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.layout = _HeroLayout.imageTop,
    this.glow = false,
    this.centerImage = false,
    this.imageBackground,
    this.imageForeground,
  });

  final String image;
  final String title;
  final String subtitle;
  final Widget actions;
  final _HeroLayout layout;

  /// Adds a soft radial glow behind the image (overlay layout only) so a dark,
  /// transparent-background illustration reads against the black screen.
  final bool glow;

  /// Overlay layout only: centre the image vertically instead of pinning it to
  /// the top.
  final bool centerImage;

  /// Overlay layout only: a full-screen layer painted behind the image
  /// (e.g. animated radar circles).
  final Widget? imageBackground;

  /// Overlay layout only: a layer centred over the image (e.g. an icon + label).
  final Widget? imageForeground;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1.4,
          ),
        ),
      ],
    );

    // Bottom inset keeps the button at the same height across all pages.
    const bottomActions = EdgeInsets.fromLTRB(24, 8, 24, 56);

    final coverImage = Image.asset(
      image,
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );

    return switch (layout) {
      // Welcome: image bleeds behind the status bar; text + actions below it.
      _HeroLayout.imageTop => SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(child: coverImage),
              Padding(
                padding: bottomActions,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [header, const SizedBox(height: 28), actions],
                ),
              ),
            ],
          ),
        ),
      // Allow access: title + subtitle on top, image fitted in the middle.
      _HeroLayout.textTop => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: header,
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
              ),
              Padding(padding: bottomActions, child: actions),
            ],
          ),
        ),
      // Turn on the TV: image fills the whole screen (behind the status bar),
      // title + subtitle overlaid at the top, actions at the bottom.
      _HeroLayout.overlay => Stack(
          children: [
            if (glow)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.15),
                      radius: 0.75,
                      colors: [Color(0xFF33333A), Colors.transparent],
                    ),
                  ),
                ),
              ),
            if (imageBackground != null)
              Positioned.fill(child: imageBackground!),
            // fitWidth: the whole width of the image shows (no side cropping).
            if (centerImage)
              // Centred vertically at ~80% width; its bottom fades into black.
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        image,
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
                              stops: [0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Pinned to the top; gradient fades its bottom into black
              // (Turn on the TV).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Stack(
                  children: [
                    Image.asset(
                      image,
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
                            stops: [0.72, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (imageForeground != null)
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, -0.06),
                  child: imageForeground!,
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: header,
                  ),
                  const Spacer(),
                  Padding(padding: bottomActions, child: actions),
                ],
              ),
            ),
          ],
        ),
    };
  }
}

/// Android-only "Help us grow" onboarding step: the monochrome illustration and
/// a Continue button that triggers the Google Play in-app review.
class _RatePage extends StatelessWidget {
  const _RatePage({required this.onContinue});

  final VoidCallback onContinue;

  /// Ask for the Google Play in-app review, then move on regardless of whether
  /// the rating card was shown (Play decides eligibility / quota).
  Future<void> _requestReviewThenContinue() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } catch (_) {
      // Review unavailable — proceed anyway.
    }
    onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Stack(
            children: [
              Image.asset(
                'assets/onboarding/onboarding_rate_us.png',
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
                      stops: [0.72, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Help us grow',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Your feedback helps us improve the app and make it '
                      'better for everyone',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                child: _OnboardingButton(
                  label: 'Continue',
                  onPressed: _requestReviewThenContinue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Pill-shaped progress bar with a centred percentage. The label is drawn twice
/// so it stays readable: white over the dark track, dark over the white fill.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  /// 0.0 – 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.clamp(0.0, 1.0);
    final label = '${(fraction * 100).round()}%';
    const radius = BorderRadius.all(Radius.circular(16));
    const textStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: Stack(
        children: [
          // Track + white label.
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: radius,
            ),
            child: Center(
              child:
                  Text(label, style: textStyle.copyWith(color: Colors.white)),
            ),
          ),
          // White fill + dark label, revealed up to the current fraction.
          ClipRect(
            clipper: _LeftClipper(fraction),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: radius,
              ),
              child: Center(
                child:
                    Text(label, style: textStyle.copyWith(color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips its child to the left [fraction] of the available width.
class _LeftClipper extends CustomClipper<Rect> {
  const _LeftClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.fraction != fraction;
}

/// Dim white concentric rings expanding from the centre — a "radar" pulse that
/// sits behind the phone on the Setting up screen.
class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => CustomPaint(
        painter: _RadarPainter(_controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final maxRadius = size.width * 0.62;
    const rings = 3;
    for (var i = 0; i < rings; i++) {
      final t = (progress + i / rings) % 1.0;
      canvas.drawCircle(
        center,
        maxRadius * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Color.fromRGBO(255, 255, 255, (1 - t) * 0.14),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A Cupertino Wi-Fi glyph above a dim "Searching for TVs…" label, overlaid on
/// the phone.
class _SearchingLabel extends StatelessWidget {
  const _SearchingLabel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.wifi, color: Colors.white, size: 44),
        SizedBox(height: 18),
        Text(
          'Searching for TVs...',
          style: TextStyle(color: Color(0x80FFFFFF), fontSize: 16),
        ),
      ],
    );
  }
}
