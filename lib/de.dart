// // // // // import 'dart:async';
// // // // // import 'dart:typed_data';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:usb_serial/usb_serial.dart';

// // // // // void main() {
// // // // //   runApp(
// // // // //     MaterialApp(
// // // // //       debugShowCheckedModeBanner: false,
// // // // //       title: 'Sensor Control App',
// // // // //       theme: ThemeData(primarySwatch: Colors.blue),
// // // // //       home: MainControlPage(),
// // // // //     ),
// // // // //   );
// // // // // }

// // // // // // --- MAIN WIDGET: Manages State, USB, and Navigation ---
// // // // // class MainControlPage extends StatefulWidget {
// // // // //   @override
// // // // //   _MainControlPageState createState() => _MainControlPageState();
// // // // // }

// // // // // class _MainControlPageState extends State<MainControlPage> {
// // // // //   // USB State
// // // // //   UsbPort? _port;
// // // // //   String usbStatus = "Disconnected";
// // // // //   bool isConnected = false;
// // // // //   String lastSentString = "Nothing sent yet";
// // // // //   String lastReceivedString = "Nothing received yet";
// // // // //   TextEditingController commandController = TextEditingController();

// // // // //   // UI State
// // // // //   int _selectedIndex = 0;
// // // // //   String _incomingBuffer = "";

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _initUsb();
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _port?.close();
// // // // //     super.dispose();
// // // // //   }

// // // // //   // --- USB Communication Methods ---

// // // // //   Future<void> _initUsb() async {
// // // // //     try {
// // // // //       setState(() {
// // // // //         usbStatus = "Scanning for USB devices...";
// // // // //       });

// // // // //       List<UsbDevice> devices = await UsbSerial.listDevices();
// // // // //       print("Found ${devices.length} USB devices");

// // // // //       if (devices.isEmpty) {
// // // // //         setState(() {
// // // // //           usbStatus = "No USB devices found";
// // // // //           isConnected = false;
// // // // //         });
// // // // //         return;
// // // // //       }

// // // // //       UsbDevice device = devices.first;
// // // // //       print("Connecting to: ${device.deviceName}");

// // // // //       setState(() {
// // // // //         usbStatus = "Connecting to ${device.deviceName}...";
// // // // //       });

// // // // //       _port = await device.create();
// // // // //       bool open = await _port!.open();

// // // // //       if (open) {
// // // // //         await _port!.setPortParameters(9600, 8, 1, 0);
// // // // //         _port!.inputStream?.listen(_onDataReceived);

// // // // //         setState(() {
// // // // //           usbStatus = "Connected to ${device.deviceName}";
// // // // //           isConnected = true;
// // // // //         });

