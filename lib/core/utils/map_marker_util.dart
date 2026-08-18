import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_colors.dart';

class MapMarkerUtil {
  /// Converts a network image URL to a circular [BitmapDescriptor] with a border.
  static Future<BitmapDescriptor> getMarkerImageFromUrl(
    String url, {
    int targetWidth = 150,
  }) async {
    try {
      final ByteData imageData = await NetworkAssetBundle(Uri.parse(url)).load("");
      final Uint8List bytes = imageData.buffer.asUint8List();

      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final double radius = targetWidth / 2;

      // Draw border
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

      // Draw image circle
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius - 8));
      canvas.clipPath(clipPath);

      final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final Rect dst = Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetWidth.toDouble());
      canvas.drawImageRect(image, src, dst, Paint());

      final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
            targetWidth,
            targetWidth,
          );
      final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.bytes(pngBytes);
    } catch (e) {
      // Fallback to default marker if image download fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  /// Creates a fallback circular marker with initials
  static Future<BitmapDescriptor> createInitialsMarker(String name, {int targetWidth = 150}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double radius = targetWidth / 2;

    // Background circle
    final Paint paint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Text
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: initials,
      style: TextStyle(fontSize: targetWidth / 2.5, color: Colors.white, fontWeight: FontWeight.bold),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset((targetWidth - painter.width) / 2, (targetWidth - painter.height) / 2),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(targetWidth, targetWidth);
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }
}
