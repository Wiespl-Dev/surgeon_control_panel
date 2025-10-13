// temperature_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/usb_serial.dart';
import 'dart:typed_data';

class TemperatureState with ChangeNotifier {
  double _pendingTemperature = 25.0;
  String? lastReceivedValue;
  String? lastSentMessage;
  String temp = "--";

  UsbPort? _port;
  String usbStatus = "Disconnected";
  bool isConnected = false;
  String _incomingBuffer = "";

  late SharedPreferences _prefs;

  // Getters
  double get pendingTemperature => _pendingTemperature;
  String get currentTemperature => temp;

  // Initialize shared preferences
  Future<void> initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedValues();
  }

  void _loadSavedValues() {
    temp = _prefs.getString('current_temperature') ?? "--";
    _pendingTemperature = _prefs.getDouble('setpoint_temperature') ?? 25.0;
    notifyListeners();

    print(
      "Loaded saved values - Current: $temp, Setpoint: $_pendingTemperature",
    );
  }

  void _saveCurrentTemperature(String value) {
    _prefs.setString('current_temperature', value);
    print("Saved current temperature: $value");
  }

  void _saveSetpointTemperature(double value) {
    _prefs.setDouble('setpoint_temperature', value);
    print("Saved setpoint temperature: $value");
  }

  // Update pending temperature
  void updatePendingTemperature(double value) {
    _pendingTemperature = value.clamp(15.0, 35.0);
    notifyListeners();
  }

  // USB Methods
  Future<void> initUsb() async {
    try {
      usbStatus = "Scanning for USB devices...";
      notifyListeners();

      List<UsbDevice> devices = await UsbSerial.listDevices();
      print("Found ${devices.length} USB devices");

      if (devices.isEmpty) {
        usbStatus = "No USB devices found";
        isConnected = false;
        notifyListeners();
        return;
      }

      UsbDevice device = devices.first;
      print("Connecting to: ${device.deviceName}");

      usbStatus = "Connecting to ${device.deviceName}...";
      notifyListeners();

      _port = await device.create();
      bool open = await _port!.open();

      if (open) {
        await _port!.setDTR(true);
        await _port!.setRTS(true);
        await _port!.setPortParameters(9600, 8, 1, 0);

        usbStatus = "Connected to ${device.deviceName}";
        isConnected = true;
        notifyListeners();

        print("USB connected successfully");
        _port!.inputStream?.listen(_onDataReceived);
      } else {
        usbStatus = "Failed to open USB port";
        isConnected = false;
        notifyListeners();
      }
    } catch (e) {
      print("USB Error: $e");
      usbStatus = "Error: $e";
      isConnected = false;
      notifyListeners();
    }
  }

  void _onDataReceived(Uint8List data) {
    String str = String.fromCharCodes(data);
    print("Received RAW chunk: $str");

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
    print("Processing complete message: $completeMessage");
    lastReceivedValue = completeMessage;
    _parseStructuredData(completeMessage);
  }

  void _parseStructuredData(String data) {
    try {
      print("Parsing complete message: $data");

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

        print("Parsed data: $parsedData");

        // Parse current temperature (C_OT_TEMP:239 = 23.9°C)
        if (parsedData.containsKey('C_OT_TEMP')) {
          String tempStr = parsedData['C_OT_TEMP'].toString();
          if (tempStr.length >= 2) {
            // Convert "239" to "23.9"
            String wholePart = tempStr.substring(0, tempStr.length - 1);
            String decimalPart = tempStr.substring(tempStr.length - 1);
            temp = '$wholePart.$decimalPart';
            print("Parsed temperature: $temp°C");
            _saveCurrentTemperature(temp);
          } else {
            temp = tempStr;
            _saveCurrentTemperature(temp);
          }
        } else {
          print("C_OT_TEMP key not found in parsed data");
        }

        // Parse set temperature (S_TEMP_SETPT:215 = 21.5°C)
        if (parsedData.containsKey('S_TEMP_SETPT')) {
          String setTempStr = parsedData['S_TEMP_SETPT'].toString();
          if (setTempStr.length >= 2) {
            // Convert "215" to 21.5
            String numericPart = setTempStr.substring(0, setTempStr.length - 1);
            _pendingTemperature = double.parse(numericPart).toDouble();
            print("Parsed set temperature: $_pendingTemperature°C");
            _saveSetpointTemperature(_pendingTemperature);
          }
        } else {
          print("S_TEMP_SETPT key not found in parsed data");
        }

        notifyListeners();
      } else {
        print("Data doesn't have proper structure: $data");
      }
    } catch (e) {
      print("Error parsing structured data: $e");
      print("Data that caused error: $data");
    }
  }

  void sendCompleteStructure() {
    if (_port == null || !isConnected) {
      throw Exception("USB not connected");
    }

    List<String> pairs = [];

    pairs.add('SR_WSL:200001');
    pairs.add('C_PRESSURE_1:000');
    pairs.add('C_PRESSURE_1_SIGN_BIT:1');
    pairs.add('C_PRESSURE_2:000');
    pairs.add('C_PRESSURE_2_SIGN_BIT:1');

    // Convert current temperature to 3-digit format
    String tempValue = "250"; // default
    if (temp != "--") {
      try {
        double currentTemp = double.parse(temp);
        tempValue = (currentTemp * 10).toInt().toString().padLeft(3, '0');
      } catch (e) {
        tempValue = "250";
      }
    }
    pairs.add('C_OT_TEMP:$tempValue');
    pairs.add('C_RH:500');

    for (int i = 1; i <= 10; i++) {
      pairs.add('F_Sensor_${i}_FAULT_BIT:0');
      pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
      pairs.add('S_Light_${i}_ON_OFF:1');
      pairs.add('S_Light_${i}_Intensity:000');
    }

    pairs.add('S_IOT_TIMER:0060');
    pairs.add(
      'S_TEMP_SETPT:${(_pendingTemperature * 10).toInt().toString().padLeft(3, '0')}',
    );
    pairs.add('S_RH_SETPT:500');

    String command = '{${pairs.join(',')}}\n';
    _port!.write(Uint8List.fromList(command.codeUnits));

    lastSentMessage = command.trim();
    _saveSetpointTemperature(_pendingTemperature);

    print("Sent: $command");
    notifyListeners();
  }

  void reconnectUsb() {
    initUsb();
  }

  void requestStatus() {
    if (_port != null && isConnected) {
      String command = "STATUS\n";
      _port!.write(Uint8List.fromList(command.codeUnits));
      print("Sent STATUS request");
    }
  }

  @override
  void dispose() {
    _port?.close();
    super.dispose();
  }
}
