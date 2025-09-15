import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TemperatureGaugeScreen extends StatefulWidget {
  const TemperatureGaugeScreen({super.key});

  @override
  State<TemperatureGaugeScreen> createState() => _TemperatureGaugeScreenState();
}

class _TemperatureGaugeScreenState extends State<TemperatureGaugeScreen> {
  final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.0.100:8080'),
  );

  double _temperature = 23.0;
  double _pendingTemperature = 23.0;

  Map<String, dynamic> dataMap = {};
  bool dataInitialized = false;

  @override
  void initState() {
    super.initState();
    channel.stream.listen((message) {
      final parsed = _parseMessage(message);
      final tempStr = parsed["S_TEMP_SETPT"];
      if (tempStr != null) {
        final parsedTemp = (int.tryParse(tempStr) ?? 230) / 10.0;
        setState(() {
          dataMap = parsed;
          _temperature = parsedTemp;
          _pendingTemperature = parsedTemp;
          dataInitialized = true;
        });
      }
    });
  }

  Map<String, dynamic> _parseMessage(String message) {
    final parts = message.replaceFirst('{,', '').replaceAll('}', '').split(',');
    final map = <String, dynamic>{};
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

  void _sendTemperatureUpdate() {
    final int temp = (_pendingTemperature * 10).round();
    final tempStr = temp.toString().padLeft(3, '0');
    dataMap["S_TEMP_SETPT"] = tempStr;

    final updatedMessage =
        "{,${dataMap.entries.map((e) => "${e.key}:${e.value}").join(",")}}";

    channel.sink.add(updatedMessage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Temperature set to ${_pendingTemperature.toStringAsFixed(1)}°C",
        ),
      ),
    );

    setState(() {
      _temperature = _pendingTemperature;
    });
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
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
                    icon: Icon(Icons.close, color: Colors.white70, size: 26),
                  ),
                ],
              ),
              const Text(
                "Temperature",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Current Setpoint: ${_temperature.toStringAsFixed(1)}°C",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final position = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    final center = renderBox.size.center(Offset.zero);
                    final angle = (position - center).direction;

                    double startAngleRad = 150 * (math.pi / 180);
                    double sweepAngleRad = 240 * (math.pi / 180);

                    double normalizedAngle =
                        (angle - startAngleRad) % (2 * math.pi);
                    if (normalizedAngle < 0) {
                      normalizedAngle += 2 * math.pi;
                    }

                    double value = (normalizedAngle / sweepAngleRad) * 17 + 16;
                    value = value.clamp(16.0, 33.0);

                    setState(() {
                      _pendingTemperature = value;
                    });
                  },
                  child: SfRadialGauge(
                    axes: [
                      RadialAxis(
                        minimum: 16,
                        maximum: 33,
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
                            value: _pendingTemperature,
                            width: 0.2,
                            color: Colors.white,
                            cornerStyle: CornerStyle.bothCurve,
                            sizeUnit: GaugeSizeUnit.factor,
                          ),
                          MarkerPointer(
                            value: _pendingTemperature,
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
                              "${_pendingTemperature.toStringAsFixed(1)}°C",
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
                onPressed: _sendTemperatureUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
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
