import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:surgeon_control_panel/services/usb_service.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:provider/provider.dart';

class GasStatusPage extends StatefulWidget {
  @override
  _GasStatusPageState createState() => _GasStatusPageState();
}

class _GasStatusPageState extends State<GasStatusPage> {
  List<GasStatus> _gasStatusList = [];
  String _buffer = '';

  // Gas configuration
  final List<Map<String, dynamic>> _gasConfigs = [
    {"name": "Oxygen", "icon": Icons.air},
    {"name": "Nitrogen", "icon": Icons.waves},
    {"name": "Carbon Dioxide", "icon": Icons.cloud},
    {"name": "Vacuum", "icon": Icons.arrow_upward},
    {"name": "Normal Air", "icon": Icons.brightness_1},
    {"name": "Air Bar 3", "icon": Icons.whatshot},
    {"name": "Air Bar 7", "icon": Icons.fireplace},
  ];

  @override
  void initState() {
    super.initState();
    _initializeDefaultGasStatus();
    _setupDataListener();
  }

  void _initializeDefaultGasStatus() {
    _gasStatusList = List.generate(
      7,
      (index) => GasStatus(
        name: _gasConfigs[index]["name"] as String,
        sensorNumber: index + 1,
        status: "WAITING DATA",
        color: Colors.orange,
        faultBit: -1,
        icon: _gasConfigs[index]["icon"] as IconData,
      ),
    );
  }

