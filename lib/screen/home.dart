import 'dart:async';
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
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
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
    'phone', // Phone item added
  ];

  bool _isSwitched = false;
  String _ipAddress = 'Fetching...';
  bool _isLaunching = false;
  bool _isInPipMode = false;
  static const platform = MethodChannel('app_launcher_channel');

  Future<void> _launchDroidRenderAndEnterPip() async {
    setState(() {
      _isLaunching = true;
    });

    try {
      final bool success = await platform.invokeMethod(
        'launchAppAndEnterPip', // Changed from 'enterPipMode'
        'com.luolai.droidrender',
      );

      if (success) {
        // _showSuccessSnackbar('Opening DroidRender and entering PiP mode...');
        setState(() {
          _isInPipMode = true;
        });
      } else {
        _showErrorSnackbar(
          'Failed to open DroidRender. App may not be installed.',
        );
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar('Error: ${e.message}');
    } finally {
      setState(() {
        _isLaunching = false;
      });
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

  late WebSocketChannel _channel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    fetchIpAddress().then((ip) {
      setState(() => _ipAddress = ip);
    });
    connectWebSocket();
    _tabController = TabController(length: 2, vsync: this);
  }

  void connectWebSocket() {
    const url = 'ws://192.168.0.100:8080';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel.stream.listen(
      (data) {
        final parsed = _parseData(data);
        if (parsed.containsKey('C_RH') && parsed.containsKey('C_OT_TEMP')) {
          setState(() {});
        }
      },
      onError: (error) {
        debugPrint("WebSocket Error: $error");
      },
    );
  }

  Map<String, String> _parseData(String rawData) {
    final Map<String, String> result = {};
    rawData = rawData.replaceAll(RegExp(r'[{}]'), '');
    final parts = rawData.split(',');

    for (var part in parts) {
      if (part.contains(':')) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          result[keyValue[0]] = keyValue[1];
        }
      }
    }
    return result;
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

  // Add phone call function

  Future<void> handleTap(int itemNumber) async {
    switch (itemNumber) {
      case 1:
        Get.to(
          () => const TemperatureGaugeScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 2:
        Get.to(
          () => const RhGaugeScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 3:
        Get.to(
          () => MyHomePage(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 4:
        Future.delayed(Duration.zero, () {
          if (!_isLaunching) {
            _launchDroidRenderAndEnterPip();
          }
        });
        break;
      case 5:
        Get.to(
          () => StylishStopwatchPage(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 6:
        Get.to(
          () => MusicPlayerScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 7:
        List<ConnectivityResult> results = await Connectivity()
            .checkConnectivity();
        if (results.contains(ConnectivityResult.none)) {
          Get.snackbar(
            "no_internet".tr,
            "check_connection".tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            maxWidth: 400,
            borderRadius: 10,
            snackStyle: SnackStyle.FLOATING,
            mainButton: TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "close".tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else {
          Get.to(
            () => VideoSwitcherScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 500),
          );
        }
        break;
      case 8:
        Get.to(
          () => CardGridScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 9: // PIS'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        Get.to(
          () => DashboardScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 10: // Store
        Get.to(
          () => HospitalStoreScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 11: // Clean
        Get.to(
          () => HospitalCleaningApp(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 12: // Phone - NEW
        Get.to(
          () => RelayControlApp(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMainTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "hepa_status".tr,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
                    Icons.device_thermostat,
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
            margin: const EdgeInsets.symmetric(vertical: 8),
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
                // Changed from 5 to 7 to accommodate phone item
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
                    Icons.phone, // Phone icon
                  ][itemNumber - 9];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => handleTap(itemNumber),
                      child: buildScoreContainer(
                        context,
                        itemKeys[itemNumber - 1].tr,
                        icon,
                        false,
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 112, 143, 214),
              Color.fromARGB(255, 157, 102, 228),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                            border: Border.all(color: Colors.black, width: 2),
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
                        icon: const Icon(Icons.language, color: Colors.white),
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
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Text(
                          "${'connect_to'.tr}: IP: $_ipAddress",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar with minimal indicators
            TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
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

            // Main Content Area - Takes remaining space
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMainTab(), _buildSecondTab()],
              ),
            ),

            // Footer Section
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    height: 100,
                    width: 300,
                    child: Image.asset('assets/app_logo-removebg-preview.png'),
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
                      Switch(
                        value: _isSwitched,
                        activeColor: Colors.lightBlueAccent,
                        inactiveThumbColor: Colors.grey.shade300,
                        inactiveTrackColor: Colors.grey.shade500,
                        onChanged: (value) {
                          setState(() {
                            _isSwitched = value;
                          });
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
                      connectWebSocket();
                      Get.snackbar(
                        "refreshing".tr,
                        "",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFFB0D3DC),
                        colorText: Colors.white,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 20,
                        ),
                        maxWidth: 400,
                        borderRadius: 10,
                        snackStyle: SnackStyle.FLOATING,
                        mainButton: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            "close".tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // IconButton(
                  //   icon: const Icon(
                  //     Icons.settings,
                  //     size: 42,
                  //     color: Colors.white,
                  //   ),
                  //   onPressed: () {
                  //     Get.to(
                  //       () => ProfilePage1(),
                  //       transition: Transition.rightToLeft,
                  //       duration: const Duration(milliseconds: 400),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildScoreContainer(
  BuildContext context,
  String label,
  IconData icon,
  bool showTimer,
) {
  final stopwatchProvider = Provider.of<StopwatchProvider>(context);

  return Container(
    margin: const EdgeInsets.all(0),
    height: MediaQuery.of(context).size.height * 0.22,
    width: MediaQuery.of(context).size.width * 0.22,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(1.0), width: 3.0),
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
