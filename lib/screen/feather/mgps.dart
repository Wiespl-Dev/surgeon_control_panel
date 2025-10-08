import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:surgeon_control_panel/provider/audioProvider.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:provider/provider.dart';
// Import the AudioProvider

class GasStatusPage extends StatefulWidget {
  @override
  _GasStatusPageState createState() => _GasStatusPageState();
}

class _GasStatusPageState extends State<GasStatusPage> {
  List<UsbDevice> _devices = [];
  UsbPort? _port;
  bool _isConnected = false;
  bool _isScanning = false;
  String _receivedData = '';
  String _statusMessage = 'Disconnected';
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
    _autoConnectToDevice();
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

  Future<void> _autoConnectToDevice() async {
    try {
      setState(() {
        _isScanning = true;
        _statusMessage = 'Scanning for USB devices...';
      });

      List<UsbDevice> devices = await UsbSerial.listDevices();

      setState(() {
        _devices = devices;
        _isScanning = false;
      });

      if (devices.isNotEmpty) {
        _statusMessage =
            'Found ${devices.length} device(s). Connecting to ${devices.first.deviceName}...';
        bool connected = await _connectToDevice(devices.first);

        if (connected) {
          setState(() {
            _statusMessage =
                "Automatically connected to ${devices.first.deviceName}";
          });
        } else {
          setState(() {
            _statusMessage =
                "Failed to auto-connect to ${devices.first.deviceName}";
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No USB devices found';
        });
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Auto-connect failed: $e';
      });
    }
  }

  Future<void> _scanDevices() async {
    try {
      setState(() {
        _isScanning = true;
        _statusMessage = 'Scanning for USB devices...';
      });

      List<UsbDevice> devices = await UsbSerial.listDevices();
      setState(() {
        _devices = devices;
        _isScanning = false;
        _statusMessage = 'Found ${devices.length} USB device(s)';
      });

      if (devices.isNotEmpty && !_isConnected) {
        _statusMessage = 'Auto-connecting to ${devices.first.deviceName}...';
        bool connected = await _connectToDevice(devices.first);

        if (connected) {
          setState(() {
            _statusMessage =
                "Automatically connected to ${devices.first.deviceName}";
          });
        }
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Failed to scan devices: $e';
      });
    }
  }

  Future<bool> _connectToDevice(UsbDevice device) async {
    try {
      _port = await device.create();

      if (await _port!.open() != true) {
        setState(() {
          _statusMessage = "Failed to open port";
        });
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        9600,
        8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      setState(() {
        _isConnected = true;
        _statusMessage = "Connected to ${device.deviceName}";
        _buffer = '';
      });

      _port!.inputStream!.listen(_onDataReceived);

      return true;
    } catch (e) {
      setState(() {
        _statusMessage = "Failed to connect: $e";
      });
      return false;
    }
  }

  void _onDataReceived(Uint8List data) {
    String newData = String.fromCharCodes(data);

    setState(() {
      _buffer += newData;
      _receivedData = _buffer;
    });

    if (_buffer.contains('}')) {
      int lastCompleteIndex = _buffer.lastIndexOf('}');
      if (lastCompleteIndex != -1) {
        String completeMessage = _buffer.substring(0, lastCompleteIndex + 1);

        _parseGasData(completeMessage);

        setState(() {
          _buffer = _buffer.substring(lastCompleteIndex + 1);
        });
      }
    }
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
        _statusMessage =
            "Data updated - ${DateTime.now().toString().substring(11, 19)}";
      });

      // Check and play alert dynamically
      _checkAndPlayAlert();
    } catch (e) {
      print('Error parsing data: $e');
      setState(() {
        _statusMessage = "Error parsing data: $e";
      });
    }
  }

  void _checkAndPlayAlert() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    // Get all EMPTY gases
    List<GasStatus> emptyGases = _gasStatusList
        .where((gas) => gas.status == "EMPTY")
        .toList();

    if (emptyGases.isNotEmpty && !audioProvider.isAlertPlaying) {
      audioProvider.setAlertPlaying(true);
      _playLoopAlert(emptyGases);
    } else if (emptyGases.isEmpty && audioProvider.isAlertPlaying) {
      audioProvider.setAlertPlaying(false);
      audioProvider.stopAudio();
    }
  }

  Future<void> _playLoopAlert(List<GasStatus> emptyGases) async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
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

    while (audioProvider.isAlertPlaying && alertFiles.isNotEmpty) {
      String currentFile = alertFiles[index];
      await audioProvider.audioPlayer.play(
        AssetSource(currentFile.replaceFirst('assets/', '')),
      );
      await audioProvider.audioPlayer.onPlayerComplete.first;
      index = (index + 1) % alertFiles.length;
    }
  }

  Future<void> _disconnect() async {
    try {
      await _port?.close();
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.isAlertPlaying) {
        audioProvider.setAlertPlaying(false);
        await audioProvider.stopAudio();
      }
      setState(() {
        _port = null;
        _isConnected = false;
        _statusMessage = "Disconnected";
        _receivedData = '';
        _buffer = '';
        _initializeDefaultGasStatus();
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Failed to disconnect: $e";
      });
    }
  }

  @override
  void dispose() {
    _port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MGPS', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 18, 39, 41),
        elevation: 0,
        actions: [_buildConnectionStatus(), _buildUsbMenu()],
      ),
      body: Container(
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
            if (!_isConnected && _devices.isNotEmpty) _buildDeviceList(),
            Expanded(child: _buildGasGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.usb : Icons.usb_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Text(
            _isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: _isConnected ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsbMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'scan') {
          _scanDevices();
        } else if (value == 'disconnect') {
          _disconnect();
        } else if (value == 'auto_connect') {
          _autoConnectToDevice();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'scan',
          child: Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Scan Devices'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'auto_connect',
          child: Row(
            children: [
              Icon(Icons.usb, color: Colors.green),
              SizedBox(width: 8),
              Text('Auto Connect'),
            ],
          ),
        ),
        if (_isConnected)
          PopupMenuItem(
            value: 'disconnect',
            child: Row(
              children: [
                Icon(Icons.usb_off, color: Colors.red),
                SizedBox(width: 8),
                Text('Disconnect'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceList() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(8),
      color: Colors.black.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available USB Devices:',
            style: TextStyle(
              color: const Color.fromARGB(68, 255, 255, 255),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: Icon(Icons.usb),
                    title: Text(
                      _devices[index].deviceName ?? 'Unknown Device',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      'PID: ${_devices[index].pid}',
                      style: TextStyle(fontSize: 12),
                    ),
                    dense: true,
                    onTap: () {
                      _connectToDevice(_devices[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
