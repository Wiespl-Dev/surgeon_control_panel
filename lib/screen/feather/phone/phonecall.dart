import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RelayControlApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Relay Control',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(
          0xFF1A1A2E,
        ), // Dark theme background
      ),
      home: RelayControlScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RelayControlScreen extends StatefulWidget {
  @override
  _RelayControlScreenState createState() => _RelayControlScreenState();
}

class _RelayControlScreenState extends State<RelayControlScreen> {
  final TextEditingController _ipController = TextEditingController();
  String _statusMessage = 'Enter ESP32 IP and connect';
  String _currentIp = '';
  bool _isConnected = false;
  String _currentMode = 'UP'; // Track current mode: UP or OFF

  // Function to control a relay
  Future<void> _controlRelay(int relayNumber) async {
    if (_currentIp.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter ESP32 IP address first';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Activating Relay $relayNumber...';
    });

    try {
      // Send the actual relay number (0-9) as expected by the ESP code
      final response = await http
          .get(
            Uri.parse('http://$_currentIp/control?relay=$relayNumber'),
            headers: {'Connection': 'close'},
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = response.body;
        });

        // Clear status after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Ready to control relays';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage =
              'Error: Server returned status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // Function to control the dial relay
  Future<void> _controlDialRelay() async {
    if (_currentIp.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter ESP32 IP address first';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Activating Dial Relay...';
    });

    try {
      final response = await http
          .get(
            Uri.parse('http://$_currentIp/dial'),
            headers: {'Connection': 'close'},
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = response.body;
        });

        // Clear status after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Ready to control relays';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage =
              'Error: Server returned status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // Function to set UP mode
  Future<void> _setUpMode() async {
    if (_currentIp.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter ESP32 IP address first';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Setting UP mode...';
    });

    try {
      final response = await http
          .get(
            Uri.parse('http://$_currentIp/up'),
            headers: {'Connection': 'close'},
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = response.body;
          _currentMode = 'UP';
        });

        // Clear status after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'UP mode activated';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage =
              'Error: Server returned status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // Function to set OFF mode
  Future<void> _setOffMode() async {
    if (_currentIp.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter ESP32 IP address first';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Setting OFF mode...';
    });

    try {
      final response = await http
          .get(
            Uri.parse('http://$_currentIp/off'),
            headers: {'Connection': 'close'},
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = response.body;
          _currentMode = 'OFF';
        });

        // Clear status after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'OFF mode activated';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage =
              'Error: Server returned status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // Function to test connection
  Future<void> _testConnection() async {
    if (_ipController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter an IP address';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Connecting...';
      _currentIp = _ipController.text;
    });

