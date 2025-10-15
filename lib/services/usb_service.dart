import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/usb_serial.dart';
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

  // Getters
  double get pendingTemperature => _pendingTemperature;
  String get currentTemperature => temp;
  double get pendingHumidity => _pendingHumidity;
  String get currentHumidity => humidity;
  List<int> get lightIntensities => _lightIntensities;
  List<bool> get lightStates => _lightStates;
  bool get nightMode => _nightMode;
  bool get allLightsState => _lightStates.any((state) => state);

  // HomeProvider Getters
  bool get isSwitched => _isSwitched;
  bool get isHepaHealthy => _isHepaHealthy;
  String get hepaStatusText => _hepaStatusText;

  // Initialize shared preferences - CALL THIS ONLY ONCE
  Future<void> initSharedPreferences() async {
    if (_isInitialized) {
      print("GlobalUsbProvider already initialized, skipping...");
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    await _loadSavedValues();
    _isInitialized = true;
    print("GlobalUsbProvider initialized successfully");
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
        // Small delay to allow Android OS to fully set up the device after a reboot/attach
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

    // Lights - Load with detailed logging
    List<String>? intensityStrings = _prefs.getStringList('light_intensities');
    List<String>? stateStrings = _prefs.getStringList('light_states');

    print("Loading light states from SharedPreferences:");
    print("Intensity strings: $intensityStrings");
    print("State strings: $stateStrings");

    if (intensityStrings != null &&
        stateStrings != null &&
        intensityStrings.length == 7 &&
        stateStrings.length == 7) {
      _lightIntensities = intensityStrings
          .map((s) => int.tryParse(s) ?? 0)
          .toList();
      _lightStates = stateStrings.map((s) => s == 'true').toList();
      _nightMode = !_lightStates.any((state) => state);

      print("✅ Successfully loaded light states: $_lightStates");
      print("✅ Successfully loaded light intensities: $_lightIntensities");
    } else {
      print("❌ No valid saved light states found, initializing defaults");
      _lightStates = List.filled(7, false);
      _lightIntensities = List.filled(7, 0);
      _nightMode = true;
      await _saveLightSettings();
    }

    // Load HEPA status
    refreshHepaStatus();

    notifyListeners();
    print(
      "Loaded saved values - Temp: $temp/$_pendingTemperature, Humidity: $humidity/$_pendingHumidity, System: $_isSwitched, Lights: $_lightStates",
    );
  }

  // Save methods
  void _saveCurrentTemperature(String value) {
    _prefs.setString('current_temperature', value);
    print("Saved current temperature: $value");
  }

  void _saveSetpointTemperature(double value) {
    _prefs.setDouble('setpoint_temperature', value);
    print("Saved setpoint temperature: $value");
  }

  void _saveCurrentHumidity(String value) {
    _prefs.setString('current_humidity', value);
    print("Saved current humidity: $value");
  }

  void _saveSetpointHumidity(double value) {
    _prefs.setDouble('setpoint_humidity', value);
    print("Saved setpoint humidity: $value");
  }

  Future<void> _saveLightSettings() async {
    List<String> intensityStrings = _lightIntensities
        .map((i) => i.toString())
        .toList();
    List<String> stateStrings = _lightStates.map((b) => b.toString()).toList();

    await _prefs.setStringList('light_intensities', intensityStrings);
    await _prefs.setStringList('light_states', stateStrings);
    print(
      "💡 Light settings SAVED - States: $_lightStates, Intensities: $_lightIntensities",
    );
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
    print("System status updated: $status");
    notifyListeners();
  }

  // Sensor Data Methods (from HomeProvider)
  void updateTemperature(String temp) {
    this.temp = temp;
    _saveCurrentTemperature(temp);
    print("Temperature updated: $temp");
    notifyListeners();
  }

  void updateHumidity(String humidity) {
    this.humidity = humidity;
    _saveCurrentHumidity(humidity);
    print("Humidity updated: $humidity");
    notifyListeners();
  }

  // HEPA Status Methods (from HomeProvider)
  void refreshHepaStatus() {
    final faultBit = _prefs.getString('F_Sensor_10_FAULT_BIT') ?? '0';
    _isHepaHealthy = faultBit == '0';
    _hepaStatusText = _isHepaHealthy ? "HEPA Healthy" : "HEPA Fault";
    print("HEPA status refreshed: $_hepaStatusText");
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
    print("All sensors reset to no fault");
    notifyListeners();
  }

  // Light methods - ALWAYS save when changing lights
  void handleLightChange(int lightIndex, bool? turnOn, int? intensity) {
    print(
      "🔄 Changing light $lightIndex - turnOn: $turnOn, intensity: $intensity",
    );
    print(
      "Before change - States: $_lightStates, Intensities: $_lightIntensities",
    );

    if (turnOn != null) {
      _lightStates[lightIndex] = turnOn;
      if (!turnOn) _lightIntensities[lightIndex] = 0;
    }
    if (intensity != null) {
      _lightIntensities[lightIndex] = intensity;
      if (intensity > 0) _lightStates[lightIndex] = true;
    }

    _nightMode = !_lightStates.any((state) => state);

    print(
      "After change - States: $_lightStates, Intensities: $_lightIntensities",
    );

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
    print("Cleaning up USB connection...");
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
      // If already connected, skip
      if (isConnected && _port != null) {
        print("Already connected, skipping...");
        return;
      }

      // Clean up any existing connection
      _cleanupConnection();

      usbStatus = "Scanning for USB devices... (attempt ${retry + 1})";
      notifyListeners();

      // Small delay to allow Android to enumerate
      if (retry == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      List<UsbDevice> devices = await UsbSerial.listDevices();
      print("Found ${devices.length} USB devices (attempt #${retry + 1})");

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
        print(
          "Found Device: ${device.deviceName} VID: ${device.vid} PID: ${device.pid}",
        );
        if (device.vid == CH340_VID && device.pid == CH340_PID) {
          targetDevice = device;
          print("✅ Found Target CH340/CH341 Device!");
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

      print(
        "Attempting to connect to: ${device.deviceName} (VID: ${device.vid}, PID: ${device.pid})",
      );

      _port = await device.create();
      _connectedDevice = device;

      if (_port == null) {
        throw "Failed to create USB port";
      }

      await Future.delayed(const Duration(milliseconds: 300));

      // CRITICAL: This attempts to open the port and triggers the permission dialog
      bool open = await _port!.open();

      if (!open) {
        // ----------------------------------------------------------------------------------
        // ⚡️ CRITICAL FIX: TARGETED DELAYED RE-ATTEMPT AFTER PERMISSION DIALOG IS SHOWN ⚡️
        // ----------------------------------------------------------------------------------
        _cleanupConnection();
        usbStatus = "Awaiting USB Permission or device busy. Retrying soon...";
        isConnected = false;
        notifyListeners();

        print("Port failed to open (likely permission related/busy port).");

        // Wait 2 seconds for the OS to process the permission grant/device setup.
        // Then attempt a single, dedicated retry.
        Future.delayed(const Duration(seconds: 2), () {
          if (!isConnected && !_manualDisconnect) {
            print(
              "2-Second Permission Delay Passed: Attempting forced reconnect.",
            );
            initUsb(); // Force an immediate retry now
          }
        });

        // Keep the 5-second timer running as a long-term fallback.
        _startAutoReconnectTimer();

        return; // Exit the current failed attempt
      }

      print("Port opened successfully, configuring...");

      await Future.delayed(const Duration(milliseconds: 100));
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(9600, 8, 1, 0);

      usbStatus = "Connected to ${device.deviceName}";
      isConnected = true;
      _manualDisconnect = false;
      notifyListeners();

      print("✅ USB Connected and configured!");

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
      requestStatus();

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
    print("Connection lost, initiating auto-reconnect...");
    isConnected = false;
    usbStatus = "Connection lost, reconnecting...";
    _cleanupConnection();
    notifyListeners();
    // Start auto-reconnect timer as a fallback/immediate recovery attempt
    if (!_manualDisconnect) {
      _startAutoReconnectTimer();
    }
  }

  void _startAutoReconnectTimer() {
    _reconnectTimer?.cancel();
    print("Starting auto-reconnect timer (${_reconnectInterval.inSeconds}s)");
    _reconnectTimer = Timer.periodic(_reconnectInterval, (_) {
      if (!isConnected && !_manualDisconnect) {
        print("Auto-reconnect attempt...");
        initUsb();
      }
    });
  }

  void _startStatusRequestTimer() {
    _statusRequestTimer?.cancel();
    _statusRequestTimer = Timer.periodic(_statusRequestInterval, (_) {
      if (isConnected) {
        print("Periodic status request");
        requestStatus();
      }
    });
  }

  void _onDataReceived(Uint8List data) {
    String str = String.fromCharCodes(data);
    print("Received data chunk: $str");

    _incomingBuffer += str;

    // Process complete messages
    if (_incomingBuffer.contains('\n')) {
      List<String> messages = _incomingBuffer.split('\n');

      for (int i = 0; i < messages.length - 1; i++) {
        String completeMessage = messages[i].trim();
        if (completeMessage.isNotEmpty) {
          _processCompleteMessage(completeMessage);
        }
      }

      _incomingBuffer = messages.last;
    }

    // Process JSON-style messages
    if (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}')) {
      _processCompleteMessage(_incomingBuffer);
      _incomingBuffer = "";
    }
  }

  void _processCompleteMessage(String completeMessage) {
    print("Processing message: $completeMessage");
    lastReceivedValue = completeMessage;
    _parseStructuredData(completeMessage);
  }

  void _parseStructuredData(String data) {
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

            if (key.startsWith('F_Sensor_') && key.endsWith('_FAULT_BIT')) {
              _prefs.setString(key, value);
            }
          }
        }

        // Parse temperature
        if (parsedData.containsKey('C_OT_TEMP')) {
          String tempStr = parsedData['C_OT_TEMP'].toString();
          if (tempStr.length >= 2) {
            String wholePart = tempStr.substring(0, tempStr.length - 1);
            String decimalPart = tempStr.substring(tempStr.length - 1);
            temp = '$wholePart.$decimalPart';
            _saveCurrentTemperature(temp);
          } else {
            temp = tempStr;
            _saveCurrentTemperature(temp);
          }
        }

        // Parse set temperature
        if (parsedData.containsKey('S_TEMP_SETPT')) {
          String setTempStr = parsedData['S_TEMP_SETPT'].toString();
          if (setTempStr.length >= 2) {
            String numericPart = setTempStr.substring(0, setTempStr.length - 1);
            _pendingTemperature = double.parse(numericPart).toDouble();
            _saveSetpointTemperature(_pendingTemperature);
          }
        }

        // Parse humidity
        if (parsedData.containsKey('C_RH')) {
          String humStr = parsedData['C_RH'].toString();
          if (humStr.length >= 2) {
            String wholePart = humStr.substring(0, humStr.length - 1);
            String decimalPart = humStr.substring(humStr.length - 1);
            humidity = '$wholePart.$decimalPart';
            _saveCurrentHumidity(humidity);
          } else {
            humidity = humStr;
            _saveCurrentHumidity(humidity);
          }
        }

        // Parse set humidity
        if (parsedData.containsKey('S_RH_SETPT')) {
          String setHumStr = parsedData['S_RH_SETPT'].toString();
          if (setHumStr.length >= 2) {
            String wholePart = setHumStr.substring(0, setHumStr.length - 1);
            String decimalPart = setHumStr.substring(wholePart.length - 1);
            _pendingHumidity = double.parse(
              "$wholePart.$decimalPart",
            ).toDouble();
            _saveSetpointHumidity(_pendingHumidity);
          }
        }

        // Parse lights
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
              _lightIntensities[i - 1] = int.parse(
                parsedData[intensityKey].toString(),
              );
            } catch (e) {
              print(
                "Error parsing intensity for light $i: ${parsedData[intensityKey]}",
              );
            }
          }
        }
        _nightMode = !anyLightOn;
        _saveLightSettings();

        refreshHepaStatus();
        notifyListeners();
      }
    } catch (e) {
      print("Error parsing data: $e");
    }
  }

  void sendCompleteStructure() {
    if (_port == null || !isConnected) {
      print("Cannot send - USB not connected");
      return;
    }

    List<String> pairs = [];

    pairs.add('SR_WSL:200001');
    pairs.add('C_PRESSURE_1:000');
    pairs.add('C_PRESSURE_1_SIGN_BIT:1');
    pairs.add('C_PRESSURE_2:000');
    pairs.add('C_PRESSURE_2_SIGN_BIT:1');

    String tempValue = "250";
    if (temp != "--") {
      try {
        double currentTemp = double.parse(temp);
        tempValue = (currentTemp * 10).toInt().toString().padLeft(3, '0');
      } catch (e) {
        tempValue = "250";
      }
    }
    pairs.add('C_OT_TEMP:$tempValue');

    String humValue = "500";
    if (humidity != "--") {
      try {
        double currentHum = double.parse(humidity);
        humValue = (currentHum * 10).toInt().toString().padLeft(3, '0');
      } catch (e) {
        humValue = "500";
      }
    }
    pairs.add('C_RH:$humValue');

    for (int i = 1; i <= 7; i++) {
      pairs.add('F_Sensor_${i}_FAULT_BIT:0');
      pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
      pairs.add('S_Light_${i}_ON_OFF:${_lightStates[i - 1] ? '1' : '0'}');
      pairs.add(
        'S_Light_${i}_Intensity:${_lightIntensities[i - 1].toString().padLeft(3, '0')}',
      );
    }

    pairs.add('S_IOT_TIMER:0060');
    pairs.add(
      'S_TEMP_SETPT:${(_pendingTemperature * 10).toInt().toString().padLeft(3, '0')}',
    );
    pairs.add(
      'S_RH_SETPT:${(_pendingHumidity * 10).toInt().toString().padLeft(3, '0')}',
    );

    String command = '{${pairs.join(',')}}\n';
    _port!.write(Uint8List.fromList(command.codeUnits));

    lastSentMessage = command.trim();

    _saveSetpointTemperature(_pendingTemperature);
    _saveSetpointHumidity(_pendingHumidity);
    _saveLightSettings();

    print("Sent command: $command");
    notifyListeners();
  }

  void reconnectUsb() {
    print("Manual reconnect requested");
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    isConnected = false;
    _cleanupConnection();
    initUsb();
  }

  void requestStatus() {
    if (_port != null && isConnected) {
      String command = "STATUS\n";
      _port!.write(Uint8List.fromList(command.codeUnits));
      print("Sent STATUS request");
    } else {
      print("Cannot send STATUS - USB not connected");
    }
  }

  void testUsbCommunication() {
    if (_port != null && isConnected) {
      print("Testing USB communication...");

      String testCommand = "TEST\n";
      _port!.write(Uint8List.fromList(testCommand.codeUnits));
      print("Sent test command");

      requestStatus();

      Future.delayed(Duration(seconds: 2), () {
        sendCompleteStructure();
      });
    } else {
      print("USB not connected for testing");
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _statusRequestTimer?.cancel();
    _inputStreamSubscription?.cancel();
    _usbEventSubscription?.cancel();
    _port?.close();
    super.dispose();
  }
}
