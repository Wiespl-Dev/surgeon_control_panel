import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:typed_data';

class GlobalUsbProvider with ChangeNotifier {
  // USB Connection
  UsbPort? _port;
  String usbStatus = "Disconnected";
  bool isConnected = false;
  String _incomingBuffer = "";
  StreamSubscription? _inputStreamSubscription;
  StreamSubscription<UsbEvent>? _usbEventSubscription;

  UsbDevice? _connectedDevice;

  // CH340/CH341 Device IDs (in DECIMAL)
  // VID: 0x1A86 = 6790
  // PID: 0x7523 = 29987
  static const int CH340_VID = 6790;
  static const int CH340_PID = 29987;

  // Temperature State
  double _pendingTemperature = 25.0;
  String temp = "--";
  String _receivedData = ""; // ADD THIS - for GasStatusPage to access
  // Humidity State
  double _pendingHumidity = 50.0;
  String humidity = "--";

  // Light State
  List<int> _lightIntensities = List.filled(7, 0);
  List<bool> _lightStates = List.filled(7, false);
  bool _nightMode = false;

  // System Status (from HomeProvider)
  bool _isSwitched = false;

  // HEPA Status (from HomeProvider)
  bool _isHepaHealthy = true;
  String _hepaStatusText = "HEPA Healthy";

  // OR Status Provider Functions
  bool _defumigation = false; // Light 9
  bool _orNightMode = false; // Light 8
  int _pressure1 = 0; // C_PRESSURE_1 with sign
  bool _isPressurePositive = true; // Track pressure sign

  // Audio functionality
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false;
  bool _isAlertPlaying = false;

  // Message tracking
  String? lastReceivedValue;
  String? lastSentMessage;

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Auto-reconnect mechanism
  Timer? _reconnectTimer;
  Timer? _statusRequestTimer;
  bool _manualDisconnect = false;
  static const Duration _reconnectInterval = Duration(seconds: 5);
  static const Duration _statusRequestInterval = Duration(seconds: 10);

  // Command protection
  DateTime? _lastCommandTime;
  static const Duration _commandCooldown = Duration(milliseconds: 500);
  bool _isSendingCommand = false;

  // Getters
  double get pendingTemperature => _pendingTemperature;
  String get currentTemperature => temp;
  double get pendingHumidity => _pendingHumidity;
  String get currentHumidity => humidity;
  List<int> get lightIntensities => _lightIntensities;
  List<bool> get lightStates => _lightStates;
  bool get nightMode => _nightMode;
  bool get allLightsState => _lightStates.any((state) => state);
  String get receivedData => _receivedData;
  // HomeProvider Getters
  bool get isSwitched => _isSwitched;
  bool get isHepaHealthy => _isHepaHealthy;
  String get hepaStatusText => _hepaStatusText;

  // OR Status Provider Getters
  bool get defumigation => _defumigation;
  bool get orNightMode => _orNightMode;
  int get pressure1 => _pressure1;
  bool get isPressurePositive => _isPressurePositive;

  // Audio Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isMuted => _isMuted;
  bool get isAlertPlaying => _isAlertPlaying;

  // Initialize shared preferences - CALL THIS ONLY ONCE
  Future<void> initSharedPreferences() async {
    if (_isInitialized) {
      print("GlobalUsbProvider already initialized, skipping...");
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    await _loadSavedValues();
    _isInitialized = true;
    notifyListeners(); // Notify after loading values
    print("GlobalUsbProvider initialized successfully");
  }

  // Audio Methods
  void toggleMute() {
    _isMuted = !_isMuted;
    _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    notifyListeners();
  }

  void setAlertPlaying(bool value) {
    _isAlertPlaying = value;
    notifyListeners();
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _isAlertPlaying = false;
    notifyListeners();
  }

  // Function to start active USB monitoring
  void startUsbMonitoring() {
    // 1. Initial connection attempt (will trigger permission dialog if needed)
    initUsb();

    // 2. Start listening for USB connect/disconnect events
    _usbEventSubscription?.cancel(); // Cancel any previous subscription
    _usbEventSubscription = UsbSerial.usbEventStream!.listen((UsbEvent event) {
      print(
        "USB Event received: ${event.event} for device ${event.device?.deviceName}",
      );
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        // Device attached - trigger connection attempt
        Future.delayed(const Duration(seconds: 1), () {
          if (!isConnected && !_manualDisconnect) {
            print("USB ATTACHED event: Attempting connection...");
            initUsb();
          }
        });
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        // Device detached - handle connection loss if it was our port
        if (_connectedDevice != null &&
            event.device?.deviceName == _connectedDevice!.deviceName) {
          print("USB DETACHED event: Handling connection loss...");
          _handleConnectionLoss();
        }
      }
    });

    // 3. Ensure the auto-reconnect timer is running as a fallback
    _startAutoReconnectTimer();
  }

