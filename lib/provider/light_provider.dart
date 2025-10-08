// lib/provider/light_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LightProvider with ChangeNotifier {
  // Light state - 7 lights
  List<int> _intensities = List.filled(7, 0);
  List<bool> _lightStates = List.filled(7, false);
  bool _nightMode = false;
  bool _isConnected = false;

  // SharedPreferences instance
  SharedPreferences? _prefs;

  // Constants for SharedPreferences keys
  static const String _kIntensityKey = 'light_intensities';
  static const String _kStateKey = 'light_states';

  // Getters
  List<int> get intensities => _intensities;
  List<bool> get lightStates => _lightStates;
  bool get nightMode => _nightMode;
  bool get isConnected => _isConnected;
  bool get allLightsState => _lightStates.any((state) => state);

  LightProvider() {
    _initPreferences();
  }

  // Initialize SharedPreferences
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLightSettings();
  }

  // Load light settings from SharedPreferences
  Future<void> _loadLightSettings() async {
    if (_prefs == null) return;

    List<String>? intensityStrings = _prefs!.getStringList(_kIntensityKey);
    List<String>? stateStrings = _prefs!.getStringList(_kStateKey);

    // Check if saved data is valid
    if (intensityStrings != null &&
        stateStrings != null &&
        intensityStrings.length == 7 &&
        stateStrings.length == 7) {
      _intensities = intensityStrings.map((s) => int.tryParse(s) ?? 0).toList();
      _lightStates = stateStrings.map((s) => s == 'true').toList();

      // Recalculate night mode based on loaded states
      bool anyLightOn = _lightStates.any((state) => state);
      _nightMode = !anyLightOn;
    } else {
      // Initialize ALL lights to OFF and 0 intensity if no settings are found
      _lightStates = List.filled(7, false);
      _intensities = List.filled(7, 0);
      _nightMode = true;
      _saveLightSettings();
    }
    notifyListeners();
  }

  // Save current light settings to SharedPreferences
  Future<void> _saveLightSettings() async {
    if (_prefs == null) return;

    List<String> intensityStrings = _intensities
        .map((i) => i.toString())
        .toList();
    List<String> stateStrings = _lightStates.map((b) => b.toString()).toList();

    await _prefs!.setStringList(_kIntensityKey, intensityStrings);
    await _prefs!.setStringList(_kStateKey, stateStrings);
    debugPrint("Light settings saved.");
  }

  // USB connection status
  void updateConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  // Handle light changes
  void handleLightChange(int lightIndex, bool? turnOn, int? intensity) {
    if (turnOn != null) {
      _lightStates[lightIndex] = turnOn;
      if (!turnOn) _intensities[lightIndex] = 0;
    }
    if (intensity != null) {
      _intensities[lightIndex] = intensity;
      if (intensity > 0) _lightStates[lightIndex] = true;
    }

    // Update night mode
    bool anyLightOn = _lightStates.any((state) => state);
    _nightMode = !anyLightOn;

    _saveLightSettings();
    notifyListeners();
  }

  // Toggle night mode
  void toggleNightMode() {
    _nightMode = !_nightMode;
    if (_nightMode) {
      for (int i = 0; i < 7; i++) {
        _lightStates[i] = false;
        _intensities[i] = 0;
      }
    }
    _saveLightSettings();
    notifyListeners();
  }

  // Toggle all lights
  void toggleAllLights() {
    bool allLightsOn = _lightStates.every(
      (state) => state && _intensities[_lightStates.indexOf(state)] > 0,
    );
    bool newState = !allLightsOn;

    for (int i = 0; i < 7; i++) {
      _lightStates[i] = newState;
      _intensities[i] = newState ? 50 : 0;
    }

    _nightMode = !newState;
    _saveLightSettings();
    notifyListeners();
  }

  // Parse structured data from USB
  void parseStructuredData(Map<String, dynamic> parsedData) {
    bool anyLightOn = false;

    for (int i = 1; i <= 7; i++) {
      String lightOnOffKey = 'S_Light_${i}_ON_OFF';
      if (parsedData.containsKey(lightOnOffKey)) {
        bool state = parsedData[lightOnOffKey] == '1';
        _lightStates[i - 1] = state;
        if (state) anyLightOn = true;
      }

      String intensityKey = 'S_Light_${i}_Intensity';
      if (parsedData.containsKey(intensityKey)) {
        try {
          _intensities[i - 1] = int.parse(parsedData[intensityKey].toString());
        } catch (e) {
          debugPrint(
            "Error parsing intensity for light $i: ${parsedData[intensityKey]}",
          );
        }
      }
    }

    _nightMode = !anyLightOn;
    _saveLightSettings();
    notifyListeners();
  }

  // Generate command structure for USB
  String generateCommandStructure() {
    List<String> pairs = [];
    pairs.add('SR_WSL:200001');
    pairs.add('C_PRESSURE_1:000');
    pairs.add('C_PRESSURE_1_SIGN_BIT:1');
    pairs.add('C_PRESSURE_2:000');
    pairs.add('C_PRESSURE_2_SIGN_BIT:1');
    pairs.add('C_OT_TEMP:250');
    pairs.add('C_RH:500');

    for (int i = 1; i <= 7; i++) {
      pairs.add('F_Sensor_${i}_FAULT_BIT:0');
      pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
      pairs.add('S_Light_${i}_ON_OFF:${_lightStates[i - 1] ? '1' : '0'}');
      pairs.add(
        'S_Light_${i}_Intensity:${_intensities[i - 1].toString().padLeft(3, '0')}',
      );
    }

    pairs.add('S_IOT_TIMER:0060');
    pairs.add('S_TEMP_SETPT:250');
    pairs.add('S_RH_SETPT:500');

    return '{${pairs.join(',')}}';
  }
}
