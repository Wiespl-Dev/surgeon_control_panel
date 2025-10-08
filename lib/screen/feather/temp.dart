import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TempGaugeScreen extends StatefulWidget {
  const TempGaugeScreen({super.key});

  @override
  State<TempGaugeScreen> createState() => _TempGaugeScreenState();
}

class _TempGaugeScreenState extends State<TempGaugeScreen> {
  double _pendingTemperature = 25.0;
  String? lastReceivedValue;
  String? lastSentMessage;
  String temp = "--";

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
    // Load saved temperature values
    setState(() {
      temp = _prefs.getString('current_temperature') ?? "--";
      _pendingTemperature = _prefs.getDouble('setpoint_temperature') ?? 25.0;
    });

    print(
      "Loaded saved values - Current: $temp, Setpoint: $_pendingTemperature",
    );
  }

  void _saveCurrentTemperature(String value) {
    _prefs.setString('current_temperature', value);
    print("Saved current temperature: $value");
  }

  void _saveSetpointTemperature(double value) {
    _prefs.setDouble('setpoint_temperature', value);
    print("Saved setpoint temperature: $value");
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
          // Parse current temperature (C_OT_TEMP:239 = 23.9°C)
          if (parsedData.containsKey('C_OT_TEMP')) {
            String tempStr = parsedData['C_OT_TEMP'].toString();
            if (tempStr.length >= 2) {
              // Convert "239" to "23.9"
              String wholePart = tempStr.substring(0, tempStr.length - 1);
              String decimalPart = tempStr.substring(tempStr.length - 1);
              temp = '$wholePart.$decimalPart';
              print("Parsed temperature: $temp°C");

              // Save current temperature to shared preferences
              _saveCurrentTemperature(temp);
            } else {
              temp = tempStr;
              _saveCurrentTemperature(temp);
            }
          } else {
            print("C_OT_TEMP key not found in parsed data");
          }

          // Parse set temperature (S_TEMP_SETPT:215 = 21.5°C)
          if (parsedData.containsKey('S_TEMP_SETPT')) {
            String setTempStr = parsedData['S_TEMP_SETPT'].toString();
            if (setTempStr.length >= 2) {
              // Convert "215" to 21.5
              String numericPart = setTempStr.substring(
                0,
                setTempStr.length - 1,
              );
              _pendingTemperature = double.parse(numericPart).toDouble();
              print("Parsed set temperature: $_pendingTemperature°C");

              // Save setpoint temperature to shared preferences
              _saveSetpointTemperature(_pendingTemperature);
            }
          } else {
            print("S_TEMP_SETPT key not found in parsed data");
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

    // Convert current temperature to 3-digit format
    String tempValue = "250"; // default
    if (temp != "--") {
      try {
        double currentTemp = double.parse(temp);
        tempValue = (currentTemp * 10).toInt().toString().padLeft(3, '0');
      } catch (e) {
        tempValue = "250";
      }
    }
    pairs.add('C_OT_TEMP:$tempValue');
    pairs.add('C_RH:500');

    for (int i = 1; i <= 10; i++) {
      pairs.add('F_Sensor_${i}_FAULT_BIT:0');
      pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
      pairs.add('S_Light_${i}_ON_OFF:0');
      pairs.add('S_Light_${i}_Intensity:000');
    }

    pairs.add('S_IOT_TIMER:0060');
    pairs.add(
      'S_TEMP_SETPT:${(_pendingTemperature * 10).toInt().toString().padLeft(3, '0')}',
    );
    pairs.add('S_RH_SETPT:500');

    String command = '{${pairs.join(',')}}\n';

    _port!.write(Uint8List.fromList(command.codeUnits));

    setState(() {
      lastSentMessage = command.trim();
    });

    print("Sent: $command");

    // Save the setpoint when user sets it manually
    _saveSetpointTemperature(_pendingTemperature);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Temperature set to ${_pendingTemperature.toStringAsFixed(1)}°C",
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
      // backgroundColor: const Color.fromARGB(205, 157, 102, 228),
      backgroundColor: const Color(0xFF3D8A8F),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                // Color.fromARGB(255, 237, 137, 68),
                // Color.fromARGB(255, 179, 44, 116),
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
                "Temperature Control",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // Current temperature display
              Text(
                "Current: $temp°C",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Setpoint: ${_pendingTemperature.toStringAsFixed(1)}°C",
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

                    double value = (normalized / sweepAngleRad) * 20 + 15;
                    value = value.clamp(15.0, 35.0);

                    setState(() {
                      _pendingTemperature = value;
                    });
                  },
                  child: SfRadialGauge(
                    axes: [
                      RadialAxis(
                        minimum: 15,
                        maximum: 35,
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
                            value: _pendingTemperature,
                            width: 0.2,
                            color: Colors.white,
                            cornerStyle: CornerStyle.bothCurve,
                            sizeUnit: GaugeSizeUnit.factor,
                          ),
                          MarkerPointer(
                            value: _pendingTemperature,
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
                              "${_pendingTemperature.toStringAsFixed(1)}°C",
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

              // Debug info (optional - remove in production)
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
