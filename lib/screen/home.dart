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
import 'package:surgeon_control_panel/provider/stopwatch_provider.dart';
import 'package:surgeon_control_panel/provider/home_provider.dart';
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
    'dicom',
    'timer',
    'music',
    'cctv',
    'mgps',
    'pis',
    'store',
    'clean',
    'phone',
  ];

  // USB related variables
  UsbPort? _port;
  String _incomingBuffer = "";
  StreamSubscription<dynamic>? _usbSubscription;

  static const platform = MethodChannel('app_launcher_channel');

  // Timer for periodic updates
  Timer? _updateTimer;

  late TabController _tabController;

  // Animation controllers
  late AnimationController _cardController;
  late Animation<Offset> _cardSlideAnimation;
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Random _random = Random();
  final List<MedicalParticle> _particles = [];

  @override
  void initState() {
    super.initState();

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

    _cardController.forward();
    _tabController = TabController(length: 2, vsync: this);

    // Start USB and periodic updates
    _initUsb();
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      homeProvider.refreshHepaStatus();
    });
  }

  // USB Initialization
  Future<void> _initUsb() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    try {
      homeProvider.updateUsbStatus(false, "Scanning for USB devices...");

      List<UsbDevice> devices = await UsbSerial.listDevices();
      debugPrint("Found ${devices.length} USB devices");

      if (devices.isEmpty) {
        homeProvider.updateUsbStatus(false, "No USB devices found");
        return;
      }

      UsbDevice device = devices.first;
      homeProvider.updateUsbStatus(
        false,
        "Connecting to ${device.deviceName}...",
      );

      _port = await device.create();
      bool open = await _port!.open();

      if (open) {
        await _port!.setDTR(true);
        await _port!.setRTS(true);
        await _port!.setPortParameters(9600, 8, 1, 0);

        homeProvider.updateUsbStatus(true, "Connected to ${device.deviceName}");

        // Cancel previous subscription if any
        await _usbSubscription?.cancel();

        _usbSubscription = _port!.inputStream?.listen(
          (data) {
            _onDataReceived(data);
          },
          onError: (e) {
            debugPrint("USB input stream error: $e");
            homeProvider.updateUsbStatus(false, "Connection error");
          },
          onDone: () {
            debugPrint("USB input stream done");
            homeProvider.updateUsbStatus(false, "Disconnected");
          },
        );
      } else {
        homeProvider.updateUsbStatus(false, "Failed to open USB port");
      }
    } catch (e) {
      debugPrint("USB Error: $e");
      homeProvider.updateUsbStatus(false, "Error: $e");
    }
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
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final prefs = homeProvider.prefs;

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
                prefs?.setString(key, value);
                debugPrint("🔄 Updated $key: $value");

                if (sensorNum == 10) {
                  homeProvider.refreshHepaStatus();
                }
              }
            }
          }
        }

        debugPrint("Parsed data: $parsedData");

        // Parse current temperature
        if (parsedData.containsKey('C_OT_TEMP')) {
          String tempStr = parsedData['C_OT_TEMP']!;
          String newTemp = _formatNumericWithOneDecimal(tempStr);
          homeProvider.updateTemperature(newTemp);
          debugPrint("Parsed and saved temperature: $newTemp°C");
        }

        // Parse current humidity
        if (parsedData.containsKey('C_RH')) {
          String humStr = parsedData['C_RH']!;
          String newHum = _formatNumericWithOneDecimal(humStr);
          homeProvider.updateHumidity(newHum);
          debugPrint("Parsed and saved humidity: $newHum%");
        }

        // Parse system status
        if (parsedData.containsKey('S_Light_10_ON_OFF')) {
          String systemStatusStr = parsedData['S_Light_10_ON_OFF']!;
          bool systemStatus = systemStatusStr == '1';
          homeProvider.updateSystemStatus(systemStatus);
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

  String _formatNumericWithOneDecimal(String s) {
    if (s.length == 1) {
      return "0.${s}";
    } else {
      String whole = s.substring(0, s.length - 1);
      String dec = s.substring(s.length - 1);
      int wholeInt = int.tryParse(whole) ?? 0;
      return "$wholeInt.$dec";
    }
  }

  void _reconnectUsb() {
    _initUsb();
  }

  // Send system status command to USB
  void _sendSystemStatusCommand(bool isOn) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    if (_port != null && homeProvider.isConnected) {
      List<String> pairs = [];
      pairs.add('SR_WSL:200001');
      pairs.add('C_PRESSURE_1:000');
      pairs.add('C_PRESSURE_1_SIGN_BIT:1');
      pairs.add('C_PRESSURE_2:000');
      pairs.add('C_PRESSURE_2_SIGN_BIT:1');
      pairs.add('C_OT_TEMP:250');
      pairs.add('C_RH:500');

      // Add all parameters
      for (int i = 1; i <= 10; i++) {
        String? fault;
        if (i <= 7) {
          fault =
              homeProvider.prefs?.getString('F_Sensor_${i}_FAULT_BIT') ?? '0';
        } else {
          fault = '0';
        }
        pairs.add('F_Sensor_${i}_FAULT_BIT:$fault');
        pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');

        if (i == 10) {
          pairs.add('S_Light_${i}_ON_OFF:${isOn ? '1' : '0'}');
        } else {
          pairs.add('S_Light_${i}_ON_OFF:0');
        }
        pairs.add(
          'S_Light_${i}_Intensity:${i == 10 ? (isOn ? '100' : '000') : '000'}',
        );
      }

      pairs.add('S_IOT_TIMER:0060');
      pairs.add('S_TEMP_SETPT:250');
      pairs.add('S_RH_SETPT:500');

      String command = '{${pairs.join(',')}}';
      _port!.write(Uint8List.fromList((command + "\n").codeUnits));

      debugPrint("Sent system status command: $command");
      _showSuccessSnackbar("System turned ${isOn ? 'ON' : 'OFF'}");
    } else {
      _showErrorSnackbar("USB is not connected");
    }
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

  Future<String> fetchIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return 'Failed to fetch IP'.tr;
      }
    } catch (e) {
      return 'Error: $e'.tr;
    }
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
        _launchDroidRenderAndEnterPip();
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
        List<ConnectivityResult> results = await Connectivity()
            .checkConnectivity();
        if (results.contains(ConnectivityResult.none)) {
          Get.snackbar(
            "no_internet".tr,
            "check_connection".tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.to(() => VideoSwitcherScreen(), transition: Transition.fadeIn);
        }
        break;
      case 8:
        Get.to(() => GasStatusPage(), transition: Transition.rightToLeft);
        break;
      case 9:
        Get.to(() => DashboardScreen(), transition: Transition.rightToLeft);
        break;
      case 10:
        Get.to(() => HospitalStoreScreen(), transition: Transition.rightToLeft);
        break;
      case 11:
        Get.to(() => HospitalCleaningApp(), transition: Transition.rightToLeft);
        break;
      case 12:
        Get.to(() => PatientDashboard(), transition: Transition.rightToLeft);
        break;
    }
  }

  @override
  void dispose() {
    _usbSubscription?.cancel();
    _port?.close();
    _tabController.dispose();
    _updateTimer?.cancel();
    _cardController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
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
    final homeProvider = Provider.of<HomeProvider>(context);

    bool isMgpsWithFault = itemNumber == 8 && homeProvider.hasSensorFault();

    return Container(
      margin: const EdgeInsets.all(0),
      height: MediaQuery.of(context).size.height * 0.22,
      width: MediaQuery.of(context).size.width * 0.22,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMgpsWithFault ? Colors.red : Colors.white.withOpacity(1.0),
          width: 3.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 35),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (currentValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                currentValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMainTab() {
    final homeProvider = Provider.of<HomeProvider>(context);

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
                            ? (homeProvider.currentTemp == "--"
                                  ? "00"
                                  : '${homeProvider.currentTemp}°C')
                            : itemNumber == 2
                            ? (homeProvider.currentHumidity == "--"
                                  ? "00"
                                  : '${homeProvider.currentHumidity}%')
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
              children: List.generate(7, (index) {
                if (index.isOdd) {
                  return Container(
                    width: 2,
                    height: 100,
                    color: Colors.white.withOpacity(0.0),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  );
                } else {
                  int itemNumber = (index ~/ 2) + 9;
                  final icon = [
                    Icons.medical_services,
                    Icons.store,
                    Icons.cleaning_services,
                    Icons.phone,
                  ][itemNumber - 9];

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

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

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
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20, bottom: 5),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              height: 100,
                              width: 100,
                              child: AnalogClock(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                width: 60,
                                height: 60,
                                isLive: true,
                                hourHandColor: Colors.black,
                                minuteHandColor: Colors.black,
                                secondHandColor: Colors.red,
                                showSecondHand: true,
                                showNumbers: true,
                                showTicks: true,
                                datetime: DateTime.now(),
                                textScaleFactor: 1.1,
                              ),
                            ),
                          ),
                          const Spacer(),
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
                          const SizedBox(width: 20),
                          const Spacer(),
                          // Status indicators
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: homeProvider.isHepaHealthy
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: homeProvider.isHepaHealthy
                                    ? Colors.green
                                    : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  homeProvider.isHepaHealthy
                                      ? Icons.air
                                      : Icons.warning,
                                  color: homeProvider.isHepaHealthy
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  homeProvider.hepaStatusText,
                                  style: TextStyle(
                                    color: homeProvider.isHepaHealthy
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: homeProvider.isConnected
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              homeProvider.isConnected
                                  ? "USB Connected"
                                  : "USB Disconnected",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.bug_report,
                              size: 30,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              homeProvider.notifyListeners();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.restart_alt,
                              size: 30,
                              color: Colors.yellow,
                            ),
                            onPressed: () {
                              homeProvider.resetAllSensorsToNoFault();
                              _showSuccessSnackbar(
                                "All sensors reset to no fault",
                              );
                            },
                          ),
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
                    Tab(icon: Icon(Icons.circle, size: 12)),
                    Tab(icon: Icon(Icons.circle, size: 12)),
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
                        children: [
                          // 1. The main content (what you want to see the effect over)
                          // This is where your background image or other content goes.
                          // For a visible effect, this content should be behind the glass
                          // e.g., an image filling the screen.
                          Center(
                            // Center is just an example; put this where you need it
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                20.0,
                              ), // Optional: rounded corners for the 'glass'
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX:
                                      10.0, // Adjust for horizontal blur intensity
                                  sigmaY:
                                      10.0, // Adjust for vertical blur intensity
                                ),
                                child: Container(
                                  height: 100,
                                  width: 300,
                                  // 2. The semi-transparent overlay (the 'glass' color)
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      0.2,
                                    ), // White with 30% opacity
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        0.3,
                                      ), // Optional: subtle white border
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    // Center the content inside the glass container
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "system_status".tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<HomeProvider>(
                            builder: (context, homeProvider, child) {
                              return Switch(
                                value: homeProvider.isSwitched,
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
                                  _sendSystemStatusCommand(value);
                                  homeProvider.updateSystemStatus(value);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          size: 42,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _reconnectUsb();
                          homeProvider.refreshHepaStatus();
                          Get.snackbar(
                            "refreshing".tr,
                            "",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          size: 42,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Get.to(
                            () => ProfilePage1(),
                            transition: Transition.rightToLeft,
                          );
                        },
                      ),
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
    _drawECG(canvas, size, t);
  }

  void _drawECG(Canvas canvas, Size size, double phase) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final amplitude = size.height * 0.03;
    final baselineY = size.height * 0.22;
    final speed = 0.6;
    final offsetX = phase * size.width * speed;

    bool first = true;
    for (double x = -size.width; x <= size.width * 2; x += 4) {
      final local = (x / 80.0);
      final beat = sin(local * 2 * pi);
      final spike = exp(-pow((local % 6.0) - 3.0, 2)) * 6.0;
      final yOffset = beat * amplitude * 0.6 + (spike * amplitude * 0.12);

      final px = x - offsetX % (size.width * 1.2);
      final py = baselineY + yOffset + 4 * sin((phase * 2 * pi) + x * 0.01);

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
