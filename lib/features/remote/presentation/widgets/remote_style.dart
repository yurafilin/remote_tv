import 'package:flutter/material.dart';

/// Shared visual tokens for the Apple-remote-style controls.
abstract final class RemoteStyle {
  static const Color icon = Colors.white;
  static const Color dot = Color(0xFF8E8E93);

  static const List<Color> _face = [Color(0xFF2C2C2E), Color(0xFF161618)];
  static const List<Color> _facePressed = [Color(0xFF202022), Color(0xFF0C0C0E)];

  static LinearGradient faceGradient({bool pressed = false}) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: pressed ? _facePressed : _face,
      );

  /// Thin top-light rim that gives the buttons their "physical" edge.
  static const Border hairline = Border.fromBorderSide(
    BorderSide(color: Color(0x14FFFFFF)),
  );

  static const List<BoxShadow> lift = [
    BoxShadow(color: Color(0xB3000000), blurRadius: 10, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x33FFFFFF), blurRadius: 26, spreadRadius: 1),
    BoxShadow(color: Color(0xB3000000), blurRadius: 10, offset: Offset(0, 6)),
  ];
}
