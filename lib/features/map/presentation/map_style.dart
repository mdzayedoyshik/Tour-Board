import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps style for dark mode (muted navy land, dark water) and a
/// light style that hides business clutter so itinerary pins stand out.
abstract final class MapStyles {
  static String forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;

  static const light = '''
[
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","elementType":"labels.icon","stylers":[{"saturation":-60},{"lightness":15}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#b9dcf5"}]}
]''';

  static const dark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1b2230"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#a6b0c2"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d1117"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3b4454"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#222a38"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1d3329"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2a3342"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1b2230"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a4558"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e2a47"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5b7fa8"}]}
]''';
}

/// Draws crisp numbered/colored pins at device resolution and caches them.
class MarkerPainter {
  MarkerPainter._();

  static final _cache = <String, BitmapDescriptor>{};

  /// A teardrop pin with [label] (e.g. stop number) in [color].
  static Future<BitmapDescriptor> pin({
    required Color color,
    required String label,
    required double devicePixelRatio,
    bool selected = false,
  }) async {
    final key = '${color.toARGB32()}|$label|$devicePixelRatio|$selected';
    final cached = _cache[key];
    if (cached != null) return cached;

    final logical = selected ? 46.0 : 38.0;
    final scale = devicePixelRatio;
    final width = logical * scale;
    final height = logical * 1.3 * scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final r = width / 2;

    // Soft shadow.
    canvas.drawCircle(
      Offset(r, r + 2 * scale),
      r * 0.92,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale),
    );
    // Pointer.
    final tip = Path()
      ..moveTo(r - r * 0.45, r * 1.55)
      ..lineTo(r, height - 1 * scale)
      ..lineTo(r + r * 0.45, r * 1.55)
      ..close();
    canvas.drawPath(tip, Paint()..color = color);
    // Body with white ring.
    canvas.drawCircle(Offset(r, r), r * 0.94, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(r, r), r * 0.78, Paint()..color = color);

    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: (label.length > 2 ? 11 : 14) * scale,
          fontWeight: FontWeight.w800,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(r - text.width / 2, r - text.height / 2));

    final image = await recorder.endRecording().toImage(
      width.ceil(),
      height.ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      Uint8List.view(bytes!.buffer),
      imagePixelRatio: scale,
    );
    _cache[key] = descriptor;
    return descriptor;
  }
}
