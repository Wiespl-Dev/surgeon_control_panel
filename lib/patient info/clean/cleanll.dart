import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- Constants and Theme Setup ---
const Color primaryColor = Color(0xFF007AFF); // Apple Blue
const Color successColor = Colors.green;
const Color warningColor = Colors.red;
const Color idleColor = Colors.blueGrey;

class CleanControlApp extends StatelessWidget {
  const CleanControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OT Cleaning Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Set a clean, consistent font
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          color: primaryColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Global button theme for a modern look
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const CleanControlPage(),
    );
  }
}

class CleanControlPage extends StatefulWidget {
  const CleanControlPage({super.key});

  @override
  State<CleanControlPage> createState() => _CleanControlPageState();
}

class _CleanControlPageState extends State<CleanControlPage> {
  // Use a mock IP for the environment
  final String espIp = "192.168.0.157";
  bool cleaning = false;
  bool humanDetected = false;
  String statusText = "Initializing...";
  Timer? statusTimer;
  Timer? cleanTimer;

  // Track connection status separately
  bool isConnected = true;

  Future<String> sendCommand(String endpoint) async {
    try {
      final url = Uri.parse("http://$espIp/$endpoint");
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        setState(() {
          statusText = response.body.trim(); // Use trim for clean data
          isConnected = true;
        });
        return response.body.trim();
      }
    } on TimeoutException {
      setState(() {
        statusText = "Error: Connection Timed Out";
        isConnected = false;
      });
    } catch (e) {
      setState(() {
        statusText = "Error: ESP not reachable";
        isConnected = false;
      });
    }
    return "";
  }

  Future<void> getStatus() async {
    bool previouslyDetected = humanDetected;
    try {
      final url = Uri.parse("http://$espIp/status");
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = response.body.trim();
        setState(() {
          isConnected = true;
          cleaning = data.contains("CLEANING_ON");
          humanDetected = data.contains("HUMAN_PRESENT");
          statusText = data;
        });

        if (humanDetected && !previouslyDetected) {
          // Show alert only when detection is new
          showHumanAlert();
        }
      } else {
        setState(() {
          isConnected = false;
          statusText = "ESP Disconnected (Code: ${response.statusCode})";
        });
      }
    } on TimeoutException {
      setState(() {
        isConnected = false;
        statusText = "ESP Disconnected (Timeout)";
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        statusText = "ESP Disconnected";
      });
    }

    // Original separate check is removed, as combined '/status' endpoint is preferred
    // and safer for state management.
  }

  void showHumanAlert() {
    // Show a persistent dialog style snackbar for critical alert
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.dangerous, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "HUMAN DETECTED! Cleaning stopped immediately for safety.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: warningColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void startCleaning(int seconds) async {
    // User interface confirmation before starting
    if (humanDetected) {
      setState(() {
        statusText = "Cannot start - Human detected!";
      });
      showHumanAlert();
      return;
    }

    String response = await sendCommand("clean-on");

    if (response.contains("CLEANING STARTED")) {
      setState(() {
        cleaning = true;
        statusText = "Cleaning started. Duration: ${seconds}s";
      });

      // Start polling status
      statusTimer?.cancel();
      statusTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => getStatus(),
      );

      // Timer to auto-stop cleaning
      cleanTimer?.cancel();
      cleanTimer = Timer(Duration(seconds: seconds), () async {
        await sendCommand("clean-off");
        statusTimer?.cancel(); // Stop polling after auto-stop

        setState(() {
          cleaning = false;
          statusText = "Cleaning completed (auto-stop)";
        });
      });
    } else {
      // Catch rejection from ESP32 like "HUMAN DETECTED"
      setState(() {
        cleaning = false;
        statusText = "Command rejected: $response";
      });
    }
  }

  void stopCleaning() async {
    await sendCommand("clean-off");
    setState(() {
      cleaning = false;
      statusText = "Stopped manually";
    });
    cleanTimer?.cancel();
    statusTimer?.cancel(); // Stop polling
  }

  @override
  void initState() {
    super.initState();
    // Initial status check to populate UI
    getStatus();
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    cleanTimer?.cancel();
    super.dispose();
  }

  // --- New Helper Widgets for Clean UI ---

  Color get currentColor {
    if (humanDetected) return warningColor;
    if (cleaning) return successColor;
    if (!isConnected) return Colors.grey;
    return idleColor;
  }

  String get currentStatusText {
    if (!isConnected) return "SYSTEM OFFLINE";
    if (humanDetected) return "HUMAN PRESENCE DETECTED";
    if (cleaning) return "CLEANING IN PROGRESS";
    return "SYSTEM IDLE";
  }

  IconData get currentIcon {
    if (humanDetected) return Icons.person_off_rounded;
    if (cleaning) return Icons.person_off_rounded;
    return Icons.power_settings_new_rounded;
  }

  Widget _buildStatusIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: currentColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: currentColor, width: 8),
        boxShadow: [
          BoxShadow(
            color: currentColor.withOpacity(0.4),
            blurRadius: cleaning ? 20.0 : 5.0,
            spreadRadius: cleaning ? 5.0 : 0.0,
          ),
        ],
      ),
      child: Center(child: Icon(currentIcon, size: 100, color: currentColor)),
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          currentStatusText,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: currentColor,
          ),
        ),
        const SizedBox(height: 10),
        // Dedicated area for the detailed status response from ESP32
        Container(
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            statusText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: const Text(
            "START CLEANING (60s)",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: successColor,
            disabledBackgroundColor: successColor.withOpacity(0.3),
          ),
          // Disable if cleaning, human is detected, or not connected
          onPressed: cleaning || humanDetected || !isConnected
              ? null
              : () => startCleaning(60),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.stop_rounded, color: Colors.white),
          label: const Text(
            "STOP CLEANING",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: warningColor,
            disabledBackgroundColor: warningColor.withOpacity(0.3),
          ),
          // Disable if not cleaning or not connected
          onPressed: cleaning && isConnected ? stopCleaning : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("OT Cleaning Control Panel"),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Icon(
              isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isConnected ? Colors.white : Colors.yellowAccent,
              size: 24,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Main Status Card
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [_buildStatusIndicator(), _buildStatusText()],
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Control Buttons
              _buildControls(),

              const SizedBox(height: 50),

              // Footer / IP Info
              Text(
                "Connected to ESP32 at: $espIp",
                style: TextStyle(
                  fontSize: 14,
                  color: isConnected ? Colors.blueGrey : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