  Future<void> _loadSavedValues() async {
    // Temperature
    temp = _prefs.getString('current_temperature') ?? "--";
    _pendingTemperature = _prefs.getDouble('setpoint_temperature') ?? 25.0;

    // Humidity
    humidity = _prefs.getString('current_humidity') ?? "--";
    _pendingHumidity = _prefs.getDouble('setpoint_humidity') ?? 50.0;

    // System Status
    _isSwitched = _prefs.getBool('system_switched') ?? false;

    // OR Status Provider Values
    _defumigation = _prefs.getBool('or_defumigation') ?? false;
    _orNightMode = _prefs.getBool('or_night_mode') ?? false;

    // Lights - Load with detailed logging
    List<String>? intensityStrings = _prefs.getStringList('light_intensities');
    List<String>? stateStrings = _prefs.getStringList('light_states');

    if (intensityStrings != null &&
        stateStrings != null &&
        intensityStrings.length == 7 &&
        stateStrings.length == 7) {
      _lightIntensities = intensityStrings
          .map((s) => int.tryParse(s) ?? 0)
          .toList();
      _lightStates = stateStrings.map((s) => s == 'true').toList();
      _nightMode = !_lightStates.any((state) => state);
    } else {
      _lightStates = List.filled(7, false);
      _lightIntensities = List.filled(7, 0);
      _nightMode = true;
      await _saveLightSettings();
    }

    // Load HEPA status
    refreshHepaStatus();

    print(
      "Loaded saved values - Temp: $temp/$_pendingTemperature, Humidity: $humidity/$_pendingHumidity, System: $_isSwitched, Lights: $_lightStates",
    );
  }

  // Save methods
  void _saveCurrentTemperature(String value) {
    _prefs.setString('current_temperature', value);
  }

  void _saveSetpointTemperature(double value) {
    _prefs.setDouble('setpoint_temperature', value);
  }

  void _saveCurrentHumidity(String value) {
    _prefs.setString('current_humidity', value);
  }

  void _saveSetpointHumidity(double value) {
    _prefs.setDouble('setpoint_humidity', value);
  }

  Future<void> _saveLightSettings() async {
    List<String> intensityStrings = _lightIntensities
        .map((i) => i.toString())
        .toList();
    List<String> stateStrings = _lightStates.map((b) => b.toString()).toList();

    await _prefs.setStringList('light_intensities', intensityStrings);
    await _prefs.setStringList('light_states', stateStrings);
  }

  // OR Status Provider Save Methods
  void _saveORStatusSettings() async {
    await _prefs.setBool('or_defumigation', _defumigation);
    await _prefs.setBool('or_night_mode', _orNightMode);
  }

  // Temperature methods
  void updatePendingTemperature(double value) {
    _pendingTemperature = value.clamp(15.0, 35.0);
    notifyListeners();
  }

  // Humidity methods
  void updatePendingHumidity(double value) {
    _pendingHumidity = value.clamp(0.0, 100.0);
    notifyListeners();
  }

  // System Status Methods (from HomeProvider)
  void updateSystemStatus(bool status) {
    _isSwitched = status;
    _prefs.setBool('system_switched', status);
    notifyListeners();
  }

  // OR Status Provider Methods
  void toggleDefumigation(bool newValue) {
    _defumigation = newValue;
    _prefs.setBool('or_defumigation', _defumigation);
    sendCompleteStructure();
    notifyListeners();
  }

  void toggleORNightMode(bool newValue) {
    _orNightMode = newValue;
    _prefs.setBool('or_night_mode', _orNightMode);
    sendCompleteStructure();
    notifyListeners();
  }

  // Sensor Data Methods (from HomeProvider)
  void updateTemperature(String temp) {
    this.temp = temp;
    _saveCurrentTemperature(temp);
    notifyListeners();
  }

  void updateHumidity(String humidity) {
    this.humidity = humidity;
    _saveCurrentHumidity(humidity);
    notifyListeners();
  }

