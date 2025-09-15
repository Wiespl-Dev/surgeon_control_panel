import 'package:flutter/material.dart';
import 'package:surgeon_control_panel/patient info/dashboard_items/patient_list.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard/history/sur_history.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard/ser_setting/ser_settings.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard/sur/sur_screen.dart';
import 'package:surgeon_control_panel/patient%20info/dashboard_items/user/user_list.dart';

class DashboardScreen extends StatelessWidget {
  final List<_DashboardItem> items = [
    _DashboardItem(
      "Patient List",
      Icons.people,
      HospitalPortalApp(),
    ), // ✅ Use directly
    _DashboardItem("Surgery", Icons.local_hospital, SurgeryScreen()),
    _DashboardItem("Surgery History", Icons.history, SurgeryHistoryPage()),
    _DashboardItem("Settings", Icons.settings, SurgerySettingsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double itemHeight = (screenHeight - kToolbarHeight - 100) / 2;
    double itemWidth = screenWidth / 2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 112, 143, 214),
              Color.fromARGB(255, 157, 102, 228),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    "WIESPL PI DISHBOARD",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.abc, color: Colors.transparent),
                ],
              ),
              Expanded(
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: itemWidth / itemHeight,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item.screen),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(0),
                        height: MediaQuery.of(context).size.height * 0.22,
                        width: MediaQuery.of(context).size.width * 0.22,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(1.0),
                            width: 3.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: screenWidth * 0.12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Widget screen;

  _DashboardItem(this.title, this.icon, this.screen);
}

/// -------- Screens --------

// class SurgeryScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Surgery")),
//       body: Center(child: Text("Surgery details will appear here")),
//     );
//   }
// }

class SurgeryHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Surgery History")),
      body: Center(child: Text("Surgery history will appear here")),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Center(child: Text("Settings options will appear here")),
    );
  }
}
