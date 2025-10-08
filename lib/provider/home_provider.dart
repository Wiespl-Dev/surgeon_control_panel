// lib/provider/home_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeProvider with ChangeNotifier {
  // System state
  bool _isSwitched = false;
  String _currentTemp = "--";
  String _currentHumidity = "--";

  // HEPA Status
  bool _isHepaHealthy = true;
  String _hepaStatusText = "HEPA Healthy";

  // USB Status
  bool _isConnected = false;
  String _usbStatus = "Disconnected";

  // Getters
  bool get isSwitched => _isSwitched;
  String get currentTemp => _currentTemp;
  String get currentHumidity => _currentHumidity;
  bool get isHepaHealthy => _isHepaHealthy;
  String get hepaStatusText => _hepaStatusText;
  bool get isConnected => _isConnected;
  String get usbStatus => _usbStatus;

  // SharedPreferences instance
  SharedPreferences? _prefs;

  HomeProvider() {
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    // Initialize sensor fault bits to '0' (no fault) if not set - ONLY 7 SENSORS
    for (int i = 1; i <= 7; i++) {
      String key = 'F_Sensor_${i}_FAULT_BIT';
      if (!_prefs!.containsKey(key)) {
        await _prefs!.setString(key, '0');
        debugPrint("Initialized $key to '0' (NO FAULT)");
      }
    }

    // Initialize HEPA sensor fault bit to '0' (healthy) if not set
    if (!_prefs!.containsKey('F_Sensor_10_FAULT_BIT')) {
      await _prefs!.setString('F_Sensor_10_FAULT_BIT', '0');
      debugPrint("Initialized F_Sensor_10_FAULT_BIT to '0' (HEPA Healthy)");
    }

    _loadSavedValues();
  }

  void _loadSavedValues() {
    if (_prefs == null) return;

    _currentTemp = _prefs!.getString('current_temperature') ?? "--";
    _currentHumidity = _prefs!.getString('current_humidity') ?? "--";
    _isSwitched = _prefs!.getBool('system_status') ?? false;

    // Load HEPA status
    String? hepaFaultBit = _prefs!.getString('F_Sensor_10_FAULT_BIT');
    if (hepaFaultBit != null) {
      _updateHepaStatus(hepaFaultBit);
    }

    notifyListeners();
  }

  // Temperature methods
  void updateTemperature(String value) {
    _currentTemp = value;
    _prefs?.setString('current_temperature', value);
    notifyListeners();
  }

  void updateHumidity(String value) {
    _currentHumidity = value;
    _prefs?.setString('current_humidity', value);
    notifyListeners();
  }

  // System status methods
  void updateSystemStatus(bool value) {
    _isSwitched = value;
    _prefs?.setBool('system_status', value);
    notifyListeners();
  }

  // HEPA status methods
  void _updateHepaStatus(String faultBit) {
    _isHepaHealthy = faultBit == '0';
    _hepaStatusText = _isHepaHealthy ? "HEPA Healthy" : "HEPA Unhealthy";
    notifyListeners();
  }

  void refreshHepaStatus() {
    if (_prefs == null) return;

    String? hepaFaultBit = _prefs!.getString('F_Sensor_10_FAULT_BIT');
    if (hepaFaultBit != null) {
      _updateHepaStatus(hepaFaultBit);
    }
  }

  // USB status methods
  void updateUsbStatus(bool connected, String status) {
    _isConnected = connected;
    _usbStatus = status;
    notifyListeners();
  }

  // Check sensor faults
  bool hasSensorFault() {
    if (_prefs == null) return false;

    for (int i = 1; i <= 7; i++) {
      String? fault = _prefs!.getString('F_Sensor_${i}_FAULT_BIT');
      if (fault == '1') {
        return true;
      }
    }
    return false;
  }

  // Reset all sensors
  void resetAllSensorsToNoFault() {
    if (_prefs == null) return;

    for (int i = 1; i <= 7; i++) {
      _prefs!.setString('F_Sensor_${i}_FAULT_BIT', '0');
    }
    notifyListeners();
  }

  // Get prefs for USB communication
  SharedPreferences? get prefs => _prefs;
}
