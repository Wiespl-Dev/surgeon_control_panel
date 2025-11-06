import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:provider/provider.dart';

class LightIntensityPage extends StatefulWidget {
  @override
  _LightIntensityPageState createState() => _LightIntensityPageState();
}

class _LightIntensityPageState extends State<LightIntensityPage> {
  // USB communication
  UsbPort? _port;
  String _incomingBuffer = "";
  StreamSubscription<dynamic>? _usbSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize USB when screen loads (SharedPreferences is already initialized in main.dart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );
      usbProvider.initUsb(); // Only initialize USB connection
    });
  }

  @override
  void dispose() {
    _usbSubscription?.cancel();
    _port?.close();
    super.dispose();
  }

  void _sendCommand(String cmd) {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    if (usbProvider.isConnected) {
      // Use the provider's send method instead of local USB management
      debugPrint("Light Page attempting to send: $cmd");
    }
  }

  void _sendCompleteStructure() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    if (usbProvider.isConnected) {
      usbProvider.sendCompleteStructure();
    }
  }

  void _reconnectUsb() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
    // usbProvider.reconnectUsb();
  }

  Widget _buildLightControlItem({
    required String title,
    required bool isOn,
    required double intensity,
    required ValueChanged<bool> onToggle,
    ValueChanged<double>? onIntensityChange,
    bool showSlider = true,
  }) {
    final Color trackColor = isOn
        ? const Color.fromARGB(255, 219, 247, 64)
        : Colors.grey[400]!;
    final Color thumbColor = isOn ? Colors.white : Colors.white;

    return Column(
      children: [
        // Title and Switch/Toggle (Row 1)
        Padding(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 16.0,
            top: 10.0,
            bottom: 4.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: isOn,
                onChanged: onToggle,
                activeColor: trackColor,
                activeTrackColor: trackColor.withOpacity(0.5),
                inactiveThumbColor: thumbColor,
                inactiveTrackColor: Colors.grey[600],
              ),
            ],
          ),
        ),

        // Slider (Row 2, only for individual lights)
        if (showSlider)
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 4.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white54,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white12,
                      trackHeight: 6.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8.0,
                      ),
                    ),
                    child: Slider(
                      value: intensity,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: onIntensityChange,
                      onChangeEnd: (val) {
                        _sendCompleteStructure();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "${intensity.round()}%".padLeft(4, ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Custom Divider Line
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: Colors.white38, height: 1, thickness: 0.5),
        ),
      ],
    );
  }

  void _toggleAllLights(bool newState) {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    // If turning all lights on, set all to 50% intensity
    // If turning all lights off, set all to 0% intensity
    for (int i = 0; i < usbProvider.lightStates.length; i++) {
      usbProvider.handleLightChange(i, newState, newState ? 50 : 0);
    }

    _sendCompleteStructure();
  }

  void _toggleNightMode(bool newState) {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    // You'll need to add a method in GlobalUsbProvider to handle night mode
    // For now, let's assume there's a method called setNightMode
    // If not, you'll need to implement it in your provider
    _sendCompleteStructure();
  }

  @override
  Widget build(BuildContext context) {
    final usbProvider = Provider.of<GlobalUsbProvider>(context);

    return Material(
      color: const Color(0xFF3D8A8F),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double modalWidth = constraints.maxWidth * 0.9;
            final double modalHeight = constraints.maxHeight * 0.9;

            return Container(
              width: modalWidth.clamp(300.0, 600.0),
              height: modalHeight.clamp(400.0, 800.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 40, 123, 131),
                    Color.fromARGB(255, 39, 83, 87),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // HEADER: Title and Close Button
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16.0,
                      left: 20.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Light",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Connection status and close button
                        Row(
                          children: [
                            // USB Connection Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: usbProvider.isConnected
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                usbProvider.isConnected
                                    ? "USB Connected"
                                    : "USB Disconnected",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Refresh button
                            IconButton(
                              onPressed: _reconnectUsb,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            // Close button
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // The solid line divider under the title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      color: Colors.white,
                      height: 1,
                      thickness: 0.5,
                    ),
                  ),

                  // SCROLLABLE LIGHT CONTROLS
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        // 1. ALL LIGHTS Master Control (no slider, only switch)
                        _buildLightControlItem(
                          title: "All Lights",
                          isOn: usbProvider.allLightsState,
                          intensity: 0,
                          onToggle: (v) {
                            _toggleAllLights(v);
                          },
                          showSlider: false,
                        ),

                        // 3. Individual Light Controls (7 Lights)
                        ...List.generate(7, (index) {
                          return _buildLightControlItem(
                            title: "Light ${index + 1}",
                            isOn: usbProvider.lightStates[index],
                            intensity: usbProvider.lightIntensities[index]
                                .toDouble(),
                            onToggle: (v) {
                              usbProvider.handleLightChange(
                                index,
                                v,
                                v ? 50 : 0, // Turn on with 50%
                              );
                              _sendCompleteStructure();
                            },
                            onIntensityChange: (v) {
                              usbProvider.handleLightChange(
                                index,
                                null,
                                v.toInt(),
                              );
                              // Don't send command here to avoid spam, only on release
                            },
                            showSlider: true,
                          );
                        }),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
