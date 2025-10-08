import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HumidityGaugeScreen extends StatefulWidget {
  const HumidityGaugeScreen({super.key});

  @override
  State<HumidityGaugeScreen> createState() => _HumidityGaugeScreenState();
}

class _HumidityGaugeScreenState extends State<HumidityGaugeScreen> {
  double _pendingHumidity = 50.0;
  String? lastReceivedValue;
  String? lastSentMessage;
  String humidity = "--";

  UsbPort? _port;
  String usbStatus = "Disconnected";
  bool isConnected = false;
  String _incomingBuffer = "";

  // SharedPreferences instance
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _initUsb();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedValues();
  }

  void _loadSavedValues() {
    // Load saved humidity values
    setState(() {
      humidity = _prefs.getString('current_humidity') ?? "--";
      _pendingHumidity = _prefs.getDouble('setpoint_humidity') ?? 50.0;
    });

    print(
      "Loaded saved values - Current: $humidity, Setpoint: $_pendingHumidity",
    );
  }

  void _saveCurrentHumidity(String value) {
    _prefs.setString('current_humidity', value);
    print("Saved current humidity: $value");
  }

  void _saveSetpointHumidity(double value) {
    _prefs.setDouble('setpoint_humidity', value);
    print("Saved setpoint humidity: $value");
  }

  Future<void> _initUsb() async {
    try {
      setState(() {
        usbStatus = "Scanning for USB devices...";
      });

      List<UsbDevice> devices = await UsbSerial.listDevices();
      print("Found ${devices.length} USB devices");

      if (devices.isEmpty) {
        setState(() {
          usbStatus = "No USB devices found";
          isConnected = false;
        });
        return;
      }

      UsbDevice device = devices.first;
      print("Connecting to: ${device.deviceName}");

      setState(() {
        usbStatus = "Connecting to ${device.deviceName}...";
      });

      _port = await device.create();
      bool open = await _port!.open();

      if (open) {
        await _port!.setDTR(true);
        await _port!.setRTS(true);
        await _port!.setPortParameters(9600, 8, 1, 0);

        setState(() {
          usbStatus = "Connected to ${device.deviceName}";
          isConnected = true;
        });

        print("USB connected successfully");
        _port!.inputStream?.listen(_onDataReceived);
      } else {
        setState(() {
          usbStatus = "Failed to open USB port";
          isConnected = false;
        });
      }
    } catch (e) {
      print("USB Error: $e");
      setState(() {
        usbStatus = "Error: $e";
        isConnected = false;
      });
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
    setState(() {
      lastReceivedValue = completeMessage;
    });
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

        setState(() {
          // Parse current humidity (C_RH:295 = 29.5%)
          if (parsedData.containsKey('C_RH')) {
            String humStr = parsedData['C_RH'].toString();
            if (humStr.length >= 2) {
              String wholePart = humStr.substring(0, humStr.length - 1);
              String decimalPart = humStr.substring(humStr.length - 1);
              humidity = '$wholePart.$decimalPart';
              print("Parsed humidity: $humidity%");

              // Save current humidity to shared preferences
              _saveCurrentHumidity(humidity);
            } else {
              humidity = humStr;
              _saveCurrentHumidity(humidity);
            }
          } else {
            print("C_RH key not found in parsed data");
          }

          // Parse set humidity (S_RH_SETPT:784 = 78.4%)
          if (parsedData.containsKey('S_RH_SETPT')) {
            String setHumStr = parsedData['S_RH_SETPT'].toString();
            if (setHumStr.length >= 2) {
              String wholePart = setHumStr.substring(0, setHumStr.length - 1);
              String decimalPart = setHumStr.substring(setHumStr.length - 1);
              _pendingHumidity = double.parse(
                "$wholePart.$decimalPart",
              ).toDouble();
              print("Parsed set humidity: $_pendingHumidity%");

              // Save setpoint humidity to shared preferences
              _saveSetpointHumidity(_pendingHumidity);
            }
          } else {
            print("S_RH_SETPT key not found in parsed data");
          }
        });
      } else {
        print("Data doesn't have proper structure: $data");
      }
    } catch (e) {
      print("Error parsing structured data: $e");
      print("Data that caused error: $data");
    }
  }

  void _sendCompleteStructure() {
    if (_port == null || !isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("USB not connected"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> pairs = [];

    pairs.add('SR_WSL:200001');
    pairs.add('C_PRESSURE_1:000');
    pairs.add('C_PRESSURE_1_SIGN_BIT:1');
    pairs.add('C_PRESSURE_2:000');
    pairs.add('C_PRESSURE_2_SIGN_BIT:1');

    // Current humidity
    String humValue = "500"; // default 50.0%
    if (humidity != "--") {
      try {
        double currentHum = double.parse(humidity);
        humValue = (currentHum * 10).toInt().toString().padLeft(3, '0');
      } catch (e) {
        humValue = "500";
      }
    }
    pairs.add('C_RH:$humValue');

    // Dummy temperature value (since this screen is for humidity)
    pairs.add('C_OT_TEMP:250');

    for (int i = 1; i <= 10; i++) {
      pairs.add('F_Sensor_${i}_FAULT_BIT:0');
      pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
      pairs.add('S_Light_${i}_ON_OFF:0');
      pairs.add('S_Light_${i}_Intensity:000');
    }

    pairs.add('S_IOT_TIMER:0060');
    pairs.add(
      'S_RH_SETPT:${(_pendingHumidity * 10).toInt().toString().padLeft(3, '0')}',
    );
    pairs.add('S_TEMP_SETPT:215');

    String command = '{${pairs.join(',')}}\n';

    _port!.write(Uint8List.fromList(command.codeUnits));

    setState(() {
      lastSentMessage = command.trim();
    });

    print("Sent: $command");

    // Save the setpoint when user sets it manually
    _saveSetpointHumidity(_pendingHumidity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Humidity set to ${_pendingHumidity.toStringAsFixed(1)}%",
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reconnectUsb() {
    _initUsb();
  }

  void _requestStatus() {
    if (_port != null && isConnected) {
      String command = "STATUS\n";
      _port!.write(Uint8List.fromList(command.codeUnits));
      print("Sent STATUS request");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status request sent"),
          backgroundColor: Colors.blue,
        ),
      );
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
      backgroundColor: const Color(0xFF3D8A8F),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 40, 123, 131),
                Color.fromARGB(255, 39, 83, 87),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with USB status and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isConnected ? "Connected" : "Disconnected",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (usbStatus.isNotEmpty)
                        Text(
                          usbStatus.length > 20
                              ? "${usbStatus.substring(0, 20)}..."
                              : usbStatus,
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                "Humidity Control",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // Current humidity display
              Text(
                "Current: $humidity%",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Setpoint: ${_pendingHumidity.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // Gauge
              SizedBox(
                height: 250,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final offset = box.globalToLocal(details.globalPosition);
                    final center = box.size.center(Offset.zero);
                    final angle = (offset - center).direction;

                    double startAngleRad = 150 * (math.pi / 180);
                    double sweepAngleRad = 240 * (math.pi / 180);

                    double normalized = (angle - startAngleRad) % (2 * math.pi);
                    if (normalized < 0) normalized += 2 * math.pi;

                    double value = (normalized / sweepAngleRad) * 100;
                    value = value.clamp(0.0, 100.0);

                    setState(() {
                      _pendingHumidity = value;
                    });
                  },
                  child: SfRadialGauge(
                    axes: [
                      RadialAxis(
                        minimum: 0,
                        maximum: 100,
                        startAngle: 150,
                        endAngle: 30,
                        showTicks: false,
                        showLabels: false,
                        axisLineStyle: const AxisLineStyle(
                          thickness: 0.2,
                          thicknessUnit: GaugeSizeUnit.factor,
                          color: Colors.white24,
                        ),
                        pointers: [
                          RangePointer(
                            value: _pendingHumidity,
                            width: 0.2,
                            color: Colors.white,
                            cornerStyle: CornerStyle.bothCurve,
                            sizeUnit: GaugeSizeUnit.factor,
                          ),
                          MarkerPointer(
                            value: _pendingHumidity,
                            markerType: MarkerType.circle,
                            color: Colors.white,
                            markerHeight: 20,
                            markerWidth: 20,
                          ),
                        ],
                        annotations: [
                          GaugeAnnotation(
                            angle: 90,
                            positionFactor: 0,
                            widget: Text(
                              "${_pendingHumidity.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Debug info
              if (lastReceivedValue != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Last received: ${lastReceivedValue!.length > 50 ? '${lastReceivedValue!.substring(0, 50)}...' : lastReceivedValue!}",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontFamily: 'Monospace',
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _reconnectUsb,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "RECONNECT",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _requestStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("STATUS", style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: _sendCompleteStructure,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("SET", style: TextStyle(fontSize: 14)),
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
