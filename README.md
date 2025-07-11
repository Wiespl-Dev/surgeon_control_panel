# surgeon_control_panel

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
import 'dart:async';
import 'package:analog_clock/analog_clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import 'package:wiespl_web/screen/feather/clock/clock.dart'd;

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:surgeon_control_panel/provider/stopwatch_provider.dart';
import 'package:surgeon_control_panel/screen/feather/cctv.dart';
import 'package:surgeon_control_panel/screen/feather/clock/clock.dart';
import 'package:surgeon_control_panel/screen/feather/dicomeview.dart';
import 'package:surgeon_control_panel/screen/feather/light.dart';
import 'package:surgeon_control_panel/screen/feather/mgps.dart';
import 'package:surgeon_control_panel/screen/feather/music.dart';
import 'package:surgeon_control_panel/screen/feather/rh.dart';
import 'package:surgeon_control_panel/screen/feather/temp.dart';
import 'package:surgeon_control_panel/screen/feather/timer.dart';
import 'package:surgeon_control_panel/screen/profil/profilescreen.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<String> itemNames = [
    'Temp: 00 °C',
    'RH: 00 %',
    'Lighting',
    // 'Dicom',
    'Timer',
    'Music',
    // 'CCTV',
    'MGPS',
  ];

  bool _isSwitched = false;
  String _ipAddress = 'Fetching...';
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    // fetchIpAddress().then((ip) {
    //   setState(() => _ipAddress = ip);
    // });
    connectWebSocket();
  }

  void connectWebSocket() {
    const url = 'ws://192.168.0.100:8080';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel.stream.listen(
      (data) {
        final parsed = _parseData(data);
        if (parsed.containsKey('C_RH') && parsed.containsKey('C_OT_TEMP')) {
          setState(() {
            itemNames[1] =
                "RH: ${(int.parse(parsed['C_RH']!) / 10).toStringAsFixed(1)} %";
            itemNames[6] =
                "Temp: ${(int.parse(parsed['C_OT_TEMP']!) / 10).toStringAsFixed(1)} °C";
          });
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
        return 'Failed to fetch IP';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

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
          () => LightControlScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
        break;
      case 4:
        Get.to(
          () => HttpPackageWebView(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
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
            "No Internet",
            "Please check your connection.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            maxWidth: 400,
            borderRadius: 10,
            snackStyle: SnackStyle.FLOATING,
            mainButton: TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                "CLOSE",
                style: TextStyle(
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
      default:
        Get.to(
          () => CardGridScreen(),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 400),
        );
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // connectWebSocket();
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
        child: Padding(
          padding: const EdgeInsets.all(18.0),
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
                  Text(
                    "Connect to: IP: $_ipAddress",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: ClockWidget(),
                  ),
                  const Text(
                    "Hepa: Healthy",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 180, right: 180),
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
                        Icons.thermostat, //thermostat
                        Icons.device_thermostat,
                        Icons.lightbulb_outline,
                        // Icons.door_front_door,
                      ][itemNumber - 1];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => handleTap(itemNumber),
                          child: buildScoreContainer(
                            context,
                            itemNames[itemNumber - 1],
                            icon,
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
                padding: const EdgeInsets.only(left: 180, right: 180),
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
                        // Icons.videocam,
                        Icons.map,
                      ][itemNumber - 5];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => handleTap(itemNumber),
                          child: buildScoreContainer(
                            context,
                            itemNames[itemNumber - 1],
                            icon,
                          ),
                        ),
                      );
                    }
                  }),
                ),
              ),
              const Spacer(),
              Row(
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
                      const Text(
                        "System On/Off",
                        style: TextStyle(
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
                    // onPressed: () => fetchIpAddress().then((ip) {
                    //   setState(() => _ipAddress = ip);
                    // }),
                    onPressed: () {
                      connectWebSocket();
                      Get.snackbar(
                        "Refreshing ...",
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
                          child: const Text(
                            "CLOSE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                        duration: const Duration(milliseconds: 400),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildScoreContainer(BuildContext context, String label, IconData icon) {
  final stopwatchProvider = Provider.of<StopwatchProvider>(context);

  double screenHeight = MediaQuery.of(context).size.height;
  double containerHeight = screenHeight * 0.26; // ~22% of screen height
  double containerWidth =
      MediaQuery.of(context).size.width * 0.22; // Optional: responsive width

  return Container(
    margin: const EdgeInsets.all(0),
    height: containerHeight,
    width: containerWidth, // Optional: responsive width
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(1.0), // Fully visible white
        width:
            3.0, // Increase this value to make it thicker (e.g., 4.0, 5.0, etc.)
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
        if (label == "Timer" && stopwatchProvider.isRunning)
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


#   s u r g e o n _ c o n t r o l _ p a n e l  
 #   s u r g e o n _ c o n t r o l _ p a n e l  
 