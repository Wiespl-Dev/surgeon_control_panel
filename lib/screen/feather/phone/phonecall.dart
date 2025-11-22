import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  // Dialer UI State
  String _phoneNumber = '';

  // IoT/Relay Control State (Integrated from RelayControlApp)
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.4.1',
  ); // Optional default IP
  String _statusMessage = 'Enter and connect to ESP32';
  String _currentIp = '';
  bool _isConnected = false;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  // -------------------------
  // 📞 IoT/Relay Control Functions
  // -------------------------

  // Function to control a single digit relay (0-9)
  Future<void> _controlRelay(int relayNumber) async {
    if (_currentIp.isEmpty || !_isConnected) {
      setState(() {
        _statusMessage = 'Connect to ESP32 first';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Activating Relay $relayNumber...';
    });

    try {
      final response = await http
          .get(
            Uri.parse('http://$_currentIp/control?relay=$relayNumber'),
            headers: const {'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Relay $relayNumber: ${response.body}';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Ready to dial';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage =
              'Error Relay: Server returned status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection Error: ${e.toString()}';
      });
    }
  }

  // Function to control the dedicated dial relay (e.g., initiating the sequence)
  Future<void> _controlDialRelay() async {
    if (_currentIp.isEmpty || !_isConnected) {
      setState(() {
        _statusMessage = 'Connect to ESP32 first';
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
            headers: const {'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Dial Relay: ${response.body}';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Ready to dial';
            });
          }
        });
      } else {
        setState(() {
          _statusMessage =
              'Error Dial: Server returned status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection Error: ${e.toString()}';
      });
    }
  }

  // Function to test connection and set up the IP
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
            headers: const {'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
          _statusMessage = 'Connected successfully! Ready to dial 📞';
        });
      } else {
        setState(() {
          _isConnected = false;
          _statusMessage =
              'Connection failed: Status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }

  // -------------------------
  // 📱 Dialer Logic & UI Helpers
  // -------------------------

  void _inputNumber(String number) {
    setState(() {
      _phoneNumber += number;
    });
  }

  void _deleteNumber() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  void _initiateCall() {
    if (_phoneNumber.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting dial sequence...')),
      );

      // Triggers the special dial pulse relay
      _controlDialRelay();

      // Optionally clear the number after initiating the sequence
      setState(() {
        _phoneNumber = '';
      });
    }
  }

  // Helper to build a single button on the keypad
  Widget _buildDialerButton(
    String text, {
    String? subText,
    bool isCallButton = false,
  }) {
    // Logic to map digit (1-9, 0) to relay number (0-8, 9)
    int? relayNumber;
    if (text.length == 1 && int.tryParse(text) != null) {
      int digit = int.parse(text);
      if (digit >= 1 && digit <= 9) {
        relayNumber = digit - 1;
      } else if (digit == 0) {
        relayNumber = 9;
      }
    }

    VoidCallback? onTapFunction;
    if (isCallButton) {
      onTapFunction = _isConnected && _phoneNumber.isNotEmpty
          ? _initiateCall
          : null;
    } else if (relayNumber != null) {
      onTapFunction = _isConnected
          ? () {
              _inputNumber(text);
              _controlRelay(relayNumber!);
            }
          : null;
    } else {
      // For * and #, only update the display
      onTapFunction = () => _inputNumber(text);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isCallButton
            ? FloatingActionButton(
                heroTag: text,
                onPressed: onTapFunction,
                backgroundColor: _isConnected && _phoneNumber.isNotEmpty
                    ? Colors.green
                    : Colors.grey,
                child: const Icon(Icons.call, size: 30),
              )
            : InkWell(
                onTap: onTapFunction,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  height: 75,
                  width: 75,
                  decoration: BoxDecoration(
                    color: Colors.white10.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (subText != null)
                          Text(
                            subText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // Helper for the connection control panel
  Widget _buildConnectionPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _isConnected
                ? Colors.green.shade400.withOpacity(0.5)
                : Colors.red.shade400.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'ESP32 IP',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: '192.168.x.x',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(
                        Icons.wifi,
                        color: _isConnected ? Colors.green : Colors.cyanAccent,
                        size: 18,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.green : Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isConnected
                    ? Colors.green.shade400
                    : Colors.red.shade400,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // 🎨 Main Widget Build
  // -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // 1. Background Image with Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/irwan-rbDE93-0hHs-unsplash.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. Dark Overlay for better readability
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          // 3. Blur Effect (Glassmorphism)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 4. Main Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // AppBar space
                AppBar(
                  title: Text(
                    'WIESPL CALL (IoT Dialer)',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 80,
                ),

                // Connection Panel
                _buildConnectionPanel(),

                // Phone Number Display Area
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: SelectableText(
                    _phoneNumber.isEmpty ? 'Enter a number' : _phoneNumber,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w300,
                      color: _phoneNumber.isEmpty
                          ? Colors.white70
                          : Colors.white,
                    ),
                  ),
                ),

                // Keypad Grid
                Column(
                  children: <Widget>[
                    // Row 1: 1, 2, 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildDialerButton('1', subText: ''),
                        _buildDialerButton('2', subText: ''),
                        _buildDialerButton('3', subText: ''),
                      ],
                    ),
                    // Row 2: 4, 5, 6
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildDialerButton('4', subText: ''),
                        _buildDialerButton('5', subText: ''),
                        _buildDialerButton('6', subText: ''),
                      ],
                    ),
                    // Row 3: 7, 8, 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildDialerButton('7', subText: ''),
                        _buildDialerButton('8', subText: ''),
                        _buildDialerButton('9', subText: ''),
                      ],
                    ),
                    // Row 4: *, 0, #
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildDialerButton('*', subText: ''),
                        _buildDialerButton('0', subText: ''),
                        _buildDialerButton('#', subText: ''),
                      ],
                    ),
                  ],
                ),

                // Action Buttons (Call & Backspace)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, top: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      // Placeholder for alignment
                      const SizedBox(width: 75),

                      // Call Button (Triggers _controlDialRelay)
                      _buildDialerButton('Call', isCallButton: true),

                      // Backspace/Delete Button
                      SizedBox(
                        width: 75,
                        child: IconButton(
                          icon: const Icon(Icons.backspace, size: 30),
                          color: _phoneNumber.isEmpty
                              ? Colors.transparent
                              : Colors.white70,
                          onPressed: _phoneNumber.isEmpty
                              ? null
                              : _deleteNumber,
                        ),
                      ),
                    ],
                  ),
                ),

                // Note/Instructions
                const Padding(
                  padding: EdgeInsets.only(bottom: 20, left: 10, right: 10),
                  child: Text(
                    'Note: Digits pulse Relays 0-9 (0 maps to Relay 9). Call button pulses Dial relay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
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
}