  // HEPA Status Methods (from HomeProvider)
  void refreshHepaStatus() {
    // Read the fault bit from SharedPreferences
    final faultBit = _prefs.getString('F_Sensor_10_FAULT_BIT') ?? '0';
    _isHepaHealthy = faultBit == '0';
    _hepaStatusText = _isHepaHealthy ? "HEPA Healthy" : "HEPA Fault";
    notifyListeners();
  }

  bool hasSensorFault() {
    for (int i = 1; i <= 10; i++) {
      final faultBit = _prefs.getString('F_Sensor_${i}_FAULT_BIT') ?? '0';
      if (faultBit == '1') return true;
    }
    return false;
  }

  void resetAllSensorsToNoFault() {
    for (int i = 1; i <= 10; i++) {
      _prefs.setString('F_Sensor_${i}_FAULT_BIT', '0');
    }
    refreshHepaStatus();
    notifyListeners();
  }

  // Light methods - ALWAYS save when changing lights
  void handleLightChange(int lightIndex, bool? turnOn, int? intensity) {
    if (turnOn != null) {
      _lightStates[lightIndex] = turnOn;
      if (!turnOn) _lightIntensities[lightIndex] = 0;
    }
    if (intensity != null) {
      _lightIntensities[lightIndex] = intensity.clamp(0, 100);
      if (intensity > 0) _lightStates[lightIndex] = true;
    }

    _nightMode = !_lightStates.any((state) => state);

    _saveLightSettings();
    notifyListeners();

    if (isConnected) {
      sendCompleteStructure();
    }
  }

  void toggleNightMode() {
    _nightMode = !_nightMode;
    if (_nightMode) {
      for (int i = 0; i < 7; i++) {
        _lightStates[i] = false;
        _lightIntensities[i] = 0;
      }
    }
    _saveLightSettings();
    if (isConnected) {
      sendCompleteStructure();
    }
    notifyListeners();
  }

  void toggleAllLights() {
    bool allLightsOn = _lightStates.every(
      (state) => state && _lightIntensities[_lightStates.indexOf(state)] > 0,
    );
    bool newState = !allLightsOn;

    for (int i = 0; i < 7; i++) {
      _lightStates[i] = newState;
      _lightIntensities[i] = newState ? 50 : 0;
    }

    _nightMode = !newState;
    _saveLightSettings();
    if (isConnected) {
      sendCompleteStructure();
    }
    notifyListeners();
  }

  void _cleanupConnection() {
    _inputStreamSubscription?.cancel();
    _inputStreamSubscription = null;
    _statusRequestTimer?.cancel();
    _statusRequestTimer = null;
    _port?.close();
    _port = null;
    // Clear the stored connected device
    _connectedDevice = null;
  }

  Future<void> initUsb({int retry = 0}) async {
    try {
      if (isConnected && _port != null) {
        return;
      }

      _cleanupConnection();

      usbStatus = "Scanning for USB devices... (attempt ${retry + 1})";
      notifyListeners();

      if (retry == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      List<UsbDevice> devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        if (retry < 5) {
          await Future.delayed(const Duration(milliseconds: 500));
          return initUsb(retry: retry + 1);
        }
        usbStatus = "No USB devices found";
        isConnected = false;
        notifyListeners();
        _startAutoReconnectTimer();
        return;
      }

      // Explicitly look for the CH340 serial device
      UsbDevice? targetDevice;
      for (var device in devices) {
        if (device.vid == CH340_VID && device.pid == CH340_PID) {
          targetDevice = device;
          break;
        }
      }

      if (targetDevice == null) {
        usbStatus = "CH340 serial device not found.";
        isConnected = false;
        notifyListeners();
        _startAutoReconnectTimer();
        return;
      }

      UsbDevice device = targetDevice;

      _port = await device.create();
      _connectedDevice = device;

      if (_port == null) {
        throw "Failed to create USB port";
      }

      await Future.delayed(const Duration(milliseconds: 300));

      // CRITICAL: This attempts to open the port and triggers the permission dialog
      bool open = await _port!.open();

      if (!open) {
        _cleanupConnection();
        usbStatus = "Awaiting USB Permission or device busy. Retrying soon...";
        isConnected = false;
        notifyListeners();

        // Wait 2 seconds for the OS to process the permission grant/device setup.
        Future.delayed(const Duration(seconds: 2), () {
          if (!isConnected && !_manualDisconnect) {
            initUsb(); // Force an immediate retry now
          }
        });

        _startAutoReconnectTimer();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 100));
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(9600, 8, 1, 0);

      usbStatus = "Connected to ${device.deviceName}";
      isConnected = true;
      _manualDisconnect = false;
      notifyListeners();

      // Cancel any pending reconnect timers
      _reconnectTimer?.cancel();

      // Set up input stream listener with proper error handling
      _inputStreamSubscription = _port!.inputStream?.listen(
        _onDataReceived,
        onError: (error) {
          print("Stream error: $error");
          _handleConnectionLoss();
        },
        onDone: () {
          print("Stream closed by device");
          _handleConnectionLoss();
        },
        cancelOnError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Start periodic status requests
      _startStatusRequestTimer();
    } catch (e) {
      print("USB init error: $e");
      usbStatus = "Error: $e";
      isConnected = false;
      _cleanupConnection();
      notifyListeners();

      _startAutoReconnectTimer();
    }
  }