// // // // //         print("USB connected successfully");
// // // // //         _sendCommand("STATUS");
// // // // //       } else {
// // // // //         setState(() {
// // // // //           usbStatus = "Failed to open USB port";
// // // // //           isConnected = false;
// // // // //         });
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("USB Error: $e");
// // // // //       setState(() {
// // // // //         usbStatus = "Error: $e";
// // // // //         isConnected = false;
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _onDataReceived(Uint8List data) {
// // // // //     String str = String.fromCharCodes(data);
// // // // //     print("Received RAW chunk: $str");

// // // // //     _incomingBuffer += str;

// // // // //     if (_incomingBuffer.contains('\n') ||
// // // // //         (_incomingBuffer.startsWith('{') && _incomingBuffer.contains('}'))) {
// // // // //       List<String> messages = _incomingBuffer.split('\n');

// // // // //       for (int i = 0; i < messages.length - 1; i++) {
// // // // //         String completeMessage = messages[i].trim();
// // // // //         if (completeMessage.isNotEmpty) {
// // // // //           _processCompleteMessage(completeMessage);
// // // // //         }
// // // // //       }

// // // // //       _incomingBuffer = messages.last;
// // // // //     }

// // // // //     if (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}')) {
// // // // //       _processCompleteMessage(_incomingBuffer);
// // // // //       _incomingBuffer = "";
// // // // //     }
// // // // //   }

// // // // //   void _processCompleteMessage(String completeMessage) {
// // // // //     print("Processing complete message: $completeMessage");
// // // // //     setState(() {
// // // // //       lastReceivedString = completeMessage;
// // // // //     });
// // // // //   }

// // // // //   void _sendCommand(String cmd) {
// // // // //     if (_port != null && isConnected) {
// // // // //       String commandToSend = cmd + "\n";
// // // // //       _port!.write(Uint8List.fromList(commandToSend.codeUnits));

// // // // //       setState(() {
// // // // //         lastSentString = commandToSend.trim();
// // // // //       });

// // // // //       print("Sent: $commandToSend");
// // // // //     } else {
// // // // //       print("Cannot send - USB not connected");
// // // // //       setState(() {
// // // // //         lastSentString = "FAILED: USB not connected";
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _sendCustomCommand() {
// // // // //     if (commandController.text.isNotEmpty) {
// // // // //       _sendCommand(commandController.text);
// // // // //       commandController.clear();
// // // // //     }
// // // // //   }

// // // // //   void _reconnectUsb() {
// // // // //     _initUsb();
// // // // //   }

// // // // //   void _onItemTapped(int index) {
// // // // //     setState(() {
// // // // //       _selectedIndex = index;
// // // // //     });
// // // // //   }

// // // // //   // --- Widget Build ---

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final List<Widget> _widgetOptions = <Widget>[
// // // // //       TemperatureControlPage(), // No parameters needed
// // // // //       HumidityControlPage(), // No parameters needed
// // // // //       LightIntensityPage(), // No parameters needed
// // // // //       CommunicationPage(
// // // // //         usbStatus: usbStatus,
// // // // //         isConnected: isConnected,
// // // // //         lastSentString: lastSentString,
// // // // //         lastReceivedString: lastReceivedString,
// // // // //         incomingBuffer: _incomingBuffer,
// // // // //         commandController: commandController,
// // // // //         onSendCommand: _sendCommand,
// // // // //         onSendCustomCommand: _sendCustomCommand,
// // // // //         onReconnectUsb: _reconnectUsb,
// // // // //       ),
// // // // //     ];

// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         title: Text(_getPageTitle(_selectedIndex)),
// // // // //         backgroundColor: isConnected ? Colors.green : Colors.red,
// // // // //       ),
// // // // //       body: _widgetOptions.elementAt(_selectedIndex),
// // // // //       bottomNavigationBar: BottomNavigationBar(
// // // // //         items: const <BottomNavigationBarItem>[
// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(Icons.thermostat_outlined),
// // // // //             label: 'Temperature',
// // // // //           ),
// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(Icons.water_drop_outlined),
// // // // //             label: 'Humidity',
// // // // //           ),
// // // // //           BottomNavigationBarItem(
// // // // //             icon: Icon(Icons.lightbulb_outline),
// // // // //             label: 'Lights',
// // // // //           ),
// // // // //           BottomNavigationBarItem(icon: Icon(Icons.usb), label: 'Comms'),
// // // // //         ],
// // // // //         currentIndex: _selectedIndex,
// // // // //         selectedItemColor: isConnected ? Colors.green[800] : Colors.red[800],
// // // // //         unselectedItemColor: Colors.grey,
// // // // //         type: BottomNavigationBarType.fixed,
// // // // //         onTap: _onItemTapped,
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   String _getPageTitle(int index) {
// // // // //     switch (index) {
// // // // //       case 0:
// // // // //         return "Temperature Control";
// // // // //       case 1:
// // // // //         return "Humidity Control";
// // // // //       case 2:
// // // // //         return "Light Intensity Control";
// // // // //       case 3:
// // // // //         return "USB Communication";
// // // // //       default:
// // // // //         return "Sensor Control App";
// // // // //     }
// // // // //   }
// // // // // }

// // // // // // -----------------------------------------------------------------------------
// // // // // // --- TEMPERATURE CONTROL SCREEN (Standalone) ---
// // // // // // -----------------------------------------------------------------------------

// // // // // class TemperatureControlPage extends StatefulWidget {
// // // // //   @override
// // // // //   _TemperatureControlPageState createState() => _TemperatureControlPageState();
// // // // // }

// // // // // class _TemperatureControlPageState extends State<TemperatureControlPage> {
// // // // //   // Temperature state
// // // // //   String currentTemp = "--";
// // // // //   int setTemperature = 25;

// // // // //   // USB communication
// // // // //   UsbPort? _port;
// // // // //   bool isConnected = false;
// // // // //   String _incomingBuffer = "";

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _initUsb();
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _port?.close();
// // // // //     super.dispose();
// // // // //   }

// // // // //   // USB Initialization
// // // // //   Future<void> _initUsb() async {
// // // // //     try {
// // // // //       List<UsbDevice> devices = await UsbSerial.listDevices();
// // // // //       if (devices.isEmpty) {
// // // // //         setState(() {
// // // // //           isConnected = false;
// // // // //         });
// // // // //         return;
// // // // //       }

// // // // //       UsbDevice device = devices.first;
// // // // //       _port = await device.create();
// // // // //       bool open = await _port!.open();

// // // // //       if (open) {
// // // // //         await _port!.setPortParameters(9600, 8, 1, 0);
// // // // //         _port!.inputStream?.listen(_onDataReceived);

// // // // //         setState(() {
// // // // //           isConnected = true;
// // // // //         });

// // // // //         _sendCommand("STATUS");
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("USB Error in TemperatureControlPage: $e");
// // // // //       setState(() {
// // // // //         isConnected = false;
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _onDataReceived(Uint8List data) {
// // // // //     String str = String.fromCharCodes(data);
// // // // //     _incomingBuffer += str;

// // // // //     if (_incomingBuffer.contains('\n') ||
// // // // //         (_incomingBuffer.startsWith('{') && _incomingBuffer.contains('}'))) {
// // // // //       List<String> messages = _incomingBuffer.split('\n');

// // // // //       for (int i = 0; i < messages.length - 1; i++) {
// // // // //         String completeMessage = messages[i].trim();
// // // // //         if (completeMessage.isNotEmpty) {
// // // // //           _processCompleteMessage(completeMessage);
// // // // //         }
// // // // //       }

// // // // //       _incomingBuffer = messages.last;
// // // // //     }

// // // // //     if (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}')) {
// // // // //       _processCompleteMessage(_incomingBuffer);
// // // // //       _incomingBuffer = "";
// // // // //     }
// // // // //   }

// // // // //   void _processCompleteMessage(String completeMessage) {
// // // // //     _parseStructuredData(completeMessage);
// // // // //   }

// // // // //   void _parseStructuredData(String data) {
// // // // //     try {
// // // // //       if (data.startsWith('{') && data.endsWith('}')) {
// // // // //         String content = data.substring(1, data.length - 1);
// // // // //         List<String> pairs = content.split(',');

// // // // //         Map<String, dynamic> parsedData = {};

// // // // //         for (String pair in pairs) {
// // // // //           List<String> keyValue = pair.split(':');
// // // // //           if (keyValue.length == 2) {
// // // // //             String key = keyValue[0].trim();
// // // // //             String value = keyValue[1].trim();
// // // // //             parsedData[key] = value;
// // // // //           }
// // // // //         }

// // // // //         setState(() {
// // // // //           // Parse temperature (C_OT_TEMP:239 = 23.9°C)
// // // // //           if (parsedData.containsKey('C_OT_TEMP')) {
// // // // //             String tempStr = parsedData['C_OT_TEMP'].toString();
// // // // //             if (tempStr.length >= 2) {
// // // // //               currentTemp =
// // // // //                   '${tempStr.substring(0, tempStr.length - 1)}.${tempStr.substring(tempStr.length - 1)}';
// // // // //             } else {
// // // // //               currentTemp = tempStr;
// // // // //             }
// // // // //           }

// // // // //           // Parse set temperature (S_TEMP_SETPT:215 = 21.5°C)
// // // // //           if (parsedData.containsKey('S_TEMP_SETPT')) {
// // // // //             String setTempStr = parsedData['S_TEMP_SETPT'].toString();
// // // // //             if (setTempStr.length >= 2) {
// // // // //               setTemperature = int.parse(
// // // // //                 setTempStr.substring(0, setTempStr.length - 1),
// // // // //               );
// // // // //             }
// // // // //           }
// // // // //         });
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("Error parsing temperature data: $e");
// // // // //     }
// // // // //   }

// // // // //   void _sendCommand(String cmd) {
// // // // //     if (_port != null && isConnected) {
// // // // //       String commandToSend = cmd + "\n";
// // // // //       _port!.write(Uint8List.fromList(commandToSend.codeUnits));
// // // // //       print("Temperature Page Sent: $commandToSend");
// // // // //     }
// // // // //   }

// // // // //   void _sendCompleteStructure() {
// // // // //     List<String> pairs = [];

// // // // //     pairs.add('SR_WSL:200001');
// // // // //     pairs.add('C_PRESSURE_1:000');
// // // // //     pairs.add('C_PRESSURE_1_SIGN_BIT:1');
// // // // //     pairs.add('C_PRESSURE_2:000');
// // // // //     pairs.add('C_PRESSURE_2_SIGN_BIT:1');

// // // // //     String tempValue = currentTemp != "--"
// // // // //         ? (double.tryParse(currentTemp) ?? 25.0).toInt().toString().padLeft(
// // // // //             3,
// // // // //             '0',
// // // // //           )
// // // // //         : "250";

// // // // //     pairs.add('C_OT_TEMP:$tempValue');
// // // // //     pairs.add('C_RH:500'); // Default humidity

// // // // //     for (int i = 1; i <= 10; i++) {
// // // // //       pairs.add('F_Sensor_${i}_FAULT_BIT:0');
// // // // //       pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
// // // // //       pairs.add('S_Light_${i}_ON_OFF:0'); // Default lights off
// // // // //       pairs.add('S_Light_${i}_Intensity:000');
// // // // //     }

// // // // //     pairs.add('S_IOT_TIMER:0060');
// // // // //     pairs.add(
// // // // //       'S_TEMP_SETPT:${(setTemperature * 10).toString().padLeft(3, '0')}',
// // // // //     );
// // // // //     pairs.add('S_RH_SETPT:500'); // Default humidity setpoint

// // // // //     String command = '{${pairs.join(',')}}';
// // // // //     _sendCommand(command);
// // // // //   }

// // // // //   void _setTemperature(int value) {
// // // // //     setState(() {
// // // // //       setTemperature = value;
// // // // //     });
// // // // //     _sendCompleteStructure();
// // // // //   }

// // // // //   Widget _buildSetPointControl(
// // // // //     String title,
// // // // //     int value,
// // // // //     int min,
// // // // //     int max,
// // // // //     int step,
// // // // //     ValueChanged<int> onChanged,
// // // // //   ) {
// // // // //     return Card(
// // // // //       margin: EdgeInsets.all(8.0),
// // // // //       child: Padding(
// // // // //         padding: const EdgeInsets.all(16.0),
// // // // //         child: Column(
// // // // //           children: [
// // // // //             Text(
// // // // //               title,
// // // // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // // //             ),
// // // // //             SizedBox(height: 10),
// // // // //             Text(
// // // // //               '$value',
// // // // //               style: TextStyle(
// // // // //                 fontSize: 48,
// // // // //                 fontWeight: FontWeight.bold,
// // // // //                 color: Colors.blue,
// // // // //               ),
// // // // //             ),
// // // // //             SizedBox(height: 10),
// // // // //             Row(
// // // // //               mainAxisAlignment: MainAxisAlignment.center,
// // // // //               children: [
// // // // //                 IconButton(
// // // // //                   icon: Icon(Icons.remove_circle_outline, size: 30),
// // // // //                   onPressed: () => value > min ? onChanged(value - step) : null,
// // // // //                 ),
// // // // //                 SizedBox(width: 20),
// // // // //                 IconButton(
// // // // //                   icon: Icon(Icons.add_circle_outline, size: 30),
// // // // //                   onPressed: () => value < max ? onChanged(value + step) : null,
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return SingleChildScrollView(
// // // // //       padding: EdgeInsets.all(16.0),
// // // // //       child: Column(
// // // // //         crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //         children: <Widget>[
// // // // //           // Connection Status
// // // // //           Card(
// // // // //             color: isConnected ? Colors.green[50] : Colors.red[50],
// // // // //             child: Padding(
// // // // //               padding: const EdgeInsets.all(12.0),
// // // // //               child: Row(
// // // // //                 children: [
// // // // //                   Icon(
// // // // //                     isConnected ? Icons.usb : Icons.usb_off,
// // // // //                     color: isConnected ? Colors.green : Colors.red,
// // // // //                   ),
// // // // //                   SizedBox(width: 8),
// // // // //                   Text(
// // // // //                     isConnected ? "USB Connected" : "USB Disconnected",
// // // // //                     style: TextStyle(fontWeight: FontWeight.bold),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 16),

// // // // //           // Current Temperature
// // // // //           Card(
// // // // //             color: Colors.blue[50],
// // // // //             child: Padding(
// // // // //               padding: const EdgeInsets.all(20.0),
// // // // //               child: Column(
// // // // //                 children: [
// // // // //                   Text("Current Temperature", style: TextStyle(fontSize: 16)),
// // // // //                   Text(
// // // // //                     "$currentTemp °C",
// // // // //                     style: TextStyle(
// // // // //                       fontSize: 40,
// // // // //                       fontWeight: FontWeight.bold,
// // // // //                       color: Colors.blue,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 20),

// // // // //           // Set Point Control
// // // // //           Text(
// // // // //             "Temperature Set Point",
// // // // //             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// // // // //             textAlign: TextAlign.center,
// // // // //           ),
// // // // //           _buildSetPointControl(
// // // // //             "Set Temp (°C)",
// // // // //             setTemperature,
// // // // //             15,
// // // // //             35,
// // // // //             1,
// // // // //             _setTemperature,
// // // // //           ),
// // // // //           SizedBox(height: 20),

// // // // //           // Action Buttons
// // // // //           Row(
// // // // //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // // //             children: [
// // // // //               ElevatedButton(
// // // // //                 onPressed: () => _sendCommand("STATUS"),
// // // // //                 child: Text("Refresh Status"),
// // // // //               ),
// // // // //               ElevatedButton(
// // // // //                 onPressed: _sendCompleteStructure,
// // // // //                 child: Text("Send All Data"),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //           SizedBox(height: 20),

// // // // //           Text(
// // // // //             "Set points are sent upon change.",
// // // // //             textAlign: TextAlign.center,
// // // // //             style: TextStyle(
// // // // //               fontStyle: FontStyle.italic,
// // // // //               color: Colors.grey[600],
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // -----------------------------------------------------------------------------
// // // // // // --- HUMIDITY CONTROL SCREEN (Standalone) ---
// // // // // // -----------------------------------------------------------------------------

// // // // // class HumidityControlPage extends StatefulWidget {
// // // // //   @override
// // // // //   _HumidityControlPageState createState() => _HumidityControlPageState();
// // // // // }

// // // // // class _HumidityControlPageState extends State<HumidityControlPage> {
// // // // //   // Humidity state
// // // // //   String currentHum = "--";
// // // // //   int setHumidity = 50;

// // // // //   // USB communication
// // // // //   UsbPort? _port;
// // // // //   bool isConnected = false;
// // // // //   String _incomingBuffer = "";

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _initUsb();
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _port?.close();
// // // // //     super.dispose();
// // // // //   }

// // // // //   // USB Initialization
// // // // //   Future<void> _initUsb() async {
// // // // //     try {
// // // // //       List<UsbDevice> devices = await UsbSerial.listDevices();
// // // // //       if (devices.isEmpty) {
// // // // //         setState(() {
// // // // //           isConnected = false;
// // // // //         });
// // // // //         return;
// // // // //       }

// // // // //       UsbDevice device = devices.first;
// // // // //       _port = await device.create();
// // // // //       bool open = await _port!.open();

// // // // //       if (open) {
// // // // //         await _port!.setPortParameters(9600, 8, 1, 0);
// // // // //         _port!.inputStream?.listen(_onDataReceived);

// // // // //         setState(() {
// // // // //           isConnected = true;
// // // // //         });

// // // // //         _sendCommand("STATUS");
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("USB Error in HumidityControlPage: $e");
// // // // //       setState(() {
// // // // //         isConnected = false;
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _onDataReceived(Uint8List data) {
// // // // //     String str = String.fromCharCodes(data);
// // // // //     _incomingBuffer += str;

// // // // //     if (_incomingBuffer.contains('\n') ||
// // // // //         (_incomingBuffer.startsWith('{') && _incomingBuffer.contains('}'))) {
// // // // //       List<String> messages = _incomingBuffer.split('\n');

// // // // //       for (int i = 0; i < messages.length - 1; i++) {
// // // // //         String completeMessage = messages[i].trim();
// // // // //         if (completeMessage.isNotEmpty) {
// // // // //           _processCompleteMessage(completeMessage);
// // // // //         }
// // // // //       }

// // // // //       _incomingBuffer = messages.last;
// // // // //     }

// // // // //     if (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}')) {
// // // // //       _processCompleteMessage(_incomingBuffer);
// // // // //       _incomingBuffer = "";
// // // // //     }
// // // // //   }

// // // // //   void _processCompleteMessage(String completeMessage) {
// // // // //     _parseStructuredData(completeMessage);
// // // // //   }

// // // // //   void _parseStructuredData(String data) {
// // // // //     try {
// // // // //       if (data.startsWith('{') && data.endsWith('}')) {
// // // // //         String content = data.substring(1, data.length - 1);
// // // // //         List<String> pairs = content.split(',');

// // // // //         Map<String, dynamic> parsedData = {};

// // // // //         for (String pair in pairs) {
// // // // //           List<String> keyValue = pair.split(':');
// // // // //           if (keyValue.length == 2) {
// // // // //             String key = keyValue[0].trim();
// // // // //             String value = keyValue[1].trim();
// // // // //             parsedData[key] = value;
// // // // //           }
// // // // //         }

// // // // //         setState(() {
// // // // //           // Parse humidity (C_RH:295 = 29.5%)
// // // // //           if (parsedData.containsKey('C_RH')) {
// // // // //             String humStr = parsedData['C_RH'].toString();
// // // // //             if (humStr.length >= 2) {
// // // // //               currentHum =
// // // // //                   '${humStr.substring(0, humStr.length - 1)}.${humStr.substring(humStr.length - 1)}';
// // // // //             } else {
// // // // //               currentHum = humStr;
// // // // //             }
// // // // //           }

// // // // //           // Parse set humidity (S_RH_SETPT:784 = 78.4%)
// // // // //           if (parsedData.containsKey('S_RH_SETPT')) {
// // // // //             String setHumStr = parsedData['S_RH_SETPT'].toString();
// // // // //             if (setHumStr.length >= 2) {
// // // // //               setHumidity = int.parse(
// // // // //                 setHumStr.substring(0, setHumStr.length - 1),
// // // // //               );
// // // // //             }
// // // // //           }
// // // // //         });
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("Error parsing humidity data: $e");
// // // // //     }
// // // // //   }

// // // // //   void _sendCommand(String cmd) {
// // // // //     if (_port != null && isConnected) {
// // // // //       String commandToSend = cmd + "\n";
// // // // //       _port!.write(Uint8List.fromList(commandToSend.codeUnits));
// // // // //       print("Humidity Page Sent: $commandToSend");
// // // // //     }
// // // // //   }

// // // // //   void _sendCompleteStructure() {
// // // // //     List<String> pairs = [];

// // // // //     pairs.add('SR_WSL:200001');
// // // // //     pairs.add('C_PRESSURE_1:000');
// // // // //     pairs.add('C_PRESSURE_1_SIGN_BIT:1');
// // // // //     pairs.add('C_PRESSURE_2:000');
// // // // //     pairs.add('C_PRESSURE_2_SIGN_BIT:1');

// // // // //     pairs.add('C_OT_TEMP:250'); // Default temperature
// // // // //     String humValue = currentHum != "--"
// // // // //         ? (double.tryParse(currentHum) ?? 50.0).toInt().toString().padLeft(
// // // // //             3,
// // // // //             '0',
// // // // //           )
// // // // //         : "500";

// // // // //     pairs.add('C_RH:$humValue');

// // // // //     for (int i = 1; i <= 10; i++) {
// // // // //       pairs.add('F_Sensor_${i}_FAULT_BIT:0');
// // // // //       pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
// // // // //       pairs.add('S_Light_${i}_ON_OFF:0'); // Default lights off
// // // // //       pairs.add('S_Light_${i}_Intensity:000');
// // // // //     }

// // // // //     pairs.add('S_IOT_TIMER:0060');
// // // // //     pairs.add('S_TEMP_SETPT:250'); // Default temperature setpoint
// // // // //     pairs.add('S_RH_SETPT:${(setHumidity * 10).toString().padLeft(3, '0')}');

// // // // //     String command = '{${pairs.join(',')}}';
// // // // //     _sendCommand(command);
// // // // //   }

// // // // //   void _setHumidity(int value) {
// // // // //     setState(() {
// // // // //       setHumidity = value;
// // // // //     });
// // // // //     _sendCompleteStructure();
// // // // //   }

// // // // //   Widget _buildSetPointControl(
// // // // //     String title,
// // // // //     int value,
// // // // //     int min,
// // // // //     int max,
// // // // //     int step,
// // // // //     ValueChanged<int> onChanged,
// // // // //   ) {
// // // // //     return Card(
// // // // //       margin: EdgeInsets.all(8.0),
// // // // //       child: Padding(
// // // // //         padding: const EdgeInsets.all(16.0),
// // // // //         child: Column(
// // // // //           children: [
// // // // //             Text(
// // // // //               title,
// // // // //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // // //             ),
// // // // //             SizedBox(height: 10),
// // // // //             Text(
// // // // //               '$value',
// // // // //               style: TextStyle(
// // // // //                 fontSize: 48,
// // // // //                 fontWeight: FontWeight.bold,
// // // // //                 color: Colors.teal,
// // // // //               ),
// // // // //             ),
// // // // //             SizedBox(height: 10),
// // // // //             Row(
// // // // //               mainAxisAlignment: MainAxisAlignment.center,
// // // // //               children: [
// // // // //                 IconButton(
// // // // //                   icon: Icon(Icons.remove_circle_outline, size: 30),
// // // // //                   onPressed: () => value > min ? onChanged(value - step) : null,
// // // // //                 ),
// // // // //                 SizedBox(width: 20),
// // // // //                 IconButton(
// // // // //                   icon: Icon(Icons.add_circle_outline, size: 30),
// // // // //                   onPressed: () => value < max ? onChanged(value + step) : null,
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return SingleChildScrollView(
// // // // //       padding: EdgeInsets.all(16.0),
// // // // //       child: Column(
// // // // //         crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //         children: <Widget>[
// // // // //           // Connection Status
// // // // //           Card(
// // // // //             color: isConnected ? Colors.green[50] : Colors.red[50],
// // // // //             child: Padding(
// // // // //               padding: const EdgeInsets.all(12.0),
// // // // //               child: Row(
// // // // //                 children: [
// // // // //                   Icon(
// // // // //                     isConnected ? Icons.usb : Icons.usb_off,
// // // // //                     color: isConnected ? Colors.green : Colors.red,
// // // // //                   ),
// // // // //                   SizedBox(width: 8),
// // // // //                   Text(
// // // // //                     isConnected ? "USB Connected" : "USB Disconnected",
// // // // //                     style: TextStyle(fontWeight: FontWeight.bold),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 16),

// // // // //           // Current Humidity
// // // // //           Card(
// // // // //             color: Colors.teal[50],
// // // // //             child: Padding(
// // // // //               padding: const EdgeInsets.all(20.0),
// // // // //               child: Column(
// // // // //                 children: [
// // // // //                   Text(
// // // // //                     "Current Relative Humidity",
// // // // //                     style: TextStyle(fontSize: 16),
// // // // //                   ),
// // // // //                   Text(
// // // // //                     "$currentHum %",
// // // // //                     style: TextStyle(
// // // // //                       fontSize: 40,
// // // // //                       fontWeight: FontWeight.bold,
// // // // //                       color: Colors.teal,
// // // // //                     ),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 20),

// // // // //           // Set Point Control
// // // // //           Text(
// // // // //             "Humidity Set Point",
// // // // //             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// // // // //             textAlign: TextAlign.center,
// // // // //           ),
// // // // //           _buildSetPointControl(
// // // // //             "Set Humidity (%)",
// // // // //             setHumidity,
// // // // //             30,
// // // // //             80,
// // // // //             1,
// // // // //             _setHumidity,
// // // // //           ),
// // // // //           SizedBox(height: 20),

// // // // //           // Action Buttons
// // // // //           Row(
// // // // //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // // //             children: [
// // // // //               ElevatedButton(
// // // // //                 onPressed: () => _sendCommand("STATUS"),
// // // // //                 child: Text("Refresh Status"),
// // // // //               ),
// // // // //               ElevatedButton(
// // // // //                 onPressed: _sendCompleteStructure,
// // // // //                 child: Text("Send All Data"),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //           SizedBox(height: 20),

// // // // //           Text(
// // // // //             "Set points are sent upon change.",
// // // // //             textAlign: TextAlign.center,
// // // // //             style: TextStyle(
// // // // //               fontStyle: FontStyle.italic,
// // // // //               color: Colors.grey[600],
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // -----------------------------------------------------------------------------
// // // // // // --- LIGHT INTENSITY CONTROL SCREEN (Standalone) ---
// // // // // // -----------------------------------------------------------------------------

// // // // // class LightIntensityPage extends StatefulWidget {
// // // // //   @override
// // // // //   _LightIntensityPageState createState() => _LightIntensityPageState();
// // // // // }

// // // // // class _LightIntensityPageState extends State<LightIntensityPage> {
// // // // //   // Light state
// // // // //   List<int> intensities = List.filled(10, 0);
// // // // //   List<bool> lightStates = List.filled(10, false);
// // // // //   bool nightMode = false;

// // // // //   // USB communication
// // // // //   UsbPort? _port;
// // // // //   bool isConnected = false;
// // // // //   String _incomingBuffer = "";

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _initUsb();
// // // // //   }

// // // // //   @override
// // // // //   void dispose() {
// // // // //     _port?.close();
// // // // //     super.dispose();
// // // // //   }

// // // // //   // USB Initialization
// // // // //   Future<void> _initUsb() async {
// // // // //     try {
// // // // //       List<UsbDevice> devices = await UsbSerial.listDevices();
// // // // //       if (devices.isEmpty) {
// // // // //         setState(() {
// // // // //           isConnected = false;
// // // // //         });
// // // // //         return;
// // // // //       }

// // // // //       UsbDevice device = devices.first;
// // // // //       _port = await device.create();
// // // // //       bool open = await _port!.open();

// // // // //       if (open) {
// // // // //         await _port!.setPortParameters(9600, 8, 1, 0);
// // // // //         _port!.inputStream?.listen(_onDataReceived);

// // // // //         setState(() {
// // // // //           isConnected = true;
// // // // //         });

// // // // //         _sendCommand("STATUS");
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("USB Error in LightIntensityPage: $e");
// // // // //       setState(() {
// // // // //         isConnected = false;
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _onDataReceived(Uint8List data) {
// // // // //     String str = String.fromCharCodes(data);
// // // // //     _incomingBuffer += str;

// // // // //     if (_incomingBuffer.contains('\n') ||
// // // // //         (_incomingBuffer.startsWith('{') && _incomingBuffer.contains('}'))) {
// // // // //       List<String> messages = _incomingBuffer.split('\n');

// // // // //       for (int i = 0; i < messages.length - 1; i++) {
// // // // //         String completeMessage = messages[i].trim();
// // // // //         if (completeMessage.isNotEmpty) {
// // // // //           _processCompleteMessage(completeMessage);
// // // // //         }
// // // // //       }

// // // // //       _incomingBuffer = messages.last;
// // // // //     }

// // // // //     if (_incomingBuffer.startsWith('{') && _incomingBuffer.endsWith('}')) {
// // // // //       _processCompleteMessage(_incomingBuffer);
// // // // //       _incomingBuffer = "";
// // // // //     }
// // // // //   }

// // // // //   void _processCompleteMessage(String completeMessage) {
// // // // //     _parseStructuredData(completeMessage);
// // // // //   }

// // // // //   void _parseStructuredData(String data) {
// // // // //     try {
// // // // //       if (data.startsWith('{') && data.endsWith('}')) {
// // // // //         String content = data.substring(1, data.length - 1);
// // // // //         List<String> pairs = content.split(',');

// // // // //         Map<String, dynamic> parsedData = {};

// // // // //         for (String pair in pairs) {
// // // // //           List<String> keyValue = pair.split(':');
// // // // //           if (keyValue.length == 2) {
// // // // //             String key = keyValue[0].trim();
// // // // //             String value = keyValue[1].trim();
// // // // //             parsedData[key] = value;
// // // // //           }
// // // // //         }

// // // // //         setState(() {
// // // // //           // Parse light ON/OFF states and intensities
// // // // //           bool anyLightOn = false;
// // // // //           for (int i = 1; i <= 10; i++) {
// // // // //             String lightOnOffKey = 'S_Light_${i}_ON_OFF';
// // // // //             if (parsedData.containsKey(lightOnOffKey)) {
// // // // //               bool state = parsedData[lightOnOffKey] == '1';
// // // // //               lightStates[i - 1] = state;
// // // // //               if (state) anyLightOn = true;
// // // // //             }

// // // // //             String intensityKey = 'S_Light_${i}_Intensity';
// // // // //             if (parsedData.containsKey(intensityKey)) {
// // // // //               try {
// // // // //                 intensities[i - 1] = int.parse(
// // // // //                   parsedData[intensityKey].toString(),
// // // // //                 );
// // // // //               } catch (e) {
// // // // //                 print(
// // // // //                   "Error parsing intensity for light $i: ${parsedData[intensityKey]}",
// // // // //                 );
// // // // //               }
// // // // //             }
// // // // //           }

// // // // //           nightMode = !anyLightOn;
// // // // //         });
// // // // //       }
// // // // //     } catch (e) {
// // // // //       print("Error parsing light data: $e");
// // // // //     }
// // // // //   }

// // // // //   void _sendCommand(String cmd) {
// // // // //     if (_port != null && isConnected) {
// // // // //       String commandToSend = cmd + "\n";
// // // // //       _port!.write(Uint8List.fromList(commandToSend.codeUnits));
// // // // //       print("Light Page Sent: $commandToSend");
// // // // //     }
// // // // //   }

// // // // //   void _sendCompleteStructure() {
// // // // //     List<String> pairs = [];

// // // // //     pairs.add('SR_WSL:200001');
// // // // //     pairs.add('C_PRESSURE_1:000');
// // // // //     pairs.add('C_PRESSURE_1_SIGN_BIT:1');
// // // // //     pairs.add('C_PRESSURE_2:000');
// // // // //     pairs.add('C_PRESSURE_2_SIGN_BIT:1');

// // // // //     pairs.add('C_OT_TEMP:250'); // Default temperature
// // // // //     pairs.add('C_RH:500'); // Default humidity

// // // // //     for (int i = 1; i <= 10; i++) {
// // // // //       pairs.add('F_Sensor_${i}_FAULT_BIT:0');
// // // // //       pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
// // // // //       pairs.add('S_Light_${i}_ON_OFF:${lightStates[i - 1] ? '1' : '0'}');
// // // // //       pairs.add(
// // // // //         'S_Light_${i}_Intensity:${intensities[i - 1].toString().padLeft(3, '0')}',
// // // // //       );
// // // // //     }

// // // // //     pairs.add('S_IOT_TIMER:0060');
// // // // //     pairs.add('S_TEMP_SETPT:250'); // Default temperature setpoint
// // // // //     pairs.add('S_RH_SETPT:500'); // Default humidity setpoint

// // // // //     String command = '{${pairs.join(',')}}';
// // // // //     _sendCommand(command);
// // // // //   }

// // // // //   void _handleLightChange(int lightIndex, bool? turnOn, int? intensity) {
// // // // //     setState(() {
// // // // //       if (turnOn != null) {
// // // // //         lightStates[lightIndex] = turnOn;
// // // // //         if (!turnOn) intensities[lightIndex] = 0;
// // // // //       }
// // // // //       if (intensity != null) {
// // // // //         intensities[lightIndex] = intensity;
// // // // //         if (intensity > 0) lightStates[lightIndex] = true;
// // // // //       }
// // // // //     });
// // // // //     _sendCompleteStructure();
// // // // //   }

// // // // //   void _toggleNightMode() {
// // // // //     setState(() {
// // // // //       nightMode = !nightMode;
// // // // //       if (nightMode) {
// // // // //         for (int i = 0; i < 10; i++) {
// // // // //           lightStates[i] = false;
// // // // //           intensities[i] = 0;
// // // // //         }
// // // // //       }
// // // // //     });
// // // // //     _sendCompleteStructure();
// // // // //   }

// // // // //   Widget _buildLightControl(int index) {
// // // // //     return Card(
// // // // //       margin: EdgeInsets.symmetric(vertical: 4.0),
// // // // //       child: ListTile(
// // // // //         leading: Icon(
// // // // //           Icons.lightbulb,
// // // // //           color: lightStates[index] ? Colors.amber : Colors.grey,
// // // // //         ),
// // // // //         title: Text("Light ${index + 1}"),
// // // // //         subtitle: Slider(
// // // // //           value: intensities[index].toDouble(),
// // // // //           min: 0,
// // // // //           max: 100,
// // // // //           divisions: 100,
// // // // //           label: "${intensities[index]}%",
// // // // //           onChanged: (val) {
// // // // //             _handleLightChange(index, null, val.toInt());
// // // // //           },
// // // // //         ),
// // // // //         trailing: Switch(
// // // // //           value: lightStates[index],
// // // // //           onChanged: (val) {
// // // // //             _handleLightChange(index, val, null);
// // // // //           },
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return SingleChildScrollView(
// // // // //       padding: EdgeInsets.all(16.0),
// // // // //       child: Column(
// // // // //         crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //         children: <Widget>[
// // // // //           // Connection Status
// // // // //           Card(
// // // // //             color: isConnected ? Colors.green[50] : Colors.red[50],
// // // // //             child: Padding(
// // // // //               padding: const EdgeInsets.all(12.0),
// // // // //               child: Row(
// // // // //                 children: [
// // // // //                   Icon(
// // // // //                     isConnected ? Icons.usb : Icons.usb_off,
// // // // //                     color: isConnected ? Colors.green : Colors.red,
// // // // //                   ),
// // // // //                   SizedBox(width: 8),
// // // // //                   Text(
// // // // //                     isConnected ? "USB Connected" : "USB Disconnected",
// // // // //                     style: TextStyle(fontWeight: FontWeight.bold),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 16),

// // // // //           // Night Mode
// // // // //           Card(
// // // // //             color: nightMode ? Colors.grey[200] : Colors.yellow[100],
// // // // //             child: ListTile(
// // // // //               title: Text("Night Mode"),
// // // // //               subtitle: Text(
// // // // //                 nightMode ? "All lights are OFF" : "Lights are ON",
// // // // //               ),
// // // // //               trailing: Switch(
// // // // //                 value: nightMode,
// // // // //                 onChanged: (v) => _toggleNightMode(),
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           Divider(height: 20, thickness: 2),

// // // // //           // Action Buttons
// // // // //           Row(
// // // // //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // // // //             children: [
// // // // //               ElevatedButton(
// // // // //                 onPressed: () => _sendCommand("STATUS"),
// // // // //                 child: Text("Refresh Status"),
// // // // //               ),
// // // // //               ElevatedButton(
// // // // //                 onPressed: _sendCompleteStructure,
// // // // //                 child: Text("Send All Data"),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //           SizedBox(height: 20),

// // // // //           Text(
// // // // //             "Individual Light Controls (10)",
// // // // //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // // //             textAlign: TextAlign.center,
// // // // //           ),
// // // // //           SizedBox(height: 10),
// // // // //           ...List.generate(10, (index) => _buildLightControl(index)),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // -----------------------------------------------------------------------------
// // // // // // --- COMMUNICATION SCREEN ---
// // // // // // -----------------------------------------------------------------------------

// // // // // class CommunicationPage extends StatelessWidget {
// // // // //   final String usbStatus;
// // // // //   final bool isConnected;
// // // // //   final String lastSentString;
// // // // //   final String lastReceivedString;
// // // // //   final String incomingBuffer;
// // // // //   final TextEditingController commandController;
// // // // //   final Function(String) onSendCommand;
// // // // //   final VoidCallback onSendCustomCommand;
// // // // //   final VoidCallback onReconnectUsb;

// // // // //   CommunicationPage({
// // // // //     required this.usbStatus,
// // // // //     required this.isConnected,
// // // // //     required this.lastSentString,
// // // // //     required this.lastReceivedString,
// // // // //     required this.incomingBuffer,
// // // // //     required this.commandController,
// // // // //     required this.onSendCommand,
// // // // //     required this.onSendCustomCommand,
// // // // //     required this.onReconnectUsb,
// // // // //   });

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return SingleChildScrollView(
// // // // //       padding: EdgeInsets.all(16.0),
// // // // //       child: Column(
// // // // //         crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //         children: <Widget>[
// // // // //           // USB Status
// // // // //           Card(
// // // // //             color: isConnected ? Colors.green[50] : Colors.red[50],
// // // // //             child: Padding(
// // // // //               padding: EdgeInsets.all(16.0),
// // // // //               child: Row(
// // // // //                 children: [
// // // // //                   Icon(
// // // // //                     isConnected ? Icons.usb : Icons.usb_off,
// // // // //                     color: isConnected ? Colors.green : Colors.red,
// // // // //                   ),
// // // // //                   SizedBox(width: 10),
// // // // //                   Expanded(child: Text(usbStatus)),
// // // // //                   ElevatedButton(
// // // // //                     onPressed: onReconnectUsb,
// // // // //                     child: Text("Retry"),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 10),
// // // // //           // Last Sent/Received Strings
// // // // //           Card(
// // // // //             child: Padding(
// // // // //               padding: EdgeInsets.all(16.0),
// // // // //               child: Column(
// // // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                 children: [
// // // // //                   Text(
// // // // //                     "Communication Log",
// // // // //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // // //                   ),
// // // // //                   SizedBox(height: 10),
// // // // //                   Text(
// // // // //                     "Last Sent:",
// // // // //                     style: TextStyle(fontWeight: FontWeight.bold),
// // // // //                   ),
// // // // //                   Container(
// // // // //                     width: double.infinity,
// // // // //                     padding: EdgeInsets.all(8),
// // // // //                     color: Colors.grey[100],
// // // // //                     child: Text(
// // // // //                       lastSentString,
// // // // //                       style: TextStyle(fontFamily: 'Monospace', fontSize: 10),
// // // // //                     ),
// // // // //                   ),
// // // // //                   SizedBox(height: 10),
// // // // //                   Text(
// // // // //                     "Last Received:",
// // // // //                     style: TextStyle(fontWeight: FontWeight.bold),
// // // // //                   ),
// // // // //                   Container(
// // // // //                     width: double.infinity,
// // // // //                     padding: EdgeInsets.all(8),
// // // // //                     color: Colors.grey[100],
// // // // //                     child: Text(
// // // // //                       lastReceivedString,
// // // // //                       style: TextStyle(fontFamily: 'Monospace', fontSize: 10),
// // // // //                     ),
// // // // //                   ),
// // // // //                   SizedBox(height: 10),
// // // // //                   Text(
// // // // //                     "Buffer: '$incomingBuffer'",
// // // // //                     style: TextStyle(fontSize: 12, color: Colors.grey),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //           SizedBox(height: 10),
// // // // //           // Command Palette
// // // // //           Card(
// // // // //             child: Padding(
// // // // //               padding: EdgeInsets.all(16.0),
// // // // //               child: Column(
// // // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // // //                 children: [
// // // // //                   Text(
// // // // //                     "Command Palette",
// // // // //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // // // //                   ),
// // // // //                   SizedBox(height: 10),
// // // // //                   Row(
// // // // //                     children: [
// // // // //                       Expanded(
// // // // //                         child: TextField(
// // // // //                           controller: commandController,
// // // // //                           decoration: InputDecoration(
// // // // //                             hintText: "Enter custom command...",
// // // // //                             border: OutlineInputBorder(),
// // // // //                           ),
// // // // //                         ),
// // // // //                       ),
// // // // //                       SizedBox(width: 10),
// // // // //                       ElevatedButton(
// // // // //                         onPressed: onSendCustomCommand,
// // // // //                         child: Text("Send"),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   SizedBox(height: 10),
// // // // //                   Wrap(
// // // // //                     spacing: 8,
// // // // //                     children: [
// // // // //                       ElevatedButton(
// // // // //                         onPressed: () => onSendCommand("STATUS"),
// // // // //                         child: Text("STATUS"),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }
// // // import 'dart:async';
// // // import 'dart:typed_data';
// // // import 'package:analog_clock/analog_clock.dart';
// // // import 'package:connectivity_plus/connectivity_plus.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter/services.dart';
// // // import 'package:get/get.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:provider/provider.dart';
// // // import 'package:stop_watch_timer/stop_watch_timer.dart';
// // // import 'package:surgeon_control_panel/main.dart';
// // // import 'package:surgeon_control_panel/patient%20info/clean/clean_pro.dart';
// // // import 'package:surgeon_control_panel/patient%20info/dashboard/dashboard.dart';
// // // import 'package:surgeon_control_panel/patient%20info/dashboard/store/storeitems.dart';
// // // import 'package:surgeon_control_panel/patient%20info/dashboard_items/patient_list.dart';
// // // import 'package:surgeon_control_panel/provider/stopwatch_provider.dart';
// // // import 'package:surgeon_control_panel/screen/feather/cctv.dart';
// // // import 'package:surgeon_control_panel/screen/feather/clock/clock.dart';
// // // import 'package:surgeon_control_panel/screen/feather/light.dart';
// // // import 'package:surgeon_control_panel/screen/feather/mgps.dart';
// // // import 'package:surgeon_control_panel/screen/feather/music.dart';
// // // import 'package:surgeon_control_panel/screen/feather/phone/phonecall.dart';
// // // import 'package:surgeon_control_panel/screen/feather/rh.dart';
// // // import 'package:surgeon_control_panel/screen/feather/temp.dart';
// // // import 'package:surgeon_control_panel/screen/feather/timer.dart';
// // // import 'package:surgeon_control_panel/screen/profil/profilescreen.dart';
// // // import 'package:url_launcher/url_launcher.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:usb_serial/usb_serial.dart';

// // // class Home extends StatefulWidget {
// // //   const Home({super.key});

// // //   @override
// // //   State<Home> createState() => _HomeState();
// // // }

// // // class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
// // //   final List<String> itemKeys = [
// // //     'temp',
// // //     'rh',
// // //     'lighting',
// // //     'dicom',
// // //     'timer',
// // //     'music',
// // //     'cctv',
// // //     'mgps',
// // //     'pis',
// // //     'store',
// // //     'clean',
// // //     'phone',
// // //   ];

// // //   bool _isSwitched = false;
// // //   String _ipAddress = 'Fetching...';
// // //   bool _isLaunching = false;
// // //   bool _isInPipMode = false;

// // //   // Temperature and Humidity values (strings so we can show "--")
// // //   String _currentTemp = "--";
// // //   String _currentHumidity = "--";

// // //   // USB related variables
// // //   UsbPort? _port;
// // //   bool isConnected = false;
// // //   String usbStatus = "Disconnected";
// // //   String _incomingBuffer = "";

// // //   StreamSubscription<dynamic>? _usbSubscription;

// // //   static const platform = MethodChannel('app_launcher_channel');

// // //   // SharedPreferences instance
// // //   SharedPreferences? _prefs;

// // //   // Timer for periodic updates
// // //   Timer? _updateTimer;

// // //   late TabController _tabController;

// // //   // HEPA Status variables
// // //   bool _isHepaHealthy = true;
// // //   String _hepaStatusText = "HEPA Healthy";
// // //   Color _hepaStatusColor = Colors.green;

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     _tabController = TabController(length: 2, vsync: this);

// // //     // Initialize prefs first, then start USB and periodic updates
// // //     _initSharedPreferences().then((_) {
// // //       // Load values as soon as prefs ready
// // //       _loadSavedValues();

// // //       // Start periodic refresh read from prefs (keeps UI synced if other screens update prefs)
// // //       _startPeriodicUpdates();

// // //       // Init USB after prefs ready
// // //       _initUsb();
// // //     });

// // //     // Fetch IP (doesn't need prefs)
// // //     fetchIpAddress().then((ip) {
// // //       setState(() => _ipAddress = ip);
// // //     });

// // //     // Add debug build listener
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       _refreshFaultStatus();
// // //       _refreshHepaStatus();
// // //     });
// // //   }

// // //   Future<void> _initSharedPreferences() async {
// // //     _prefs = await SharedPreferences.getInstance();
// // //     // Initialize sensor fault bits to '0' (no fault) if not set - ONLY 7 SENSORS
// // //     for (int i = 1; i <= 7; i++) {
// // //       String key = 'F_Sensor_${i}_FAULT_BIT';
// // //       if (!_prefs!.containsKey(key)) {
// // //         await _prefs!.setString(key, '0');
// // //         debugPrint("Initialized $key to '0' (NO FAULT)");
// // //       }
// // //     }
// // //     // Initialize HEPA sensor fault bit to '0' (healthy) if not set
// // //     if (!_prefs!.containsKey('F_Sensor_10_FAULT_BIT')) {
// // //       await _prefs!.setString('F_Sensor_10_FAULT_BIT', '0');
// // //       debugPrint("Initialized F_Sensor_10_FAULT_BIT to '0' (HEPA Healthy)");
// // //     }
// // //   }

// // //   void _loadSavedValues() {
// // //     if (_prefs == null) return;

// // //     setState(() {
// // //       _currentTemp = _prefs!.getString('current_temperature') ?? "--";
// // //       _currentHumidity = _prefs!.getString('current_humidity') ?? "--";
// // //       _isSwitched = _prefs!.getBool('system_status') ?? false;
// // //     });

// // //     debugPrint(
// // //       "Loaded saved values - Temp: $_currentTemp, Humidity: $_currentHumidity, System Status: $_isSwitched",
// // //     );
// // //   }

// // //   void _saveCurrentTemperature(String value) {
// // //     if (_prefs == null) return;
// // //     _prefs!.setString('current_temperature', value);
// // //     debugPrint("Saved current temperature: $value");

// // //     // Immediately update the UI after saving
// // //     if (mounted) {
// // //       setState(() {
// // //         _currentTemp = value;
// // //       });
// // //     }
// // //   }

// // //   void _saveCurrentHumidity(String value) {
// // //     if (_prefs == null) return;
// // //     _prefs!.setString('current_humidity', value);
// // //     debugPrint("Saved current humidity: $value");

// // //     // Immediately update the UI after saving
// // //     if (mounted) {
// // //       setState(() {
// // //         _currentHumidity = value;
// // //       });
// // //     }
// // //   }

// // //   void _saveSystemStatus(bool value) {
// // //     if (_prefs == null) return;
// // //     _prefs!.setBool('system_status', value);
// // //     debugPrint("Saved system status: $value");

// // //     // Immediately update the UI after saving
// // //     if (mounted) {
// // //       setState(() {
// // //         _isSwitched = value;
// // //       });
// // //     }
// // //   }

// // //   void _startPeriodicUpdates() {
// // //     _updateTimer?.cancel();
// // //     _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
// // //       _loadSavedValues();
// // //       _refreshHepaStatus();
// // //     });
// // //   }

// // //   void _toggleMute() {
// // //     // final audioProvider = Provider.of<AudioProvider>(context, listen: false);
// // //     audioProvider.toggleMute();
// // //     _showSuccessSnackbar(
// // //       audioProvider.isMuted ? "Audio muted" : "Audio unmuted",
// // //     );
// // //   }

// // //   // USB Initialization
// // //   Future<void> _initUsb() async {
// // //     try {
// // //       setState(() {
// // //         usbStatus = "Scanning for USB devices...";
// // //       });

// // //       List<UsbDevice> devices = await UsbSerial.listDevices();
// // //       debugPrint("Found ${devices.length} USB devices");

// // //       if (devices.isEmpty) {
// // //         setState(() {
// // //           usbStatus = "No USB devices found";
// // //           isConnected = false;
// // //         });
// // //         return;
// // //       }

// // //       UsbDevice device = devices.first;
// // //       debugPrint("Connecting to: ${device.deviceName}");

// // //       setState(() {
// // //         usbStatus = "Connecting to ${device.deviceName}...";
// // //       });

// // //       _port = await device.create();
// // //       bool open = await _port!.open();

// // //       if (open) {
// // //         await _port!.setDTR(true);
// // //         await _port!.setRTS(true);
// // //         await _port!.setPortParameters(9600, 8, 1, 0);

// // //         setState(() {
// // //           usbStatus = "Connected to ${device.deviceName}";
// // //           isConnected = true;
// // //         });

// // //         debugPrint("USB connected successfully");

// // //         // Cancel previous subscription if any
// // //         await _usbSubscription?.cancel();

// // //         // inputStream emits Uint8List chunks; some implementations may emit String
// // //         _usbSubscription = _port!.inputStream?.listen(
// // //           (data) {
// // //             _onDataReceived(data);
// // //           },
// // //           onError: (e) {
// // //             debugPrint("USB input stream error: $e");
// // //           },
// // //           onDone: () {
// // //             debugPrint("USB input stream done");
// // //             setState(() {
// // //               isConnected = false;
// // //               usbStatus = "Disconnected";
// // //             });
// // //           },
// // //         );
// // //       } else {
// // //         setState(() {
// // //           usbStatus = "Failed to open USB port";
// // //           isConnected = false;
// // //         });
// // //       }
// // //     } catch (e) {
// // //       debugPrint("USB Error: $e");
// // //       setState(() {
// // //         usbStatus = "Error: $e";
// // //         isConnected = false;
// // //       });
// // //     }
// // //   }

// // //   // Accepts either Uint8List or String (some platforms) or anything that can be converted
// // //   void _onDataReceived(dynamic chunk) {
// // //     try {
// // //       String str;
// // //       if (chunk is Uint8List) {
// // //         str = String.fromCharCodes(chunk);
// // //       } else if (chunk is String) {
// // //         str = chunk;
// // //       } else if (chunk is List<int>) {
// // //         str = String.fromCharCodes(chunk);
// // //       } else {
// // //         // Unexpected type: try toString
// // //         str = chunk.toString();
// // //       }

// // //       // Enhanced raw data logging
// // //       debugPrint(
// // //         "📨 RAW USB DATA: ${str.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}",
// // //       );

// // //       // Append and attempt to parse messages separated by newline or full {...} JSON-like blocks
// // //       _incomingBuffer += str;

// // //       // If multiple newline separated messages, split and process each complete line
// // //       if (_incomingBuffer.contains('\n')) {
// // //         List<String> lines = _incomingBuffer.split('\n');
// // //         for (int i = 0; i < lines.length - 1; i++) {
// // //           String line = lines[i].trim();
// // //           if (line.isNotEmpty) _processCompleteMessage(line);
// // //         }
// // //         _incomingBuffer = lines.last;
// // //       }

// // //       // If incomingBuffer contains a complete {...} block, extract and process
// // //       // There might be multiple braces; process greedily
// // //       while (_incomingBuffer.contains('{') && _incomingBuffer.contains('}')) {
// // //         int start = _incomingBuffer.indexOf('{');
// // //         int end = _incomingBuffer.indexOf('}', start);
// // //         if (end == -1) break;
// // //         String block = _incomingBuffer.substring(start, end + 1);
// // //         _processCompleteMessage(block);
// // //         // Remove processed block
// // //         _incomingBuffer = _incomingBuffer.substring(end + 1);
// // //       }

// // //       // If buffer itself is a clean block like "{...}" without trailing newline
// // //       if (_incomingBuffer.trim().startsWith('{') &&
// // //           _incomingBuffer.trim().endsWith('}')) {
// // //         _processCompleteMessage(_incomingBuffer.trim());
// // //         _incomingBuffer = "";
// // //       }
// // //     } catch (e) {
// // //       debugPrint("Error in _onDataReceived: $e");
// // //     }
// // //   }

// // //   void _processCompleteMessage(String completeMessage) {
// // //     debugPrint("Processing complete message: $completeMessage");
// // //     _parseStructuredData(completeMessage);
// // //   }

// // //   // Enhanced debugging method
// // //   void _debugSensorFaults() {
// // //     if (_prefs == null) {
// // //       debugPrint("❌ Prefs not initialized");
// // //       return;
// // //     }

// // //     debugPrint("=== COMPREHENSIVE SENSOR FAULT DEBUG ===");
// // //     debugPrint("LOGIC: '0' = FULL (NO FAULT), '1' = EMPTY (FAULT)");
// // //     bool anyFault = false;

// // //     for (int i = 1; i <= 7; i++) {
// // //       String? fault = _prefs!.getString('F_Sensor_${i}_FAULT_BIT');
// // //       String status = fault == '1' ? "❌ FAULT (EMPTY)" : "✅ OK (FULL)";
// // //       debugPrint("Sensor $i: $status (value: $fault)");

// // //       if (fault == '1') {
// // //         anyFault = true;
// // //         debugPrint("🚨🚨🚨 FAULT FOUND IN SENSOR $i 🚨🚨🚨");
// // //       }
// // //     }

// // //     debugPrint("=== SUMMARY: ${anyFault ? 'RED BORDER' : 'WHITE BORDER'} ===");
// // //   }

// // //   // Updated parser to match the working light intensity code pattern
// // //   void _parseStructuredData(String data) {
// // //     try {
// // //       if (data.startsWith('{') && data.endsWith('}')) {
// // //         String content = data.substring(1, data.length - 1);
// // //         List<String> pairs = content.split(',');
// // //         Map<String, dynamic> parsedData = {};

// // //         for (String pair in pairs) {
// // //           List<String> keyValue = pair.split(':');
// // //           if (keyValue.length == 2) {
// // //             String key = keyValue[0].trim();
// // //             String value = keyValue[1].trim();
// // //             parsedData[key] = value;
// // //             // Save sensor fault bits to SharedPreferences - FOR SENSORS 1-7 AND HEPA (10)
// // //             if (key.startsWith('F_Sensor_') && key.endsWith('_FAULT_BIT')) {
// // //               // Extract sensor number from key (e.g., "F_Sensor_3_FAULT_BIT" -> 3)
// // //               String sensorNumStr = key
// // //                   .replaceAll('F_Sensor_', '')
// // //                   .replaceAll('_FAULT_BIT', '');
// // //               int? sensorNum = int.tryParse(sensorNumStr);
// // //               // Only save if it's one of the first 7 sensors OR HEPA sensor (10)
// // //               if (sensorNum != null &&
// // //                   (sensorNum >= 1 && sensorNum <= 7 || sensorNum == 10)) {
// // //                 String oldValue = _prefs?.getString(key) ?? 'not set';
// // //                 _prefs?.setString(key, value);
// // //                 debugPrint("🔄 Updated $key: $oldValue → $value");

// // //                 // If it's HEPA sensor, update HEPA status
// // //                 if (sensorNum == 10) {
// // //                   _updateHepaStatus(value);
// // //                 }
// // //               } else {
// // //                 debugPrint(
// // //                   "⏩ Ignoring $key: $value (sensor $sensorNum not in range 1-7 or 10)",
// // //                 );
// // //               }
// // //             }
// // //           }
// // //         }

// // //         debugPrint("Parsed data: $parsedData");

// // //         // Parse current temperature (C_OT_TEMP:239 -> 23.9°C)
// // //         if (parsedData.containsKey('C_OT_TEMP')) {
// // //           String tempStr = parsedData['C_OT_TEMP']!;
// // //           String newTemp = _formatNumericWithOneDecimal(tempStr);
// // //           _saveCurrentTemperature(newTemp);
// // //           debugPrint("Parsed and saved temperature: $newTemp°C");
// // //         } else {
// // //           debugPrint("C_OT_TEMP key not found in parsed data");
// // //         }

// // //         // Parse current humidity (C_RH:295 -> 29.5%)
// // //         if (parsedData.containsKey('C_RH')) {
// // //           String humStr = parsedData['C_RH']!;
// // //           String newHum = _formatNumericWithOneDecimal(humStr);
// // //           _saveCurrentHumidity(newHum);
// // //           debugPrint("Parsed and saved humidity: $newHum%");
// // //         } else {
// // //           debugPrint("C_RH key not found in parsed data");
// // //         }

// // //         // Parse system status from S_Light_10_ON_OFF (1 = ON, 0 = OFF)
// // //         if (parsedData.containsKey('S_Light_10_ON_OFF')) {
// // //           String systemStatusStr = parsedData['S_Light_10_ON_OFF']!;
// // //           bool systemStatus = systemStatusStr == '1';
// // //           _saveSystemStatus(systemStatus);
// // //           debugPrint("Parsed and saved system status: $systemStatus");
// // //         } else {
// // //           debugPrint("S_Light_10_ON_OFF key not found in parsed data");
// // //         }

// // //         // Force UI update after parsing new sensor data including fault bits
// // //         _updateFaultStatus();
// // //         _refreshHepaStatus();
// // //       } else {
// // //         debugPrint("Data doesn't have proper structure: $data");
// // //       }
// // //     } catch (e) {
// // //       debugPrint("Error parsing structured data: $e");
// // //       debugPrint("Data that caused error: $data");
// // //     }
// // //   }

// // //   // Update HEPA status based on F_Sensor_10_FAULT_BIT value
// // //   void _updateHepaStatus(String faultBit) {
// // //     bool isHealthy = faultBit == '0';
// // //     setState(() {
// // //       _isHepaHealthy = isHealthy;
// // //       _hepaStatusText = isHealthy ? "HEPA Healthy" : "HEPA Unhealthy";
// // //       _hepaStatusColor = isHealthy ? Colors.green : Colors.red;
// // //     });
// // //     debugPrint(
// // //       "HEPA Status Updated: $_hepaStatusText (F_Sensor_10_FAULT_BIT: $faultBit)",
// // //     );
// // //   }

// // //   // Refresh HEPA status from SharedPreferences
// // //   void _refreshHepaStatus() {
// // //     if (_prefs == null) return;

// // //     String? hepaFaultBit = _prefs!.getString('F_Sensor_10_FAULT_BIT');
// // //     if (hepaFaultBit != null) {
// // //       _updateHepaStatus(hepaFaultBit);
// // //     }
// // //   }

// // //   // Helper: convert "239" -> "23.9", "035" -> "3.5", "100" -> "10.0"
// // //   String _formatNumericWithOneDecimal(String s) {
// // //     // Ensure s has at least 2 chars
// // //     if (s.length == 1) {
// // //       return "0.${s}";
// // //     } else {
// // //       String whole = s.substring(0, s.length - 1);
// // //       String dec = s.substring(s.length - 1);
// // //       // Remove leading zeros from whole if any, but keep "0" if that is all
// // //       int wholeInt = int.tryParse(whole) ?? 0;
// // //       return "$wholeInt.$dec";
// // //     }
// // //   }

// // //   // Check if any sensor fault bit is explicitly '1' - ONLY FOR SENSORS 1-7
// // //   // LOGIC: '0' = FULL (NO FAULT), '1' = EMPTY (FAULT) - Matches GasStatusPage
// // //   bool _hasSensorFault() {
// // //     if (_prefs == null) {
// // //       debugPrint("Prefs not initialized, no fault assumed");
// // //       return false;
// // //     }

// // //     // Call comprehensive debug
// // //     _debugSensorFaults();

// // //     bool hasFault = false;
// // //     // Only check sensors 1 through 7
// // //     for (int i = 1; i <= 7; i++) {
// // //       String? fault = _prefs!.getString('F_Sensor_${i}_FAULT_BIT');

// // //       // CORRECTED LOGIC: '1' means FAULT (EMPTY), '0' means NO FAULT (FULL)
// // //       if (fault == '1') {
// // //         debugPrint(
// // //           "*** FAULT DETECTED at sensor $i - RED BORDER SHOULD SHOW ***",
// // //         );
// // //         hasFault = true;
// // //         // Don't break here - we want to log all faults
// // //       }
// // //     }

// // //     debugPrint(
// // //       "Sensor fault summary (Sensors 1-7): $hasFault - Border should be ${hasFault ? 'RED' : 'WHITE'}",
// // //     );
// // //     return hasFault;
// // //   }

// // //   // Add this method to manually reset all sensors to '0' (no fault)
// // //   void _resetAllSensorsToNoFault() {
// // //     if (_prefs == null) return;

// // //     debugPrint("=== MANUALLY RESETTING ALL SENSORS TO '0' (NO FAULT) ===");
// // //     for (int i = 1; i <= 7; i++) {
// // //       _prefs!.setString('F_Sensor_${i}_FAULT_BIT', '0');
// // //       debugPrint("Reset Sensor $i to '0' (NO FAULT)");
// // //     }

// // //     // Force UI update
// // //     _updateFaultStatus();
// // //     _showSuccessSnackbar("All sensors reset to no fault");
// // //   }

// // //   void _updateFaultStatus() {
// // //     debugPrint("=== UPDATING FAULT STATUS (Sensors 1-7) ===");
// // //     bool currentFaultStatus = _hasSensorFault();
// // //     debugPrint("Current fault status after update: $currentFaultStatus");

// // //     if (mounted) {
// // //       setState(() {
// // //         // This will trigger rebuild and re-check _hasSensorFault()
// // //       });
// // //     }
// // //   }

// // //   void _refreshFaultStatus() {
// // //     debugPrint("=== MANUAL FAULT STATUS REFRESH (Sensors 1-7) ===");
// // //     for (int i = 1; i <= 7; i++) {
// // //       String? fault = _prefs?.getString('F_Sensor_${i}_FAULT_BIT');
// // //       debugPrint("Sensor $i fault bit: $fault");
// // //     }

// // //     bool currentFaultStatus = _hasSensorFault();
// // //     debugPrint("Current fault status: $currentFaultStatus");

// // //     if (mounted) {
// // //       setState(() {});
// // //     }
// // //   }

// // //   void _reconnectUsb() {
// // //     _initUsb();
// // //   }

// // //   // Send system status command to USB
// // //   void _sendSystemStatusCommand(bool isOn) {
// // //     if (_port != null && isConnected) {
// // //       // Create complete command structure like in light intensity page
// // //       List<String> pairs = [];
// // //       pairs.add('SR_WSL:200001');
// // //       pairs.add('C_PRESSURE_1:000');
// // //       pairs.add('C_PRESSURE_1_SIGN_BIT:1');
// // //       pairs.add('C_PRESSURE_2:000');
// // //       pairs.add('C_PRESSURE_2_SIGN_BIT:1');
// // //       pairs.add('C_OT_TEMP:250');
// // //       pairs.add('C_RH:500');

// // //       // Add all light parameters (maintaining existing states)
// // //       for (int i = 1; i <= 10; i++) {
// // //         // For fault bits, only include sensors 1-7, others default to '0'
// // //         String? fault;
// // //         if (i <= 7) {
// // //           fault = _prefs?.getString('F_Sensor_${i}_FAULT_BIT') ?? '0';
// // //         } else {
// // //           fault = '0'; // Default to no fault for sensors 8-10
// // //         }
// // //         pairs.add('F_Sensor_${i}_FAULT_BIT:$fault');
// // //         pairs.add('S_Sensor_${i}_NO_NC_SETTING:1');
// // //         // Set Light 10 to the desired state, others maintain current (or default to 0)
// // //         if (i == 10) {
// // //           pairs.add('S_Light_${i}_ON_OFF:${isOn ? '1' : '0'}');
// // //         } else {
// // //           pairs.add('S_Light_${i}_ON_OFF:0'); // Default other lights to off
// // //         }
// // //         pairs.add(
// // //           'S_Light_${i}_Intensity:${i == 10 ? (isOn ? '100' : '000') : '000'}',
// // //         );
// // //       }

// // //       pairs.add('S_IOT_TIMER:0060');
// // //       pairs.add('S_TEMP_SETPT:250');
// // //       pairs.add('S_RH_SETPT:500');

// // //       String command = '{${pairs.join(',')}}';
// // //       _port!.write(Uint8List.fromList((command + "\n").codeUnits));

// // //       debugPrint("Sent system status command: $command");
// // //       _showSuccessSnackbar("System turned ${isOn ? 'ON' : 'OFF'}");
// // //     } else {
// // //       _showErrorSnackbar("USB is not connected");
// // //     }
// // //   }

// // //   void _requestStatus() {
// // //     if (_port != null && isConnected) {
// // //       String command = "STATUS\n";
// // //       _port!.write(Uint8List.fromList(command.codeUnits));
// // //       debugPrint("Sent STATUS request");

// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(
// // //           content: Text("Status request sent"),
// // //           backgroundColor: Colors.blue,
// // //         ),
// // //       );
// // //     } else {
// // //       _showErrorSnackbar("USB is not connected");
// // //     }
// // //   }

// // //   Future<void> _launchDroidRenderAndEnterPip() async {
// // //     setState(() {
// // //       _isLaunching = true;
// // //     });

// // //     try {
// // //       final bool success = await platform.invokeMethod(
// // //         'launchAppAndEnterPip',
// // //         'com.luolai.droidrender',
// // //       );

// // //       if (success) {
// // //         setState(() {
// // //           _isInPipMode = true;
// // //         });
// // //       } else {
// // //         _showErrorSnackbar(
// // //           'Failed to open DroidRender. App may not be installed.',
// // //         );
// // //       }
// // //     } on PlatformException catch (e) {
// // //       _showErrorSnackbar('Error: ${e.message}');
// // //     } finally {
// // //       setState(() {
// // //         _isLaunching = false;
// // //       });
// // //     }
// // //   }

// // //   void _showErrorSnackbar(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(message),
// // //         backgroundColor: Colors.red,
// // //         duration: const Duration(seconds: 3),
// // //       ),
// // //     );
// // //   }

// // //   void _showSuccessSnackbar(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(message),
// // //         backgroundColor: Colors.green,
// // //         duration: const Duration(seconds: 2),
// // //       ),
// // //     );
// // //   }

// // //   Future<String> fetchIpAddress() async {
// // //     try {
// // //       final response = await http.get(Uri.parse('https://api.ipify.org'));
// // //       if (response.statusCode == 200) {
// // //         return response.body;
// // //       } else {
// // //         return 'Failed to fetch IP'.tr;
// // //       }
// // //     } catch (e) {
// // //       return 'Error: $e'.tr;
// // //     }
// // //   }

// // //   Future<void> handleTap(int itemNumber) async {
// // //     switch (itemNumber) {
// // //       case 1:
// // //         Get.to(
// // //           () => TempGaugeScreen(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 2:
// // //         Get.to(
// // //           () => HumidityGaugeScreen(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 3:
// // //         Get.to(
// // //           () => LightIntensityPage(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 4:
// // //         Future.delayed(Duration.zero, () {
// // //           if (!_isLaunching) {
// // //             _launchDroidRenderAndEnterPip();
// // //           }
// // //         });
// // //         break;
// // //       case 5:
// // //         Get.to(
// // //           () => StylishStopwatchPage(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 6:
// // //         Get.to(
// // //           () => MusicPlayerScreen(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 7:
// // //         List<ConnectivityResult> results = await Connectivity()
// // //             .checkConnectivity();
// // //         if (results.contains(ConnectivityResult.none)) {
// // //           Get.snackbar(
// // //             "no_internet".tr,
// // //             "check_connection".tr,
// // //             snackPosition: SnackPosition.BOTTOM,
// // //             backgroundColor: Colors.red,
// // //             colorText: Colors.white,
// // //             margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
// // //             maxWidth: 400,
// // //             borderRadius: 10,
// // //             snackStyle: SnackStyle.FLOATING,
// // //             mainButton: TextButton(
// // //               onPressed: () => Get.back(),
// // //               child: Text(
// // //                 "close".tr,
// // //                 style: const TextStyle(
// // //                   color: Colors.white,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //             ),
// // //           );
// // //         } else {
// // //           Get.to(
// // //             () => VideoSwitcherScreen(),
// // //             transition: Transition.fadeIn,
// // //             duration: const Duration(milliseconds: 500),
// // //           );
// // //         }
// // //         break;
// // //       case 8:
// // //         Get.to(
// // //           () => GasStatusPage(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 9:
// // //         Get.to(
// // //           () => DashboardScreen(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 10:
// // //         Get.to(
// // //           () => HospitalStoreScreen(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 11:
// // //         Get.to(
// // //           () => HospitalCleaningApp(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //       case 12:
// // //         Get.to(
// // //           () => PatientDashboard(),
// // //           transition: Transition.rightToLeft,
// // //           duration: const Duration(milliseconds: 400),
// // //         );
// // //         break;
// // //     }
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _usbSubscription?.cancel();
// // //     _port?.close();
// // //     _tabController.dispose();
// // //     _updateTimer?.cancel();
// // //     super.dispose();
// // //   }

// // //   Widget buildScoreContainer(
// // //     BuildContext context,
// // //     String label,
// // //     IconData icon,
// // //     bool showTimer, {
// // //     String? currentValue,
// // //     required int itemNumber,
// // //   }) {
// // //     final stopwatchProvider = Provider.of<StopwatchProvider>(context);
// // //     bool isMgpsWithFault = itemNumber == 8 && _hasSensorFault();
// // //     debugPrint(
// // //       "Building container for item $itemNumber - MGPS fault: $isMgpsWithFault",
// // //     );

// // //     return Container(
// // //       margin: const EdgeInsets.all(0),
// // //       height: MediaQuery.of(context).size.height * 0.22,
// // //       width: MediaQuery.of(context).size.width * 0.22,
// // //       decoration: BoxDecoration(
// // //         color: Colors.white.withOpacity(0),
// // //         borderRadius: BorderRadius.circular(20),
// // //         border: Border.all(
// // //           color: isMgpsWithFault ? Colors.red : Colors.white.withOpacity(1.0),
// // //           width: 3.0,
// // //         ),
// // //       ),
// // //       child: Column(
// // //         mainAxisAlignment: MainAxisAlignment.center,
// // //         children: [
// // //           Icon(icon, color: Colors.white, size: 35),
// // //           const SizedBox(height: 6),
// // //           Text(
// // //             label,
// // //             textAlign: TextAlign.center,
// // //             style: const TextStyle(
// // //               color: Colors.white,
// // //               fontSize: 26,
// // //               fontWeight: FontWeight.w600,
// // //             ),
// // //           ),
// // //           if (currentValue != null)
// // //             Padding(
// // //               padding: const EdgeInsets.only(top: 4),
// // //               child: Text(
// // //                 currentValue,
// // //                 style: const TextStyle(
// // //                   color: Colors.white,
// // //                   fontSize: 24,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //             ),
// // //           if (showTimer && stopwatchProvider.isRunning)
// // //             StreamBuilder<int>(
// // //               stream: stopwatchProvider.stopWatchTimer.rawTime,
// // //               initialData: stopwatchProvider.stopWatchTimer.rawTime.value,
// // //               builder: (context, snapshot) {
// // //                 final displayTime = StopWatchTimer.getDisplayTime(
// // //                   snapshot.data!,
// // //                   milliSecond: false,
// // //                 );
// // //                 return Text(
// // //                   displayTime,
// // //                   style: const TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 14,
// // //                     fontWeight: FontWeight.bold,
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildMainTab() {
// // //     return SingleChildScrollView(
// // //       child: Column(
// // //         children: [
// // //           Row(
// // //             mainAxisAlignment: MainAxisAlignment.end,
// // //             children: [
// // //               Container(
// // //                 padding: const EdgeInsets.symmetric(
// // //                   horizontal: 16,
// // //                   vertical: 8,
// // //                 ),
// // //                 decoration: BoxDecoration(
// // //                   color: _hepaStatusColor.withOpacity(0.2),
// // //                   borderRadius: BorderRadius.circular(20),
// // //                   border: Border.all(color: _hepaStatusColor, width: 2),
// // //                 ),
// // //                 child: Row(
// // //                   mainAxisSize: MainAxisSize.min,
// // //                   children: [
// // //                     Icon(
// // //                       _isHepaHealthy ? Icons.air : Icons.warning,
// // //                       color: _hepaStatusColor,
// // //                       size: 20,
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     Text(
// // //                       _hepaStatusText,
// // //                       style: TextStyle(
// // //                         color: _hepaStatusColor,
// // //                         fontSize: 16,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               const SizedBox(width: 12),
// // //               Container(
// // //                 padding: const EdgeInsets.symmetric(
// // //                   horizontal: 12,
// // //                   vertical: 6,
// // //                 ),
// // //                 decoration: BoxDecoration(
// // //                   color: isConnected ? Colors.green : Colors.red,
// // //                   borderRadius: BorderRadius.circular(12),
// // //                 ),
// // //                 child: Text(
// // //                   isConnected ? "USB Connected" : "USB Disconnected",
// // //                   style: const TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 12,
// // //                     fontWeight: FontWeight.bold,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 8),
// // //           Padding(
// // //             padding: const EdgeInsets.symmetric(horizontal: 180),
// // //             child: Row(
// // //               children: List.generate(7, (index) {
// // //                 if (index.isOdd) {
// // //                   return Container(
// // //                     width: 2,
// // //                     height: 100,
// // //                     color: Colors.white.withOpacity(0.0),
// // //                     margin: const EdgeInsets.symmetric(horizontal: 4),
// // //                   );
// // //                 } else {
// // //                   int itemNumber = (index ~/ 2) + 1;
// // //                   final icon = [
// // //                     Icons.thermostat,
// // //                     Icons.device_thermostat,
// // //                     Icons.lightbulb_outline,
// // //                     Icons.door_front_door,
// // //                   ][itemNumber - 1];

// // //                   return Expanded(
// // //                     child: GestureDetector(
// // //                       onTap: () => handleTap(itemNumber),
// // //                       child: buildScoreContainer(
// // //                         context,
// // //                         itemKeys[itemNumber - 1].tr,
// // //                         icon,
// // //                         itemNumber == 5,
// // //                         currentValue: itemNumber == 1
// // //                             ? (_currentTemp == "--" ? "--" : '$_currentTemp°C')
// // //                             : itemNumber == 2
// // //                             ? (_currentHumidity == "--"
// // //                                   ? "--"
// // //                                   : '$_currentHumidity%')
// // //                             : null,
// // //                         itemNumber: itemNumber,
// // //                       ),
// // //                     ),
// // //                   );
// // //                 }
// // //               }),
// // //             ),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           Container(
// // //             height: 2,
// // //             width: double.infinity,
// // //             color: Colors.white.withOpacity(0.0),
// // //             margin: const EdgeInsets.symmetric(vertical: 8),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           Padding(
// // //             padding: const EdgeInsets.symmetric(horizontal: 180),
// // //             child: Row(
// // //               children: List.generate(7, (index) {
// // //                 if (index.isOdd) {
// // //                   return Container(
// // //                     width: 2,
// // //                     height: 100,
// // //                     color: Colors.white.withOpacity(0.0),
// // //                     margin: const EdgeInsets.symmetric(horizontal: 4),
// // //                   );
// // //                 } else {
// // //                   int itemNumber = (index ~/ 2) + 5;
// // //                   final icon = [
// // //                     Icons.timer,
// // //                     Icons.music_note,
// // //                     Icons.videocam,
// // //                     Icons.map,
// // //                   ][itemNumber - 5];

// // //                   return Expanded(
// // //                     child: GestureDetector(
// // //                       onTap: () => handleTap(itemNumber),
// // //                       child: buildScoreContainer(
// // //                         context,
// // //                         itemKeys[itemNumber - 1].tr,
// // //                         icon,
// // //                         false,
// // //                         itemNumber: itemNumber,
// // //                       ),
// // //                     ),
// // //                   );
// // //                 }
// // //               }),
// // //             ),
// // //           ),
// // //           const SizedBox(height: 20),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildSecondTab() {
// // //     return SingleChildScrollView(
// // //       child: Column(
// // //         children: [
// // //           const SizedBox(height: 20),
// // //           Padding(
// // //             padding: const EdgeInsets.symmetric(horizontal: 180),
// // //             child: Row(
// // //               children: List.generate(7, (index) {
// // //                 if (index.isOdd) {
// // //                   return Container(
// // //                     width: 2,
// // //                     height: 100,
// // //                     color: Colors.white.withOpacity(0.0),
// // //                     margin: const EdgeInsets.symmetric(horizontal: 4),
// // //                   );
// // //                 } else {
// // //                   int itemNumber = (index ~/ 2) + 9;
// // //                   final icon = [
// // //                     Icons.medical_services,
// // //                     Icons.store,
// // //                     Icons.cleaning_services,
// // //                     Icons.phone,
// // //                   ][itemNumber - 9];

// // //                   return Expanded(
// // //                     child: GestureDetector(
// // //                       onTap: () => handleTap(itemNumber),
// // //                       child: buildScoreContainer(
// // //                         context,
// // //                         itemKeys[itemNumber - 1].tr,
// // //                         icon,
// // //                         false,
// // //                         itemNumber: itemNumber,
// // //                       ),
// // //                     ),
// // //                   );
// // //                 }
// // //               }),
// // //             ),
// // //           ),
// // //           const SizedBox(height: 20),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     // final audioProvider = Provider.of<AudioProvider>(context);
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       debugPrint(
// // //         "=== BUILD CALLED - Current Fault Status (Sensors 1-7): ${_hasSensorFault()} ===",
// // //       );
// // //       debugPrint(
// // //         "=== HEPA Status: $_hepaStatusText (F_Sensor_10_FAULT_BIT: ${_prefs?.getString('F_Sensor_10_FAULT_BIT')}) ===",
// // //       );
// // //     });

// // //     return Scaffold(
// // //       body: Container(
// // //         width: double.infinity,
// // //         height: MediaQuery.of(context).size.height,
// // //         decoration: const BoxDecoration(
// // //           gradient: LinearGradient(
// // //             colors: [Color(0xFF4c3797), Color(0xFF814EA8)],
// // //             begin: Alignment.topLeft,
// // //             end: Alignment.bottomRight,
// // //           ),
// // //         ),
// // //         child: Column(
// // //           children: [
// // //             Padding(
// // //               padding: const EdgeInsets.all(10.0),
// // //               child: Column(
// // //                 children: [
// // //                   Row(
// // //                     children: [
// // //                       Padding(
// // //                         padding: const EdgeInsets.only(left: 20, bottom: 5),
// // //                         child: Container(
// // //                           padding: const EdgeInsets.all(8),
// // //                           decoration: BoxDecoration(
// // //                             color: Colors.white,
// // //                             shape: BoxShape.circle,
// // //                             border: Border.all(color: Colors.black, width: 2),
// // //                           ),
// // //                           height: 100,
// // //                           width: 100,
// // //                           child: AnalogClock(
// // //                             decoration: const BoxDecoration(
// // //                               shape: BoxShape.circle,
// // //                               color: Colors.transparent,
// // //                             ),
// // //                             width: 60,
// // //                             height: 60,
// // //                             isLive: true,
// // //                             hourHandColor: Colors.black,
// // //                             minuteHandColor: Colors.black,
// // //                             secondHandColor: Colors.red,
// // //                             showSecondHand: true,
// // //                             showNumbers: true,
// // //                             showTicks: true,
// // //                             datetime: DateTime.now(),
// // //                             textScaleFactor: 1.1,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                       const Spacer(),
// // //                       DropdownButton<String>(
// // //                         value: Get.locale?.languageCode ?? 'en',
// // //                         icon: const Icon(Icons.language, color: Colors.white),
// // //                         dropdownColor: Colors.blue[800],
// // //                         style: const TextStyle(color: Colors.white),
// // //                         underline: Container(),
// // //                         items: const [
// // //                           DropdownMenuItem(
// // //                             value: 'en',
// // //                             child: Text(
// // //                               'English',
// // //                               style: TextStyle(color: Colors.white),
// // //                             ),
// // //                           ),
// // //                           DropdownMenuItem(
// // //                             value: 'hi',
// // //                             child: Text(
// // //                               'हिंदी',
// // //                               style: TextStyle(color: Colors.white),
// // //                             ),
// // //                           ),
// // //                           DropdownMenuItem(
// // //                             value: 'ar',
// // //                             child: Text(
// // //                               'العربية',
// // //                               style: TextStyle(color: Colors.white),
// // //                             ),
// // //                           ),
// // //                         ],
// // //                         onChanged: (String? value) {
// // //                           if (value != null) {
// // //                             Get.updateLocale(Locale(value));
// // //                             setState(() {});
// // //                           }
// // //                         },
// // //                       ),
// // //                       const SizedBox(width: 20),
// // //                       const Spacer(),
// // //                       IconButton(
// // //                         icon: const Icon(
// // //                           Icons.bug_report,
// // //                           size: 30,
// // //                           color: Colors.white,
// // //                         ),
// // //                         onPressed: _refreshFaultStatus,
// // //                       ),
// // //                       IconButton(
// // //                         icon: const Icon(
// // //                           Icons.restart_alt,
// // //                           size: 30,
// // //                           color: Colors.yellow,
// // //                         ),
// // //                         onPressed: _resetAllSensorsToNoFault,
// // //                       ),
// // //                       IconButton(
// // //                         onPressed: () async {
// // //                           final prefs = await SharedPreferences.getInstance();
// // //                           await prefs.remove("uniqueCode");
// // //                           await prefs.remove("mode");
// // //                           Navigator.pushAndRemoveUntil(
// // //                             context,
// // //                             MaterialPageRoute(
// // //                               builder: (context) => const LoginPage(),
// // //                             ),
// // //                             (route) => false,
// // //                           );
// // //                         },
// // //                         icon: Icon(
// // //                           Icons.logout_rounded,
// // //                           color: Colors.white60,
// // //                           size: 30,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),

// // //             TabBar(
// // //               controller: _tabController,
// // //               indicator: const BoxDecoration(
// // //                 shape: BoxShape.circle,
// // //                 color: Colors.white,
// // //               ),
// // //               indicatorSize: TabBarIndicatorSize.label,
// // //               labelColor: Colors.transparent,
// // //               unselectedLabelColor: Colors.transparent,
// // //               tabs: const [
// // //                 Tab(icon: Icon(Icons.circle, size: 12)),
// // //                 Tab(icon: Icon(Icons.circle, size: 12)),
// // //               ],
// // //             ),

// // //             Expanded(
// // //               child: TabBarView(
// // //                 controller: _tabController,
// // //                 children: [_buildMainTab(), _buildSecondTab()],
// // //               ),
// // //             ),

// // //             Padding(
// // //               padding: const EdgeInsets.all(18.0),
// // //               child: Row(
// // //                 children: [
// // //                   Container(
// // //                     height: 100,
// // //                     width: 300,
// // //                     child: Image.asset('assets/app_logo-removebg-preview.png'),
// // //                   ),
// // //                   const Spacer(),
// // //                   Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.end,
// // //                     children: [
// // //                       Text(
// // //                         "system_status".tr,
// // //                         style: const TextStyle(
// // //                           color: Colors.white,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                       Switch(
// // //                         value: _isSwitched,
// // //                         activeColor: Colors.lightBlueAccent,
// // //                         inactiveThumbColor: Colors.grey.shade300,
// // //                         inactiveTrackColor: Colors.grey.shade500,
// // //                         onChanged: (value) async {
// // //                           if (!value) {
// // //                             bool confirm = await showDialog(
// // //                               context: context,
// // //                               builder: (context) => AlertDialog(
// // //                                 title: const Text("Confirm"),
// // //                                 content: const Text(
// // //                                   "Are you sure you want to turn off the system?",
// // //                                 ),
// // //                                 actions: [
// // //                                   TextButton(
// // //                                     onPressed: () =>
// // //                                         Navigator.of(context).pop(false),
// // //                                     child: const Text("Cancel"),
// // //                                   ),
// // //                                   TextButton(
// // //                                     onPressed: () =>
// // //                                         Navigator.of(context).pop(true),
// // //                                     child: const Text("Yes"),
// // //                                   ),
// // //                                 ],
// // //                               ),
// // //                             );

// // //                             if (!confirm) {
// // //                               return;
// // //                             }
// // //                           }

// // //                           _sendSystemStatusCommand(value);
// // //                           _saveSystemStatus(value);
// // //                         },
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   const SizedBox(width: 12),
// // //                   IconButton(
// // //                     icon: Icon(
// // //                       audioProvider.isMuted
// // //                           ? Icons.volume_off
// // //                           : Icons.volume_up,
// // //                       size: 42,
// // //                       color: Colors.white,
// // //                     ),
// // //                     onPressed: _toggleMute,
// // //                     tooltip: audioProvider.isMuted ? "Unmute" : "Mute",
// // //                   ),
// // //                   IconButton(
// // //                     icon: const Icon(
// // //                       Icons.refresh,
// // //                       size: 42,
// // //                       color: Colors.white,
// // //                     ),
// // //                     onPressed: () {
// // //                       _reconnectUsb();
// // //                       _loadSavedValues();
// // //                       _refreshFaultStatus();
// // //                       _refreshHepaStatus();
// // //                       Get.snackbar(
// // //                         "refreshing".tr,
// // //                         "",
// // //                         snackPosition: SnackPosition.BOTTOM,
// // //                         backgroundColor: const Color(0xFFB0D3DC),
// // //                         colorText: Colors.white,
// // //                         margin: const EdgeInsets.symmetric(
// // //                           horizontal: 50,
// // //                           vertical: 20,
// // //                         ),
// // //                         maxWidth: 400,
// // //                         borderRadius: 10,
// // //                         snackStyle: SnackStyle.FLOATING,
// // //                         mainButton: TextButton(
// // //                           onPressed: () => Get.back(),
// // //                           child: Text(
// // //                             "close".tr,
// // //                             style: const TextStyle(
// // //                               color: Colors.white,
// // //                               fontWeight: FontWeight.bold,
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       );
// // //                     },
// // //                   ),
// // //                   IconButton(
// // //                     icon: const Icon(
// // //                       Icons.settings,
// // //                       size: 42,
// // //                       color: Colors.white,
// // //                     ),
// // //                     onPressed: () {
// // //                       Get.to(
// // //                         () => ProfilePage1(),
// // //                         transition: Transition.rightToLeft,
// // //                         duration: const Duration(milliseconds: 400),
// // //                       );
// // //                     },
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'dart:typed_data';
// // import 'dart:ui' as ui;

// // import 'package:flutter/material.dart';
// // import 'package:flutter/rendering.dart';
// // import 'package:get/get.dart';
// // import 'package:share_plus/share_plus.dart';
// // import 'package:surgeon_control_panel/screen/feather/allcctv/allcctv.dart';
// // import 'package:webview_flutter/webview_flutter.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:path/path.dart' as path;
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:fluttertoast/fluttertoast.dart';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:shared_preferences/shared_preferences.dart';

// // class VideoSwitcherScreen extends StatefulWidget {
// //   const VideoSwitcherScreen({super.key});

// //   @override
// //   State<VideoSwitcherScreen> createState() => _VideoSwitcherScreenState();
// // }

// // class _VideoSwitcherScreenState extends State<VideoSwitcherScreen> {
// //   // late YoutubePlayerController _controller;

// //   int selectedVideoIndex = 0;
// //   final String baseUrl = 'http://192.168.0.43:5000'; // Your local server IP
// //   bool isRecording = false;
// //   bool isConnected = false;

// //   // Recording variables
// //   String? _usbPath;
// //   bool _usbConnected = false;
// //   GlobalKey _repaintKey = GlobalKey();
// //   Timer? _recordingTimer;
// //   int _recordingSeconds = 0; // Elapsed recording time
// //   bool _isRecordingScreen = false;
// //   List<String> _recordedFiles = [];

// //   Future<void> checkConnection() async {
// //     try {
// //       print("Sending request to $baseUrl/status");

// //       final response = await http
// //           .get(Uri.parse('$baseUrl/status'))
// //           .timeout(Duration(seconds: 5));

// //       print("Response status: ${response.statusCode}");
// //       print("Response body: ${response.body}");

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);
// //         print("Decoded response: $data");

// //         setState(() {
// //           isConnected = data['connected'].toString().toLowerCase() == 'true';
// //         });

// //         print("isConnected set to: $isConnected");
// //       } else {
// //         setState(() => isConnected = false);
// //         print("Connection failed with status: ${response.statusCode}");
// //       }
// //     } on TimeoutException {
// //       setState(() => isConnected = false);
// //       print("Connection timed out - server not responding");
// //     } catch (e) {
// //       setState(() => isConnected = false);
// //       print("Connection error: $e");
// //     }
// //   }

// //   Future<void> startRecording() async {
// //     print('nsnnss');
// //     try {
// //       final response = await http.get(Uri.parse('$baseUrl/start_recording'));
// //       final data = jsonDecode(response.body);
// //       if (data['status'] != null) {
// //         setState(() => isRecording = true);
// //       }
// //     } catch (e) {
// //       print("Error starting recording: $e");
// //     }
// //   }

// //   Future<void> stopRecording() async {
// //     try {
// //       final response = await http.get(Uri.parse('$baseUrl/stop_recording'));
// //       final data = jsonDecode(response.body);
// //       if (data['status'] != null) {
// //         setState(() => isRecording = false);
// //       }
// //     } catch (e) {
// //       print("Error stopping recording: $e");
// //     }
// //   }

// //   String? selectedScene;
// //   Future<void> switchScene(String sceneName) async {
// //     try {
// //       print("Switching to scene: $sceneName");
// //       final response = await http.get(
// //         Uri.parse('$baseUrl/switch_scene/${Uri.encodeComponent(sceneName)}'),
// //       );
// //       print("Response: ${response.body}");
// //       final data = jsonDecode(response.body);
// //       if (data['status'] != null) {
// //         setState(() => selectedScene = sceneName);
// //       } else {
// //         print("Switch error: ${data['error']}");
// //       }
// //     } catch (e) {
// //       print("Error switching scene: $e");
// //     }
// //   }

// //   // Recording Functions
// //   Future<void> _requestPermissions() async {
// //     await Permission.storage.request();
// //     await Permission.manageExternalStorage.request();
// //     await Permission.microphone.request();
// //     await Permission.camera.request();
// //   }

// //   Future<void> _loadUSBPath() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final savedPath = prefs.getString("usbPath");
// //     if (savedPath != null && Directory(savedPath).existsSync()) {
// //       setState(() {
// //         _usbPath = savedPath;
// //         _usbConnected = true;
// //       });
// //     }
// //   }

// //   Future<void> _selectUSBDirectory() async {
// //     try {
// //       String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
// //       if (selectedDirectory != null) {
// //         setState(() {
// //           _usbPath = selectedDirectory;
// //           _usbConnected = true;
// //         });

// //         final prefs = await SharedPreferences.getInstance();
// //         await prefs.setString("usbPath", selectedDirectory);

// //         Fluttertoast.showToast(
// //           msg: "USB Storage Selected: ${path.basename(selectedDirectory)}",
// //           toastLength: Toast.LENGTH_SHORT,
// //           gravity: ToastGravity.BOTTOM,
// //         );
// //       }
// //     } catch (e) {
// //       print("Error selecting USB directory: $e");
// //       Fluttertoast.showToast(
// //         msg: "Failed to select USB storage",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     }
// //   }

// //   Future<void> _startScreenRecording() async {
// //     if (!_usbConnected || _usbPath == null) {
// //       Fluttertoast.showToast(
// //         msg: "Please select USB storage first",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //       return;
// //     }

// //     setState(() {
// //       _isRecordingScreen = true;
// //       _recordingSeconds = 0;
// //     });

// //     Fluttertoast.showToast(
// //       msg: "Screen recording started...",
// //       gravity: ToastGravity.BOTTOM,
// //     );

// //     // In a real implementation, you would use a screen recording package
// //     // For now, we'll simulate the recording process

// //     // Start recording timer
// //     _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
// //       setState(() {
// //         _recordingSeconds++;
// //       });
// //     });
// //   }

// //   Future<void> _stopScreenRecording() async {
// //     if (!_isRecordingScreen) return;

// //     setState(() {
// //       _isRecordingScreen = false;
// //     });

// //     _recordingTimer?.cancel();
// //     _recordingTimer = null;

// //     // Simulate saving the recording
// //     try {
// //       final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
// //       final recordingsDir = Directory(path.join(_usbPath!, 'Recordings'));

// //       if (!await recordingsDir.exists()) {
// //         await recordingsDir.create(recursive: true);
// //       }

// //       final outputPath = path.join(recordingsDir.path, fileName);

// //       // In a real implementation, you would save the actual recording file here
// //       // For simulation, we'll just create an empty file
// //       final file = File(outputPath);
// //       await file.writeAsString("Simulated recording file");

// //       setState(() {
// //         _recordedFiles.add(outputPath);
// //       });

// //       Fluttertoast.showToast(
// //         msg: "Recording saved: $fileName",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     } catch (e) {
// //       Fluttertoast.showToast(
// //         msg: "Failed to save recording: $e",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     }
// //   }

// //   Future<void> _takeScreenshot() async {
// //     try {
// //       if (!_usbConnected || _usbPath == null) {
// //         Fluttertoast.showToast(
// //           msg: "Please select USB storage first",
// //           gravity: ToastGravity.BOTTOM,
// //         );
// //         return;
// //       }

// //       // In a real implementation, you would capture the screen using RepaintBoundary
// //       // For now, we'll simulate it
// //       final screenshotDir = Directory(path.join(_usbPath!, 'Screenshots'));
// //       if (!await screenshotDir.exists())
// //         await screenshotDir.create(recursive: true);

// //       final fileName =
// //           'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
// //       final file = File(path.join(screenshotDir.path, fileName));

// //       // Create a simulated screenshot file
// //       await file.writeAsString("Simulated screenshot data");

// //       Fluttertoast.showToast(
// //         msg: "Screenshot saved: $fileName",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     } catch (e) {
// //       Fluttertoast.showToast(
// //         msg: "Failed to capture screenshot: $e",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     }
// //   }

// //   Future<void> _viewRecordings() async {
// //     if (_usbPath == null || !Directory(_usbPath!).existsSync()) {
// //       Fluttertoast.showToast(
// //         msg: "USB storage not available",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //       return;
// //     }

// //     final recordingsDir = Directory(path.join(_usbPath!, 'Recordings'));
// //     if (!recordingsDir.existsSync()) {
// //       Fluttertoast.showToast(
// //         msg: "No recordings found",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //       return;
// //     }

// //     final files = recordingsDir.listSync().whereType<File>().toList();
// //     if (files.isEmpty) {
// //       Fluttertoast.showToast(
// //         msg: "No recordings found",
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //       return;
// //     }

// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: Text("Recorded Files"),
// //         content: SizedBox(
// //           width: double.maxFinite,
// //           child: ListView.builder(
// //             shrinkWrap: true,
// //             itemCount: files.length,
// //             itemBuilder: (context, index) {
// //               final file = files[index];
// //               final fileSize = file.lengthSync();
// //               return ListTile(
// //                 title: Text(path.basename(file.path)),
// //                 subtitle: Text("${fileSize ~/ 1024} KB"),
// //                 trailing: Row(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     IconButton(
// //                       icon: Icon(Icons.play_arrow),
// //                       onPressed: () {}, // You can implement playback here
// //                     ),
// //                     IconButton(
// //                       icon: Icon(Icons.delete),
// //                       onPressed: () {
// //                         file.deleteSync();
// //                         Navigator.pop(context);
// //                         _viewRecordings();
// //                         Fluttertoast.showToast(
// //                           msg: "File deleted",
// //                           gravity: ToastGravity.BOTTOM,
// //                         );
// //                       },
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             },
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text("Close"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   late WebViewController _obsController;
// //   late WebViewController _motionEyeController;
// //   late WebViewController _motionEyeControllerr;
// //   late WebViewController _motionEyeControllerrr;
// //   // late YoutubePlayerController _youtubeController;
// //   int _selectedStreamIndex = 0; // 0 = OBS, 1 = MotionEye, 2 = YouTube

// //   final List<String> youtubeUrls = [
// //     "https://www.youtube.com/watch?v=dQw4w9WgXcQ", // example video
// //   ];

// //   final TextEditingController _messageController = TextEditingController();
// //   bool _isSending = false;
// //   String? _lastStatus;
// //   String? _lastSid;

// //   Future<void> _sendMessage() async {
// //     if (_messageController.text.isEmpty) {
// //       _showSnackBar('Please enter phone number and message');
// //       return;
// //     }

// //     setState(() {
// //       _isSending = true;
// //       _lastStatus = null;
// //       _lastSid = null;
// //     });

// //     // Simulate message sending
// //     await Future.delayed(Duration(seconds: 2));

// //     setState(() {
// //       _isSending = false;
// //       _lastStatus = 'Message sent successfully!';
// //       _lastSid = 'SM1234567890';
// //     });

// //     _showSnackBar(_lastStatus!);
// //     if (_lastSid != null) {
// //       _messageController.clear();
// //     }
// //   }

// //   void _showSnackBar(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: _lastSid != null ? Colors.green : Colors.red,
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //       ),
// //     );
// //   }

// //   void _showMessageDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return Dialog(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(16),
// //           ),
// //           elevation: 0,
// //           backgroundColor: Colors.transparent,
// //           child: Container(
// //             padding: const EdgeInsets.all(24),
// //             decoration: BoxDecoration(
// //               gradient: const LinearGradient(
// //                 colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //               ),
// //               borderRadius: BorderRadius.circular(16),
// //             ),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     const Text(
// //                       'New WhatsApp Message',
// //                       style: TextStyle(
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.bold,
// //                         color: Colors.white,
// //                       ),
// //                     ),
// //                     IconButton(
// //                       icon: const Icon(Icons.close, color: Colors.grey),
// //                       onPressed: () => Navigator.pop(context),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 16),
// //                 TextField(
// //                   controller: _messageController,
// //                   decoration: InputDecoration(
// //                     labelText: 'Message',
// //                     prefixIcon: const Icon(
// //                       Icons.message,
// //                       color: Colors.white54,
// //                     ),
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     filled: true,
// //                     fillColor: Colors.white38,
// //                   ),
// //                   maxLines: 5,
// //                 ),
// //                 const SizedBox(height: 24),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   height: 50,
// //                   child: ElevatedButton(
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: Colors.white54,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       elevation: 0,
// //                     ),
// //                     onPressed: _isSending
// //                         ? null
// //                         : () async {
// //                             await _sendMessage();
// //                             if (!_isSending) Navigator.pop(context);
// //                           },
// //                     child: _isSending
// //                         ? const CircularProgressIndicator(color: Colors.white)
// //                         : const Row(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: [
// //                               Icon(Icons.send, size: 20),
// //                               SizedBox(width: 8),
// //                               Text(
// //                                 'Send Message',
// //                                 style: TextStyle(fontSize: 16),
// //                               ),
// //                             ],
// //                           ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     checkConnection();
// //     _requestPermissions();
// //     _loadUSBPath();

// //     _obsController = WebViewController()
// //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// //       ..loadRequest(Uri.parse("http://192.168.0.160:9081"));

// //     // MotionEye Stream WebView
// //     _motionEyeController = WebViewController()
// //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// //       ..loadRequest(Uri.parse("http://192.168.0.160:9082"));
// //     _motionEyeControllerr = WebViewController()
// //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// //       ..loadRequest(Uri.parse("http://192.168.0.160:9083"));
// //     _motionEyeControllerrr = WebViewController()
// //       ..setJavaScriptMode(JavaScriptMode.unrestricted)
// //       ..loadRequest(Uri.parse("http://192.168.0.160:9084"));
// //   }

// //   @override
// //   void dispose() {
// //     // _youtubeController.dispose();
// //     _recordingTimer?.cancel();
// //     super.dispose();
// //   }

// //   Widget _buildStreamView() {
// //     switch (_selectedStreamIndex) {
// //       case 0:
// //         return RepaintBoundary(
// //           key: _repaintKey,
// //           child: WebViewWidget(controller: _obsController),
// //         );
// //       case 1:
// //         return RepaintBoundary(
// //           key: _repaintKey,
// //           child: WebViewWidget(controller: _motionEyeController),
// //         );
// //       case 2:
// //         return RepaintBoundary(
// //           key: _repaintKey,
// //           child: WebViewWidget(controller: _motionEyeControllerr),
// //         );
// //       default:
// //         return RepaintBoundary(
// //           key: _repaintKey,
// //           child: WebViewWidget(controller: _motionEyeControllerrr),
// //         );
// //     }
// //   }

// //   Widget _buildSwitchButton(String label, int index) {
// //     return ElevatedButton(
// //       onPressed: () {
// //         setState(() {
// //           _selectedStreamIndex = index;
// //         });
// //       },
// //       child: Text(label),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     String timerText =
// //         "${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}";

// //     return Scaffold(
// //       body: Row(
// //         children: [
// //           // Left Panel
// //           Expanded(
// //             flex: 1,
// //             child: Container(
// //               decoration: const BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     Color.fromARGB(255, 40, 123, 131),
// //                     Color.fromARGB(255, 39, 83, 87),
// //                   ],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
// //               ),
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.start,
// //                 children: [
// //                   // Center(
// //                   //   child: Text(
// //                   //     '✅ ${'connect_to'.tr} to WIESPL',
// //                   //     style: TextStyle(
// //                   //       fontWeight: FontWeight.bold,
// //                   //       fontSize: 16,
// //                   //       color: isConnected ? Colors.green : Colors.green,
// //                   //     ),
// //                   //   ),
// //                   // ),
// //                   SizedBox(height: 25),
// //                   Expanded(
// //                     flex: 1,
// //                     child: Container(
// //                       decoration: const BoxDecoration(
// //                         gradient: LinearGradient(
// //                           colors: [
// //                             Color.fromARGB(255, 40, 123, 131),
// //                             Color.fromARGB(255, 39, 83, 87),
// //                           ],
// //                           begin: Alignment.topCenter,
// //                           end: Alignment.bottomCenter,
// //                         ),
// //                       ),
// //                       child: Column(
// //                         children: [
// //                           const SizedBox(height: 16),
// //                           const Text(
// //                             "CCTV",
// //                             style: TextStyle(
// //                               fontSize: 20,
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.white,
// //                             ),
// //                           ),
// //                           const Divider(color: Colors.white38),
// //                           const SizedBox(height: 12),
// //                           Expanded(
// //                             child: ListView(
// //                               padding: const EdgeInsets.symmetric(
// //                                 horizontal: 12,
// //                               ),
// //                               children: [
// //                                 buildTvItem("${'cctv'.tr}1", 0),
// //                                 buildTvItem("${'cctv'.tr} 2", 1),
// //                                 buildTvItem("${'cctv'.tr} 3", 2),
// //                                 buildTvItem("${'cctv'.tr} 4", 3),
// //                               ],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),

// //                   Padding(
// //                     padding: const EdgeInsets.only(bottom: 16.0),
// //                     child: ElevatedButton(
// //                       onPressed: () {
// //                         Navigator.pop(context);
// //                       },
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.red,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(10),
// //                         ),
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 40,
// //                           vertical: 12,
// //                         ),
// //                       ),
// //                       child: const Text(
// //                         "BACK",
// //                         style: TextStyle(
// //                           color: Colors.white70,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),

// //           // Center Panel
// //           Expanded(
// //             flex: 3,
// //             child: Container(
// //               decoration: const BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     Color.fromARGB(255, 40, 123, 131),
// //                     Color.fromARGB(255, 39, 83, 87),
// //                   ],
// //                   begin: Alignment.topCenter,
// //                   end: Alignment.bottomCenter,
// //                 ),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.center,
// //                 children: [
// //                   const SizedBox(height: 10),
// //                   const Text(
// //                     "Dr. Ajay Kothari",
// //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
// //                   ),
// //                   const Text("Orthopaedic OT", style: TextStyle(fontSize: 14)),
// //                   const SizedBox(height: 6),

// //                   Expanded(
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(8.0),
// //                       child: _buildStreamView(),
// //                     ),
// //                   ),

// //                   Padding(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 8,
// //                       vertical: 8,
// //                     ),
// //                     child: Column(
// //                       children: [
// //                         Wrap(
// //                           alignment: WrapAlignment.center,
// //                           spacing: 8,
// //                           runSpacing: 8,
// //                           children: [
// //                             buildControlBtn(
// //                               "start".tr,
// //                               onPressed: () {
// //                                 print(" pressed");
// //                                 startRecording();
// //                               },
// //                             ),
// //                             buildControlBtn(
// //                               "stop".tr,
// //                               onPressed: () {
// //                                 print("STARTTTTT");
// //                                 stopRecording();
// //                               },
// //                               icon: isRecording
// //                                   ? Icons.record_voice_over_rounded
// //                                   : null,
// //                             ),
// //                             // Screen recording buttons
// //                             buildControlBtn(
// //                               _isRecordingScreen
// //                                   ? "Recording... $timerText"
// //                                   : "Screen Record",
// //                               onPressed: _isRecordingScreen
// //                                   ? null
// //                                   : _startScreenRecording,
// //                               icon: _isRecordingScreen
// //                                   ? Icons.circle
// //                                   : Icons.fiber_manual_record,
// //                             ),
// //                             buildControlBtn(
// //                               "Stop Screen Rec",
// //                               onPressed: _isRecordingScreen
// //                                   ? _stopScreenRecording
// //                                   : null,
// //                               icon: Icons.stop,
// //                             ),
// //                             buildControlBtn(
// //                               "message".tr,
// //                               onPressed: () {
// //                                 _showMessageDialog();
// //                               },
// //                             ),
// //                           ],
// //                         ),
// //                         const SizedBox(height: 8),
// //                         Wrap(
// //                           alignment: WrapAlignment.center,
// //                           spacing: 8,
// //                           runSpacing: 8,
// //                           children: [
// //                             buildControlBtn(
// //                               "task_ss".tr,
// //                               icon: Icons.camera_alt,
// //                               onPressed: _takeScreenshot,
// //                             ),
// //                             buildControlBtn(
// //                               "gallery".tr,
// //                               icon: Icons.photo_library,
// //                               onPressed: _viewRecordings,
// //                             ),
// //                             buildControlBtn(
// //                               "USB Storage",
// //                               icon: Icons.usb,
// //                               onPressed: _selectUSBDirectory,
// //                             ),
// //                             buildControlBtn(
// //                               "share".tr,
// //                               icon: Icons.share,
// //                               onPressed: () {
// //                                 Share.share(
// //                                   'Invite to Wiespl Meet: https://wiespl.com/',
// //                                 );
// //                               },
// //                             ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),

// //           // Right Panel
// //           Expanded(
// //             flex: 1,
// //             child: Container(
// //               decoration: const BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     Color.fromARGB(255, 40, 123, 131),
// //                     Color.fromARGB(255, 39, 83, 87),
// //                   ],
// //                   begin: Alignment.topCenter,
// //                   end: Alignment.bottomCenter,
// //                 ),
// //               ),
// //               child: Column(
// //                 children: [
// //                   const SizedBox(height: 16),
// //                   const Padding(
// //                     padding: EdgeInsets.only(top: 24.0),
// //                     child: Text(
// //                       "TV List",
// //                       style: TextStyle(
// //                         fontSize: 22,
// //                         fontWeight: FontWeight.bold,
// //                         color: Colors.white,
// //                       ),
// //                     ),
// //                   ),
// //                   const Divider(color: Colors.white38),
// //                   const SizedBox(height: 12),
// //                   Expanded(
// //                     child: ListView(
// //                       padding: const EdgeInsets.symmetric(horizontal: 12),
// //                       children: [
// //                         InkWell(
// //                           onTap: () {
// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder: (context) => DraggableGridScreen(),
// //                               ),
// //                             );
// //                           },
// //                           child: buildTvItemm("TV 1", 0),
// //                         ),
// //                         buildTvItemm("TV 2", 1),
// //                       ],
// //                     ),
// //                   ),
// //                   // Padding(
// //                   //   padding: const EdgeInsets.only(bottom: 12),
// //                   //   child: ElevatedButton(
// //                   //     onPressed: () {
// //                   //       // Navigator.push(
// //                   //       //     context,
// //                   //       //     MaterialPageRoute(
// //                   //       //       builder: (context) => YouTubeGridScreen(),
// //                   //       //     ));
// //                   //     },
// //                   //     style: ElevatedButton.styleFrom(
// //                   //       backgroundColor: Colors.green,
// //                   //     ),
// //                   //     child: const Text(
// //                   //       "APPLY",
// //                   //       style: TextStyle(
// //                   //         color: Colors.white,
// //                   //         fontWeight: FontWeight.bold,
// //                   //       ),
// //                   //     ),
// //                   //   ),
// //                   // ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget buildControlBtnn(String label, {IconData? icon}) {
// //     return SizedBox(
// //       width: 120,
// //       child: ElevatedButton.icon(
// //         onPressed: () {},
// //         icon: icon != null ? Icon(icon, size: 16) : const SizedBox(width: 0),
// //         label: Text(label, overflow: TextOverflow.ellipsis),
// //         style: ElevatedButton.styleFrom(
// //           backgroundColor: Colors.white,
// //           foregroundColor: Colors.black,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(30),
// //           ),
// //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget buildControlBtn(
// //     String label, {
// //     IconData? icon,
// //     VoidCallback? onPressed,
// //   }) {
// //     return SizedBox(
// //       width: 120,
// //       child: ElevatedButton.icon(
// //         onPressed: onPressed,
// //         icon: icon != null ? Icon(icon, size: 16) : const SizedBox(width: 0),
// //         label: Text(label, overflow: TextOverflow.ellipsis),
// //         style: ElevatedButton.styleFrom(
// //           backgroundColor: Colors.white,
// //           foregroundColor: Colors.black,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(30),
// //           ),
// //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget buildTvItem(String name, int index) {
// //     return InkWell(
// //       onTap: () {
// //         setState(() {
// //           _selectedStreamIndex = index;
// //         });
// //       },
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             name,
// //             style: const TextStyle(
// //               color: Colors.white,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //           Text("Playing $name", style: const TextStyle(color: Colors.white70)),
// //           const Divider(color: Colors.white38),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget buildTvItemm(String name, int index) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           name,
// //           style: const TextStyle(
// //             color: Colors.white,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         Text("Playing $name", style: const TextStyle(color: Colors.white70)),
// //         const Divider(color: Colors.white38),
// //       ],
// //     );
// //   }
// // }
// In this, remove the or camera , DICOME , PI ,STORE , CLEAN and phone

// import 'dart:async';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui';
// import 'package:analog_clock/analog_clock.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:stop_watch_timer/stop_watch_timer.dart';
// import 'package:surgeon_control_panel/main.dart';
// import 'package:surgeon_control_panel/patient%20info/clean/clean_pro.dart';
// import 'package:surgeon_control_panel/patient%20info/dashboard/dashboard.dart';
// import 'package:surgeon_control_panel/patient%20info/dashboard/store/storeitems.dart';
// import 'package:surgeon_control_panel/patient%20info/dashboard_items/patient_list.dart';
// import 'package:surgeon_control_panel/provider/audioProvider.dart';
// import 'package:surgeon_control_panel/provider/stopwatch_provider.dart';
// import 'package:surgeon_control_panel/screen/feather/cctv.dart';
// import 'package:surgeon_control_panel/screen/feather/clock/clock.dart';
// import 'package:surgeon_control_panel/screen/feather/light.dart';
// import 'package:surgeon_control_panel/screen/feather/mgps.dart';
// import 'package:surgeon_control_panel/screen/feather/music.dart';
// import 'package:surgeon_control_panel/screen/feather/phone/phonecall.dart';
// import 'package:surgeon_control_panel/screen/feather/rh.dart';
// import 'package:surgeon_control_panel/screen/feather/temp.dart';
// import 'package:surgeon_control_panel/screen/feather/timer.dart';
// import 'package:surgeon_control_panel/screen/profil/profilescreen.dart';
// import 'package:surgeon_control_panel/services/usb_service.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:usb_serial/usb_serial.dart';

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> with TickerProviderStateMixin {
//   final List<String> itemKeys = [
//     'temp',
//     'rh',
//     'lighting',
//     'dicom',
//     'Stop Watch',
//     'music',
//     'cctv',
//     'mgps',
//     'pis',
//     'store',
//     'clean',
//     'phone',
//   ];
//   // Send system status command to USB using GlobalUsbProvider
//   void _sendSystemStatusCommand(bool isOn) {
//     final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

//     // Use the provider's method instead of direct USB communication
//     usbProvider.toggleSystemPower(isOn);

//     _showSuccessSnackbar("System turned ${isOn ? 'ON' : 'OFF'}");
//   }

//   // USB related variables
//   UsbPort? _port;
//   String _incomingBuffer = "";
//   StreamSubscription<dynamic>? _usbSubscription;

//   static const platform = MethodChannel('app_launcher_channel');

//   // Timer for periodic updates
//   Timer? _updateTimer;

//   late TabController _tabController;

//   // Animation controllers
//   late AnimationController _cardController;
//   late Animation<Offset> _cardSlideAnimation;
//   late AnimationController _bgController;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;

//   final Random _random = Random();
//   final List<MedicalParticle> _particles = [];

//   @override
//   void initState() {
//     super.initState();
//     // Initialize USB when screen loads (SharedPreferences is already initialized in main.dart)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final usbProvider = Provider.of<GlobalUsbProvider>(
//         context,
//         listen: false,
//       );
//       usbProvider.initUsb(); // Only initialize USB connection
//     });
//     // Initialize particles
//     for (int i = 0; i < 18; i++) {
//       _particles.add(MedicalParticle(_random));
//     }

//     // Animation setup
//     _cardController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );
//     _cardSlideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1.0),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

//     _bgController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 12),
//     )..repeat();

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );

//     _cardController.forward();
//     _tabController = TabController(length: 2, vsync: this);

//     // Start USB and periodic updates
//     _initUsb();
//     _startPeriodicUpdates();
//   }

//   void _startPeriodicUpdates() {
//     _updateTimer?.cancel();
//     _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       final usbProvider = Provider.of<GlobalUsbProvider>(
//         context,
//         listen: false,
//       );
//       usbProvider.refreshHepaStatus();
//     });
//   }

//   // USB Initialization
//   Future<void> _initUsb() async {
//     final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

//     try {
//       // USB status is now managed by GlobalUsbProvider
//       List<UsbDevice> devices = await UsbSerial.listDevices();
//       debugPrint("Found ${devices.length} USB devices");

//       if (devices.isEmpty) {
//         return;
//       }

//       UsbDevice device = devices.first;

//       _port = await device.create();
//       bool open = await _port!.open();

//       if (open) {
//         await _port!.setDTR(true);
//         await _port!.setRTS(true);
//         await _port!.setPortParameters(9600, 8, 1, 0);

//         // Cancel previous subscription if any
//         await _usbSubscription?.cancel();

//         _usbSubscription = _port!.inputStream?.listen(
//           (data) {
//             _onDataReceived(data);
//           },
//           onError: (e) {
//             debugPrint("USB input stream error: $e");
//           },
//           onDone: () {
//             debugPrint("USB input stream done");
//           },
//         );
//       }
//     } catch (e) {
//       debugPrint("USB Error: $e");
//     }
//   }

//   void _toggleMute() {
//     final audioProvider = Provider.of<GlobalUsbProvider>(
//       context,
//       listen: false,
//     );
//     audioProvider.toggleMute();
//     _showSuccessSnackbar(
//       audioProvider.isMuted ? "Audio muted" : "Audio unmuted",
//     );
//   }

//   void _onDataReceived(dynamic chunk) {
//     try {
//       String str;
//       if (chunk is Uint8List) {
//         str = String.fromCharCodes(chunk);
//       } else if (chunk is String) {
//         str = chunk;
//       } else if (chunk is List<int>) {
//         str = String.fromCharCodes(chunk);
//       } else {
//         str = chunk.toString();
//       }

//       debugPrint(
//         "📨 RAW USB DATA: ${str.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}",
//       );

//       _incomingBuffer += str;

//       if (_incomingBuffer.contains('\n')) {
//         List<String> lines = _incomingBuffer.split('\n');
//         for (int i = 0; i < lines.length - 1; i++) {
//           String line = lines[i].trim();
//           if (line.isNotEmpty) _processCompleteMessage(line);
//         }
//         _incomingBuffer = lines.last;
//       }

//       while (_incomingBuffer.contains('{') && _incomingBuffer.contains('}')) {
//         int start = _incomingBuffer.indexOf('{');
//         int end = _incomingBuffer.indexOf('}', start);
//         if (end == -1) break;
//         String block = _incomingBuffer.substring(start, end + 1);
//         _processCompleteMessage(block);
//         _incomingBuffer = _incomingBuffer.substring(end + 1);
//       }

//       if (_incomingBuffer.trim().startsWith('{') &&
//           _incomingBuffer.trim().endsWith('}')) {
//         _processCompleteMessage(_incomingBuffer.trim());
//         _incomingBuffer = "";
//       }
//     } catch (e) {
//       debugPrint("Error in _onDataReceived: $e");
//     }
//   }

//   void _processCompleteMessage(String completeMessage) {
//     debugPrint("Processing complete message: $completeMessage");
//     _parseStructuredData(completeMessage);
//   }

//   void _parseStructuredData(String data) {
//     final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);

//     try {
//       if (data.startsWith('{') && data.endsWith('}')) {
//         String content = data.substring(1, data.length - 1);
//         List<String> pairs = content.split(',');
//         Map<String, dynamic> parsedData = {};

//         for (String pair in pairs) {
//           List<String> keyValue = pair.split(':');
//           if (keyValue.length == 2) {
//             String key = keyValue[0].trim();
//             String value = keyValue[1].trim();
//             parsedData[key] = value;

//             // Save sensor fault bits
//             if (key.startsWith('F_Sensor_') && key.endsWith('_FAULT_BIT')) {
//               String sensorNumStr = key
//                   .replaceAll('F_Sensor_', '')
//                   .replaceAll('_FAULT_BIT', '');
//               int? sensorNum = int.tryParse(sensorNumStr);
//               if (sensorNum != null &&
//                   (sensorNum >= 1 && sensorNum <= 7 || sensorNum == 10)) {
//                 debugPrint("🔄 Updated $key: $value");

//                 if (sensorNum == 10) {
//                   usbProvider.refreshHepaStatus();
//                 }
//               }
//             }
//           }
//         }

//         debugPrint("Parsed data: $parsedData");

//         // Parse current temperature
//         if (parsedData.containsKey('C_OT_TEMP')) {
//           String tempStr = parsedData['C_OT_TEMP']!;
//           String newTemp = _formatNumericWithOneDecimal(tempStr);
//           usbProvider.updateTemperature(newTemp);
//           debugPrint("Parsed and saved temperature: $newTemp°C");
//         }

//         // Parse current humidity
//         if (parsedData.containsKey('C_RH')) {
//           String humStr = parsedData['C_RH']!;
//           String newHum = _formatNumericWithOneDecimal(humStr);
//           usbProvider.updateHumidity(newHum);
//           debugPrint("Parsed and saved humidity: $newHum%");
//         }

//         // Parse system status
//         if (parsedData.containsKey('S_Light_10_ON_OFF')) {
//           String systemStatusStr = parsedData['S_Light_10_ON_OFF']!;
//           bool systemStatus = systemStatusStr == '1';
//           usbProvider.updateSystemStatus(systemStatus);
//           debugPrint("Parsed and saved system status: $systemStatus");
//         }
//       } else {
//         debugPrint("Data doesn't have proper structure: $data");
//       }
//     } catch (e) {
//       debugPrint("Error parsing structured data: $e");
//       debugPrint("Data that caused error: $data");
//     }
//   }

//   String _formatNumericWithOneDecimal(String s) {
//     if (s.length == 1) {
//       return "0.${s}";
//     } else {
//       String whole = s.substring(0, s.length - 1);
//       String dec = s.substring(s.length - 1);
//       int wholeInt = int.tryParse(whole) ?? 0;
//       return "$wholeInt.$dec";
//     }
//   }

//   void _reconnectUsb() {
//     final usbProvider = Provider.of<GlobalUsbProvider>(context, listen: false);
//     usbProvider.reconnectUsb();
//   }

//   Future<void> _launchDroidRenderAndEnterPip() async {
//     try {
//       final bool success = await platform.invokeMethod(
//         'launchAppAndEnterPip',
//         'com.luolai.droidrender',
//       );

//       if (!success) {
//         _showErrorSnackbar(
//           'Failed to open DroidRender. App may not be installed.',
//         );
//       }
//     } on PlatformException catch (e) {
//       _showErrorSnackbar('Error: ${e.message}');
//     }
//   }

//   void _showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showSuccessSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   Future<String> fetchIpAddress() async {
//     try {
//       final response = await http.get(Uri.parse('https://api.ipify.org'));
//       if (response.statusCode == 200) {
//         return response.body;
//       } else {
//         return 'Failed to fetch IP'.tr;
//       }
//     } catch (e) {
//       return 'Error: $e'.tr;
//     }
//   }

//   Future<void> handleTap(int itemNumber) async {
//     switch (itemNumber) {
//       case 1:
//         Get.to(() => TempGaugeScreen(), transition: Transition.rightToLeft);
//         break;
//       case 2:
//         Get.to(() => HumidityGaugeScreen(), transition: Transition.rightToLeft);
//         break;
//       case 3:
//         Get.to(() => LightIntensityPage(), transition: Transition.rightToLeft);
//         break;
//       case 4:
//         _launchDroidRenderAndEnterPip();
//         break;
//       case 5:
//         Get.to(
//           () => StylishStopwatchPage(),
//           transition: Transition.rightToLeft,
//         );
//         break;
//       case 6:
//         Get.to(() => MusicPlayerScreen(), transition: Transition.rightToLeft);
//         break;
//       case 7:
//         List<ConnectivityResult> results = await Connectivity()
//             .checkConnectivity();
//         if (results.contains(ConnectivityResult.none)) {
//           Get.snackbar(
//             "no_internet".tr,
//             "check_connection".tr,
//             snackPosition: SnackPosition.BOTTOM,
//           );
//         } else {
//           Get.to(() => VideoSwitcherScreen(), transition: Transition.fadeIn);
//         }
//         break;
//       case 8:
//         Get.to(() => GasStatusPage(), transition: Transition.rightToLeft);
//         break;
//       case 9:
//         Get.to(() => DashboardScreen(), transition: Transition.rightToLeft);
//         break;
//       case 10:
//         Get.to(() => HospitalStoreScreen(), transition: Transition.rightToLeft);
//         break;
//       case 11:
//         Get.to(
//           () => RoomCleanlinessContainer(),
//           transition: Transition.rightToLeft,
//         );
//         break;
//       case 12:
//         Get.to(() => DialerScreen(), transition: Transition.rightToLeft);
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     _usbSubscription?.cancel();
//     _port?.close();
//     _tabController.dispose();
//     _updateTimer?.cancel();
//     _cardController.dispose();
//     _bgController.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }

//   Widget buildScoreContainer(
//     BuildContext context,
//     String label,
//     IconData icon,
//     bool showTimer, {
//     String? currentValue,
//     required int itemNumber,
//   }) {
//     final stopwatchProvider = Provider.of<StopwatchProvider>(
//       context,
//       listen: false,
//     );
//     final usbProvider = Provider.of<GlobalUsbProvider>(context);

//     bool isMgpsWithFault = itemNumber == 8 && usbProvider.hasSensorFault();

//     return Container(
//       margin: const EdgeInsets.all(0),
//       height: MediaQuery.of(context).size.height * 0.22,
//       width: MediaQuery.of(context).size.width * 0.22,
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isMgpsWithFault ? Colors.red : Colors.white.withOpacity(1.0),
//           width: 3.0,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: Colors.white, size: 35),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 26,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           if (currentValue != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(
//                 currentValue,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           if (showTimer && stopwatchProvider.isRunning)
//             StreamBuilder<int>(
//               stream: stopwatchProvider.stopWatchTimer.rawTime,
//               initialData: stopwatchProvider.stopWatchTimer.rawTime.value,
//               builder: (context, snapshot) {
//                 final displayTime = StopWatchTimer.getDisplayTime(
//                   snapshot.data!,
//                   milliSecond: false,
//                 );
//                 return Text(
//                   displayTime,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainTab() {
//     final usbProvider = Provider.of<GlobalUsbProvider>(context);

//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 180),
//             child: Row(
//               children: List.generate(7, (index) {
//                 if (index.isOdd) {
//                   return Container(
//                     width: 2,
//                     height: 100,
//                     color: Colors.white.withOpacity(0.0),
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                   );
//                 } else {
//                   int itemNumber = (index ~/ 2) + 1;
//                   final icon = [
//                     Icons.thermostat,
//                     Icons.water_drop_outlined,
//                     Icons.lightbulb_outline,
//                     Icons.door_front_door,
//                   ][itemNumber - 1];

//                   return Expanded(
//                     child: GestureDetector(
//                       onTap: () => handleTap(itemNumber),
//                       child: buildScoreContainer(
//                         context,
//                         itemKeys[itemNumber - 1].tr,
//                         icon,
//                         itemNumber == 5,
//                         currentValue: itemNumber == 1
//                             ? (usbProvider.currentTemperature == "--"
//                                   ? "00"
//                                   : '${usbProvider.currentTemperature}°C')
//                             : itemNumber == 2
//                             ? (usbProvider.currentHumidity == "--"
//                                   ? "00"
//                                   : '${usbProvider.currentHumidity}%')
//                             : null,
//                         itemNumber: itemNumber,
//                       ),
//                     ),
//                   );
//                 }
//               }),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             height: 2,
//             width: double.infinity,
//             color: Colors.white.withOpacity(0.0),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 180),
//             child: Row(
//               children: List.generate(7, (index) {
//                 if (index.isOdd) {
//                   return Container(
//                     width: 2,
//                     height: 100,
//                     color: Colors.white.withOpacity(0.0),
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                   );
//                 } else {
//                   int itemNumber = (index ~/ 2) + 5;
//                   final icon = [
//                     Icons.timer,
//                     Icons.music_note,
//                     Icons.videocam,
//                     Icons.map,
//                   ][itemNumber - 5];

//                   return Expanded(
//                     child: GestureDetector(
//                       onTap: () => handleTap(itemNumber),
//                       child: buildScoreContainer(
//                         context,
//                         itemKeys[itemNumber - 1].tr,
//                         icon,
//                         false,
//                         itemNumber: itemNumber,
//                       ),
//                     ),
//                   );
//                 }
//               }),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildSecondTab() {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           const SizedBox(height: 20),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 180),
//             child: Row(
//               children: List.generate(7, (index) {
//                 if (index.isOdd) {
//                   return Container(
//                     width: 2,
//                     height: 100,
//                     color: Colors.white.withOpacity(0.0),
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                   );
//                 } else {
//                   int itemNumber = (index ~/ 2) + 9;
//                   final icon = [
//                     Icons.medical_services,
//                     Icons.store,
//                     Icons.cleaning_services,
//                     Icons.phone,
//                   ][itemNumber - 9];

//                   return Expanded(
//                     child: GestureDetector(
//                       onTap: () => handleTap(itemNumber),
//                       child: buildScoreContainer(
//                         context,
//                         itemKeys[itemNumber - 1].tr,
//                         icon,
//                         false,
//                         itemNumber: itemNumber,
//                       ),
//                     ),
//                   );
//                 }
//               }),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final usbProvider = Provider.of<GlobalUsbProvider>(context);
//     final audioProvider = Provider.of<GlobalUsbProvider>(context);
//     return Scaffold(
//       body: Stack(
//         children: [
//           AnimatedBuilder(
//             animation: _bgController,
//             builder: (context, child) {
//               return CustomPaint(
//                 painter: ClinicalBackgroundPainter(
//                   t: _bgController.value,
//                   particles: _particles,
//                 ),
//                 size: Size.infinite,
//               );
//             },
//           ),
//           Container(
//             width: double.infinity,
//             height: MediaQuery.of(context).size.height,
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 50),
//                   child: Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(left: 20, bottom: 5),
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.black,
//                                   width: 2,
//                                 ),
//                               ),
//                               height: 100,
//                               width: 100,
//                               child: AnalogClock(
//                                 decoration: const BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: Colors.transparent,
//                                 ),
//                                 width: 60,
//                                 height: 60,
//                                 isLive: true,
//                                 hourHandColor: Colors.black,
//                                 minuteHandColor: Colors.black,
//                                 secondHandColor: Colors.red,
//                                 showSecondHand: true,
//                                 showNumbers: true,
//                                 showTicks: true,
//                                 datetime: DateTime.now(),
//                                 textScaleFactor: 1.1,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(),
//                           Text(
//                             "WELCOME TO WIESPL CONTROL PANEL",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(),
//                           Row(
//                             children: [
//                               DropdownButton<String>(
//                                 value: Get.locale?.languageCode ?? 'en',
//                                 icon: const Icon(
//                                   Icons.language,
//                                   color: Colors.white,
//                                 ),
//                                 dropdownColor: Colors.blue[800],
//                                 style: const TextStyle(color: Colors.white),
//                                 underline: Container(),
//                                 items: const [
//                                   DropdownMenuItem(
//                                     value: 'en',
//                                     child: Text(
//                                       'English',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'hi',
//                                     child: Text(
//                                       'हिंदी',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                   DropdownMenuItem(
//                                     value: 'ar',
//                                     child: Text(
//                                       'العربية',
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ],
//                                 onChanged: (String? value) {
//                                   if (value != null) {
//                                     Get.updateLocale(Locale(value));
//                                   }
//                                 },
//                               ),
//                               const SizedBox(width: 12),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 6,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: usbProvider.isConnected
//                                       ? Colors.transparent
//                                       : Colors.red,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),

//                               IconButton(
//                                 onPressed: () async {
//                                   final prefs =
//                                       await SharedPreferences.getInstance();
//                                   await prefs.remove("uniqueCode");
//                                   await prefs.remove("mode");
//                                   Navigator.pushAndRemoveUntil(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => const LoginPage(),
//                                     ),
//                                     (route) => false,
//                                   );
//                                 },
//                                 icon: const Icon(
//                                   Icons.logout_rounded,
//                                   color: Colors.white60,
//                                   size: 30,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Tab Bar
//                 TabBar(
//                   controller: _tabController,
//                   indicator: const BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white,
//                   ),
//                   indicatorSize: TabBarIndicatorSize.label,
//                   labelColor: Colors.transparent,
//                   unselectedLabelColor: Colors.transparent,
//                   tabs: const [
//                     Tab(icon: Icon(Icons.circle, size: 12)),
//                     Tab(icon: Icon(Icons.circle, size: 12)),
//                   ],
//                 ),

//                 // Main Content
//                 Expanded(
//                   child: TabBarView(
//                     controller: _tabController,
//                     children: [_buildMainTab(), _buildSecondTab()],
//                   ),
//                 ),

//                 // Footer
//                 Padding(
//                   padding: const EdgeInsets.all(18.0),
//                   child: Row(
//                     children: [
//                       Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           Center(
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(20.0),
//                               child: BackdropFilter(
//                                 filter: ImageFilter.blur(
//                                   sigmaX: 10.0,
//                                   sigmaY: 10.0,
//                                 ),
//                                 child: Container(
//                                   height: 120,
//                                   width: 270,
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(0.3),
//                                     border: Border.all(
//                                       color: Colors.white.withOpacity(0.2),
//                                       width: 1.0,
//                                     ),
//                                   ),
//                                   child: Center(
//                                     child: Image.asset(
//                                       'assets/image.png',
//                                       height: 100,
//                                       width: 300,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Center(
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(20.0),
//                               child: BackdropFilter(
//                                 filter: ImageFilter.blur(
//                                   sigmaX: 10.0,
//                                   sigmaY: 10.0,
//                                 ),
//                                 child: Container(
//                                   height: 100,
//                                   width: 250,
//                                   decoration: BoxDecoration(
//                                     color: Colors.white.withOpacity(0.3),
//                                     border: Border.all(
//                                       color: Colors.white.withOpacity(0.2),
//                                       width: 1.0,
//                                     ),
//                                   ),
//                                   child: Center(
//                                     child: Image.asset(
//                                       'assets/app_logo-removebg-preview.png',
//                                       height: 100,
//                                       width: 300,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const Spacer(),
//                       Column(
//                         children: [
//                           Text(
//                             "system_status".tr,
//                             style: const TextStyle(
//                               color: Colors.transparent,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               color: usbProvider.isHepaHealthy
//                                   ? Colors.green.withOpacity(0.2)
//                                   : Colors.red.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                 color: usbProvider.isHepaHealthy
//                                     ? Colors.green
//                                     : Colors.red,
//                                 width: 2,
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   usbProvider.isHepaHealthy
//                                       ? Icons.air
//                                       : Icons.warning,
//                                   color: usbProvider.isHepaHealthy
//                                       ? Colors.green
//                                       : Colors.red,
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   usbProvider.hepaStatusText,
//                                   style: TextStyle(
//                                     color: usbProvider.isHepaHealthy
//                                         ? Colors.green
//                                         : Colors.red,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             "system_status".tr,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Consumer<GlobalUsbProvider>(
//                             builder: (context, usbProvider, child) {
//                               bool isSwitching =
//                                   false; // You'll need to add this to your provider

//                               return Stack(
//                                 alignment: Alignment.center,
//                                 children: [
//                                   Switch(
//                                     value: usbProvider.isSwitched,
//                                     activeColor: Colors.lightBlueAccent,
//                                     inactiveThumbColor: Colors.grey.shade300,
//                                     inactiveTrackColor: Colors.grey.shade500,
//                                     onChanged: isSwitching
//                                         ? null
//                                         : (value) async {
//                                             // Disable during operation
//                                             if (!value) {
//                                               bool confirm = await showDialog(
//                                                 context: context,
//                                                 builder: (context) => AlertDialog(
//                                                   title: const Text("Confirm"),
//                                                   content: const Text(
//                                                     "Are you sure you want to turn off the system?",
//                                                   ),
//                                                   actions: [
//                                                     TextButton(
//                                                       onPressed: () =>
//                                                           Navigator.of(
//                                                             context,
//                                                           ).pop(false),
//                                                       child: const Text(
//                                                         "Cancel",
//                                                       ),
//                                                     ),
//                                                     TextButton(
//                                                       onPressed: () =>
//                                                           Navigator.of(
//                                                             context,
//                                                           ).pop(true),
//                                                       child: const Text("Yes"),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               );
//                                               if (!confirm) return;
//                                             }

//                                             // Show loading state
//                                             // usbProvider.setSwitching(true); // Add this method to provider

//                                             try {
//                                               _sendSystemStatusCommand(value);
//                                               // Success handled in provider
//                                             } catch (e) {
//                                               // Show error message
//                                               ScaffoldMessenger.of(
//                                                 context,
//                                               ).showSnackBar(
//                                                 SnackBar(
//                                                   content: Text(
//                                                     "Failed to ${value ? 'start' : 'stop'} system",
//                                                   ),
//                                                   backgroundColor: Colors.red,
//                                                 ),
//                                               );
//                                               // Revert UI state on error
//                                               // usbProvider.updateSystemStatus(!value);
//                                             } finally {
//                                               // usbProvider.setSwitching(false);
//                                             }
//                                           },
//                                   ),

//                                   // Loading indicator overlay
//                                   if (isSwitching)
//                                     Container(
//                                       width: 48,
//                                       height: 48,
//                                       decoration: BoxDecoration(
//                                         color: Colors.black54,
//                                         borderRadius: BorderRadius.circular(24),
//                                       ),
//                                       child: const CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor:
//                                             AlwaysStoppedAnimation<Color>(
//                                               Colors.white,
//                                             ),
//                                       ),
//                                     ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Text(
//                             "system_status".tr,
//                             style: const TextStyle(
//                               color: Colors.transparent,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             icon: Icon(
//                               audioProvider.isMuted
//                                   ? Icons.volume_off
//                                   : Icons.volume_up,
//                               size: 42,
//                               color: Colors.white,
//                             ),
//                             onPressed: _toggleMute,
//                             tooltip: audioProvider.isMuted ? "Unmute" : "Mute",
//                           ),
//                         ],
//                       ),
//                       const SizedBox(width: 12),
//                       // IconButton(
//                       //   icon: const Icon(
//                       //     Icons.refresh,
//                       //     size: 42,
//                       //     color: Colors.white,
//                       //   ),
//                       //   onPressed: () {
//                       //     _reconnectUsb();
//                       //     usbProvider.refreshHepaStatus();
//                       //     Get.snackbar(
//                       //       "refreshing".tr,
//                       //       "",
//                       //       snackPosition: SnackPosition.BOTTOM,
//                       //     );
//                       //   },
//                       // ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Keep all your existing helper classes below (they remain unchanged):

// class _AnimatedCounter extends StatefulWidget {
//   final String value;
//   const _AnimatedCounter({Key? key, required this.value}) : super(key: key);

//   @override
//   State<_AnimatedCounter> createState() => _AnimatedCounterState();
// }

// class _AnimatedCounterState extends State<_AnimatedCounter>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   String _currentValue = "0";

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 420),
//     );
//     _updateValue();
//   }

//   @override
//   void didUpdateWidget(covariant _AnimatedCounter oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.value != widget.value) {
//       _updateValue();
//     }
//   }

//   void _updateValue() {
//     final start = double.tryParse(_currentValue) ?? 0.0;
//     final end = double.tryParse(widget.value) ?? 0.0;
//     _animation = Tween<double>(
//       begin: start,
//       end: end,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
//     _controller.forward(from: 0);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         _currentValue = _animation.value.toStringAsFixed(
//           _animation.value.truncateToDouble() == _animation.value ? 0 : 1,
//         );
//         return Text(
//           _currentValue,
//           style: const TextStyle(
//             fontSize: 30,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         );
//       },
//     );
//   }
// }

// /// A thin separator used inside the card
// class SimpleSeparatorPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.14)
//       ..strokeWidth = 1;
//     canvas.drawLine(
//       Offset(0, size.height / 2),
//       Offset(size.width, size.height / 2),
//       paint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant SimpleSeparatorPainter oldDelegate) => false;
// }

// /// particles for subtle texture (no glow)
// class MedicalParticle {
//   double x, y, size, vx, vy, opacity;
//   final Random _random;

//   MedicalParticle(this._random)
//     : x = _random.nextDouble(),
//       y = _random.nextDouble(),
//       size = _random.nextDouble() * 2 + 0.6,
//       vx = _random.nextDouble() * 0.0008 - 0.0004,
//       vy = _random.nextDouble() * 0.0008 - 0.0004,
//       opacity = 0.06 + _random.nextDouble() * 0.06;

//   void update(double t) {
//     // very slow drifting with slight sinus wobble
//     x += vx + 0.0002 * sin(t * 2 * pi + x * 10);
//     y += vy + 0.0002 * cos(t * 2 * pi + y * 10);

//     if (x < -0.02) x = 1.02;
//     if (x > 1.02) x = -0.02;
//     if (y < -0.02) y = 1.02;
//     if (y > 1.02) y = -0.02;
//   }
// }

// /// Clinical background painter: premium gradient, faint grid, subtle particles,
// /// diagonal light rays, glowing circles, and ECG waveform.
// class ClinicalBackgroundPainter extends CustomPainter {
//   final double t; // 0..1
//   final List<MedicalParticle> particles;
//   ClinicalBackgroundPainter({required this.t, required this.particles});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rect = Offset.zero & size;

//     // === 1) Dynamic premium gradient ===
//     final gT = (sin(t * 2 * pi) + 1) / 2 * 0.2;
//     final gradient = LinearGradient(
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//       colors: [
//         Color.lerp(const Color(0xFF0F3D3E), const Color(0xFF2C6975), gT)!,
//         Color.lerp(const Color(0xFF144552), const Color(0xFF205375), gT)!,
//         Color.lerp(const Color(0xFF16324F), const Color(0xFF112031), gT)!,
//       ],
//     );
//     canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

//     // === 2) Faint futuristic grid ===
//     final gridPaint = Paint()
//       ..color = Colors.white.withOpacity(0.02)
//       ..strokeWidth = 0.5;
//     const double step = 40;
//     for (double x = 0; x < size.width; x += step) {
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
//     }
//     for (double y = 0; y < size.height; y += step) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
//     }

//     // === 3) Diagonal light ray ===
//     final rayPaint = Paint()
//       ..shader = LinearGradient(
//         colors: [Colors.white.withOpacity(0.07), Colors.transparent],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ).createShader(rect);

//     final rayPath = Path()
//       ..moveTo(size.width * (0.15 + t * 0.05), 0)
//       ..lineTo(size.width * (0.35 + t * 0.05), 0)
//       ..lineTo(size.width * (0.75 + t * 0.05), size.height)
//       ..lineTo(size.width * (0.55 + t * 0.05), size.height)
//       ..close();
//     canvas.drawPath(rayPath, rayPaint);

//     // === 4) Glowing circles (scanner-style highlights) ===
//     final glowPaint = Paint()
//       ..color = Colors.cyanAccent.withOpacity(0.12)
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

//     canvas.drawCircle(
//       Offset(size.width * 0.25, size.height * (0.35 + 0.05 * sin(t * 2 * pi))),
//       120,
//       glowPaint,
//     );
//     canvas.drawCircle(
//       Offset(size.width * 0.75, size.height * (0.65 + 0.05 * cos(t * 2 * pi))),
//       100,
//       glowPaint,
//     );

//     // === 5) Subtle particles ===
//     final dotPaint = Paint()..style = PaintingStyle.fill;
//     for (var p in particles) {
//       p.update(t);
//       dotPaint.color = Colors.white.withOpacity(p.opacity);
//       final cx = p.x * size.width;
//       final cy = p.y * size.height;
//       canvas.drawCircle(Offset(cx, cy), p.size, dotPaint);
//     }

//     // === 6) ECG waveform ===
//     _drawECG(canvas, size);
//   }

//   void _drawECG(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.transparent
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.4
//       ..strokeCap = StrokeCap.round;

//     final path = Path();
//     final amplitude = size.height * 0.03;
//     final baselineY = size.height * 0.22;

//     // Static offset (no animation)
//     final offsetX =
//         0.0; // Set a static value instead of using phase for animation

//     bool first = true;
//     for (double x = -size.width; x <= size.width * 2; x += 4) {
//       final local = (x / 80.0);
//       final beat = sin(local * 2 * pi);
//       final spike = exp(-pow((local % 6.0) - 3.0, 2)) * 6.0;
//       final yOffset = beat * amplitude * 0.6 + (spike * amplitude * 0.12);

//       final px = x - offsetX % (size.width * 1.2);
//       final py = baselineY + yOffset;

//       if (first) {
//         path.moveTo(px, py);
//         first = false;
//       } else {
//         path.lineTo(px, py);
//       }
//     }
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant ClinicalBackgroundPainter oldDelegate) => true;
// }
