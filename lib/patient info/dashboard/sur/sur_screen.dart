import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SurgeryScreen extends StatefulWidget {
  const SurgeryScreen({super.key});

  @override
  State<SurgeryScreen> createState() => _SurgeryScreenState();
}

class _SurgeryScreenState extends State<SurgeryScreen> {
  // Define the custom colors
  final Color _primaryColor = const Color.fromARGB(255, 112, 143, 214);
  final Color _secondaryColor = const Color.fromARGB(255, 157, 102, 228);

  int _currentTab = 0; // 0: Upcoming, 1: Schedule Surgery

  // Sample data
  final List<Surgery> _upcomingSurgeries = [
    Surgery(
      id: 'SUR-2024-001',
      patientName: 'John Doe',
      procedure: 'Appendectomy',
      surgeon: 'Dr. Sarah Johnson',
      date: DateTime.now().add(const Duration(days: 2)),
      duration: const Duration(hours: 1, minutes: 30),
      theater: 'Operating Room 1',
      status: 'Scheduled',
      priority: 'High',
    ),
    Surgery(
      id: 'SUR-2024-002',
      patientName: 'Jane Smith',
      procedure: 'Knee Replacement',
      surgeon: 'Dr. Michael Chen',
      date: DateTime.now().add(const Duration(days: 5)),
      duration: const Duration(hours: 3, minutes: 0),
      theater: 'Operating Room 2',
      status: 'Scheduled',
      priority: 'Medium',
    ),
    Surgery(
      id: 'SUR-2024-003',
      patientName: 'Robert Brown',
      procedure: 'Cataract Surgery',
      surgeon: 'Dr. Emily Rodriguez',
      date: DateTime.now().add(const Duration(days: 7)),
      duration: const Duration(hours: 1, minutes: 0),
      theater: 'Operating Room 3',
      status: 'Scheduled',
      priority: 'Low',
    ),
  ];

  final List<Surgery> _completedSurgeries = [
    Surgery(
      id: 'SUR-2023-045',
      patientName: 'Alice Johnson',
      procedure: 'Gallbladder Removal',
      surgeon: 'Dr. James Wilson',
      date: DateTime.now().subtract(const Duration(days: 15)),
      duration: const Duration(hours: 2, minutes: 15),
      theater: 'Operating Room 1',
      status: 'Completed',
      priority: 'High',
    ),
    Surgery(
      id: 'SUR-2023-046',
      patientName: 'David Miller',
      procedure: 'Hernia Repair',
      surgeon: 'Dr. Sarah Johnson',
      date: DateTime.now().subtract(const Duration(days: 8)),
      duration: const Duration(hours: 1, minutes: 45),
      theater: 'Operating Room 2',
      status: 'Completed',
      priority: 'Medium',
    ),
  ];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _procedureController = TextEditingController();
  final _surgeonController = TextEditingController();
  final _theaterController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedPriority = 'Medium';
  final List<String> _priorityOptions = ['High', 'Medium', 'Low'];