    try {
      final response = await http
          .get(
            Uri.parse('http://$_currentIp/status'),
            headers: {'Connection': 'close'},
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Parse mode from response
        final responseText = response.body;
        if (responseText.contains('Mode:UP')) {
          _currentMode = 'UP';
        } else if (responseText.contains('Mode:OFF')) {
          _currentMode = 'OFF';
        }

        setState(() {
          _isConnected = true;
          _statusMessage =
              'Connected successfully! Current mode: $_currentMode';
        });
      } else {
        setState(() {
          _isConnected = false;
          _statusMessage =
              'Connection failed: Server returned status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred background layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1E2C),
                  const Color(0xFF2D2D44),
                  const Color(0xFF1E1E2C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),

          // Main scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Main Title
                const Text(
                  'WIESPL CALL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE0F7FA),
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Connection Section
                _buildGlassmorphismCard(
                  child: Column(
                    children: [
                      // IP Address Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ipController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'ESP32 IP Address',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                hintText: '192.168.1.100',
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                prefixIcon: const Icon(
                                  Icons.wifi,
                                  color: Colors.cyanAccent,
                                  size: 20, // Reduced icon size
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _testConnection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, // Reduced horizontal padding
                                vertical: 12, // Reduced vertical padding
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Connect',
                              style: TextStyle(fontSize: 14),
                            ), // Reduced font size
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Message
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isConnected
                                ? Colors.green.shade400
                                : Colors.red.shade400,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isConnected
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: _isConnected
                                  ? Colors.green.shade400
                                  : Colors.red.shade400,
                              size: 20, // Reduced icon size
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isConnected
                                      ? Colors.green.shade400
                                      : Colors.red.shade400,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14, // Reduced font size
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mode Control Section
                _buildGlassmorphismCard(
                  child: Column(
                    children: [
                      const Text(
                        'OPERATION MODE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14, // Reduced font size
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildModeButton(
                              'UP Mode',
                              'UP',
                              Icons.arrow_upward,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModeButton(
                              'OFF Mode',
                              'OFF',
                              Icons.power_off,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Relay Buttons Grid (0-9)
                _buildGlassmorphismCard(
                  child: Column(
                    children: [
                      const Text(
                        'RELAY CONTROLS (0-9)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14, // Reduced font size
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10, // Reduced spacing
                        mainAxisSpacing: 10, // Reduced spacing
                        childAspectRatio: 1.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // First row: 1, 2, 3
                          _buildRelayButton(
                            0,
                            '1',
                          ), // Button 1 controls relay 0
                          _buildRelayButton(
                            1,
                            '2',
                          ), // Button 2 controls relay 1
                          _buildRelayButton(
                            2,
                            '3',
                          ), // Button 3 controls relay 2
                          // Second row: 4, 5, 6
                          _buildRelayButton(
                            3,
                            '4',
                          ), // Button 4 controls relay 3
                          _buildRelayButton(
                            4,
                            '5',
                          ), // Button 5 controls relay 4
                          _buildRelayButton(
                            5,
                            '6',
                          ), // Button 6 controls relay 5
                          // Third row: 7, 8, 9
                          _buildRelayButton(
                            6,
                            '7',
                          ), // Button 7 controls relay 6
                          _buildRelayButton(
                            7,
                            '8',
                          ), // Button 8 controls relay 7
                          _buildRelayButton(
                            8,
                            '9',
                          ), // Button 9 controls relay 8
                          // Fourth row: *, 0, #
                          _buildSpecialButton('*', Colors.amber),
                          _buildRelayButton(
                            9,
                            '0',
                          ), // Button 0 controls relay 9
                          _buildSpecialButton('#', Colors.purpleAccent),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Dial Button
                _buildGlassmorphismCard(
                  child: Column(
                    children: [
                      const Text(
                        'DIAL CONTROL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14, // Reduced font size
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          onPressed: _isConnected ? _controlDialRelay : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.6),
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(
                              20,
                            ), // Reduced padding
                            minimumSize: const Size(
                              80,
                              80,
                            ), // Reduced minimum size
                            elevation: 10,
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.adjust, size: 24), // Reduced icon size
                              SizedBox(height: 4),
                              Text(
                                'DIAL',
                                style: TextStyle(
                                  fontSize: 14, // Reduced font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Instructions
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Text(
                    'Note: Relays 0-9: 500ms pulse | Dial: 1s pulse | Mode: Controls GPIO 15,4,5',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for consistent button style
  Widget _buildModeButton(String text, String mode, IconData icon) {
    bool isSelected = _currentMode == mode;
    return ElevatedButton(
      onPressed: _isConnected
          ? (mode == 'UP' ? _setUpMode : _setOffMode)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.cyan : Colors.blueGrey.shade800,
        foregroundColor: isSelected ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ), // Reduced vertical padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18), // Reduced icon size
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14)), // Reduced font size
        ],
      ),
    );
  }

  // Helper method for relay buttons - now with circular shape
  Widget _buildRelayButton(int relayNumber, String displayText) {
    return Container(
      margin: EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: _isConnected ? () => _controlRelay(relayNumber) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              relayNumber ==
                  9 // 0 button is relay 9
              ? Colors.deepOrangeAccent
              : Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
          padding: EdgeInsets.all(16),
          elevation: 8,
        ),
        child: Text(
          displayText,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Helper method for special buttons (* and #)
  Widget _buildSpecialButton(String symbol, Color color) {
    return Container(
      margin: EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: null, // These buttons are not functional
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.6),
          foregroundColor: Colors.white,
          shape: CircleBorder(),
          padding: EdgeInsets.all(16),
          elevation: 8,
        ),
        child: Text(
          symbol,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Helper method for glassmorphism card effect
  Widget _buildGlassmorphismCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
