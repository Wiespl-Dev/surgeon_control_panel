import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:analog_clock/analog_clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:surgeon_control_panel/main.dart';
import 'package:surgeon_control_panel/patient%20info/clean/clean_pro.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard/dashboard.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard/store/storeitems.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard_items/patient_list.dart';
import 'package:surgeon_control_panel/provider/audioProvider.dart';
import 'package:surgeon_control_panel/provider/stopwatch_provider.dart';
import 'package:surgeon_control_panel/screen/feather/cctv.dart';
import 'package:surgeon_control_panel/screen/feather/clock/clock.dart';
import 'package:surgeon_control_panel/screen/feather/light.dart';
import 'package:surgeon_control_panel/screen/feather/mgps.dart';
import 'package:surgeon_control_panel/screen/feather/music.dart';
import 'package:surgeon_control_panel/screen/feather/phone/phonecall.dart';
import 'package:surgeon_control_panel/screen/feather/rh.dart';
import 'package:surgeon_control_panel/screen/feather/temp.dart';
import 'package:surgeon_control_panel/screen/feather/timer.dart';
import 'package:surgeon_control_panel/screen/profil/profilescreen.dart';
import 'package:surgeon_control_panel/services/globalespprovider.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_serial/usb_serial.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final List<String> itemKeys = [
    'temp',
    'rh',
    'lighting',
    'mgps',
    'Stop Watch',
    'music',
    'cctv',
    'dicom',
    'pis',
    'store',
    'clean',
  ];

  // ESP32 configuration
  final String esp32BaseUrl = 'http://192.168.0.100:8080';
  Timer? _esp32UpdateTimer;
  bool _useEsp32 = false;

  // USB related variables
  UsbPort? _port;
  String _incomingBuffer = "";
  StreamSubscription<dynamic>? _usbSubscription;

  static const platform = MethodChannel('app_launcher_channel');
  static const Color _neonColor = Color(0xFF65D6F2);
  // Timer for periodic updates
  Timer? _updateTimer;

  late TabController _tabController;

  // Animation controllers
  late AnimationController _cardController;
  late Animation<Offset> _cardSlideAnimation;
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // MGPS blinking animation
  late AnimationController _mgpsBlinkController;
  late Animation<double> _mgpsBlinkAnimation;

  final Random _random = Random();
  final List<MedicalParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Initialize USB first, then check connection method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUSBAndCheckConnection();
    });

    // Initialize particles
    for (int i = 0; i < 18; i++) {
      _particles.add(MedicalParticle(_random));
    }

    // Animation setup
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // MGPS blinking animation
    _mgpsBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _mgpsBlinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _mgpsBlinkController, curve: Curves.easeInOut),
    );

    _cardController.forward();
    _tabController = TabController(length: 2, vsync: this);

    // Start periodic updates
    _startPeriodicUpdates();
  }

  // NEW: Improved connection initialization
  void _initializeUSBAndCheckConnection() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    // Initialize USB connection
    usbProvider.initUsb().then((_) {
      // Check connection status after USB initialization
      _checkConnectionMethod();

      // Start ESP32 data fetching only if USB is not connected
      if (!usbProvider.isConnected) {
        _initializeEsp32Data();
      }
    });
  }

  void _initializeEsp32Data() {
    final esp32Provider = Provider.of<ESP32State>(context, listen: false);
    // Fetch initial data from ESP32
    esp32Provider.refreshData();

    // Start ESP32 auto-refresh timer (every 3 seconds)
    _esp32UpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      esp32Provider.refreshData();
    });
  }

  // IMPROVED: Better connection method detection
  void _checkConnectionMethod() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    setState(() {
      _useEsp32 = !usbProvider.isConnected;
    });

    if (_useEsp32) {
      debugPrint("USB not connected, using ESP32 HTTP method");
      // Stop any existing ESP32 timer and restart
      _esp32UpdateTimer?.cancel();
      _initializeEsp32Data();
    } else {
      debugPrint("USB connected, using USB method");
      // Stop ESP32 timer when using USB
      _esp32UpdateTimer?.cancel();
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );
      usbProvider.refreshHepaStatus();

      // Re-check connection method periodically
      _checkConnectionMethod();
    });
  }

  // ESP32 HTTP command method
  Future<void> _sendEsp32Command(String key, String value) async {
    try {
      debugPrint("ESP32: Sending $key = $value");

      final response = await http
          .get(Uri.parse('$esp32BaseUrl/update?$key=$value'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 302) {
        debugPrint("ESP32: Command sent successfully");
        _showSuccessSnackbar("Command sent successfully");
        // Refresh data after successful update
        final esp32Provider = Provider.of<ESP32State>(context, listen: false);
        esp32Provider.refreshData();
      } else {
        debugPrint(
          "ESP32: Failed to send command - Status: ${response.statusCode}",
        );
        _showErrorSnackbar("Failed to send command: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ESP32: Error sending command: $e");
      _showErrorSnackbar("Connection error: $e");
    }
  }

  // FIXED: System status command that works with both USB and ESP32
  Future<void> _sendSystemStatusCommand(bool isOn) async {
    if (_useEsp32) {
      // Use ESP32 method
      await _sendEsp32Command("S_Light_10_ON_OFF", isOn ? '1' : '0');
    } else {
      // Use USB method
      final usbProvider = Provider.of<GlobalUsbProvider>(
        context,
        listen: false,
      );
      usbProvider.toggleSystemPower(isOn);
      _showSuccessSnackbar("System turned ${isOn ? 'ON' : 'OFF'}");
    }
  }

  // USB Initialization - SIMPLIFIED since GlobalUsbProvider handles this
  Future<void> _initUsb() async {
    // This is now handled by GlobalUsbProvider
    debugPrint("USB initialization handled by GlobalUsbProvider");
  }

  void _toggleMute() {
    final audioProvider = Provider.of<GlobalUsbProvider>(
      context,
      listen: false,
    );
    audioProvider.toggleMute();
    _showSuccessSnackbar(
      audioProvider.isMuted ? "Audio muted" : "Audio unmuted",
    );
  }

  void _onDataReceived(dynamic chunk) {
    try {
      String str;
      if (chunk is Uint8List) {
        str = String.fromCharCodes(chunk);
      } else if (chunk is String) {
        str = chunk;
      } else if (chunk is List<int>) {
        str = String.fromCharCodes(chunk);
      } else {
        str = chunk.toString();
      }

      debugPrint(
        "📨 RAW USB DATA: ${str.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}",
      );

      _incomingBuffer += str;

      if (_incomingBuffer.contains('\n')) {
        List<String> lines = _incomingBuffer.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          String line = lines[i].trim();
          if (line.isNotEmpty) _processCompleteMessage(line);
        }
        _incomingBuffer = lines.last;
      }

      while (_incomingBuffer.contains('{') && _incomingBuffer.contains('}')) {
        int start = _incomingBuffer.indexOf('{');
        int end = _incomingBuffer.indexOf('}', start);
        if (end == -1) break;
        String block = _incomingBuffer.substring(start, end + 1);
        _processCompleteMessage(block);
        _incomingBuffer = _incomingBuffer.substring(end + 1);
      }

      if (_incomingBuffer.trim().startsWith('{') &&
          _incomingBuffer.trim().endsWith('}')) {
        _processCompleteMessage(_incomingBuffer.trim());
        _incomingBuffer = "";
      }
    } catch (e) {
      debugPrint("Error in _onDataReceived: $e");
    }
  }

  void _processCompleteMessage(String completeMessage) {
    debugPrint("Processing complete message: $completeMessage");
    _parseStructuredData(completeMessage);
  }

  void _parseStructuredData(String data) {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
    final esp32Provider = Provider.of<ESP32State>(context, listen: false);

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

            // Save sensor fault bits
            if (key.startsWith('F_Sensor_') && key.endsWith('_FAULT_BIT')) {
              String sensorNumStr = key
                  .replaceAll('F_Sensor_', '')
                  .replaceAll('_FAULT_BIT', '');
              int? sensorNum = int.tryParse(sensorNumStr);
              if (sensorNum != null &&
                  (sensorNum >= 1 && sensorNum <= 7 || sensorNum == 10)) {
                debugPrint("🔄 Updated $key: $value");

                if (sensorNum == 10) {
                  usbProvider.refreshHepaStatus();
                }
              }
            }
          }
        }

        debugPrint("Parsed data: $parsedData");

        // Update ESP32State provider with parsed data (for consistency)
        final newData = Map<String, String>.from(esp32Provider.data);
        parsedData.forEach((key, value) {
          if (value is String) {
            newData[key] = value;
          }
        });

        // Parse current temperature - FIXED FORMAT
        if (parsedData.containsKey('C_OT_TEMP')) {
          String tempStr = parsedData['C_OT_TEMP']!;
          String newTemp = _formatTemperatureValue(tempStr);
          usbProvider.updateTemperature(newTemp);
          debugPrint("Parsed and saved temperature: $newTemp°C");
        }

        // Parse current humidity - FIXED FORMAT
        if (parsedData.containsKey('C_RH')) {
          String humStr = parsedData['C_RH']!;
          String newHum = _formatHumidityValue(humStr);
          usbProvider.updateHumidity(newHum);
          debugPrint("Parsed and saved humidity: $newHum%");
        }

        // Parse system status (Light 10)
        if (parsedData.containsKey('S_Light_10_ON_OFF')) {
          String systemStatusStr = parsedData['S_Light_10_ON_OFF']!;
          bool systemStatus = systemStatusStr == '1';
          usbProvider.updateSystemStatus(systemStatus);
          debugPrint("Parsed and saved system status: $systemStatus");
        }
      } else {
        debugPrint("Data doesn't have proper structure: $data");
      }
    } catch (e) {
      debugPrint("Error parsing structured data: $e");
      debugPrint("Data that caused error: $data");
    }
  }

  // FIXED: Proper temperature formatting (e.g., 223 -> 22.3)
  String _formatTemperatureValue(String s) {
    if (s.isEmpty || s == '--') return '--';

    try {
      // Remove any non-numeric characters
      String cleanStr = s.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanStr.length <= 1) {
        return "0.${cleanStr}";
      } else {
        // Take all but last digit as whole number, last digit as decimal
        String whole = cleanStr.substring(0, cleanStr.length - 1);
        String dec = cleanStr.substring(cleanStr.length - 1);
        int wholeInt = int.tryParse(whole) ?? 0;
        return "$wholeInt.$dec";
      }
    } catch (e) {
      debugPrint("Error formatting temperature: $e");
      return '--';
    }
  }

  // FIXED: Proper humidity formatting (e.g., 456 -> 45.6)
  String _formatHumidityValue(String s) {
    if (s.isEmpty || s == '--') return '--';

    try {
      // Remove any non-numeric characters
      String cleanStr = s.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanStr.length <= 1) {
        return "0.${cleanStr}";
      } else {
        // Take all but last digit as whole number, last digit as decimal
        String whole = cleanStr.substring(0, cleanStr.length - 1);
        String dec = cleanStr.substring(cleanStr.length - 1);
        int wholeInt = int.tryParse(whole) ?? 0;
        return "$wholeInt.$dec";
      }
    } catch (e) {
      debugPrint("Error formatting humidity: $e");
      return '--';
    }
  }

  void _reconnectUsb() {
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
    usbProvider.reconnectUsb();

    // Re-check connection method after attempting reconnect
    Future.delayed(const Duration(seconds: 2), () {
      _checkConnectionMethod();
    });
  }

  Future<void> _launchDroidRenderAndEnterPip() async {
    try {
      final bool success = await platform.invokeMethod(
        'launchAppAndEnterPip',
        'com.luolai.droidrender',
      );

      if (!success) {
        _showErrorSnackbar(
          'Failed to open DroidRender. App may not be installed.',
        );
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar('Error: ${e.message}');
    }
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

  // IMPROVED: Get temperature value from appropriate source
  String _getTemperatureValue() {
    if (_useEsp32) {
      final esp32Provider = Provider.of<ESP32State>(context);
      final tempValue = esp32Provider.data['C_OT_TEMP'] ?? '--';
      return tempValue == '--' ? '00°C' : '$tempValue°C';
    } else {
      final usbProvider = Provider.of<GlobalUsbProvider>(context);
      return usbProvider.currentTemperature == "--"
          ? "00°C"
          : '${usbProvider.currentTemperature}°C';
    }
  }

  // IMPROVED: Get humidity value from appropriate source
  String _getHumidityValue() {
    if (_useEsp32) {
      final esp32Provider = Provider.of<ESP32State>(context);
      final humValue = esp32Provider.data['C_RH'] ?? '--';
      return humValue == '--' ? '00%' : '$humValue%';
    } else {
      final usbProvider = Provider.of<GlobalUsbProvider>(context);
      return usbProvider.currentHumidity == "--"
          ? "00%"
          : '${usbProvider.currentHumidity}%';
    }
  }

  // IMPROVED: Get system status from appropriate source
  bool _getSystemStatus() {
    if (_useEsp32) {
      final esp32Provider = Provider.of<ESP32State>(context);
      return esp32Provider.data['S_Light_10_ON_OFF'] == '1';
    } else {
      final usbProvider = Provider.of<GlobalUsbProvider>(context);
      return usbProvider.isSwitched;
    }
  }

  Widget buildScoreContainer(
    BuildContext context,
    String label,
    IconData icon,
    bool showTimer, {
    String? currentValue,
    required int itemNumber,
  }) {
    final stopwatchProvider = Provider.of<StopwatchProvider>(
      context,
      listen: false,
    );
    final usbProvider = Provider.of<GlobalUsbProvider>(context);

    bool isMgpsWithFault = itemNumber == 4 && usbProvider.hasSensorFault();

    return AnimatedBuilder(
      animation: isMgpsWithFault
          ? _mgpsBlinkAnimation
          : AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(0),
          height: MediaQuery.of(context).size.height * 0.22,
          width: MediaQuery.of(context).size.width * 0.22,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMgpsWithFault
                  ? Colors.red.withOpacity(_mgpsBlinkAnimation.value)
                  : Colors.white.withOpacity(1.0),
              width: isMgpsWithFault ? 4.0 : 3.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isMgpsWithFault
                    ? Colors.red.withOpacity(_mgpsBlinkAnimation.value)
                    : Colors.white,
                size: 35,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isMgpsWithFault
                      ? Colors.red.withOpacity(_mgpsBlinkAnimation.value)
                      : Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (currentValue != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    currentValue,
                    style: TextStyle(
                      color: isMgpsWithFault
                          ? Colors.red.withOpacity(_mgpsBlinkAnimation.value)
                          : Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (showTimer && stopwatchProvider.isRunning)
                StreamBuilder<int>(
                  stream: stopwatchProvider.stopWatchTimer.rawTime,
                  initialData: stopwatchProvider.stopWatchTimer.rawTime.value,
                  builder: (context, snapshot) {
                    final displayTime = StopWatchTimer.getDisplayTime(
                      snapshot.data!,
                      milliSecond: false,
                    );
                    return Text(
                      displayTime,
                      style: TextStyle(
                        color: isMgpsWithFault
                            ? Colors.red.withOpacity(_mgpsBlinkAnimation.value)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> handleTap(int itemNumber) async {
    switch (itemNumber) {
      case 1:
        Get.to(() => TempGaugeScreen(), transition: Transition.rightToLeft);
        break;
      case 2:
        Get.to(() => HumidityGaugeScreen(), transition: Transition.rightToLeft);
        break;
      case 3:
        Get.to(() => LightIntensityPage(), transition: Transition.rightToLeft);
        break;
      case 4:
        Get.to(() => GasStatusPage(), transition: Transition.rightToLeft);
        break;
      case 5:
        Get.to(
          () => StylishStopwatchPage(),
          transition: Transition.rightToLeft,
        );
        break;
      case 6:
        Get.to(() => MusicPlayerScreen(), transition: Transition.rightToLeft);
        break;
      case 7:
        Get.to(() => VideoSwitcherScreen(), transition: Transition.fadeIn);
        break;
      case 8:
        _launchDroidRenderAndEnterPip();
        break;
      case 9:
        Get.to(() => PatientListScreen(), transition: Transition.rightToLeft);
        break;
      case 10:
        Get.to(() => StoreHomeScreen(), transition: Transition.rightToLeft);
        break;
      case 11:
        Get.to(
          () => RoomCleanlinessContainer(),
          transition: Transition.rightToLeft,
        );
        break;
    }
  }

  Widget _buildMainTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 180),
            child: Row(
              children: List.generate(7, (index) {
                if (index.isOdd) {
                  return Container(
                    width: 2,
                    height: 100,
                    color: Colors.white.withOpacity(0.0),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  );
                } else {
                  int itemNumber = (index ~/ 2) + 1;
                  final icon = [
                    Icons.thermostat,
                    Icons.water_drop_outlined,
                    Icons.lightbulb_outline,
                    Icons.door_front_door,
                  ][itemNumber - 1];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => handleTap(itemNumber),
                      child: buildScoreContainer(
                        context,
                        itemKeys[itemNumber - 1].tr,
                        icon,
                        itemNumber == 5,
                        currentValue: itemNumber == 1
                            ? _getTemperatureValue()
                            : itemNumber == 2
                            ? _getHumidityValue()
                            : null,
                        itemNumber: itemNumber,
                      ),
                    ),
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: double.infinity,
            color: Colors.white.withOpacity(0.0),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 180),
            child: Row(
              children: List.generate(7, (index) {
                if (index.isOdd) {
                  return Container(
                    width: 2,
                    height: 100,
                    color: Colors.white.withOpacity(0.0),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  );
                } else {
                  int itemNumber = (index ~/ 2) + 5;
                  final icon = [
                    Icons.timer,
                    Icons.music_note,
                    Icons.videocam,
                    Icons.map,
                  ][itemNumber - 5];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => handleTap(itemNumber),
                      child: buildScoreContainer(
                        context,
                        itemKeys[itemNumber - 1].tr,
                        icon,
                        false,
                        itemNumber: itemNumber,
                      ),
                    ),
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSecondTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 180),
            child: Row(
              children: [
                // First item
                Expanded(
                  child: GestureDetector(
                    onTap: () => handleTap(9),
                    child: buildScoreContainer(
                      context,
                      itemKeys[8].tr, // 'dicom'
                      Icons.medical_services,
                      false,
                      itemNumber: 9,
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  height: 100,
                  color: Colors.white.withOpacity(0.0),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                // Second item
                Expanded(
                  child: GestureDetector(
                    onTap: () => handleTap(10),
                    child: buildScoreContainer(
                      context,
                      itemKeys[9].tr, // 'pis'
                      Icons.store,
                      false,
                      itemNumber: 10,
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  height: 100,
                  color: Colors.white.withOpacity(0.0),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                // Third item
                Expanded(
                  child: GestureDetector(
                    onTap: () => handleTap(11),
                    child: buildScoreContainer(
                      context,
                      itemKeys[10].tr, // 'clean'
                      Icons.cleaning_services,
                      false,
                      itemNumber: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usbSubscription?.cancel();
    _port?.close();
    _tabController.dispose();
    _updateTimer?.cancel();
    _esp32UpdateTimer?.cancel();
    _cardController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    _mgpsBlinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usbProvider = Provider.of<GlobalUsbProvider>(context);
    final audioProvider = Provider.of<GlobalUsbProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return CustomPaint(
                painter: ClinicalBackgroundPainter(
                  t: _bgController.value,
                  particles: _particles,
                ),
                size: Size.infinite,
              );
            },
          ),
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ClockDisplay(neonColor: Colors.white),
                          const SizedBox(),
                          Text(
                            "WELCOME TO WIESPL DIGITAL OR",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(),
                          Row(
                            children: [
                              DropdownButton<String>(
                                value: Get.locale?.languageCode ?? 'en',
                                icon: const Icon(
                                  Icons.language,
                                  color: Colors.white,
                                ),
                                dropdownColor: Colors.blue[800],
                                style: const TextStyle(color: Colors.white),
                                underline: Container(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text(
                                      'English',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hi',
                                    child: Text(
                                      'हिंदी',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ar',
                                    child: Text(
                                      'العربية',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value != null) {
                                    Get.updateLocale(Locale(value));
                                  }
                                },
                              ),
                              const SizedBox(width: 12),

                              // Connection Status with reconnect button
                              // Row(
                              //   children: [
                              //     Container(
                              //       padding: const EdgeInsets.symmetric(
                              //         horizontal: 12,
                              //         vertical: 6,
                              //       ),
                              //       decoration: BoxDecoration(
                              //         color: _useEsp32
                              //             ? Colors.blue
                              //             : Colors.green,
                              //         borderRadius: BorderRadius.circular(12),
                              //       ),
                              //       child: Text(
                              //         _useEsp32 ? "ESP32" : "USB",
                              //         style: const TextStyle(
                              //           color: Colors.white,
                              //           fontSize: 10,
                              //           fontWeight: FontWeight.bold,
                              //         ),
                              //       ),
                              //     ),
                              //     const SizedBox(width: 8),
                              //     IconButton(
                              //       onPressed: _reconnectUsb,
                              //       icon: const Icon(
                              //         Icons.usb,
                              //         color: Colors.white,
                              //         size: 20,
                              //       ),
                              //       tooltip: "Reconnect USB",
                              //     ),
                              //   ],
                              // ),
                              // const SizedBox(width: 12),
                              IconButton(
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.remove("uniqueCode");
                                  await prefs.remove("mode");
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white60,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.transparent,
                  unselectedLabelColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      icon: Icon(
                        Icons.circle,
                        size: 12,
                        color: Colors.transparent,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        Icons.circle,
                        size: 12,
                        color: Colors.transparent,
                      ),
                    ),
                  ],
                ),

                // Main Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildMainTab(), _buildSecondTab()],
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10.0,
                                  sigmaY: 10.0,
                                ),
                                child: Container(
                                  height: 120,
                                  width: 270,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1.0,
                                    ),
                                  ),
                                  // child: Center(
                                  //   child: Image.asset(
                                  //     'assets/image.png',
                                  //     height: 100,
                                  //     width: 300,
                                  //   ),
                                  // ),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10.0,
                                  sigmaY: 10.0,
                                ),
                                child: Container(
                                  height: 100,
                                  width: 250,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/app_logo-removebg-preview.png',
                                      height: 100,
                                      width: 300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            "system_status".tr,
                            style: const TextStyle(
                              color: Colors.transparent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: usbProvider.isHepaHealthy
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: usbProvider.isHepaHealthy
                                    ? Colors.green
                                    : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  usbProvider.isHepaHealthy
                                      ? Icons.air
                                      : Icons.warning,
                                  color: usbProvider.isHepaHealthy
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  usbProvider.hepaStatusText,
                                  style: TextStyle(
                                    color: usbProvider.isHepaHealthy
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "system_status".tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<GlobalUsbProvider>(
                            builder: (context, usbProvider, child) {
                              return Switch(
                                value: _getSystemStatus(),
                                activeColor: Colors.lightBlueAccent,
                                inactiveThumbColor: Colors.grey.shade300,
                                inactiveTrackColor: Colors.grey.shade500,
                                onChanged: (value) async {
                                  if (!value) {
                                    bool confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Confirm"),
                                        content: const Text(
                                          "Are you sure you want to turn off the system?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text("Yes"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (!confirm) return;
                                  }

                                  try {
                                    await _sendSystemStatusCommand(value);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Failed to ${value ? 'start' : 'stop'} system",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "system_status".tr,
                            style: const TextStyle(
                              color: Colors.transparent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              audioProvider.isMuted
                                  ? Icons.volume_off
                                  : Icons.volume_up,
                              size: 42,
                              color: Colors.white,
                            ),
                            onPressed: _toggleMute,
                            tooltip: audioProvider.isMuted ? "Unmute" : "Mute",
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Keep all your existing helper classes below:

class _AnimatedCounter extends StatefulWidget {
  final String value;
  const _AnimatedCounter({Key? key, required this.value}) : super(key: key);

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _currentValue = "0";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _updateValue();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateValue();
    }
  }

  void _updateValue() {
    final start = double.tryParse(_currentValue) ?? 0.0;
    final end = double.tryParse(widget.value) ?? 0.0;
    _animation = Tween<double>(
      begin: start,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _currentValue = _animation.value.toStringAsFixed(
          _animation.value.truncateToDouble() == _animation.value ? 0 : 1,
        );
        return Text(
          _currentValue,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// A thin separator used inside the card
class SimpleSeparatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SimpleSeparatorPainter oldDelegate) => false;
}

/// particles for subtle texture (no glow)
class MedicalParticle {
  double x, y, size, vx, vy, opacity;
  final Random _random;

  MedicalParticle(this._random)
    : x = _random.nextDouble(),
      y = _random.nextDouble(),
      size = _random.nextDouble() * 2 + 0.6,
      vx = _random.nextDouble() * 0.0008 - 0.0004,
      vy = _random.nextDouble() * 0.0008 - 0.0004,
      opacity = 0.06 + _random.nextDouble() * 0.06;

  void update(double t) {
    // very slow drifting with slight sinus wobble
    x += vx + 0.0002 * sin(t * 2 * pi + x * 10);
    y += vy + 0.0002 * cos(t * 2 * pi + y * 10);

    if (x < -0.02) x = 1.02;
    if (x > 1.02) x = -0.02;
    if (y < -0.02) y = 1.02;
    if (y > 1.02) y = -0.02;
  }
}

/// Clinical background painter: premium gradient, faint grid, subtle particles,
/// diagonal light rays, glowing circles, and ECG waveform.
class ClinicalBackgroundPainter extends CustomPainter {
  final double t; // 0..1
  final List<MedicalParticle> particles;
  ClinicalBackgroundPainter({required this.t, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // === 1) Dynamic premium gradient ===
    final gT = (sin(t * 2 * pi) + 1) / 2 * 0.2;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF0F3D3E), const Color(0xFF2C6975), gT)!,
        Color.lerp(const Color(0xFF144552), const Color(0xFF205375), gT)!,
        Color.lerp(const Color(0xFF16324F), const Color(0xFF112031), gT)!,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // === 2) Faint futuristic grid ===
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;
    const double step = 40;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // === 3) Diagonal light ray ===
    final rayPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.07), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final rayPath = Path()
      ..moveTo(size.width * (0.15 + t * 0.05), 0)
      ..lineTo(size.width * (0.35 + t * 0.05), 0)
      ..lineTo(size.width * (0.75 + t * 0.05), size.height)
      ..lineTo(size.width * (0.55 + t * 0.05), size.height)
      ..close();
    canvas.drawPath(rayPath, rayPaint);

    // === 4) Glowing circles (scanner-style highlights) ===
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * (0.35 + 0.05 * sin(t * 2 * pi))),
      120,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * (0.65 + 0.05 * cos(t * 2 * pi))),
      100,
      glowPaint,
    );

    // === 5) Subtle particles ===
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      p.update(t);
      dotPaint.color = Colors.white.withOpacity(p.opacity);
      final cx = p.x * size.width;
      final cy = p.y * size.height;
      canvas.drawCircle(Offset(cx, cy), p.size, dotPaint);
    }

    // === 6) ECG waveform ===
    _drawECG(canvas, size);
  }

  void _drawECG(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final amplitude = size.height * 0.03;
    final baselineY = size.height * 0.22;

    // Static offset (no animation)
    final offsetX =
        0.0; // Set a static value instead of using phase for animation

    bool first = true;
    for (double x = -size.width; x <= size.width * 2; x += 4) {
      final local = (x / 80.0);
      final beat = sin(local * 2 * pi);
      final spike = exp(-pow((local % 6.0) - 3.0, 2)) * 6.0;
      final yOffset = beat * amplitude * 0.6 + (spike * amplitude * 0.12);

      final px = x - offsetX % (size.width * 1.2);
      final py = baselineY + yOffset;

      if (first) {
        path.moveTo(px, py);
        first = false;
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ClinicalBackgroundPainter oldDelegate) => true;
}
