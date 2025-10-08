import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/usb_serial.dart';

class ORStatusProvider with ChangeNotifier {
  // Toggles mapped to Light 8, 9, 10
  bool _defumigation = false; // Light 9
  bool _systemOn = false; // Light 10
  bool _nightMode = false; // Light 8

  // Sensor displays
  double _temperature = 0.0; // derived from C_OT_TEMP / 10
  double _humidity = 0.0; // derived from C_RH / 10
  int _pressure1 = 0; // C_PRESSURE_1 with sign
  bool _isPressurePositive = true; // Track pressure sign

  // USB
  UsbPort? _port;
  bool _isConnected = false;
  String _incomingBuffer = "";

  // Shared Preferences keys
  static const String _kDefumKey = 'or_defumigation';
  static const String _kSysKey = 'or_system_on';
  static const String _kNightKey = 'or_night_mode';

  // Getters
  bool get defumigation => _defumigation;
  bool get systemOn => _systemOn;
  bool get nightMode => _nightMode;
  double get temperature => _temperature;
  double get humidity => _humidity;
  int get pressure1 => _pressure1;
  bool get isPressurePositive => _isPressurePositive;
  bool get isConnected => _isConnected;

  // Shared Preferences
  late SharedPreferences _prefs;

  // Initialize preferences
  Future<void> initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _defumigation = _prefs.getBool(_kDefumKey) ?? false;
    _systemOn = _prefs.getBool(_kSysKey) ?? false;
    _nightMode = _prefs.getBool(_kNightKey) ?? false;
    notifyListeners();
  }

  // Toggle methods
  void toggleDefumigation(bool newValue) {
    _defumigation = newValue;
    _prefs.setBool(_kDefumKey, _defumigation);
    _sendCompleteStructure();
    notifyListeners();
  }

  void toggleSystem(bool newValue) {
    _systemOn = newValue;
    _prefs.setBool(_kSysKey, _systemOn);
    _sendCompleteStructure();
    notifyListeners();
  }

  void toggleNightMode(bool newValue) {
    _nightMode = newValue;
    _prefs.setBool(_kNightKey, _nightMode);
    _sendCompleteStructure();
    notifyListeners();
  }

  // USB Methods
  Future<void> initUsb() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        _isConnected = false;
        notifyListeners();
        return;
      }
      UsbDevice device = devices.first;
      _port = await device.create();
      bool open = await _port!.open();

      if (open) {
        await _port!.setPortParameters(9600, 8, 1, 0); //115200
        _port!.inputStream?.listen(_onDataReceived);
        _isConnected = true;
        notifyListeners();
        _sendCommand("STATUS");
        _sendCompleteStructure();
      }
    } catch (e) {
      print("USB Error in ORStatusProvider: $e");
      _isConnected = false;
      notifyListeners();
    }
  }

  void _onDataReceived(Uint8List data) {
    String str = String.fromCharCodes(data);
    _incomingBuffer += str;

    print("Raw USB data received: ${String.fromCharCodes(data)}");
    print("Current buffer: $_incomingBuffer");

    List<String> lines = _incomingBuffer.split('\n');

    for (int i = 0; i < lines.length - 1; i++) {
      String line = lines[i].trim();
      if (line.isNotEmpty) {
        _processCompleteMessage(line);
      }
    }

    String lastLine = lines.last;
    if (lastLine.contains('{') && lastLine.contains('}')) {
      List<String> messages = [];
      int start = lastLine.indexOf('{');
      while (start != -1) {
        int end = lastLine.indexOf('}', start);
        if (end != -1) {
          messages.add(lastLine.substring(start, end + 1));
          start = lastLine.indexOf('{', end + 1);
        } else {
          break;
        }
      }

      for (String msg in messages) {
        _processCompleteMessage(msg);
      }

      int lastCompleteEnd = lastLine.lastIndexOf('}');
      if (lastCompleteEnd != -1) {
        _incomingBuffer = lastLine.substring(lastCompleteEnd + 1);
      } else {
        _incomingBuffer = lastLine;
      }
    } else {
      _incomingBuffer = lastLine;
    }
  }

  void _processCompleteMessage(String completeMessage) {
    String msg = completeMessage.trim();
    if (msg.startsWith('{') && msg.endsWith('}')) {
      _parseStructuredData(msg);
    } else {
      print("USB Received (non-structured): $msg");
    }
  }

  int _applySign(String rawValue, String? signBit) {
    int val = int.tryParse(rawValue) ?? 0;
    if (signBit == null) return val;
    if (signBit == '1') {
      return val;
    } else {
      return -val;
    }
  }

  void _parseStructuredData(String data) {
    try {
      String content = data.substring(1, data.length - 1);
      List<String> pairs = content.split(',');
      Map<String, String> parsed = {};
      for (var p in pairs) {
        final kv = p.split(':');
        if (kv.length >= 2) {
          String key = kv[0].trim();
          String value = kv.sublist(1).join(':').trim();
          parsed[key] = value;
        }
      }

      print("Parsed USB Data: $parsed");

      // Update state
      if (parsed.containsKey('C_OT_TEMP')) {
        String tempStr = parsed['C_OT_TEMP'] ?? '0';
        int rawTemp = int.tryParse(tempStr) ?? 0;
        _temperature = rawTemp / 10.0;
      }

      if (parsed.containsKey('C_RH')) {
        String rhStr = parsed['C_RH'] ?? '0';
        int rawRh = int.tryParse(rhStr) ?? 0;
        _humidity = rawRh / 10.0;
      }

      if (parsed.containsKey('C_PRESSURE_1')) {
        String? sign = parsed['C_PRESSURE_1_SIGN_BIT'];
        _pressure1 = _applySign(parsed['C_PRESSURE_1'] ?? '0', sign);
        _isPressurePositive = sign == '1';
      }

      for (int i = 1; i <= 10; i++) {
        String key = 'S_Light_${i}_ON_OFF';
        if (parsed.containsKey(key)) {
          bool on = parsed[key] == '1';
          if (i == 8) {
            _nightMode = on;
            _prefs.setBool(_kNightKey, _nightMode);
          } else if (i == 9) {
            _defumigation = on;
            _prefs.setBool(_kDefumKey, _defumigation);
          } else if (i == 10) {
            _systemOn = on;
            _prefs.setBool(_kSysKey, _systemOn);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print("Error parsing structured data: $e");
    }
  }

  void _sendCommand(String cmd) {
    if (_port != null && _isConnected) {
      String commandToSend = cmd + "\n";
      _port!.write(Uint8List.fromList(commandToSend.codeUnits));
      print("ORStatusProvider Sent: $commandToSend");
    } else {
      print("USB port not connected - cannot send: $cmd");
    }
  }

  void requestSensorData() {
    _sendCommand("GET_SENSORS");
  }

  void _sendCompleteStructure() {
    List<String> pairs = [];

    pairs.add('SR_WSL:250028');

    String p1raw = _pressure1.abs().toString().padLeft(3, '0');
    String p1sign = _isPressurePositive ? '1' : '0';

    pairs.add('C_PRESSURE_1:$p1raw');
    pairs.add('C_PRESSURE_1_SIGN_BIT:$p1sign');

    int tempRaw = (_temperature * 10).round();
    int rhRaw = (_humidity * 10).round();
    pairs.add('C_OT_TEMP:${tempRaw.toString().padLeft(3, '0')}');
    pairs.add('C_RH:${rhRaw.toString().padLeft(3, '0')}');

    for (int i = 1; i <= 10; i++) {
      if (i <= 7) {
        pairs.add('F_Sensor_${i}_FAULT_BIT:0');
        pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
        pairs.add('S_Light_${i}_ON_OFF:0');
        pairs.add('S_Light_${i}_Intensity:000');
      } else {
        bool state = false;
        if (i == 8) state = _nightMode;
        if (i == 9) state = _defumigation;
        if (i == 10) state = _systemOn;

        pairs.add('F_Sensor_${i}_FAULT_BIT:0');
        pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
        pairs.add('S_Light_${i}_ON_OFF:${state ? '1' : '0'}');
        pairs.add('S_Light_${i}_Intensity:${state ? '050' : '000'}');
      }
    }

    pairs.add('S_IOT_TIMER:0060');
    pairs.add('S_TEMP_SETPT:${tempRaw.toString().padLeft(3, '0')}');
    pairs.add('S_RH_SETPT:${rhRaw.toString().padLeft(3, '0')}');

    String command = '{${pairs.join(',')}}';
    _sendCommand(command);
  }

  // Cleanup
  void disposeUsb() {
    _port?.close();
  }
}
