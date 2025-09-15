import 'package:flutter/material.dart';

class HospitalPortalApp extends StatelessWidget {
  const HospitalPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HospitalPortalPage(),
    );
  }
}

class HospitalPortalPage extends StatefulWidget {
  const HospitalPortalPage({super.key});

  @override
  State<HospitalPortalPage> createState() => _HospitalPortalPageState();
}

class _HospitalPortalPageState extends State<HospitalPortalPage> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Sample data
  final List<Map<String, String>> _appointments = [
    {'date': 'July 23, 2024', 'time': '10:00 AM', 'doctor': 'Dr. Smith'},
    {'date': 'August 1, 2024', 'time': '2:30 PM', 'doctor': 'Dr. Johnson'},
  ];

  final List<Map<String, String>> _medicalRecords = [
    {'date': 'July 12, 2024', 'type': 'Lab Results', 'status': 'Available'},
    {'date': 'June 5, 2024', 'type': 'X-ray', 'status': 'Available'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;

    if (screenWidth < 800) {
      crossAxisCount = 1;
    } else if (screenWidth > 1200) {
      crossAxisCount = 3;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 200,
            color: Colors.blue[700],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only show back button if we can pop
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                const SizedBox(height: 40),
                _buildNavItem(Icons.home, "Home", 0),
                _buildNavItem(Icons.calendar_today, "Appointments", 1),
                _buildNavItem(Icons.folder, "My Records", 2),
                _buildNavItem(Icons.favorite, "Health Info", 3),
                _buildNavItem(Icons.settings, "Settings", 4),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "HOSPITAL INFORMATION PORTAL",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            // Handle search functionality
                            _handleSearch(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Welcome Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Text(
                            "Welcome, John Doe",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _showProfileDialog(context);
                          },
                          child: const Text("View Profile"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.6,
                      children: [
                        _buildInfoCard("Upcoming Appointments", [
                          _appointmentItem(_appointments[0], 0),
                          _appointmentItem(_appointments[1], 1),
                          ListTile(
                            title: const Text("Schedule New Appointment"),
                            leading: const Icon(Icons.add, color: Colors.green),
                            onTap: () {
                              _scheduleAppointment(context);
                            },
                          ),
                        ]),

                        _buildInfoCard("Medical Records", [
                          _recordItem(_medicalRecords[0], 0),
                          _recordItem(_medicalRecords[1], 1),
                          ListTile(
                            title: const Text("Request Records"),
                            leading: const Icon(
                              Icons.request_page,
                              color: Colors.blue,
                            ),
                            onTap: () {
                              _requestMedicalRecords(context);
                            },
                          ),
                        ]),

                        _buildInfoCard("Health Information", [
                          ListTile(
                            title: const Text("Vaccinations"),
                            subtitle: const Text(
                              "Keep your vaccinations up to date",
                            ),
                            leading: const Icon(
                              Icons.vaccines,
                              color: Colors.green,
                            ),
                            onTap: () {
                              _viewVaccinations(context);
                            },
                          ),
                          ListTile(
                            title: const Text("Allergies"),
                            leading: const Icon(
                              Icons.warning,
                              color: Colors.orange,
                            ),
                            onTap: () {
                              _viewAllergies(context);
                            },
                          ),
                        ]),

                        _buildInfoCard("Medications", [
                          ListTile(
                            title: const Text("Current Medications"),
                            leading: const Icon(
                              Icons.medication,
                              color: Colors.red,
                            ),
                            onTap: () {
                              _viewCurrentMedications(context);
                            },
                          ),
                          ListTile(
                            title: const Text("Prescription Refill"),
                            leading: const Icon(
                              Icons.refresh,
                              color: Colors.blue,
                            ),
                            onTap: () {
                              _requestRefill(context);
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      selected: _selectedNavIndex == index,
      selectedTileColor: Colors.blue[900],
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
        _handleNavigation(index);
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(child: ListView(children: children)),
        ],
      ),
    );
  }

  Widget _appointmentItem(Map<String, String> appointment, int index) {
    return ListTile(
      leading: const Icon(Icons.event, color: Colors.blue),
      title: Text(appointment['date']!),
      subtitle: Text('${appointment['time']!} - ${appointment['doctor']!}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _editAppointment(context, index),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
            onPressed: () => _cancelAppointment(context, index),
          ),
        ],
      ),
    );
  }

  Widget _recordItem(Map<String, String> record, int index) {
    return ListTile(
      leading: const Icon(Icons.folder, color: Colors.blue),
      title: Text(record['date']!),
      subtitle: Text('${record['type']!} - ${record['status']!}'),
      trailing: ElevatedButton(
        onPressed: () => _viewMedicalRecord(context, index),
        child: const Text("View"),
      ),
    );
  }

  // Navigation handlers
  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Home - already on home
        break;
      case 1:
        _showAppointmentsPage();
        break;
      case 2:
        _showMedicalRecordsPage();
        break;
      case 3:
        _showHealthInfoPage();
        break;
      case 4:
        _showSettingsPage();
        break;
    }
  }

  void _handleSearch(String query) {
    // Implement search functionality
    print("Searching for: $query");
    // You would typically filter data based on the search query here
  }

  // Action methods
  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Patient Profile"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: John Doe"),
              Text("Age: 45"),
              Text("Blood Type: O+"),
              Text("Primary Doctor: Dr. Smith"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editProfile(context);
              },
              child: const Text("Edit"),
            ),
          ],
        );
      },
    );
  }

  void _editProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: const Text(
            "Profile editing functionality would be implemented here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated successfully")),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _scheduleAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Schedule New Appointment"),
          content: const Text(
            "Appointment scheduling functionality would be implemented here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Appointment scheduled successfully"),
                  ),
                );
              },
              child: const Text("Schedule"),
            ),
          ],
        );
      },
    );
  }

  void _editAppointment(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Appointment"),
          content: Text(
            "Editing appointment on ${_appointments[index]['date']}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Appointment updated successfully"),
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _cancelAppointment(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cancel Appointment"),
          content: Text(
            "Are you sure you want to cancel your appointment on ${_appointments[index]['date']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Appointment cancelled successfully"),
                  ),
                );
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void _requestMedicalRecords(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Request Medical Records"),
          content: const Text(
            "Medical records request functionality would be implemented here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Medical records requested successfully"),
                  ),
                );
              },
              child: const Text("Request"),
            ),
          ],
        );
      },
    );
  }

  void _viewMedicalRecord(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Medical Record - ${_medicalRecords[index]['type']}"),
          content: Text(
            "Details for ${_medicalRecords[index]['date']} would be displayed here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Record downloaded successfully"),
                  ),
                );
              },
              child: const Text("Download"),
            ),
          ],
        );
      },
    );
  }

  void _viewVaccinations(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Vaccination Records"),
          content: const Text(
            "Your vaccination history would be displayed here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _viewAllergies(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Allergies"),
          content: const Text(
            "Your allergy information would be displayed here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editAllergies(context);
              },
              child: const Text("Edit"),
            ),
          ],
        );
      },
    );
  }

  void _editAllergies(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Allergies"),
          content: const Text(
            "Allergy editing functionality would be implemented here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Allergies updated successfully"),
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _viewCurrentMedications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Current Medications"),
          content: const Text("Your current medications would be listed here."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _requestRefill(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Prescription Refill"),
          content: const Text(
            "Prescription refill request functionality would be implemented here.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Refill requested successfully"),
                  ),
                );
              },
              child: const Text("Request"),
            ),
          ],
        );
      },
    );
  }

  // Navigation page methods (stubs for now)
  void _showAppointmentsPage() {
    // Would navigate to appointments page
    print("Navigating to Appointments page");
  }

  void _showMedicalRecordsPage() {
    // Would navigate to medical records page
    print("Navigating to Medical Records page");
  }

  void _showHealthInfoPage() {
    // Would navigate to health info page
    print("Navigating to Health Info page");
  }

  void _showSettingsPage() {
    // Would navigate to settings page
    print("Navigating to Settings page");
  }
}