  @override
  void dispose() {
    _patientNameController.dispose();
    _procedureController.dispose();
    _surgeonController.dispose();
    _theaterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Surgery Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 40, 123, 131),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 40, 123, 131),
              Color.fromARGB(255, 39, 83, 87),
            ],
          ),
        ),
        child: Column(
          children: [
            // Tab Selection
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _buildTab('Upcoming Surgeries', 0),
                  _buildTab('Schedule Surgery', 1),
                  _buildTab('Completed', 2),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content based on selected tab
            Expanded(
              child: _currentTab == 0
                  ? _buildUpcomingSurgeries()
                  : _currentTab == 1
                  ? _buildScheduleForm()
                  : _buildCompletedSurgeries(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _currentTab == index
                    ? _primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _currentTab == index ? _primaryColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSurgeries() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Surgeries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _upcomingSurgeries.isEmpty
                ? const Center(
                    child: Text(
                      'No upcoming surgeries scheduled',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _upcomingSurgeries.length,
                    itemBuilder: (context, index) {
                      final surgery = _upcomingSurgeries[index];
                      return _buildSurgeryCard(surgery, true);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSurgeries() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Completed Surgeries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _completedSurgeries.isEmpty
                ? const Center(
                    child: Text(
                      'No completed surgeries',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _completedSurgeries.length,
                    itemBuilder: (context, index) {
                      final surgery = _completedSurgeries[index];
                      return _buildSurgeryCard(surgery, false);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeryCard(Surgery surgery, bool isUpcoming) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  surgery.procedure,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(surgery.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    surgery.priority,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Patient: ${surgery.patientName}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Surgeon: ${surgery.surgeon}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(surgery.date)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Theater: ${surgery.theater}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            if (isUpcoming)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _editSurgery(surgery),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: Text('Edit', style: TextStyle(color: _primaryColor)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _startSurgery(surgery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                    ),
                    child: const Text('Start Surgery'),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${surgery.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule New Surgery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _patientNameController,
              decoration: InputDecoration(
                labelText: 'Patient Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter patient name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _procedureController,
              decoration: InputDecoration(
                labelText: 'Procedure',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter procedure name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _surgeonController,
              decoration: InputDecoration(
                labelText: 'Surgeon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_information),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter surgeon name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _theaterController,
              decoration: InputDecoration(
                labelText: 'Operating Theater',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter operating theater';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Date and Time Selection
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: _primaryColor),
                      title: const Text('Surgery Date'),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: _primaryColor),
                      title: const Text('Surgery Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Priority Selection
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.priority_high, color: _primaryColor),
                  ),
                  items: _priorityOptions.map((String priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPriority = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Schedule Surgery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Combine date and time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create new surgery
      final newSurgery = Surgery(
        id: 'SUR-${DateFormat('yyyy').format(DateTime.now())}-${_upcomingSurgeries.length + 1}',
        patientName: _patientNameController.text,
        procedure: _procedureController.text,
        surgeon: _surgeonController.text,
        date: scheduledDateTime,
        duration: const Duration(hours: 1), // Default duration
        theater: _theaterController.text,
        status: 'Scheduled',
        priority: _selectedPriority,
      );

      // Add to upcoming surgeries
      setState(() {
        _upcomingSurgeries.add(newSurgery);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Surgery scheduled successfully'),
          backgroundColor: _primaryColor,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _patientNameController.clear();
      _procedureController.clear();
      _surgeonController.clear();
      _theaterController.clear();
      setState(() {
        _selectedDate = DateTime.now().add(const Duration(days: 1));
        _selectedTime = const TimeOfDay(hour: 9, minute: 0);
        _selectedPriority = 'Medium';
      });

      // Switch to upcoming surgeries tab
      setState(() {
        _currentTab = 0;
      });
    }
  }

  void _editSurgery(Surgery surgery) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Edit Surgery', style: TextStyle(color: _primaryColor)),
          content: const Text(
            'Surgery editing functionality would be implemented here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _primaryColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Surgery updated successfully'),
                    backgroundColor: _primaryColor,
                  ),
                );
              },
              child: Text('Save', style: TextStyle(color: _secondaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _startSurgery(Surgery surgery) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Start Surgery', style: TextStyle(color: _primaryColor)),
          content: Text(
            'Are you ready to start ${surgery.procedure} for ${surgery.patientName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _primaryColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Move surgery to completed
                setState(() {
                  _upcomingSurgeries.remove(surgery);
                  _completedSurgeries.add(
                    surgery.copyWith(status: 'Completed'),
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Surgery started successfully'),
                    backgroundColor: _primaryColor,
                  ),
                );
              },
              child: Text('Start', style: TextStyle(color: _secondaryColor)),
            ),
          ],
        );
      },
    );
  }
}

class Surgery {
  final String id;
  final String patientName;
  final String procedure;
  final String surgeon;
  final DateTime date;
  final Duration duration;
  final String theater;
  final String status;
  final String priority;

  Surgery({
    required this.id,
    required this.patientName,
    required this.procedure,
    required this.surgeon,
    required this.date,
    required this.duration,
    required this.theater,
    required this.status,
    required this.priority,
  });

  Surgery copyWith({
    String? id,
    String? patientName,
    String? procedure,
    String? surgeon,
    DateTime? date,
    Duration? duration,
    String? theater,
    String? status,
    String? priority,
  }) {
    return Surgery(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      procedure: procedure ?? this.procedure,
      surgeon: surgeon ?? this.surgeon,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      theater: theater ?? this.theater,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }
}