  void _handleConnectionLoss() {
    isConnected = false;
    usbStatus = "Connection lost, reconnecting...";
    _cleanupConnection();
    notifyListeners();
    if (!_manualDisconnect) {
      _startAutoReconnectTimer();
    }
  }

  void _startAutoReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(_reconnectInterval, (_) {
      if (!isConnected && !_manualDisconnect) {
        initUsb();
      }
    });
  }

  void _startStatusRequestTimer() {
    _statusRequestTimer?.cancel();
    _statusRequestTimer = Timer.periodic(_statusRequestInterval, (_) {
      if (isConnected) {
        // Use sendCompleteStructure to periodically request status by sending
        // a full command, which often triggers a response with the current state.
        sendCompleteStructure();
      }
    });
  }

  void _onDataReceived(Uint8List data) {
    String str = String.fromCharCodes(data);

    _incomingBuffer += str;
    _receivedData = _incomingBuffer;
    // Process complete messages
    int newlineIndex;
    while ((newlineIndex = _incomingBuffer.indexOf('\n')) != -1) {
      String completeMessage = _incomingBuffer
          .substring(0, newlineIndex)
          .trim();
      _incomingBuffer = _incomingBuffer.substring(newlineIndex + 1);

      if (completeMessage.isNotEmpty) {
        _processCompleteMessage(completeMessage);
      }
    }

    // Process JSON-style messages if they are not newline-terminated
    if (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}')) {
      _processCompleteMessage(_incomingBuffer);
      _incomingBuffer = "";
    }
  }

  void _processCompleteMessage(String completeMessage) {
    lastReceivedValue = completeMessage;
    _parseStructuredData(completeMessage);
  }

  // Helper method for pressure sign
  int _applySign(String rawValue, String? signBit) {
    int val = int.tryParse(rawValue) ?? 0;
    if (signBit == null) return val;
    if (signBit == '1') {
      return val;
    } else {
      return -val;
    }
  }

  // Helper method to log value changes
  void _logValueChanges(String type, String oldValue, String newValue) {
    if (oldValue != newValue) {
      print("🔄 $type changed: $oldValue → $newValue");
    } else {
      print("✅ $type unchanged: $oldValue");
    }
  }

  void _parseStructuredData(String data) async {
    try {
      if (!(data.startsWith('{') && data.endsWith('}'))) {
        print("❌ Invalid structured format: $data");
        return;
      }

      final pairs = data.substring(1, data.length - 1).split(',');
      final Map<String, dynamic> parsedData = {};

      for (String pair in pairs) {
        final int separatorIndex = pair.indexOf(':');
        if (separatorIndex == -1) continue;

        final key = pair.substring(0, separatorIndex).trim();
        final value = pair.substring(separatorIndex + 1).trim();
        parsedData[key] = value;

        // Save Fault Bits immediately
        if (key.startsWith('F_Sensor_') && key.endsWith('_FAULT_BIT')) {
          try {
            if (_prefs != null) await _prefs!.setString(key, value);
          } catch (e) {
            print("❌ Failed to save fault bit $key: $e");
          }
        }
      }

      final originalTemp = temp;
      final originalHumidity = humidity;
      final originalPendingTemp = _pendingTemperature;
      final originalPendingHumidity = _pendingHumidity;

      double? _parseScaledValue(
        String raw,
        double min,
        double max,
        String label,
      ) {
        try {
          final value = int.parse(raw) / 10.0;
          if (value >= min - 1 && value <= max + 1) return value;
          print("⚠️ $label out of range: $value");
        } catch (e) {
          print("❌ Error parsing $label: $e");
        }
        return null;
      }

      void _logValueChanges(String label, dynamic oldVal, dynamic newVal) {
        if (oldVal.toString() != newVal.toString()) {
          print("🔄 $label changed: $oldVal → $newVal");
        }
      }

      double _applySign(String value, String? signBit) {
        try {
          final doubleVal = double.parse(value) / 10.0;
          return (signBit == '1') ? doubleVal : -doubleVal;
        } catch (e) {
          print("❌ Error applying sign: $e");
          return 0.0;
        }
      }

      // 🌡️ Temperature (Current)
      if (parsedData.containsKey('C_OT_TEMP')) {
        final raw = parsedData['C_OT_TEMP'].toString();
        print("🔧 RAW C_OT_TEMP: '$raw'");
        final parsed = _parseScaledValue(raw, 15.0, 35.0, "Temperature");
        if (parsed != null) {
          final old = temp;
          temp = parsed.toStringAsFixed(1);
          _logValueChanges("Temperature", old, temp);
          _saveCurrentTemperature(temp);
        } else {
          print("⚠️ Keeping old temperature: $originalTemp");
        }
      } else {
        print("❌ C_OT_TEMP key not found");
      }

      // 🌡️ Temperature Setpoint
      if (parsedData.containsKey('S_TEMP_SETPT')) {
        final raw = parsedData['S_TEMP_SETPT'].toString();
        print("🔧 RAW S_TEMP_SETPT: '$raw'");
        final parsed = _parseScaledValue(raw, 15.0, 35.0, "Set Temperature");
        if (parsed != null) {
          final old = _pendingTemperature;
          _pendingTemperature = parsed;
          print("✅ Parsed S_TEMP_SETPT: $old → $_pendingTemperature°C");
          _saveSetpointTemperature(_pendingTemperature);
        } else {
          print("⚠️ Keeping old set temperature: $originalPendingTemp");
        }
      } else {
        print("❌ S_TEMP_SETPT key not found");
      }

      // 💧 Humidity (Current)
      if (parsedData.containsKey('C_RH')) {
        final raw = parsedData['C_RH'].toString();
        print("🔧 RAW C_RH: '$raw'");
        final parsed = _parseScaledValue(raw, 0.0, 100.0, "Humidity");
        if (parsed != null) {
          final old = humidity;
          humidity = parsed.toStringAsFixed(1);
          _logValueChanges("Humidity", old, humidity);
          _saveCurrentHumidity(humidity);
        } else {
          print("⚠️ Keeping old humidity: $originalHumidity");
        }
      } else {
        print("❌ C_RH key not found");
      }

      // 💧 Humidity Setpoint
      if (parsedData.containsKey('S_RH_SETPT')) {
        final raw = parsedData['S_RH_SETPT'].toString();
        print("🔧 RAW S_RH_SETPT: '$raw'");
        final parsed = _parseScaledValue(raw, 0.0, 100.0, "Set Humidity");
        if (parsed != null) {
          final old = _pendingHumidity;
          _pendingHumidity = parsed;
          print("✅ Parsed S_RH_SETPT: $old → $_pendingHumidity%");
          _saveSetpointHumidity(_pendingHumidity);
        } else {
          print("⚠️ Keeping old set humidity: $originalPendingHumidity");
        }
      } else {
        print("❌ S_RH_SETPT key not found");
      }

      // 🔵 Pressure
      if (parsedData.containsKey('C_PRESSURE_1')) {
        final sign = parsedData['C_PRESSURE_1_SIGN_BIT'];
        _pressure1 = _applySign(
          parsedData['C_PRESSURE_1'] ?? '0',
          sign,
        ).toInt();
        _isPressurePositive = sign == '1';
        print(
          "✅ Parsed Pressure: $_pressure1 (${_isPressurePositive ? '+' : '-'})",
        );
      }

      // 💡 OR Status Lights (8–10)
      for (int i = 8; i <= 10; i++) {
        final key = 'S_Light_${i}_ON_OFF';
        if (parsedData.containsKey(key)) {
          final on = parsedData[key] == '1';
          try {
            if (_prefs != null) {
              if (i == 8) {
                _orNightMode = on;
                await _prefs!.setBool('or_night_mode', on);
              } else if (i == 9) {
                _defumigation = on;
                await _prefs!.setBool('or_defumigation', on);
              } else if (i == 10 && _isSwitched != on) {
                _isSwitched = on;
                await _prefs!.setBool('system_switched', on);
              }
            }
          } catch (e) {
            print("❌ Failed to persist OR light $i: $e");
          }
        }
      }

      // 💡 Regular Lights (1–7)
      bool anyLightOn = false;
      for (int i = 1; i <= 7; i++) {
        final onKey = 'S_Light_${i}_ON_OFF';
        final intensityKey = 'S_Light_${i}_Intensity';

        if (parsedData.containsKey(onKey)) {
          final state = parsedData[onKey] == '1';
          if (i - 1 < _lightStates.length) {
            _lightStates[i - 1] = state;
            if (state) anyLightOn = true;
          } else {
            print("⚠️ Light index out of range: $i");
          }
        }

        if (parsedData.containsKey(intensityKey)) {
          try {
            final intensity = int.parse(parsedData[intensityKey].toString());
            if (i - 1 < _lightIntensities.length) {
              _lightIntensities[i - 1] = intensity;
            }
          } catch (e) {
            print("❌ Error parsing $intensityKey: $e");
          }
        }
      }

      _nightMode = !anyLightOn;
      _saveLightSettings();

      refreshHepaStatus();
      notifyListeners();
    } catch (e) {
      print("❌ Error parsing structured data: $e");
      print("❌ Data that caused error: $data");
    }
  }

  // Command protection helper
  bool _canSendCommand() {
    final now = DateTime.now();
    if (_isSendingCommand) {
      print("⏳ Already sending command, please wait");
      return false;
    }

    if (_lastCommandTime != null &&
        now.difference(_lastCommandTime!) < _commandCooldown) {
      print("⏳ Command cooldown - please wait");
      return false;
    }

    if (_port == null || !isConnected) {
      print("Cannot send - USB not connected");
      return false;
    }

    return true;
  }

  void sendTemperatureStructure() {
    if (_port == null || !isConnected) {
      print("Cannot send - USB not connected");
      return;
    }

    List<String> pairs = [];

    pairs.add('SR_WSL:250028');

    // Only send light states and intensities (1-10)
    for (int i = 1; i <= 10; i++) {
      pairs.add('S_Light_${i}_ON_OFF:${getLightState(i)}');
    }

    for (int i = 1; i <= 10; i++) {
      pairs.add('S_Light_${i}_Intensity:${getLightIntensity(i)}');
    }

    // Temperature setpoint ONLY (modified)
    int tempToSend = (_pendingTemperature * 10).toInt();
    String tempValue = tempToSend.toString().padLeft(3, '0');
    pairs.add('S_TEMP_SETPT:$tempValue');

    // Keep existing humidity setpoint (unchanged)
    int humidityToSend = (_pendingHumidity * 10).toInt();
    String humidityValue = humidityToSend.toString().padLeft(3, '0');
    pairs.add('S_RH_SETPT:$humidityValue');

    String command = '{${pairs.join(',')}}\n';
    _sendCommand(command, "TEMPERATURE");

    print(
      "📤 Sent TEMPERATURE ONLY - setpoint: $_pendingTemperature°C -> $tempValue",
    );
  }

  void sendHumidityStructure() {
    if (_port == null || !isConnected) {
      print("Cannot send - USB not connected");
      return;
    }

    List<String> pairs = [];

    pairs.add('SR_WSL:250028');

    // Only send light states and intensities (1-10)
    for (int i = 1; i <= 10; i++) {
      pairs.add('S_Light_${i}_ON_OFF:${getLightState(i)}');
    }

    for (int i = 1; i <= 10; i++) {
      pairs.add('S_Light_${i}_Intensity:${getLightIntensity(i)}');
    }

    // Keep existing temperature setpoint (unchanged)
    int tempToSend = (_pendingTemperature * 10).toInt();
    String tempValue = tempToSend.toString().padLeft(3, '0');
    pairs.add('S_TEMP_SETPT:$tempValue');

    // Humidity setpoint ONLY (modified)
    int humidityToSend = (_pendingHumidity * 10).toInt();
    String humidityValue = humidityToSend.toString().padLeft(3, '0');
    pairs.add('S_RH_SETPT:$humidityValue');

    String command = '{${pairs.join(',')}}\n';
    _sendCommand(command, "HUMIDITY");

    print(
      "📤 Sent HUMIDITY ONLY - setpoint: $_pendingHumidity% -> $humidityValue",
    );
  }

  // Keep the original complete structure for reference
  void sendCompleteStructure() {
    if (_port == null || !isConnected) {
      print("Cannot send - USB not connected");
      return;
    }

    List<String> pairs = [];

    pairs.add('SR_WSL:250028');

    // Only send light states and intensities (1-10)
    for (int i = 1; i <= 10; i++) {
      pairs.add('S_Light_${i}_ON_OFF:${getLightState(i)}');
    }

    for (int i = 1; i <= 10; i++) {
      pairs.add('S_Light_${i}_Intensity:${getLightIntensity(i)}');
    }

    // Both setpoints
    int tempToSend = (_pendingTemperature * 10).toInt();
    String tempValue = tempToSend.toString().padLeft(3, '0');
    pairs.add('S_TEMP_SETPT:$tempValue');

    int humidityToSend = (_pendingHumidity * 10).toInt();
    String humidityValue = humidityToSend.toString().padLeft(3, '0');
    pairs.add('S_RH_SETPT:$humidityValue');

    String command = '{${pairs.join(',')}}\n';
    _sendCommand(command, "COMPLETE");
  }

  // Helper methods
  String getLightState(int index) {
    if (index >= 1 && index <= 7) {
      return _lightStates[index - 1] ? '1' : '0';
    } else if (index == 8) {
      return _orNightMode ? '1' : '0';
    } else if (index == 9) {
      return _defumigation ? '1' : '0';
    } else if (index == 10) {
      return _isSwitched ? '1' : '0';
    }
    return '0';
  }

  String getLightIntensity(int index) {
    if (index >= 1 && index <= 7) {
      return _lightIntensities[index - 1].toString().padLeft(3, '0');
    } else if (index == 8) {
      return _orNightMode ? '080' : '000'; // Match your example
    } else if (index == 9) {
      return _defumigation ? '090' : '000'; // Match your example
    } else if (index == 10) {
      return _isSwitched ? '050' : '000'; // Match your example
    }
    return '000';
  }

  void _sendCommand(String command, String type) {
    _port!.write(Uint8List.fromList(command.codeUnits));
    lastSentMessage = command.trim();

    if (type == "TEMPERATURE") {
      _saveSetpointTemperature(_pendingTemperature);
    } else if (type == "HUMIDITY") {
      _saveSetpointHumidity(_pendingHumidity);
    } else if (type == "COMPLETE") {
      _saveSetpointTemperature(_pendingTemperature);
      _saveSetpointHumidity(_pendingHumidity);
    }

    _saveLightSettings();
    _saveORStatusSettings();

    print("📤 Sent $type command: ${command.trim()}");
    notifyListeners();
  }

  void reconnectUsb() {
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    isConnected = false;
    _cleanupConnection();
    initUsb();
  }

  void requestSensorData() {
    if (_port != null && isConnected) {
      String command = "GET_SENSORS\n";
      _port!.write(Uint8List.fromList(command.codeUnits));
    }
  }

  void testUsbCommunication() {
    if (_port != null && isConnected) {
      String testCommand = "TEST\n";
      _port!.write(Uint8List.fromList(testCommand.codeUnits));

      Future.delayed(const Duration(seconds: 2), () {
        sendCompleteStructure();
      });
    }
  }

  // System power control with complete structure
  void toggleSystemPower(bool turnOn) {
    // 1. Update UI state immediately for responsiveness
    _isSwitched = turnOn;
    _prefs.setBool('system_switched', turnOn);

    print("✅ System status updated to: $_isSwitched");
    notifyListeners();

    // 2. Send the COMPLETE, updated structure to the device
    // This ensures all other settings (temp/humidity setpoints, lights) are preserved
    if (_port != null && isConnected) {
      sendCompleteStructure();
      print(
        "📤 System power ${turnOn ? 'ON' : 'OFF'} command sent via complete structure.",
      );
    } else {
      print("⚠️ USB not connected, but UI state updated to: $turnOn");
    }
  }

  // Use toggleSystemPower internally
  void toggleSystem(bool newValue) {
    toggleSystemPower(newValue);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _statusRequestTimer?.cancel();
    _inputStreamSubscription?.cancel();
    _usbEventSubscription?.cancel();
    _port?.close();
    _audioPlayer.dispose();
    super.dispose();
  }
}
