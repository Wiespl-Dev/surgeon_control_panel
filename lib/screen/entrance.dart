import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/main.dart';
import 'package:surgeon_control_panel/provider/or_status_provider.dart';

class ORStatusMonitor extends StatefulWidget {
  @override
  State<ORStatusMonitor> createState() => _ORStatusMonitorState();
}

class _ORStatusMonitorState extends State<ORStatusMonitor>
    with TickerProviderStateMixin {
  // UI animations
  late AnimationController _cardController;
  late Animation<Offset> _cardSlideAnimation;
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Date and time
  late Timer _dateTimeTimer;
  DateTime _currentDateTime = DateTime.now();

  final Random _random = Random();
  final List<MedicalParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ORStatusProvider>(context, listen: false);
      provider.initPreferences().then((_) => provider.initUsb());
    });

    // particles
    for (int i = 0; i < 18; i++) {
      _particles.add(MedicalParticle(_random));
    }

    // animations
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardController.forward();

    // Initialize date/time timer
    _dateTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    _dateTimeTimer.cancel();

    // Cleanup USB
    final provider = Provider.of<ORStatusProvider>(context, listen: false);
    provider.disposeUsb();

    super.dispose();
  }

  Future<void> _logout() async {
    // Handle logout logic here
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // Date and time formatting methods
  String _formattedDate() {
    return "${_currentDateTime.day.toString().padLeft(2, '0')} ${_monthName(_currentDateTime.month)} ${_currentDateTime.year}";
  }

  String _formattedTime() {
    final hour = _currentDateTime.hour > 12
        ? _currentDateTime.hour - 12
        : (_currentDateTime.hour == 0 ? 12 : _currentDateTime.hour);
    final ampm = _currentDateTime.hour >= 12 ? "PM" : "AM";
    return "${hour.toString()}:${_currentDateTime.minute.toString().padLeft(2, '0')} $ampm";
  }

  String _monthName(int m) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m - 1];
  }

  // Method to format pressure value with color and proper decimal format
  Widget _buildPressureValue(ORStatusProvider provider) {
    String displayValue;
    Color textColor;

    if (provider.isPressurePositive) {
      double decimalValue = provider.pressure1 / 100.0;
      displayValue = decimalValue.toStringAsFixed(2);
      textColor = Colors.greenAccent;
    } else {
      double decimalValue = provider.pressure1.abs() / 100.0;
      displayValue = "-${decimalValue.toStringAsFixed(2)}";
      textColor = Colors.redAccent;
    }

    return Text(
      displayValue,
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ORStatusProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF3D8A8F),
          body: Stack(
            children: [
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ClinicalBackgroundPainter(
                      t: _bgController.value,
                      particles: _particles,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            "assets/app_logo-removebg-preview.png",
                            height: 70,
                          ),
                          Row(
                            children: [
                              // USB status indicator
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: provider.isConnected
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Refresh button for sensor data
                              IconButton(
                                onPressed: provider.requestSensorData,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                tooltip: "Refresh Sensor Data",
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white70,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "OR Status Monitor",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SlideTransition(
                          position: _cardSlideAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Line 1: Temperature, R/H, and Room Pressure
                                _buildThreeItemRow(
                                  item1: _statusTile(
                                    title: "Temperature",
                                    value: provider.temperature.toStringAsFixed(
                                      1,
                                    ),
                                    unit: "°C",
                                    icon: Icons.thermostat_outlined,
                                  ),
                                  item2: _statusTile(
                                    title: "R/H",
                                    value: provider.humidity.toStringAsFixed(1),
                                    unit: "%",
                                    icon: Icons.water_drop_outlined,
                                  ),
                                  item3: _pressureStatusTile(
                                    title: "Room Pressure",
                                    icon: Icons.compress_outlined,
                                    provider: provider,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                CustomPaint(
                                  size: Size(
                                    MediaQuery.of(context).size.width,
                                    34,
                                  ),
                                  painter: SimpleSeparatorPainter(),
                                ),
                                // Line 2: Time and Date
                                _buildStatusRow(
                                  title1: "Time",
                                  value1: _formattedTime(),
                                  icon1: Icons.access_time_outlined,
                                  title2: "Date",
                                  value2: _formattedDate(),
                                  icon2: Icons.calendar_today_outlined,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _customToggle(
                            label: "Defumigation",
                            value: provider.defumigation,
                            icon: Icons.wb_cloudy_outlined,
                            onChanged: provider.toggleDefumigation,
                          ),
                          _customToggle(
                            label: "System",
                            value: provider.systemOn,
                            icon: Icons.power_settings_new,
                            onChanged: provider.toggleSystem,
                          ),
                          _customToggle(
                            label: "Night",
                            value: provider.nightMode,
                            icon: Icons.mode_night_outlined,
                            onChanged: provider.toggleNightMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ... (Keep all your existing UI helper methods: _buildThreeItemRow, _buildStatusRow,
  // _statusTile, _pressureStatusTile, _customToggle, etc. They remain the same)
  // Just update _pressureStatusTile to accept provider parameter:

  Widget _pressureStatusTile({
    required String title,
    required IconData icon,
    required ORStatusProvider provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(icon, color: Colors.white70, size: 22),
                );
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _buildPressureValue(provider),
            const SizedBox(width: 6),
            const Text(
              "Pa",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ... (Keep all other UI methods exactly as they were)
  Widget _buildThreeItemRow({
    required Widget item1,
    required Widget item2,
    required Widget item3,
  }) {
    return Row(
      children: [
        Expanded(child: item1),
        const SizedBox(width: 12),
        Expanded(child: item2),
        const SizedBox(width: 12),
        Expanded(child: item3),
      ],
    );
  }

  Widget _buildStatusRow({
    required String title1,
    required String value1,
    String? unit1,
    required IconData icon1,
    required String title2,
    required String value2,
    String? unit2,
    required IconData icon2,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statusTile(
            title: title1,
            value: value1,
            unit: unit1,
            icon: icon1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statusTile(
            title: title2,
            value: value2,
            unit: unit2,
            icon: icon2,
          ),
        ),
      ],
    );
  }

  Widget _statusTile({
    required String title,
    required String value,
    String? unit,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(icon, color: Colors.white70, size: 22),
                );
              },
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (title == "Date" || title == "Time")
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            else
              _AnimatedCounter(value: value),
            if (unit != null)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _customToggle({
    required String label,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Flexible(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              width: 56,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? const Color(0xFF2ECC71) : Colors.white24,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Keep all your existing helper classes: _AnimatedCounter, SimpleSeparatorPainter,
// MedicalParticle, ClinicalBackgroundPainter exactly as they were)
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
