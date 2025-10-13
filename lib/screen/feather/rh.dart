// humidity_gauge_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/provider/humidity_state.dart';
import 'dart:math' as math;
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HumidityGaugeScreen extends StatefulWidget {
  const HumidityGaugeScreen({super.key});

  @override
  State<HumidityGaugeScreen> createState() => _HumidityGaugeScreenState();
}

class _HumidityGaugeScreenState extends State<HumidityGaugeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the state when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final humidityState = Provider.of<HumidityState>(context, listen: false);
      humidityState.initSharedPreferences();
      humidityState.initUsb();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 40, 123, 131),
                Color.fromARGB(255, 39, 83, 87),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Consumer<HumidityState>(
            builder: (context, humidityState, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with USB status and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: humidityState.isConnected
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              humidityState.isConnected
                                  ? "Connected"
                                  : "Disconnected",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (humidityState.usbStatus.isNotEmpty)
                            Text(
                              humidityState.usbStatus.length > 20
                                  ? "${humidityState.usbStatus.substring(0, 20)}..."
                                  : humidityState.usbStatus,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Humidity Control",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Current humidity display
                  Text(
                    "Current: ${humidityState.humidity}%",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Setpoint: ${humidityState.pendingHumidity.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Gauge
                  SizedBox(
                    height: 250,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final RenderBox box =
                            context.findRenderObject() as RenderBox;
                        final offset = box.globalToLocal(
                          details.globalPosition,
                        );
                        final center = box.size.center(Offset.zero);
                        final angle = (offset - center).direction;

                        double startAngleRad = 150 * (math.pi / 180);
                        double sweepAngleRad = 240 * (math.pi / 180);

                        double normalized =
                            (angle - startAngleRad) % (2 * math.pi);
                        if (normalized < 0) normalized += 2 * math.pi;

                        double value = (normalized / sweepAngleRad) * 100;
                        value = value.clamp(0.0, 100.0);

                        humidityState.updatePendingHumidity(value);
                      },
                      child: SfRadialGauge(
                        axes: [
                          RadialAxis(
                            minimum: 0,
                            maximum: 100,
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
                                value: humidityState.pendingHumidity,
                                width: 0.2,
                                color: Colors.white,
                                cornerStyle: CornerStyle.bothCurve,
                                sizeUnit: GaugeSizeUnit.factor,
                              ),
                              MarkerPointer(
                                value: humidityState.pendingHumidity,
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
                                  "${humidityState.pendingHumidity.toStringAsFixed(1)}%",
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

                  // Debug info
                  if (humidityState.lastReceivedValue != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Last received: ${humidityState.lastReceivedValue!.length > 50 ? '${humidityState.lastReceivedValue!.substring(0, 50)}...' : humidityState.lastReceivedValue!}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ElevatedButton(
                      //   onPressed: humidityState.reconnectUsb,
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.blue,
                      //     foregroundColor: Colors.white,
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 16,
                      //       vertical: 12,
                      //     ),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(30),
                      //     ),
                      //   ),
                      //   child: const Text(
                      //     "RECONNECT",
                      //     style: TextStyle(fontSize: 12),
                      //   ),
                      // ),
                      // ElevatedButton(
                      //   onPressed: humidityState.requestStatus,
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.orange,
                      //     foregroundColor: Colors.white,
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 16,
                      //       vertical: 12,
                      //     ),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(30),
                      //     ),
                      //   ),
                      //   child: const Text(
                      //     "STATUS",
                      //     style: TextStyle(fontSize: 12),
                      //   ),
                      // ),
                      ElevatedButton(
                        onPressed: () {
                          try {
                            humidityState.sendCompleteStructure();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Humidity set to ${humidityState.pendingHumidity.toStringAsFixed(1)}%",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("USB not connected"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "SET",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
