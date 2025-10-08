import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/provider/light_provider.dart';

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
    _initUsb();
  }

  @override
  void dispose() {
    _usbSubscription?.cancel();
    _port?.close();
    super.dispose();
  }

  // USB Communication Methods
  Future<void> _initUsb() async {
    final lightProvider = Provider.of<LightProvider>(context, listen: false);

    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        lightProvider.updateConnectionStatus(false);
        return;
      }

      UsbDevice device = devices.first;
      _port = await device.create();
      bool open = await _port!.open();

      if (open) {
        await _port!.setPortParameters(9600, 8, 1, 0);

        // Cancel previous subscription if any
        await _usbSubscription?.cancel();

        _usbSubscription = _port!.inputStream?.listen(_onDataReceived);
        lightProvider.updateConnectionStatus(true);
        _sendCommand("STATUS");
      } else {
        lightProvider.updateConnectionStatus(false);
      }
    } catch (e) {
      debugPrint("USB Error in LightIntensityPage: $e");
      lightProvider.updateConnectionStatus(false);
    }
  }

  void _onDataReceived(Uint8List data) {
    String str = String.fromCharCodes(data);
    _incomingBuffer += str;

    if (_incomingBuffer.contains('\n') ||
        (_incomingBuffer.startsWith('{') && _incomingBuffer.contains('}'))) {
      List<String> messages = _incomingBuffer.split('\n');
      for (int i = 0; i < messages.length - 1; i++) {
        String completeMessage = messages[i].trim();
        if (completeMessage.isNotEmpty) {
          _processCompleteMessage(completeMessage);
        }
      }
      _incomingBuffer = messages.last;
    }

    if (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}')) {
      _processCompleteMessage(_incomingBuffer);
      _incomingBuffer = "";
    }
  }

  void _processCompleteMessage(String completeMessage) {
    _parseStructuredData(completeMessage);
  }

  void _parseStructuredData(String data) {
    final lightProvider = Provider.of<LightProvider>(context, listen: false);

    try {
      if (data.startsWith('{') && data.endsWith('}')) {
        String content = data.substring(1, data.length - 1);
        List<String> pairs = content.split(',');
        Map<String, dynamic> parsedData = {};

        for (String pair in pairs) {
          List<String> keyValue = pair.split(':');
          if (keyValue.length == 2) {
            String key = keyValue[0].trim();
            String value = keyValue[1].trim();
            parsedData[key] = value;
          }
        }

        lightProvider.parseStructuredData(parsedData);
      }
    } catch (e) {
      debugPrint("Error parsing light data: $e");
    }
  }

  void _sendCommand(String cmd) {
    final lightProvider = Provider.of<LightProvider>(context, listen: false);

    if (_port != null && lightProvider.isConnected) {
      String commandToSend = cmd + "\n";
      _port!.write(Uint8List.fromList(commandToSend.codeUnits));
      debugPrint("Light Page Sent: $commandToSend");
    }
  }

  void _sendCompleteStructure() {
    final lightProvider = Provider.of<LightProvider>(context, listen: false);

    if (_port != null && lightProvider.isConnected) {
      String command = lightProvider.generateCommandStructure();
      _sendCommand(command);
    }
  }

  void _reconnectUsb() {
    _initUsb();
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

  @override
  Widget build(BuildContext context) {
    final lightProvider = Provider.of<LightProvider>(context);

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
                                color: lightProvider.isConnected
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lightProvider.isConnected
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
                          isOn: lightProvider.allLightsState,
                          intensity: 0,
                          onToggle: (v) {
                            lightProvider.toggleAllLights();
                            _sendCompleteStructure();
                          },
                          showSlider: false,
                        ),

                        // 2. Night Mode Toggle
                        _buildLightControlItem(
                          title: "Night Mode",
                          isOn: lightProvider.nightMode,
                          intensity: 0,
                          onToggle: (v) {
                            lightProvider.toggleNightMode();
                            _sendCompleteStructure();
                          },
                          showSlider: false,
                        ),

                        // 3. Individual Light Controls (7 Lights)
                        ...List.generate(7, (index) {
                          return _buildLightControlItem(
                            title: "Light ${index + 1}",
                            isOn: lightProvider.lightStates[index],
                            intensity: lightProvider.intensities[index]
                                .toDouble(),
                            onToggle: (v) {
                              lightProvider.handleLightChange(
                                index,
                                v,
                                v ? 50 : 0, // Turn on with 50%
                              );
                              _sendCompleteStructure();
                            },
                            onIntensityChange: (v) {
                              lightProvider.handleLightChange(
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
