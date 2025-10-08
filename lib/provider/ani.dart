// ----------------------------- Animated Counter Widget -----------------------------
import 'dart:math';

import 'package:flutter/material.dart';

class _AnimatedCounter extends StatefulWidget {
  final String value;
  const _AnimatedCounter({Key? key, required this.value}) : super(key: key);

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _currentValue = "0";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _updateValue();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateValue();
    }
  }

  void _updateValue() {
    final start = double.tryParse(_currentValue) ?? 0.0;
    final end = double.tryParse(widget.value) ?? 0.0;
    _animation = Tween<double>(
      begin: start,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _currentValue = _animation.value.toStringAsFixed(
          _animation.value.truncateToDouble() == _animation.value ? 0 : 1,
        );
        return Text(
          _currentValue,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

// ----------------------------- SimpleSeparatorPainter -----------------------------
class SimpleSeparatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SimpleSeparatorPainter oldDelegate) => false;
}

// ----------------------------- Particles and Background (same as provided) -----------------------------
class MedicalParticle {
  double x, y, size, vx, vy, opacity;
  final Random _random;

  MedicalParticle(this._random)
    : x = _random.nextDouble(),
      y = _random.nextDouble(),
      size = _random.nextDouble() * 2 + 0.6,
      vx = _random.nextDouble() * 0.0008 - 0.0004,
      vy = _random.nextDouble() * 0.0008 - 0.0004,
      opacity = 0.06 + _random.nextDouble() * 0.06;

  void update(double t) {
    x += vx + 0.0002 * sin(t * 2 * pi + x * 10);
    y += vy + 0.0002 * cos(t * 2 * pi + y * 10);

    if (x < -0.02) x = 1.02;
    if (x > 1.02) x = -0.02;
    if (y < -0.02) y = 1.02;
    if (y > 1.02) y = -0.02;
  }
}

class ClinicalBackgroundPainter extends CustomPainter {
  final double t; // 0..1
  final List<MedicalParticle> particles;
  ClinicalBackgroundPainter({required this.t, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gT = (sin(t * 2 * pi) + 1) / 2 * 0.2;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF0F3D3E), const Color(0xFF2C6975), gT)!,
        Color.lerp(const Color(0xFF144552), const Color(0xFF205375), gT)!,
        Color.lerp(const Color(0xFF16324F), const Color(0xFF112031), gT)!,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;
    const double step = 40;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final rayPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.07), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final rayPath = Path()
      ..moveTo(size.width * (0.15 + t * 0.05), 0)
      ..lineTo(size.width * (0.35 + t * 0.05), 0)
      ..lineTo(size.width * (0.75 + t * 0.05), size.height)
      ..lineTo(size.width * (0.55 + t * 0.05), size.height)
      ..close();
    canvas.drawPath(rayPath, rayPaint);

    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * (0.35 + 0.05 * sin(t * 2 * pi))),
      120,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * (0.65 + 0.05 * cos(t * 2 * pi))),
      100,
      glowPaint,
    );

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      p.update(t);
      dotPaint.color = Colors.white.withOpacity(p.opacity);
      final cx = p.x * size.width;
      final cy = p.y * size.height;
      canvas.drawCircle(Offset(cx, cy), p.size, dotPaint);
    }

    _drawECG(canvas, size, t);
  }

  void _drawECG(Canvas canvas, Size size, double phase) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final amplitude = size.height * 0.03;
    final baselineY = size.height * 0.22;
    final speed = 0.6;
    final offsetX = phase * size.width * speed;

    bool first = true;
    for (double x = -size.width; x <= size.width * 2; x += 4) {
      final local = (x / 80.0);
      final beat = sin(local * 2 * pi);
      final spike = exp(-pow((local % 6.0) - 3.0, 2)) * 6.0;
      final yOffset = beat * amplitude * 0.6 + (spike * amplitude * 0.12);
      final px = x - offsetX % (size.width * 1.2);
      final py = baselineY + yOffset + 4 * sin((phase * 2 * pi) + x * 0.01);
      if (first) {
        path.moveTo(px, py);
        first = false;
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ClinicalBackgroundPainter oldDelegate) => true;
}
