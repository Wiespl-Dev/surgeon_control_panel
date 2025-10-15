// temp_gauge_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';
import 'dart:math' as math;
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TempGaugeScreen extends StatefulWidget {
  const TempGaugeScreen({super.key});

  @override
  State<TempGaugeScreen> createState() => _TempGaugeScreenState();
}

class _TempGaugeScreenState extends State<TempGaugeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );
      usbProvider.initUsb().then((_) {
        // Wait a bit for USB to initialize, then request status
        Future.delayed(Duration(seconds: 1), () {
          if (usbProvider.isConnected) {
            print("🔄 Screen requesting status...");
            usbProvider.requestStatus();
          }
        });
      });
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
          child: Consumer<GlobalUsbProvider>(
            builder: (context, usbProvider, child) {
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
                              color: usbProvider.isConnected
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              usbProvider.isConnected
                                  ? "Connected"
                                  : "Disconnected",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (usbProvider.usbStatus.isNotEmpty)
                            Text(
                              usbProvider.usbStatus.length > 20
                                  ? "${usbProvider.usbStatus.substring(0, 20)}..."
                                  : usbProvider.usbStatus,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          // Refresh button to request current status
                          IconButton(
                            onPressed: () {
                              if (usbProvider.isConnected) {
                                usbProvider.requestStatus();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Requesting current status...",
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white70,
                            ),
                            tooltip: "Refresh current temperature",
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Temperature Control",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Current temperature display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Current: ${usbProvider.currentTemperature}°C",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (usbProvider.currentTemperature == "--")
                        const SizedBox(width: 8),
                      if (usbProvider.currentTemperature == "--")
                        const Text(
                          "(No data)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Setpoint: ${usbProvider.pendingTemperature.toStringAsFixed(1)}°C",
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

                        double value = (normalized / sweepAngleRad) * 20 + 15;
                        value = value.clamp(15.0, 35.0);

                        usbProvider.updatePendingTemperature(value);
                      },
                      child: SfRadialGauge(
                        axes: [
                          RadialAxis(
                            minimum: 15,
                            maximum: 35,
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
                                value: usbProvider.pendingTemperature,
                                width: 0.2,
                                color: Colors.white,
                                cornerStyle: CornerStyle.bothCurve,
                                sizeUnit: GaugeSizeUnit.factor,
                              ),
                              MarkerPointer(
                                value: usbProvider.pendingTemperature,
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
                                  "${usbProvider.pendingTemperature.toStringAsFixed(1)}°C",
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
                  if (usbProvider.lastReceivedValue != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Last received: ${usbProvider.lastReceivedValue!.length > 50 ? '${usbProvider.lastReceivedValue!.substring(0, 50)}...' : usbProvider.lastReceivedValue!}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              fontFamily: 'Monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Current temp in provider: ${usbProvider.currentTemperature}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.yellow,
                              fontFamily: 'Monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          try {
                            usbProvider.sendCompleteStructure();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Temperature set to ${usbProvider.pendingTemperature.toStringAsFixed(1)}°C",
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
                      // Add a refresh button for current status
                      ElevatedButton(
                        onPressed: () {
                          if (usbProvider.isConnected) {
                            usbProvider.requestStatus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Requesting current temperature...",
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("USB not connected"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "REFRESH",
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
