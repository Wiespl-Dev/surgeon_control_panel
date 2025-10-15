// // provider/home_provider.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomeProvider with ChangeNotifier {
//   // USB Status
//   bool _isConnected = false;
//   String _usbStatus = "Disconnected";

//   // System Status
//   bool _isSwitched = false;

//   // Sensor Data
//   String _currentTemp = "--";
//   String _currentHumidity = "--";

//   // HEPA Status
//   bool _isHepaHealthy = true;
//   String _hepaStatusText = "HEPA Healthy";

//   // Shared Preferences
//   SharedPreferences? _prefs;

//   // Getters
//   bool get isConnected => _isConnected;
//   String get usbStatus => _usbStatus;
//   bool get isSwitched => _isSwitched;
//   String get currentTemp => _currentTemp;
//   String get currentHumidity => _currentHumidity;
//   bool get isHepaHealthy => _isHepaHealthy;
//   String get hepaStatusText => _hepaStatusText;
//   SharedPreferences? get prefs => _prefs;

//   HomeProvider() {
//     _initSharedPreferences();
//   }

//   Future<void> _initSharedPreferences() async {
//     _prefs = await SharedPreferences.getInstance();
//     notifyListeners();
//   }

//   // USB Status Methods
//   void updateUsbStatus(bool connected, String status) {
//     _isConnected = connected;
//     _usbStatus = status;
//     notifyListeners();
//   }

//   // System Status Methods
//   void updateSystemStatus(bool status) {
//     _isSwitched = status;
//     notifyListeners();
//   }

//   // Sensor Data Methods
//   void updateTemperature(String temp) {
//     _currentTemp = temp;
//     notifyListeners();
//   }

//   void updateHumidity(String humidity) {
//     _currentHumidity = humidity;
//     notifyListeners();
//   }

//   // HEPA Status Methods
//   void refreshHepaStatus() {
//     // Check sensor 10 fault bit for HEPA status
//     final faultBit = _prefs?.getString('F_Sensor_10_FAULT_BIT') ?? '0';
//     _isHepaHealthy = faultBit == '0';
//     _hepaStatusText = _isHepaHealthy ? "HEPA Healthy" : "HEPA Fault";
//     notifyListeners();
//   }

//   // Check if any sensor has fault
//   bool hasSensorFault() {
//     for (int i = 1; i <= 10; i++) {
//       final faultBit = _prefs?.getString('F_Sensor_${i}_FAULT_BIT') ?? '0';
//       if (faultBit == '1') return true;
//     }
//     return false;
//   }

//   // Reset all sensors to no fault (for testing)
//   void resetAllSensorsToNoFault() {
//     for (int i = 1; i <= 10; i++) {
//       _prefs?.setString('F_Sensor_${i}_FAULT_BIT', '0');
//     }
//     refreshHepaStatus();
//     notifyListeners();
//   }
// }