  void _setupDataListener() {
    // Listen to data from GlobalUsbProvider
    final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

    // Set up listener for incoming data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The GlobalUsbProvider already handles USB connection and data streaming
      // We just need to parse the gas-specific data when it comes in
    });
  }

  void _parseGasData(String rawData) {
    try {
      String cleanData = rawData.replaceAll('{', '').replaceAll('}', '');
      List<String> pairs = cleanData.split(',');

      Map<String, String> dataMap = {};

      for (String pair in pairs) {
        if (pair.contains(':')) {
          List<String> keyValue = pair.split(':');
          if (keyValue.length == 2) {
            dataMap[keyValue[0].trim()] = keyValue[1].trim();
          }
        }
      }

      List<GasStatus> updatedList = [];
      for (int i = 1; i <= 7; i++) {
        String faultKey = 'F_Sensor_${i}_FAULT_BIT';
        String status;
        Color color;
        int faultBit = -1;

        if (dataMap.containsKey(faultKey)) {
          faultBit = int.tryParse(dataMap[faultKey]!) ?? 1;

          if (faultBit == 1) {
            status = "EMPTY";
            color = Colors.red;
          } else if (faultBit == 0) {
            status = "FULL";
            color = Colors.green;
          } else {
            status = "UNKNOWN";
            color = Colors.grey;
          }
        } else {
          status = "NO DATA";
          color = Colors.orange;
        }

        updatedList.add(
          GasStatus(
            name: _gasConfigs[i - 1]["name"] as String,
            sensorNumber: i,
            status: status,
            color: color,
            faultBit: faultBit,
            icon: _gasConfigs[i - 1]["icon"] as IconData,
          ),
        );
      }

      setState(() {
        _gasStatusList = updatedList;
      });

      // Check and play alert dynamically
      _checkAndPlayAlert();
    } catch (e) {
      print('Error parsing gas data: $e');
    }
  }

  void _checkAndPlayAlert() {
    final globalUsbProvider = Provider.of<GlobalUsbProvider>(
      context,
      listen: false,
    );

    // Get all EMPTY gases
    List<GasStatus> emptyGases = _gasStatusList
        .where((gas) => gas.status == "EMPTY")
        .toList();

    if (emptyGases.isNotEmpty && !globalUsbProvider.isAlertPlaying) {
      globalUsbProvider.setAlertPlaying(true);
      _playLoopAlert(emptyGases);
    } else if (emptyGases.isEmpty && globalUsbProvider.isAlertPlaying) {
      globalUsbProvider.setAlertPlaying(false);
      globalUsbProvider.stopAudio();
    }
  }

  Future<void> _playLoopAlert(List<GasStatus> emptyGases) async {
    final globalUsbProvider = Provider.of<GlobalUsbProvider>(
      context,
      listen: false,
    );

    Map<String, String> gasAudioMap = {
      'Oxygen': 'assets/audio/Oxygen.mp3',
      'Vacuum': 'assets/audio/VaccumError.mp3',
      'Carbon Dioxide': 'assets/audio/CO2.mp3',
      'Nitrogen': 'assets/audio/Nitrogen.mp3',
      'Air Bar 3': 'assets/audio/AirBar3.mp3',
      'Air Bar 7': 'assets/audio/AirBar7.mp3',
      'Normal Air': 'assets/audio/NormalAir.mp3',
    };

    List<String> alertFiles = emptyGases
        .map((gas) => gasAudioMap[gas.name])
        .whereType<String>()
        .toList();

    int index = 0;

    while (globalUsbProvider.isAlertPlaying && alertFiles.isNotEmpty) {
      String currentFile = alertFiles[index];
      await globalUsbProvider.audioPlayer.play(
        AssetSource(currentFile.replaceFirst('assets/', '')),
      );
      await globalUsbProvider.audioPlayer.onPlayerComplete.first;
      index = (index + 1) % alertFiles.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MGPS', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 18, 39, 41),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 makes the back button white
        ),
        actions: [_buildConnectionStatus()],
      ),

      body: Consumer<GlobalUsbProvider>(
        builder: (context, usbProvider, child) {
          // Parse incoming data from GlobalUsbProvider
          if (usbProvider.receivedData.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _buffer += usbProvider.receivedData;

              if (_buffer.contains('}')) {
                int lastCompleteIndex = _buffer.lastIndexOf('}');
                if (lastCompleteIndex != -1) {
                  String completeMessage = _buffer.substring(
                    0,
                    lastCompleteIndex + 1,
                  );
                  _parseGasData(completeMessage);
                  _buffer = _buffer.substring(lastCompleteIndex + 1);
                }
              }
            });
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 18, 39, 41),
                  Color.fromARGB(255, 25, 60, 63),
                ],
              ),
            ),
            child: Column(
              children: [
                // Status message from GlobalUsbProvider
                if (!usbProvider.isConnected)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    color: Colors.red.withOpacity(0.2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.usb_off, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'USB Disconnected - Auto-connecting...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildGasGrid()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<GlobalUsbProvider>(
      builder: (context, usbProvider, child) {
        return Padding(
          padding: EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Icon(
                usbProvider.isConnected ? Icons.usb : Icons.usb_off,
                color: usbProvider.isConnected
                    ? Colors.transparent
                    : Colors.red,
              ),
              SizedBox(width: 8),
              // Text(
              //   usbProvider.isConnected ? 'Connected' : 'Disconnected',
              //   style: TextStyle(
              //     color: usbProvider.isConnected ? Colors.green : Colors.red,
              //     fontSize: 12,
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGasGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: _gasStatusList.length,
        itemBuilder: (context, index) {
          return _buildGasCard(_gasStatusList[index]);
        },
      ),
    );
  }

  Widget _buildGasCard(GasStatus gas) {
    return Card(
      color: const Color.fromARGB(29, 255, 255, 255),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gas.color.withOpacity(0.4), width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(gas.icon, size: 28, color: gas.color),
              SizedBox(height: 6),
              Text(
                gas.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gas.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gas.color, width: 1),
                ),
                child: Text(
                  gas.status,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sensor ${gas.sensorNumber}',
                style: TextStyle(fontSize: 9, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GasStatus {
  final String name;
  final int sensorNumber;
  final String status;
  final Color color;
  final int faultBit;
  final IconData icon;

  GasStatus({
    required this.name,
    required this.sensorNumber,
    required this.status,
    required this.color,
    required this.faultBit,
    required this.icon,
  });
}
