import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/services/globalespprovider.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';
import 'dart:math' as math;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;

class TempGaugeScreen extends StatefulWidget {
  const TempGaugeScreen({super.key});

  @override
  State<TempGaugeScreen> createState() => _TempGaugeScreenState();
}

class _TempGaugeScreenState extends State<TempGaugeScreen> {
  bool _isSettingValue = false;
  DateTime? _lastSetTime;
  static const Duration _minSetInterval = Duration(seconds: 2);

  // ESP32 configuration
  final String esp32BaseUrl = 'http://192.168.0.100:8080';
  // bool _useEsp32 = false; // <-- REMOVED this stale variable

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _checkConnectionMethod(); // <-- REMOVED
      _initializeData();
    });
  }

  // _checkConnectionMethod() was REMOVED as it's no longer needed

  void _initializeData() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    // Check the live connection status
    if (!usbProvider.isConnected) {
      // Initialize ESP32 data
      final esp32Provider = Provider.of<ESP32State>(context, listen: false);
      esp32Provider.refreshData();

      // Set initial pending temperature from ESP32 data if available
      final currentTempSetpt = esp32Provider.data['S_TEMP_SETPT'];
      if (currentTempSetpt != null && currentTempSetpt.isNotEmpty) {
        // Convert from 266 format (26.6) to double
        double tempValue = _convertFromSetpointFormat(currentTempSetpt);
        usbProvider.updatePendingTemperature(tempValue);
      }
    } else {
      // Use USB method
      usbProvider.sendTemperatureStructure();
    }
  }

  // Convert from "266" format (26.6°C) to double
  double _convertFromSetpointFormat(String setpoint) {
    if (setpoint.length >= 2) {
      String whole = setpoint.substring(0, setpoint.length - 1);
      String decimal = setpoint.substring(setpoint.length - 1);
      return double.tryParse('$whole.$decimal') ?? 25.0;
    }
    return 25.0;
  }

  // Convert to "266" format (26.6°C -> 266)
  String _convertToSetpointFormat(double value) {
    int setpointValue = (value * 10).round();
    return setpointValue.toString().padLeft(3, '0');
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

    // Map angle to value range (15.0 to 35.0)
    double value =
        ((normalizedAngle - startAngleRad) /
                (endAngleRad - startAngleRad + 2 * math.pi)) *
            20 + // (35 - 15) = 20
        15; // Minimum value
    value = value.clamp(15.0, 35.0);

    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
    usbProvider.updatePendingTemperature(value);
  }

  // ESP32 HTTP command method
  Future<void> _sendEsp32Command(String key, String value) async {
    try {
      debugPrint("ESP32: Sending $key = $value");

      final response = await http
          .get(Uri.parse('$esp32BaseUrl/update?$key=$value'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 302) {
        debugPrint("ESP32: Command sent successfully");
        // Refresh data after successful update
        final esp32Provider = Provider.of<ESP32State>(context, listen: false);
        esp32Provider.refreshData();
      } else {
        debugPrint(
          "ESP32: Failed to send command - Status: ${response.statusCode}",
        );
        throw Exception("Failed to send command: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ESP32: Error sending command: $e");
      throw e;
    }
  }

  // Send complete structure to ESP32 (No longer used by this screen)
  Future<void> _sendEsp32CompleteStructure() async {
    // ... (this function can remain as-is, though it's not called)
  }

  // Build the complete structured data string (No longer used by this screen)
  String _buildCompleteStructure(
    ESP32State esp32Provider,
    GlobalUsbProvider usbProvider,
  ) {
    // ... (this function can remain as-is, though it's not called)
    final buffer = StringBuffer('{');
    buffer.write('SR_WSL:${esp32Provider.data['SR_WSL'] ?? '250029'},');
    for (int i = 1; i <= 10; i++) {
      final lightKey = 'S_Light_${i}_ON_OFF';
      final lightValue = esp32Provider.data[lightKey] ?? '0';
      buffer.write('$lightKey:$lightValue,');
    }
    for (int i = 1; i <= 10; i++) {
      final intensityKey = 'S_Light_${i}_Intensity';
      final intensityValue = esp32Provider.data[intensityKey] ?? '000';
      buffer.write('$intensityKey:$intensityValue,');
    }
    buffer.write('S_IOT_TIMER:${esp32Provider.data['S_IOT_TIMER'] ?? '0060'},');
    final tempSetpoint = _convertToSetpointFormat(
      usbProvider.pendingTemperature,
    );
    buffer.write('S_TEMP_SETPT:$tempSetpoint,');
    buffer.write('S_RH_SETPT:${esp32Provider.data['S_RH_SETPT'] ?? '212'}');
    buffer.write('}');
    return buffer.toString();
  }

  Future<void> _setTemperature() async {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    if (_isSettingValue) {
      print("⏳ Already setting temperature, please wait");
      return;
    }

    // This check is no longer needed, the button logic handles it
    // if (!usbProvider.isConnected && !_useEsp32) { ... }

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
    });

    try {
      print(
        "🎯 Setting temperature to: ${usbProvider.pendingTemperature.toStringAsFixed(1)}°C",
      );

      _lastSetTime = DateTime.now();

      // --- YOUR FIX IS HERE ---
      // Check the provider's connection status directly
      if (!usbProvider.isConnected) {
        // Use ESP32 method

        // 1. Get the value from the provider
        double tempValue = usbProvider.pendingTemperature;

        // 2. Convert to the string format (e.g., 26.5 -> "265")
        String tempSetpoint = _convertToSetpointFormat(tempValue);

        // 3. Send ONLY the changed key and value
        await _sendEsp32Command("S_TEMP_SETPT", tempSetpoint);
      } else {
        // Use USB method
        usbProvider.sendTemperatureStructure();
      }
      // --- END OF FIX ---

      Get.snackbar(
        "Success",
        "Temperature set to ${usbProvider.pendingTemperature.toStringAsFixed(1)}°C",
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
      print("❌ Error setting temperature: $e");
      Get.snackbar(
        "Set Failed",
        "Failed to set temperature: ${e.toString().split('\n').first}",
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

  // Get current temperature value from appropriate source
  String _getCurrentTemperatureValue() {
    // We check the provider directly here, listening for changes
    final usbProvider = Provider.of<GlobalUsbProvider>(context);

    if (!usbProvider.isConnected) {
      // <--- FIXED
      final esp32Provider = Provider.of<ESP32State>(context);
      // This key 'C_OT_TEMP' must exist in your ESP32's 'dataString'
      final currentTemperature = esp32Provider.data['C_OT_TEMP'] ?? '--';

      // Convert "297" (29.7) to "29.7" for display
      if (currentTemperature != '--' && currentTemperature.length >= 2) {
        String whole = currentTemperature.substring(
          0,
          currentTemperature.length - 1,
        );
        String decimal = currentTemperature.substring(
          currentTemperature.length - 1,
        );
        return '$whole.$decimal°C';
      }
      return '--°C';
    } else {
      // final usbProvider = Provider.of<GlobalUsbProvider>(context); // Already defined
      return usbProvider.currentTemperature == "--"
          ? "--"
          : '${usbProvider.currentTemperature}°C';
    }
  }

  Color _getButtonColor(GlobalUsbProvider usbProvider) {
    // Simplified logic
    if (_isSettingValue) {
      return Colors.grey;
    }
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

    String buttonText;
    // Check the provider's connection status directly
    if (!usbProvider.isConnected) {
      // <--- FIXED
      buttonText = "SET TEMPERATURE (ESP32)";
    } else if (usbProvider.isConnected) {
      buttonText = "SET TEMPERATURE (USB)";
    } else {
      // This case is covered by !usbProvider.isConnected
      buttonText = "NO CONNECTION";
    }

    return Text(
      buttonText,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildConnectionStatus() {
    // Check the provider's connection status directly
    final usbProvider = Provider.of<GlobalUsbProvider>(context);

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (!usbProvider.isConnected) {
      // <--- FIXED
      statusText = "ESP32 CONNECTED";
      statusColor = Colors.blue;
      statusIcon = Icons.wifi;
    } else if (usbProvider.isConnected) {
      statusText = "USB CONNECTED";
      statusColor = Colors.green;
      statusIcon = Icons.usb;
    } else {
      // This case is covered by !usbProvider.isConnected
      statusText = "DISCONNECTED";
      statusColor = Colors.red;
      statusIcon = Icons.wifi_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                                  // Connection Status Indicator
                                  _buildConnectionStatus(),

                                  // Title
                                  Text(
                                    "Temperature Control",
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
                                        _getCurrentTemperatureValue(),
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
                                        "${usbProvider.pendingTemperature.toStringAsFixed(1)}°C",
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
                                            minimum: 15,
                                            maximum: 35,
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
                                                value: usbProvider
                                                    .pendingTemperature,
                                                width: 0.15,
                                                color: Colors.white,
                                                cornerStyle:
                                                    CornerStyle.bothCurve,
                                                sizeUnit: GaugeSizeUnit.factor,
                                              ),
                                              MarkerPointer(
                                                value: usbProvider
                                                    .pendingTemperature,
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
                                                      "${usbProvider.pendingTemperature.toStringAsFixed(1)}",
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
                                                      "°C",
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
                                      // --- FIXED: Simplified logic ---
                                      // Button is enabled as long as it's not currently setting.
                                      !_isSettingValue ? _setTemperature : null,
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
