// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:surgeon_control_panel/patient%20info/dashboard_items/user/user_list.dart';

// class HISApiService {
//   final String baseUrl = "https://hapi.fhir.org/baseR4";

//   /// Fetch patients from HIS (FHIR API)
//   Future<List<Map<String, dynamic>>> fetchPatients() async {
//     final url = Uri.parse("$baseUrl/Patient?_count=10");
//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);

//       // Extract patient entries
//       List<Map<String, dynamic>> patients = [];
//       if (data['entry'] != null) {
//         for (var entry in data['entry']) {
//           final resource = entry['resource'];
//           patients.add({
//             "id": resource['id'],
//             "name": resource['name'] != null
//                 ? resource['name'][0]['given']?.join(" ") ?? "Unknown"
//                 : "Unknown",
//             "gender": resource['gender'] ?? "N/A",
//           });
//         }
//       }
//       return patients;
//     } else {
//       throw Exception("Failed to load patients: ${response.statusCode}");
//     }
//   }
// }

// class PatientListScreen extends StatefulWidget {
//   @override
//   _PatientListScreenState createState() => _PatientListScreenState();
// }

// class _PatientListScreenState extends State<PatientListScreen> {
//   final HISApiService apiService = HISApiService();
//   late Future<List<Map<String, dynamic>>> patientsFuture;

//   @override
//   void initState() {
//     super.initState();
//     patientsFuture = apiService.fetchPatients();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Patient List")),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: patientsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No patients found"));
//           }

//           final patients = snapshot.data!;
//           return ListView.builder(
//             itemCount: patients.length,
//             itemBuilder: (context, index) {
//               final patient = patients[index];
//               return Card(
//                 child: ListTile(
//                   title: Text(patient['name']),
//                   subtitle: Text("Gender: ${patient['gender']}"),
//                   trailing: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => HospitalPortalApp(),
//                         ),
//                       );
//                     },
//                     child: Text("#${patient['id']}"),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'dart:async';
//  Color.fromARGB(255, 40, 123, 131),
//           Color.fromARGB(255, 39, 83, 87),
import 'package:flutter/material.dart';

// --- Placeholder Screens ---
// You can replace these with your actual screen widgets.
class VideoScreen extends StatelessWidget {
  const VideoScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E212A),
      body: Center(
        child: Text(
          'Video Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class FolderScreen extends StatelessWidget {
  const FolderScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E212A),
      body: Center(
        child: Text(
          'Folder Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class ChartScreen extends StatelessWidget {
  const ChartScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E212A),
      body: Center(
        child: Text(
          'Chart Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E212A),
      body: Center(
        child: Text(
          'Settings Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

// Main screen that holds the dashboard UI and the bottom navigation
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;
  bool _isHeartRateCardSelected = false;
  late Timer _timer;
  int _seconds = 0;

  // Color Palette
  static const Color darkBg = Color(0xFF1E212A);
  static const Color cardColor = Color(0xFF2B3039);
  static const Color highlightCardColor = Color(0xFF383D4A);
  static const Color textColor = Colors.white;
  static const Color redColor = Color(0xFFFF5252);
  static const Color blueColor = Color(0xFF53A1FF);
  static const Color yellowColor = Color(0xFFFFCC00);
  static const Color fadedTextColor = Colors.white54;

  // List of screens for the bottom navigation
  static final List<Widget> _screens = <Widget>[
    const PatientDashboard(), // The main dashboard UI
    const VideoScreen(),
    const FolderScreen(),
    const ChartScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '00:$minutes:$remainingSeconds';
  }

  // --- Main Build Method for the overall app structure ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(), // The main dashboard layout
          ..._screens.skip(1), // Add the other screens here
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.videocam_outlined, 0),
            _buildNavIcon(Icons.folder_open, 1),
            _buildNavIcon(Icons.monitor_heart_outlined, 2),
            _buildNavIcon(Icons.show_chart, 3),
            _buildNavIcon(Icons.settings_outlined, 4),
          ],
        ),
      ),
    );
  }

  // A method to build the main dashboard content
  Widget _buildDashboardContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            _buildTopBar(),
            const SizedBox(height: 24),
            // Patient Info Card
            _buildPatientInfo(),
            const SizedBox(height: 24),
            // Vitals Cards
            _buildVitals(),
            const SizedBox(height: 24),
            // Surgery Timer and Alerts
            _buildTimerAndAlerts(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ... (rest of the helper methods remain the same) ...

  Widget _buildNavIcon(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? textColor : fadedTextColor, size: 32),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: isSelected ? 32 : 0,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'PATIENT INFORMATION',
          style: TextStyle(
            color: fadedTextColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Container(width: 16, height: 2, color: fadedTextColor),
            const SizedBox(width: 4),
            Container(width: 8, height: 2, color: fadedTextColor),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Michael Smith',
          style: TextStyle(
            color: textColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Dr. Johnson',
          style: TextStyle(color: fadedTextColor, fontSize: 16),
        ),
        SizedBox(height: 16),
        Text(
          'Laparoscopic\nCholecystectomy',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVitals() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildVitalCard(
          icon: Icons.favorite,
          iconColor: redColor,
          value: '75',
          unit: 'BPM',
          valueColor: redColor,
          isSelectable: true,
        ),
        _buildVitalCard(
          icon: Icons.insert_chart,
          iconColor: textColor,
          value: '120/80',
          unit: 'mmHg',
          valueColor: textColor,
        ),
        _buildVitalCard(
          icon: Icons.check_circle,
          iconColor: blueColor,
          value: '99%',
          unit: 'SpO2',
          valueColor: blueColor,
        ),
      ],
    );
  }

  Widget _buildTimerAndAlerts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildTimerCard(), _buildAlertCard()],
    );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required Color valueColor,
    bool isSelectable = false,
  }) {
    Color currentCardColor = cardColor;
    if (isSelectable && _isHeartRateCardSelected) {
      currentCardColor = highlightCardColor;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelectable) {
            setState(() {
              _isHeartRateCardSelected = !_isHeartRateCardSelected;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: currentCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unit,
                style: const TextStyle(color: fadedTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    final timeString = _formatTime(_seconds);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                timeString,
                key: ValueKey<String>(timeString),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SURGERY TIMER',
              style: TextStyle(color: fadedTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.warning, color: yellowColor, size: 36),
            SizedBox(width: 8),
            Text(
              'MEDICAL\nALERTS',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A new class for the main dashboard content
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // This is a placeholder. The actual content is in the parent widget.
      // In a real app, this widget would contain the full dashboard UI.
    );
  }
}
