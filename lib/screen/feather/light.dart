import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String esp32Ip = "192.168.0.232"; // Change to your ESP32 IP
  final TextEditingController _tempController = TextEditingController(
    text: "25.0",
  );
  final TextEditingController _humController = TextEditingController(
    text: "55.0",
  );
  final TextEditingController _ledNumController = TextEditingController(
    text: "1",
  );
  final TextEditingController _ledValueController = TextEditingController(
    text: "255",
  );

  String _response = "Not connected";
  String _sensorData = "No data received";
  double _currentTemp = 0.0;
  double _currentHum = 0.0;
  int _emptyGasCount = 0;
  List<String> _emptyGases = [];
  Timer? _sensorUpdateTimer;
  Timer? _gasStatusTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _startSensorUpdates();
    _startGasStatusUpdates();
  }

  @override
  void dispose() {
    _sensorUpdateTimer?.cancel();
    _gasStatusTimer?.cancel();
    super.dispose();
  }

  void _startSensorUpdates() {
    _sensorUpdateTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _getSensorData();
    });
  }

  void _startGasStatusUpdates() {
    _gasStatusTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _getGasStatus();
    });
  }

  Future<void> _sendCommand(String command) async {
    try {
      final response = await http.post(
        Uri.parse('http://$esp32Ip/api/command'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'command': command}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _response = "Success: ${response.body}";
          _isConnected = true;
        });
      } else {
        setState(() {
          _response = "Error: ${response.statusCode}";
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _response = "Exception: $e";
        _isConnected = false;
      });
    }
  }

  Future<void> _getSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32Ip/api/sensor-data'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sensorData =
              "Temp: ${data['temperature']}°C, Hum: ${data['humidity']}%";
          _currentTemp = data['temperature']?.toDouble() ?? 0.0;
          _currentHum = data['humidity']?.toDouble() ?? 0.0;
          _isConnected = true;
        });
      } else {
        setState(() {
          _sensorData = "Error: ${response.statusCode}";
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _sensorData = "Exception: $e";
        _isConnected = false;
      });
    }
  }

  Future<void> _getGasStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32Ip/api/gas-status'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _emptyGasCount = data['empty_gas_count'] ?? 0;
          _emptyGases = List<String>.from(data['empty_gases'] ?? []);
          _isConnected = true;
        });
      }
    } catch (e) {
      setState(() {
        _emptyGasCount = 0;
        _emptyGases = [];
      });
    }
  }

  Future<void> _getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32Ip/api/status'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _response =
              "Status: Temp: ${data['temperature']}°C, Hum: ${data['humidity']}%";
          _currentTemp = data['temperature']?.toDouble() ?? 0.0;
          _currentHum = data['humidity']?.toDouble() ?? 0.0;
          _emptyGasCount = data['empty_gas_count'] ?? 0;
          _emptyGases = List<String>.from(data['empty_gases'] ?? []);
          _isConnected = true;
        });
      } else {
        setState(() {
          _response = "Error: ${response.statusCode}";
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _response = "Exception: $e";
        _isConnected = false;
      });
    }
  }

  Future<void> _testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32Ip/'),
        headers: <String, String>{'Content-Type': 'text/plain'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _response = "Connected: ${response.body}";
          _isConnected = true;
        });
        // Refresh all data after successful connection
        _getSensorData();
        _getGasStatus();
      } else {
        setState(() {
          _response = "Error: ${response.statusCode}";
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _response = "Connection failed: $e";
        _isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gas Monitoring Control'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _testConnection),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Connection Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _isConnected
                              ? Icons.wifi
                              : Icons
                                    .wifi_off, // FIXED: Changed Icomponents to Icons
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          _isConnected ? 'Connected to ESP32' : 'Disconnected',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _testConnection,
                      child: Text('Test Connection'),
                    ),
                  ],
                ),
              ),
            ),

            // Current Sensor Data
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Sensor Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Temperature', style: TextStyle(fontSize: 16)),
                            Text(
                              '${_currentTemp.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Humidity', style: TextStyle(fontSize: 16)),
                            Text(
                              '${_currentHum.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(_sensorData, style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),

            // Gas Cylinder Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Gas Cylinder Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Empty Cylinders: $_emptyGasCount',
                      style: TextStyle(
                        fontSize: 16,
                        color: _emptyGasCount > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (_emptyGases.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Empty Gases:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _emptyGases
                                .map(
                                  (gas) => Text(
                                    '• $gas',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      )
                    else
                      Text(
                        'All gas cylinders are full',
                        style: TextStyle(color: Colors.green),
                      ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _getGasStatus,
                      child: Text('Refresh Gas Status'),
                    ),
                  ],
                ),
              ),
            ),

            // Temperature Control
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Temperature Control', //925010012799371
                      style: TextStyle(
                        //
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _tempController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter temperature (15-35)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          _sendCommand('SETT${_tempController.text}'),
                      child: Text('Set Temperature'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Humidity Control
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Humidity Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _humController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter humidity (30-80)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () =>
                          _sendCommand('SETH${_humController.text}'),
                      child: Text('Set Humidity'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Night Mode
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Night Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _sendCommand('NIGHT ON'),
                          child: Text('Night Mode ON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _sendCommand('NIGHT OFF'),
                          child: Text('Night Mode OFF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // LED Control
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'LED Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ledNumController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'LED # (1-10)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ledValueController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Value (0-255)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              _sendCommand('LED${_ledNumController.text} ON'),
                          child: Text('LED ON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _sendCommand('LED${_ledNumController.text} OFF'),
                          child: Text('LED OFF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _sendCommand(
                            'LED${_ledNumController.text} SET${_ledValueController.text}',
                          ),
                          child: Text('Set Intensity'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // System Control
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'System Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _getStatus,
                          child: Text('Get Full Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _getSensorData,
                          child: Text('Refresh Sensors'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Response
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Command Response',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _response,
                      style: TextStyle(
                        fontSize: 14,
                        color: _response.contains("Error")
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
