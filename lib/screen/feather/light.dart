import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:surgeon_control_panel/services/globalespprovider.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';

class LightIntensityPage extends StatefulWidget {
  @override
  _LightIntensityPageState createState() => _LightIntensityPageState();
}

class _LightIntensityPageState extends State<LightIntensityPage> {
  // ESP32 configuration
  final String esp32BaseUrl = 'http://192.168.0.100:8080';
  Timer? _refreshTimer;
  bool _useEsp32 = true;
  String _connectionStatus = "Connecting...";

  // Local state for immediate UI updates
  late List<bool> _localLightStates;
  late List<double> _localLightIntensities;

  // Track which lights have been manually controlled
  final Set<int> _manuallyControlledLights = Set<int>();

  // Define the light pattern: which lights should be on for each control
  final Map<int, List<int>> _lightPattern = {
    1: [1], // Light 1 controls light 1
    2: [2, 3], // Light 2 controls lights 2 and 3
    3: [4, 5], // Light 3 controls lights 4 and 5
    4: [6], // Light 4 controls light 6
  };

  @override
  void initState() {
    super.initState();
    _initializeLocalState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeLocalState() {
    // Initialize with default values (6 lights total)
    _localLightStates = List.generate(6, (index) => false);
    _localLightIntensities = List.generate(6, (index) => 0.0);
  }

  void _initializeData() {
    _checkConnectionMethod();

    if (_useEsp32) {
      final esp32Provider = Provider.of<ESP32State>(context, listen: false);
      _syncWithEsp32Provider(esp32Provider);
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        final provider = Provider.of<ESP32State>(context, listen: false);
        _syncWithEsp32Provider(provider);
      });
    } else {
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );
      _syncWithUsbProvider(usbProvider);
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        final provider = Provider.of<GlobalUsbProvider>(context, listen: false);
        _syncWithUsbProvider(provider);
      });
    }
  }

  void _syncWithEsp32Provider(ESP32State provider) {
    if (mounted) {
      setState(() {
        for (
          int i = 0;
          i < provider.lights.length && i < _localLightStates.length;
          i++
        ) {
          // Only sync lights that haven't been manually controlled
          if (!_manuallyControlledLights.contains(i + 1)) {
            _localLightStates[i] = provider.lights[i];
          }
        }
        for (
          int i = 0;
          i < provider.lightIntensities.length &&
              i < _localLightIntensities.length;
          i++
        ) {
          // Only sync intensities for lights that haven't been manually controlled
          if (!_manuallyControlledLights.contains(i + 1)) {
            _localLightIntensities[i] = provider.lightIntensities[i].toDouble();
          }
        }
      });
    }
  }

  void _syncWithUsbProvider(GlobalUsbProvider provider) {
    if (mounted) {
      setState(() {
        for (
          int i = 0;
          i < provider.lightStates.length && i < _localLightStates.length;
          i++
        ) {
          // Only sync lights that haven't been manually controlled
          if (!_manuallyControlledLights.contains(i + 1)) {
            _localLightStates[i] = provider.lightStates[i];
          }
        }
        for (
          int i = 0;
          i < provider.lightIntensities.length &&
              i < _localLightIntensities.length;
          i++
        ) {
          // Only sync intensities for lights that haven't been manually controlled
          if (!_manuallyControlledLights.contains(i + 1)) {
            _localLightIntensities[i] = provider.lightIntensities[i].toDouble();
          }
        }
      });
    }
  }

  void _checkConnectionMethod() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
    setState(() {
      _useEsp32 = !usbProvider.isConnected;
      _connectionStatus = _useEsp32 ? "ESP32 Connected" : "USB Connected";
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Send command to appropriate device
  Future<void> _sendCommand(String key, String value) async {
    if (_useEsp32) {
      await _sendEsp32Command(key, value);
    } else {
      await _sendUsbCommand(key, value);
    }
  }

  // Send command to ESP32
  Future<void> _sendEsp32Command(String key, String value) async {
    try {
      debugPrint("ESP32: Sending $key = $value");

      final response = await http
          .get(Uri.parse('$esp32BaseUrl/update?$key=$value'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 302) {
        debugPrint("ESP32: Command sent successfully");
      } else {
        debugPrint(
          "ESP32: Failed to send command - Status: ${response.statusCode}",
        );
        _showErrorSnackbar("Failed to send command to ESP32");
      }
    } catch (e) {
      debugPrint("ESP32: Error sending command: $e");
      _showErrorSnackbar("ESP32 Connection error: $e");
    }
  }

  // Send command via USB - FIXED VERSION
  Future<void> _sendUsbCommand(String key, String value) async {
    try {
      debugPrint("USB: Sending $key = $value");

      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );

      // Parse the command to update the provider state
      if (key.startsWith('S_Light_')) {
        if (key.contains('_ON_OFF')) {
          final lightNumber = int.parse(key.split('_')[2]);
          final isOn = value == '1';

          // Handle the light pattern
          if (_lightPattern.containsKey(lightNumber)) {
            final controlledLights = _lightPattern[lightNumber]!;
            for (final actualLight in controlledLights) {
              final index = actualLight - 1;
              if (index >= 0 && index < usbProvider.lightStates.length) {
                usbProvider.handleLightChange(index, isOn, isOn ? 50 : 0);
              }
            }
          }
        } else if (key.contains('_Intensity')) {
          final lightNumber = int.parse(key.split('_')[2]);
          final intensity = int.parse(value);

          // Handle the light pattern
          if (_lightPattern.containsKey(lightNumber)) {
            final controlledLights = _lightPattern[lightNumber]!;
            for (final actualLight in controlledLights) {
              final index = actualLight - 1;
              if (index >= 0 && index < usbProvider.lightStates.length) {
                final isOn = intensity > 0;
                usbProvider.handleLightChange(index, isOn, intensity);
              }
            }
          }
        }
      }

      // Send complete structure after updating state
      usbProvider.sendCompleteStructure();

      debugPrint("USB: Command sent successfully");
    } catch (e) {
      debugPrint("USB: Error sending command: $e");
      _showErrorSnackbar("USB Connection error: $e");
    }
  }

  // Update local state for immediate UI response
  void _updateLocalLightState(int controlNumber, bool? isOn, int? intensity) {
    if (mounted && _lightPattern.containsKey(controlNumber)) {
      setState(() {
        final controlledLights = _lightPattern[controlNumber]!;
        for (final actualLight in controlledLights) {
          final index = actualLight - 1;
          if (index >= 0 && index < _localLightStates.length) {
            if (isOn != null) {
              _localLightStates[index] = isOn;
              // If turning off, set intensity to 0; if turning on, set to 50 if currently 0
              if (!isOn) {
                _localLightIntensities[index] = 0.0;
              } else if (_localLightIntensities[index] == 0) {
                _localLightIntensities[index] = 50.0;
              }
            }
            if (intensity != null) {
              _localLightIntensities[index] = intensity.toDouble();
              // Update on/off state based on intensity
              _localLightStates[index] = intensity > 0;
            }
          }
        }
      });
    }
  }

  // Mark lights as manually controlled based on pattern
  void _markLightsAsManuallyControlled(int controlNumber) {
    if (_lightPattern.containsKey(controlNumber)) {
      final controlledLights = _lightPattern[controlNumber]!;
      for (final light in controlledLights) {
        _manuallyControlledLights.add(light);
      }
    }
  }

  // Reset manual control for all lights
  void _resetAllManualControls() {
    _manuallyControlledLights.clear();
  }

  // Update individual light control state - FIXED FOR PATTERN
  Future<void> _updateLightState(
    int controlNumber,
    bool isOn, [
    int? intensity,
  ]) async {
    // Mark these lights as manually controlled
    _markLightsAsManuallyControlled(controlNumber);

    // Update local state immediately for UI response
    _updateLocalLightState(controlNumber, isOn, intensity);

    // Send commands to device for this control
    await _sendCommand('S_Light_${controlNumber}_ON_OFF', isOn ? '1' : '0');

    if (intensity != null) {
      await _sendCommand(
        'S_Light_${controlNumber}_Intensity',
        intensity.toString().padLeft(3, '0'),
      );
    }
  }

  // Update all lights at once - FIXED FOR PATTERN
  Future<void> _updateAllLights(bool isOn) async {
    // Reset manual controls when using "All Lights"
    _resetAllManualControls();

    // Update local state immediately
    if (mounted) {
      setState(() {
        for (int i = 0; i < _localLightStates.length; i++) {
          _localLightStates[i] = isOn;
          _localLightIntensities[i] = isOn ? 50.0 : 0.0;
        }
      });
    }

    if (_useEsp32) {
      // Use ESP32 method - control all 4 control points
      for (int controlNumber = 1; controlNumber <= 4; controlNumber++) {
        await _sendCommand('S_Light_${controlNumber}_ON_OFF', isOn ? '1' : '0');
        if (isOn) {
          await _sendCommand('S_Light_${controlNumber}_Intensity', '050');
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } else {
      // Use USB method - Update all light states in the provider
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );

      // Update all light states in the provider (all 6 actual lights)
      for (int i = 0; i < usbProvider.lightStates.length && i < 6; i++) {
        usbProvider.handleLightChange(i, isOn, isOn ? 50 : 0);
      }

      // Send only ONE complete structure
      usbProvider.sendCompleteStructure();
    }

    _showSuccessSnackbar(
      isOn ? "All lights turned ON" : "All lights turned OFF",
    );
  }

  // Update light intensity for a control
  Future<void> _updateLightIntensity(int controlNumber, int intensity) async {
    // Mark these lights as manually controlled
    _markLightsAsManuallyControlled(controlNumber);

    // Update local state immediately
    _updateLocalLightState(controlNumber, null, intensity);

    await _sendCommand(
      'S_Light_${controlNumber}_Intensity',
      intensity.toString().padLeft(3, '0'),
    );
  }

  // Check if all lights in a control are on
  bool _getControlState(int controlNumber) {
    if (_lightPattern.containsKey(controlNumber)) {
      final controlledLights = _lightPattern[controlNumber]!;
      for (final light in controlledLights) {
        final index = light - 1;
        if (index >= _localLightStates.length || !_localLightStates[index]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  // Get average intensity for a control
  double _getControlIntensity(int controlNumber) {
    if (_lightPattern.containsKey(controlNumber)) {
      final controlledLights = _lightPattern[controlNumber]!;
      double total = 0;
      int count = 0;

      for (final light in controlledLights) {
        final index = light - 1;
        if (index < _localLightIntensities.length) {
          total += _localLightIntensities[index];
          count++;
        }
      }

      return count > 0 ? total / count : 0.0;
    }
    return 0.0;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLightControlItem({
    required String title,
    required bool isOn,
    required double intensity,
    required ValueChanged<bool> onToggle,
    ValueChanged<double>? onIntensityChange,
    bool showSlider = true,
    String? description,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
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
                        if (onIntensityChange != null) {
                          onIntensityChange(val);
                        }
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

  // Calculate if all lights are on based on local state
  bool _getAllLightsState() {
    for (int i = 0; i < _localLightStates.length; i++) {
      if (!_localLightStates[i]) {
        return false;
      }
    }
    return true;
  }

  // Manual refresh
  void _manualRefresh() {
    if (_useEsp32) {
      final esp32Provider = Provider.of<ESP32State>(context, listen: false);
      esp32Provider.refreshData();
      _syncWithEsp32Provider(esp32Provider);
    } else {
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );
      usbProvider.sendCompleteStructure();
      _syncWithUsbProvider(usbProvider);
    }
    _showSuccessSnackbar("Refreshing data...");
  }

  @override
  Widget build(BuildContext context) {
    final esp32Provider = Provider.of<ESP32State>(context);
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
                          "Light Control",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Connection status and close button
                        Row(
                          children: [
                            // Connection Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _useEsp32
                                    ? (esp32Provider.error == null
                                          ? Colors.green
                                          : Colors.red)
                                    : (usbProvider.isConnected
                                          ? Colors.green
                                          : Colors.red),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _useEsp32
                                    ? (esp32Provider.error == null
                                          ? "ESP32 Connected"
                                          : "ESP32 Error")
                                    : (usbProvider.isConnected
                                          ? "USB Connected"
                                          : "USB Error"),
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
                              onPressed: _manualRefresh,
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
                        // ALL LIGHTS Master Control (no slider, only switch)
                        _buildLightControlItem(
                          title: "All Lights",
                          isOn: _getAllLightsState(),
                          intensity: 0,
                          onToggle: (v) {
                            _updateAllLights(v);
                          },
                          showSlider: false,
                          description: "Controls all 6 lights",
                        ),

                        // Individual Light Controls with pattern
                        _buildLightControlItem(
                          title: "Light 1",
                          isOn: _getControlState(1),
                          intensity: _getControlIntensity(1),
                          onToggle: (v) async {
                            await _updateLightState(1, v, v ? 50 : 0);
                            _showSuccessSnackbar(
                              "Light 1 ${v ? 'ON' : 'OFF'} (controls 1 light)",
                            );
                          },
                          onIntensityChange: (v) async {
                            await _updateLightIntensity(1, v.round());
                            _showSuccessSnackbar(
                              "Light 1 intensity: ${v.round()}%",
                            );
                          },
                          showSlider: true,
                          description: "Controls Light 1",
                        ),

                        _buildLightControlItem(
                          title: "Light 2",
                          isOn: _getControlState(2),
                          intensity: _getControlIntensity(2),
                          onToggle: (v) async {
                            await _updateLightState(2, v, v ? 50 : 0);
                            _showSuccessSnackbar(
                              "Light 2 ${v ? 'ON' : 'OFF'} (controls 2 lights)",
                            );
                          },
                          onIntensityChange: (v) async {
                            await _updateLightIntensity(2, v.round());
                            _showSuccessSnackbar(
                              "Light 2 intensity: ${v.round()}%",
                            );
                          },
                          showSlider: true,
                          description: "Controls Lights 2 & 3",
                        ),

                        _buildLightControlItem(
                          title: "Light 3",
                          isOn: _getControlState(3),
                          intensity: _getControlIntensity(3),
                          onToggle: (v) async {
                            await _updateLightState(3, v, v ? 50 : 0);
                            _showSuccessSnackbar(
                              "Light 3 ${v ? 'ON' : 'OFF'} (controls 2 lights)",
                            );
                          },
                          onIntensityChange: (v) async {
                            await _updateLightIntensity(3, v.round());
                            _showSuccessSnackbar(
                              "Light 3 intensity: ${v.round()}%",
                            );
                          },
                          showSlider: true,
                          description: "Controls Lights 4 & 5",
                        ),

                        _buildLightControlItem(
                          title: "Light 4",
                          isOn: _getControlState(4),
                          intensity: _getControlIntensity(4),
                          onToggle: (v) async {
                            await _updateLightState(4, v, v ? 50 : 0);
                            _showSuccessSnackbar(
                              "Light 4 ${v ? 'ON' : 'OFF'} (controls 1 light)",
                            );
                          },
                          onIntensityChange: (v) async {
                            await _updateLightIntensity(4, v.round());
                            _showSuccessSnackbar(
                              "Light 4 intensity: ${v.round()}%",
                            );
                          },
                          showSlider: true,
                          description: "Controls Light 6",
                        ),

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
