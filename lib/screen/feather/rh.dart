// // humidity_gauge_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:provider/provider.dart';
// import 'package:surgeon_control_panel/services/usb_service.dart';
// import 'dart:math' as math;
// import 'package:syncfusion_flutter_gauges/gauges.dart';

// class HumidityGaugeScreen extends StatefulWidget {
//   const HumidityGaugeScreen({super.key});

//   @override
//   State<HumidityGaugeScreen> createState() => _HumidityGaugeScreenState();
// }

// class _HumidityGaugeScreenState extends State<HumidityGaugeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final usbProvider = Provider.of<GlobalUsbProvider>(
//         context,
//         listen: false,
//       );
//       usbProvider.initUsb().then((_) {
//         // Wait a bit for USB to initialize, then request status
//         Future.delayed(Duration(seconds: 1), () {
//           if (usbProvider.isConnected) {
//             print("🔄 Screen requesting status...");
//             // usbProvider.requestStatus();
//           }
//         });
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF3D8A8F),
//       body: Center(
//         child: Container(
//           margin: const EdgeInsets.all(24),
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             gradient: const LinearGradient(
//               colors: [
//                 Color.fromARGB(255, 40, 123, 131),
//                 Color.fromARGB(255, 39, 83, 87),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Consumer<GlobalUsbProvider>(
//             builder: (context, usbProvider, child) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Header with USB status and close button
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: usbProvider.isConnected
//                                   ? Colors.transparent
//                                   : Colors.red,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             // child: Text(
//                             //   usbProvider.isConnected
//                             //       ? "Connected"
//                             //       : "Disconnected",
//                             //   style: const TextStyle(
//                             //     color: Colors.white,
//                             //     fontSize: 12,
//                             //     fontWeight: FontWeight.bold,
//                             //   ),
//                             // ),
//                           ),
//                           // if (usbProvider.usbStatus.isNotEmpty)
//                           //   Text(
//                           //     usbProvider.usbStatus.length > 20
//                           //         ? "${usbProvider.usbStatus.substring(0, 20)}..."
//                           //         : usbProvider.usbStatus,
//                           //     style: const TextStyle(
//                           //       color: Colors.white70,
//                           //       fontSize: 10,
//                           //     ),
//                           //   ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           // Refresh button to request current status
//                           // IconButton(
//                           //   onPressed: () {
//                           //     if (usbProvider.isConnected) {
//                           //       // usbProvider.requestStatus();
//                           //       ScaffoldMessenger.of(context).showSnackBar(
//                           //         const SnackBar(
//                           //           content: Text(
//                           //             "Requesting current status...",
//                           //           ),
//                           //           backgroundColor: Colors.blue,
//                           //         ),
//                           //       );
//                           //     }
//                           //   },
//                           //   icon: const Icon(
//                           //     Icons.refresh,
//                           //     color: Colors.white70,
//                           //   ),
//                           //   tooltip: "Refresh current humidity",
//                           // ),
//                           IconButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             icon: const Icon(
//                               Icons.close,
//                               color: Colors.white70,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 10),

//                   const Text(
//                     "Humidity Control",
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   // Current humidity display
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         "Current: ${usbProvider.currentHumidity}%",
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       // if (usbProvider.currentHumidity == "--")
//                       //   const SizedBox(width: 8),
//                       // if (usbProvider.currentHumidity == "--")
//                       //   const Text(
//                       //     "(No data)",
//                       //     style: TextStyle(
//                       //       fontSize: 12,
//                       //       color: Colors.white70,
//                       //       fontStyle: FontStyle.italic,
//                       //     ),
//                       //   ),
//                     ],
//                   ),

//                   const SizedBox(height: 10),

//                   Text(
//                     "Setpoint: ${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.black,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Gauge
//                   SizedBox(
//                     height: 250,
//                     child: GestureDetector(
//                       onPanUpdate: (details) {
//                         final RenderBox box =
//                             context.findRenderObject() as RenderBox;
//                         final offset = box.globalToLocal(
//                           details.globalPosition,
//                         );
//                         final center = box.size.center(Offset.zero);
//                         final angle = (offset - center).direction;

//                         double startAngleRad = 150 * (math.pi / 180);
//                         double sweepAngleRad = 240 * (math.pi / 180);

//                         double normalized =
//                             (angle - startAngleRad) % (2 * math.pi);
//                         if (normalized < 0) normalized += 2 * math.pi;

//                         double value = (normalized / sweepAngleRad) * 100;
//                         value = value.clamp(0.0, 100.0);

//                         usbProvider.updatePendingHumidity(value);
//                       },
//                       child: SfRadialGauge(
//                         axes: [
//                           RadialAxis(
//                             minimum: 0,
//                             maximum: 100,
//                             startAngle: 150,
//                             endAngle: 30,
//                             showTicks: false,
//                             showLabels: false,
//                             axisLineStyle: const AxisLineStyle(
//                               thickness: 0.2,
//                               thicknessUnit: GaugeSizeUnit.factor,
//                               color: Colors.white24,
//                             ),
//                             pointers: [
//                               RangePointer(
//                                 value: usbProvider.pendingHumidity,
//                                 width: 0.2,
//                                 color: Colors.white,
//                                 cornerStyle: CornerStyle.bothCurve,
//                                 sizeUnit: GaugeSizeUnit.factor,
//                               ),
//                               MarkerPointer(
//                                 value: usbProvider.pendingHumidity,
//                                 markerType: MarkerType.circle,
//                                 color: Colors.white,
//                                 markerHeight: 20,
//                                 markerWidth: 20,
//                               ),
//                             ],
//                             annotations: [
//                               GaugeAnnotation(
//                                 angle: 90,
//                                 positionFactor: 0,
//                                 widget: Text(
//                                   "${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
//                                   style: const TextStyle(
//                                     fontSize: 32,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   // const SizedBox(height: 20),

//                   // // Debug info
//                   // if (usbProvider.lastReceivedValue != null)
//                   //   Container(
//                   //     width: double.infinity,
//                   //     padding: const EdgeInsets.all(8),
//                   //     decoration: BoxDecoration(
//                   //       color: Colors.black12,
//                   //       borderRadius: BorderRadius.circular(8),
//                   //     ),
//                   //     child: Column(
//                   //       crossAxisAlignment: CrossAxisAlignment.start,
//                   //       children: [
//                   //         Text(
//                   //           "Last received: ${usbProvider.lastReceivedValue!.length > 50 ? '${usbProvider.lastReceivedValue!.substring(0, 50)}...' : usbProvider.lastReceivedValue!}",
//                   //           style: const TextStyle(
//                   //             fontSize: 10,
//                   //             color: Colors.white70,
//                   //             fontFamily: 'Monospace',
//                   //           ),
//                   //         ),
//                   //         const SizedBox(height: 4),
//                   //         Text(
//                   //           "Current humidity in provider: ${usbProvider.currentHumidity}",
//                   //           style: const TextStyle(
//                   //             fontSize: 10,
//                   //             color: Colors.yellow,
//                   //             fontFamily: 'Monospace',
//                   //           ),
//                   //         ),
//                   //       ],
//                   //     ),
//                   //   ),
//                   const SizedBox(height: 10),

//                   // Action buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton(
//                         onPressed: () {
//                           try {
//                             usbProvider.sendCompleteStructure();
//                             // ScaffoldMessenger.of(context).showSnackBar(
//                             //   SnackBar(
//                             //     content: Text(
//                             //       "Humidity set to ${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
//                             //     ),
//                             //     backgroundColor: Colors.green,
//                             //   ),
//                             // );

//                             Get.snackbar(
//                               "Humidity set to",
//                               "${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
//                               snackPosition: SnackPosition.TOP,
//                               colorText: Colors.white,
//                             );
//                             Navigator.pop(context);
//                           } catch (e) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text("USB not connected"),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 30,
//                             vertical: 12,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         child: const Text(
//                           "SET",
//                           style: TextStyle(fontSize: 14),
//                         ),
//                       ),
//                       // Add a refresh button for current status
//                       // ElevatedButton(
//                       //   onPressed: () {
//                       //     if (usbProvider.isConnected) {
//                       //       // usbProvider.requestStatus();
//                       //       ScaffoldMessenger.of(context).showSnackBar(
//                       //         const SnackBar(
//                       //           content: Text("Requesting current humidity..."),
//                       //           backgroundColor: Colors.blue,
//                       //         ),
//                       //       );
//                       //     } else {
//                       //       ScaffoldMessenger.of(context).showSnackBar(
//                       //         const SnackBar(
//                       //           content: Text("USB not connected"),
//                       //           backgroundColor: Colors.red,
//                       //         ),
//                       //       );
//                       //     }
//                       //   },
//                       //   style: ElevatedButton.styleFrom(
//                       //     backgroundColor: Colors.blue,
//                       //     foregroundColor: Colors.white,
//                       //     padding: const EdgeInsets.symmetric(
//                       //       horizontal: 20,
//                       //       vertical: 12,
//                       //     ),
//                       //     shape: RoundedRectangleBorder(
//                       //       borderRadius: BorderRadius.circular(30),
//                       //     ),
//                       //   ),
//                       //   child: const Text(
//                       //     "REFRESH",
//                       //     style: TextStyle(fontSize: 14),
//                       //   ),
//                       // ),
//                     ],
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';
import 'dart:math' as math;
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HumidityGaugeScreen extends StatefulWidget {
  const HumidityGaugeScreen({super.key});

  @override
  State<HumidityGaugeScreen> createState() => _HumidityGaugeScreenState();
}

class _HumidityGaugeScreenState extends State<HumidityGaugeScreen> {
  bool _isSettingValue = false;
  DateTime? _lastSetTime;
  static const Duration _minSetInterval = Duration(seconds: 2);
  int _setAttemptCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );
      if (!usbProvider.isConnected) {
        usbProvider.initUsb().then((_) {
          Future.delayed(const Duration(seconds: 1), () {
            if (usbProvider.isConnected) {
              print("🔄 Humidity screen initialized - requesting status...");
              usbProvider.sendCompleteStructure();
            }
          });
        });
      } else {
        usbProvider.sendCompleteStructure();
      }
    });
  }

  void _handleGaugeInteraction(Offset localPosition, Size gaugeSize) {
    final center = gaugeSize.center(Offset.zero);
    final angle = (localPosition - center).direction;

    double startAngleRad = 150 * (math.pi / 180);
    double endAngleRad = 30 * (math.pi / 180);

    double normalizedAngle = angle;
    if (normalizedAngle < startAngleRad) {
      normalizedAngle += 2 * math.pi;
    }

    double value =
        ((normalizedAngle - startAngleRad) /
            (endAngleRad - startAngleRad + 2 * math.pi)) *
        100;
    value = value.clamp(0.0, 100.0);

    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
    usbProvider.updatePendingHumidity(value);
  }

  Future<void> _setHumidity() async {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    if (_isSettingValue) {
      print("⏳ Already setting humidity, please wait");
      return;
    }

    if (!usbProvider.isConnected) {
      Get.snackbar(
        "Error",
        "USB not connected",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    final now = DateTime.now();
    if (_lastSetTime != null &&
        now.difference(_lastSetTime!) < _minSetInterval) {
      print("⏳ Please wait before setting again");
      Get.snackbar(
        "Please Wait",
        "Wait a moment before setting again",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      );
      return;
    }

    setState(() {
      _isSettingValue = true;
      _setAttemptCount++;
    });

    try {
      print(
        "🎯 Setting humidity to: ${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
      );

      _lastSetTime = DateTime.now();
      usbProvider.sendHumidityStructure();

      Get.snackbar(
        "Success",
        "Humidity set to ${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      await Future.delayed(const Duration(milliseconds: 1800));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Error setting humidity: $e");
      Get.snackbar(
        "Set Failed",
        "Failed to set humidity: ${e.toString().split('\n').first}",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSettingValue = false;
        });
      }
    }
  }

  Color _getButtonColor(GlobalUsbProvider usbProvider) {
    if (!usbProvider.isConnected) return Colors.grey;
    if (_isSettingValue) return Colors.blue;
    return Colors.black;
  }

  Widget _buildButtonContent(GlobalUsbProvider usbProvider) {
    if (_isSettingValue) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "SETTING...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Text(
      usbProvider.isConnected ? "SET HUMIDITY" : "USB DISCONNECTED",
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height and adjust layout accordingly
            final availableHeight = constraints.maxHeight;
            final isSmallScreen = availableHeight < 600;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Consumer<GlobalUsbProvider>(
                      builder: (context, usbProvider, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header - Fixed height
                            SizedBox(
                              height: isSmallScreen ? 40 : 50,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // USB Status Indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: usbProvider.isConnected
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: usbProvider.isConnected
                                            ? Colors.green
                                            : Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          usbProvider.isConnected
                                              ? Icons.usb
                                              : Icons.usb_off,
                                          color: usbProvider.isConnected
                                              ? Colors.green
                                              : Colors.red,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          usbProvider.isConnected
                                              ? "CONNECTED"
                                              : "DISCONNECTED",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            fontWeight: FontWeight.bold,
                                            color: usbProvider.isConnected
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Title
                                  Text(
                                    "Humidity Control",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  // Close Button
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Current and Setpoint Display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        "Current",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${usbProvider.humidity}%",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.white30,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        "Setpoint",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Gauge with flexible height
                            Flexible(
                              child: Container(
                                height: isSmallScreen ? 180 : 220,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return GestureDetector(
                                      onPanUpdate: (details) {
                                        final box =
                                            context.findRenderObject()
                                                as RenderBox;
                                        final localPosition = box.globalToLocal(
                                          details.globalPosition,
                                        );
                                        _handleGaugeInteraction(
                                          localPosition,
                                          constraints.biggest,
                                        );
                                      },
                                      onTapDown: (details) {
                                        final box =
                                            context.findRenderObject()
                                                as RenderBox;
                                        final localPosition = box.globalToLocal(
                                          details.globalPosition,
                                        );
                                        _handleGaugeInteraction(
                                          localPosition,
                                          constraints.biggest,
                                        );
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
                                              thickness: 0.15,
                                              thicknessUnit:
                                                  GaugeSizeUnit.factor,
                                              color: Colors.white24,
                                              cornerStyle:
                                                  CornerStyle.bothCurve,
                                            ),
                                            pointers: [
                                              RangePointer(
                                                value:
                                                    usbProvider.pendingHumidity,
                                                width: 0.15,
                                                color: Colors.white,
                                                cornerStyle:
                                                    CornerStyle.bothCurve,
                                                sizeUnit: GaugeSizeUnit.factor,
                                              ),
                                              MarkerPointer(
                                                value:
                                                    usbProvider.pendingHumidity,
                                                markerType: MarkerType.circle,
                                                color: Colors.white,
                                                markerHeight: 20,
                                                markerWidth: 20,
                                                borderColor: const Color(
                                                  0xFF3D8A8F,
                                                ),
                                                borderWidth: 3,
                                              ),
                                            ],
                                            annotations: [
                                              GaugeAnnotation(
                                                angle: 90,
                                                positionFactor: 0,
                                                widget: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      "${usbProvider.pendingHumidity.toStringAsFixed(1)}",
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen
                                                            ? 24
                                                            : 32,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const Text(
                                                      "%",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: ElevatedButton(
                                  onPressed:
                                      usbProvider.isConnected &&
                                          !_isSettingValue
                                      ? _setHumidity
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getButtonColor(
                                      usbProvider,
                                    ),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _buildButtonContent(usbProvider),
                                ),
                              ),
                            ),

                            // Add some bottom padding for safety
                            SizedBox(height: isSmallScreen ? 10 : 20),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
