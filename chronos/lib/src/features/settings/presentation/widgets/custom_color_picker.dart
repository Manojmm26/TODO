import 'dart:math' as math;
import 'package:flutter/material.dart';

class HueRingPicker extends StatefulWidget {
  const HueRingPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  State<HueRingPicker> createState() => _HueRingPickerState();
}

class _HueRingPickerState extends State<HueRingPicker> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Hue Ring
          GestureDetector(
            onPanUpdate: _handleGesture,
            onTapDown: _handleGesture,
            child: CustomPaint(
              size: const Size(260, 260),
              painter: _HueRingPainter(),
            ),
          ),
          // Center Preview
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
          ),
          // Thumb Indicator
          IgnorePointer(
            child: CustomPaint(
              size: const Size(260, 260),
              painter: _ThumbPainter(color: widget.color),
            ),
          ),
        ],
      ),
    );
  }

  void _handleGesture(dynamic details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final Offset center = Offset(box.size.width / 2, box.size.height / 2);
    final Offset delta = localPosition - center;

    // Calculate angle in radians
    double angle = math.atan2(delta.dy, delta.dx);

    // Convert angle to hue (0-360)
    // atan2 returns -pi to pi. We need 0 to 2pi.
    if (angle < 0) angle += 2 * math.pi;

    // Map 0-2pi to 0-360
    final double hue = (angle * 180 / math.pi) % 360;

    final HSVColor hsv = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0);
    widget.onColorChanged(hsv.toColor());
  }
}

class _HueRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;
    final double strokeWidth = 30.0;

    final Rect rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    const List<Color> colors = [
      Color(0xFFFF0000), // Red
      Color(0xFFFFFF00), // Yellow
      Color(0xFF00FF00), // Green
      Color(0xFF00FFFF), // Cyan
      Color(0xFF0000FF), // Blue
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFF0000), // Red again to close loop
    ];

    final Gradient gradient = SweepGradient(colors: colors);

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius =
        size.shortestSide / 2 - 15; // Center of the ring track

    final HSVColor hsv = HSVColor.fromColor(color);
    final double angle = (hsv.hue * math.pi / 180);

    final double thumbX = center.dx + radius * math.cos(angle);
    final double thumbY = center.dy + radius * math.sin(angle);
    final Offset thumbCenter = Offset(thumbX, thumbY);

    // Draw thumb shadow
    canvas.drawCircle(
      thumbCenter,
      14,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Draw thumb border
    canvas.drawCircle(thumbCenter, 12, Paint()..color = Colors.white);

    // Draw thumb color
    canvas.drawCircle(thumbCenter, 10, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter oldDelegate) =>
      oldDelegate.color != color;
}
