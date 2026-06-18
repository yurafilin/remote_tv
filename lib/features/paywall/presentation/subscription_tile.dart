import 'package:flutter/material.dart';

import '../domain/subscription_pricing.dart';

/// Adapted from the spec's DSColor tokens to the app's monochrome palette.
const Color _primary = Colors.white; // labelPrimary / "primary"
const Color _secondary = Colors.white60; // labelSecondary / "secondary"

/// iOS "Subheadline" text size.
const double _subheadline = 15;

/// A selectable subscription option. The title/subtitle text follows the
/// product spec; the card + radio is the selection chrome for the paywall.
class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({
    super.key,
    required this.pricing,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPricing pricing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E1E22) : const Color(0xFF161618),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : const Color(0x1FFFFFFF),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: pricing.hasTrial ? _trial() : _standard()),
            const SizedBox(width: 12),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }

  // Top: "<price> / <period>". Bottom: a white "3 days free trial" badge.
  Widget _trial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _topLine(),
        const SizedBox(height: 7),
        _TrialBadge(label: pricing.trialLabel!),
      ],
    );
  }

  // Top: "<price> / <period>". Bottom: "Only <price-per-month> per month".
  Widget _standard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _topLine(),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Only ', style: _style(_secondary)),
              TextSpan(
                text: pricing.perMonthText,
                style: _style(_primary, FontWeight.w600),
              ),
              TextSpan(text: ' per month', style: _style(_secondary)),
            ],
          ),
        ),
      ],
    );
  }

  // "<price> / <period>" — price emphasised, period muted.
  Widget _topLine() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: pricing.priceText,
            style: _style(_primary, FontWeight.w600),
          ),
          TextSpan(
            text: ' / ${pricing.periodLabel}',
            style: _style(_secondary),
          ),
        ],
      ),
    );
  }

  TextStyle _style(Color color, [FontWeight weight = FontWeight.w400]) =>
      TextStyle(
        color: color,
        fontSize: _subheadline,
        fontWeight: weight,
        height: 1.25,
      );
}

class _TrialBadge extends StatelessWidget {
  const _TrialBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white : Colors.transparent,
        border: Border.all(
          color: selected ? Colors.white : const Color(0x59FFFFFF),
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.black)
          : null,
    );
  }
}
