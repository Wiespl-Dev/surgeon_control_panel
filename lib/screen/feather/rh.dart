import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/services/globalespprovider.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';
import 'dart:math' as math;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;

class HumidityGaugeScreen extends StatefulWidget {
  const HumidityGaugeScreen({super.key});

  @override
  State<HumidityGaugeScreen> createState() => _HumidityGaugeScreenState();
}

class _HumidityGaugeScreenState extends State<HumidityGaugeScreen> {
  bool _isSettingValue = false;
  DateTime? _lastSetTime;
  static const Duration _minSetInterval = Duration(seconds: 2);

  // ESP32 configuration
  final String esp32BaseUrl = 'http://192.168.0.100:8080';

  // New humidity range: 40% to 60%
  static const double _minHumidity = 40.0;
  static const double _maxHumidity = 60.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    if (!usbProvider.isConnected) {
      // Initialize ESP32 data
      final esp32Provider = Provider.of<ESP32State>(context, listen: false);
      esp32Provider.refreshData();

      // Set initial pending humidity from ESP32 data if available
      final currentRhSetpt = esp32Provider.data['S_RH_SETPT'];
      if (currentRhSetpt != null && currentRhSetpt.isNotEmpty) {
        // Convert from 212 format (21.2) to double
        double humidityValue = _convertFromSetpointFormat(currentRhSetpt);
        // Clamp the value to the new range (40-60)
        humidityValue = humidityValue.clamp(_minHumidity, _maxHumidity);
        usbProvider.updatePendingHumidity(humidityValue);
      } else {
        // Set default value within new range
        usbProvider.updatePendingHumidity(50.0); // Middle of 40-60 range
      }
    } else {
      // Use USB method
      usbProvider.sendCompleteStructure();
      // Ensure USB value is within new range
      double currentHumidity = usbProvider.pendingHumidity;
      if (currentHumidity < _minHumidity || currentHumidity > _maxHumidity) {
        usbProvider.updatePendingHumidity(50.0); // Reset to middle of range
      }
    }
  }

  // Convert from "212" format (21.2%) to double
  double _convertFromSetpointFormat(String setpoint) {
    if (setpoint.length >= 2) {
      String whole = setpoint.substring(0, setpoint.length - 1);
      String decimal = setpoint.substring(setpoint.length - 1);
      double value = double.tryParse('$whole.$decimal') ?? 50.0;
      // Clamp to new range
      return value.clamp(_minHumidity, _maxHumidity);
    }
    return 50.0; // Default to middle of new range
  }

  // Convert to "212" format (50.5 -> 505)
  String _convertToSetpointFormat(double value) {
    // Clamp value to new range before conversion
    value = value.clamp(_minHumidity, _maxHumidity);
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

    // Calculate value in 0-100 range first
    double normalizedValue =
        ((normalizedAngle - startAngleRad) /
            (endAngleRad - startAngleRad + 2 * math.pi)) *
        100;

    // Convert from 0-100 range to 40-60 range
    double value =
        _minHumidity + (normalizedValue / 100) * (_maxHumidity - _minHumidity);

    // Clamp to ensure it stays within 40-60
    value = value.clamp(_minHumidity, _maxHumidity);

    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
    usbProvider.updatePendingHumidity(value);
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

  // Send complete structure to ESP32
  Future<void> _sendEsp32CompleteStructure() async {
    final esp32Provider = Provider.of<ESP32State>(context, listen: false);
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    try {
      // Build the complete structured string
      String structuredData = _buildCompleteStructure(
        esp32Provider,
        usbProvider,
      );
      debugPrint("ESP32: Sending complete structure: $structuredData");

      // URL encode the structured data
      final encodedData = Uri.encodeComponent(structuredData);

      final response = await http
          .get(Uri.parse('$esp32BaseUrl/update?data=$encodedData'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 302) {
        debugPrint("ESP32: Complete structure sent successfully");
        esp32Provider.refreshData();
      } else {
        debugPrint(
          "ESP32: Failed to send structure - Status: ${response.statusCode}",
        );
        throw Exception("Failed to send structure: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ESP32: Error sending structured data: $e");
      throw e;
    }
  }

  // Build the complete structured data string
  String _buildCompleteStructure(
    ESP32State esp32Provider,
    GlobalUsbProvider usbProvider,
  ) {
    final buffer = StringBuffer('{');

    // Add SR_WSL (Water Level)
    buffer.write('SR_WSL:${esp32Provider.data['SR_WSL'] ?? '250029'},');

    // Add Light ON/OFF states
    for (int i = 1; i <= 10; i++) {
      final lightKey = 'S_Light_${i}_ON_OFF';
      final lightValue = esp32Provider.data[lightKey] ?? '0';
      buffer.write('$lightKey:$lightValue,');
    }

    // Add Light Intensities
    for (int i = 1; i <= 10; i++) {
      final intensityKey = 'S_Light_${i}_Intensity';
      final intensityValue = esp32Provider.data[intensityKey] ?? '000';
      buffer.write('$intensityKey:$intensityValue,');
    }

    // Add IOT Timer
    buffer.write('S_IOT_TIMER:${esp32Provider.data['S_IOT_TIMER'] ?? '0060'},');

    // Add Temperature Setpoint
    buffer.write(
      'S_TEMP_SETPT:${esp32Provider.data['S_TEMP_SETPT'] ?? '266'},',
    );

    // Add Humidity Setpoint (convert from double to setpoint format)
    final humiditySetpoint = _convertToSetpointFormat(
      usbProvider.pendingHumidity,
    );
    buffer.write('S_RH_SETPT:$humiditySetpoint');

    buffer.write('}');

    return buffer.toString();
  }

  Future<void> _setHumidity() async {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    if (_isSettingValue) {
      print("⏳ Already setting humidity, please wait");
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
    });

    try {
      print(
        "🎯 Setting humidity to: ${usbProvider.pendingHumidity.toStringAsFixed(1)}%",
      );

      _lastSetTime = DateTime.now();

      // Check the provider's connection status directly
      if (!usbProvider.isConnected) {
        // Use ESP32 method

        // 1. Get the value from the provider
        double humidityValue = usbProvider.pendingHumidity;

        // 2. Convert to the string format (e.g., 50.5 -> "505")
        String humiditySetpoint = _convertToSetpointFormat(humidityValue);

        // 3. Send ONLY the changed key and value
        await _sendEsp32Command("S_RH_SETPT", humiditySetpoint);
      } else {
        // Use USB method
        usbProvider.sendHumidityStructure();
      }

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

  // Get current humidity value from appropriate source
  String _getCurrentHumidityValue() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context);

    if (!usbProvider.isConnected) {
      final esp32Provider = Provider.of<ESP32State>(context);
      final currentHumidity = esp32Provider.data['C_RH'] ?? '--';
      return currentHumidity == '--' ? '--' : '$currentHumidity%';
    } else {
      return "";
    }
  }

  Color _getButtonColor(GlobalUsbProvider usbProvider) {
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
    if (!usbProvider.isConnected) {
      buttonText = "SET HUMIDITY (ESP32)";
    } else if (usbProvider.isConnected) {
      buttonText = "SET HUMIDITY (USB)";
    } else {
      buttonText = "NO CONNECTION";
    }

    return Text(
      buttonText,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildConnectionStatus() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context);

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (!usbProvider.isConnected) {
      statusText = "ESP32 CONNECTED";
      statusColor = Colors.blue;
      statusIcon = Icons.wifi;
    } else if (usbProvider.isConnected) {
      statusText = "USB CONNECTED";
      statusColor = Colors.green;
      statusIcon = Icons.usb;
    } else {
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
                                        _getCurrentHumidityValue(),
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
                                            minimum:
                                                _minHumidity, // Changed to 40
                                            maximum:
                                                _maxHumidity, // Changed to 60
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

                            // Range indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Range: ${_minHumidity.toInt()}% - ${_maxHumidity.toInt()}%",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                                  onPressed: !_isSettingValue
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
