import 'package:flutter/material.dart';

/// The Tour Board mark. The transparent variant works on light and dark
/// backgrounds; the white-background variant is for places that need a
/// solid tile (e.g. share previews).
class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 72, this.withBackground = false, super.key});

  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) => Image.asset(
    withBackground
        ? 'assets/branding/logo_with_bg.png'
        : 'assets/branding/logo_transparent.png',
    width: size,
    height: size,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
}
