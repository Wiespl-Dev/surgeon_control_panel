import 'package:flutter/material.dart';
import 'package:surgeon_control_panel/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ORStatusMonitor extends StatefulWidget {
  @override
  State<ORStatusMonitor> createState() => _ORStatusMonitorState();
}

class _ORStatusMonitorState extends State<ORStatusMonitor> {
  bool defumigation = false;
  bool systemOn = false;
  bool nightMode = false;
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("uniqueCode");
    await prefs.remove("mode");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CA1AF), Color.fromARGB(255, 103, 135, 167)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              children: [
                /// Top bar (Logo + settings)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.add_ic_call_outlined, color: Colors.transparent),
                    Image.asset(
                      "assets/app_logo-removebg-preview.png",
                      height: 85,
                    ),

                    IconButton(
                      onPressed: () {
                        _logout();
                      },
                      icon: Icon(
                        Icons.logout,
                        size: 26,
                        color: const Color.fromARGB(132, 255, 255, 255),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                /// Title
                const Text(
                  "OR Status Monitor",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 25),

                /// Main status card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white30, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(44, 0, 0, 0),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// Top row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statusTile(
                              title: "16 Sept 2025",
                              value: "12:07 pm",
                              alignRight: false,
                            ),
                            _statusTile(
                              title: "Room Pressure",
                              value: "000",
                              alignRight: true,
                            ),
                          ],
                        ),

                        const Divider(
                          color: Colors.white54,
                          thickness: 1,
                          height: 40,
                        ),

                        /// Bottom row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statusTile(
                              title: "Temperature",
                              value: "0.0°C",
                              alignRight: false,
                            ),
                            _statusTile(
                              title: "R/H",
                              value: "0%",
                              alignRight: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Toggle buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _customToggle(
                      label: "Defumigation Mode",
                      value: defumigation,
                      onChanged: (val) => setState(() => defumigation = val),
                    ),
                    _customToggle(
                      label: "System ON/OFF",
                      value: systemOn,
                      onChanged: (val) => setState(() => systemOn = val),
                    ),
                    _customToggle(
                      label: "Night Mode",
                      value: nightMode,
                      onChanged: (val) => setState(() => nightMode = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable status tile widget
  Widget _statusTile({
    required String title,
    required String value,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  /// Custom toggle button widget
  Widget _customToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 55,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? Colors.greenAccent : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
