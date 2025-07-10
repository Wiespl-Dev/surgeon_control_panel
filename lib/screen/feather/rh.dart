import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RhGaugeScreen extends StatefulWidget {
  const RhGaugeScreen({super.key});

  @override
  State<RhGaugeScreen> createState() => _RhGaugeScreenState();
}

class _RhGaugeScreenState extends State<RhGaugeScreen> {
  double _pendingHumidity = 50.0;
  String? lastReceivedValue;
  String? lastSentMessage;

  final WebSocketChannel channel =
      WebSocketChannel.connect(Uri.parse('ws://192.168.0.100:8080'));

  @override
  void initState() {
    super.initState();
    channel.stream.listen((message) {
      final parsed = _parseMessage(message);
      final rhValue = parsed["S_RH_SETPT"];
      if (rhValue != null) {
        setState(() {
          lastReceivedValue = rhValue;
          _pendingHumidity = (int.tryParse(rhValue) ?? 500) / 10.0;
        });
      }
    });
  }

  Map<String, String> _parseMessage(String message) {
    final parts = message.replaceFirst('{,', '').replaceAll('}', '').split(',');
    final map = <String, String>{};
    for (var part in parts) {
      if (part.contains(':')) {
        final kv = part.split(':');
        if (kv.length == 2) {
          map[kv[0]] = kv[1];
        }
      }
    }
    return map;
  }

  void _sendHumidityUpdate() {
    final int rhInt = (_pendingHumidity * 10).round();
    final formatted = rhInt.toString().padLeft(3, '0');
    final message = "{,SR_WSL:000000,S_RH_SETPT:$formatted}";

    channel.sink.add(message);
    setState(() {
      lastSentMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text("Humidity set to ${_pendingHumidity.toStringAsFixed(1)}%")),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(205, 157, 102, 228),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      ))
                ],
              ),
              const Text(
                "Humidity Control",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "Current Setpoint: ${_pendingHumidity.toStringAsFixed(1)}°C",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 250,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final offset = box.globalToLocal(details.globalPosition);
                    final center = box.size.center(Offset.zero);
                    final angle = (offset - center).direction;

                    double startAngleRad = 150 * (math.pi / 180);
                    double sweepAngleRad = 240 * (math.pi / 180);

                    double normalized = (angle - startAngleRad) % (2 * math.pi);
                    if (normalized < 0) normalized += 2 * math.pi;

                    double value = (normalized / sweepAngleRad) * 20 + 40;
                    value = value.clamp(40.0, 60.0);

                    setState(() {
                      _pendingHumidity = value;
                    });
                  },
                  child: SfRadialGauge(
                    axes: [
                      RadialAxis(
                        minimum: 40,
                        maximum: 60,
                        startAngle: 150,
                        endAngle: 30,
                        showTicks: false,
                        showLabels: false,
                        axisLineStyle: const AxisLineStyle(
                          thickness: 0.2,
                          thicknessUnit: GaugeSizeUnit.factor,
                          color: Colors.white24,
                        ),
                        pointers: [
                          RangePointer(
                            value: _pendingHumidity,
                            width: 0.2,
                            color: Colors.white,
                            cornerStyle: CornerStyle.bothCurve,
                            sizeUnit: GaugeSizeUnit.factor,
                          ),
                          MarkerPointer(
                            value: _pendingHumidity,
                            markerType: MarkerType.circle,
                            color: Colors.white,
                            markerHeight: 20,
                            markerWidth: 20,
                          ),
                        ],
                        annotations: [
                          GaugeAnnotation(
                            angle: 90,
                            positionFactor: 0,
                            widget: Text(
                              "${_pendingHumidity.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendHumidityUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("SET", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
