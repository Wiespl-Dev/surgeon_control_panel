import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:math'; // Required for log and pow in _formatBytes

// ==================== DATA MODELS ====================

class Patient {
  final int? id;
  final String patientId;
  final String name;
  final int age;
  // ... (Patient model remains the same)
  final String gender;
  final String phone;
  final String? email;
  final String? bloodGroup;
  final String? address;
  final String? emergencyContact;
  final String? emergencyName;
  final String? allergies;
  final String? medications;
  final String? medicalHistory;
  final String? insurance;
  final String? insuranceId;
  final String? operationOt;
  final String? operationDate;
  final String? operationTime;
  final String? operationDoctor;
  final String? operationDoctorRole;
  final String? operationNotes;
  final String? createdAt;

  Patient({
    this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    this.email,
    this.bloodGroup,
    this.address,
    this.emergencyContact,
    this.emergencyName,
    this.allergies,
    this.medications,
    this.medicalHistory,
    this.insurance,
    this.insuranceId,
    this.operationOt,
    this.operationDate,
    this.operationTime,
    this.operationDoctor,
    this.operationDoctorRole,
    this.operationNotes,
    this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      patientId: json['patient_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      bloodGroup: json['blood_group'],
      address: json['address'],
      emergencyContact: json['emergency_contact'],
      emergencyName: json['emergency_name'],
      allergies: json['allergies'],
      medications: json['medications'],
      medicalHistory: json['medical_history'],
      insurance: json['insurance'],
      insuranceId: json['insurance_id'],
      operationOt: json['operation_ot'],
      operationDate: json['operation_date'],
      operationTime: json['operation_time'],
      operationDoctor: json['operation_doctor'],
      operationDoctorRole: json['operation_doctor_role'],
      operationNotes: json['operation_notes'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'blood_group': bloodGroup,
      'address': address,
      'emergency_contact': emergencyContact,
      'emergency_name': emergencyName,
      'allergies': allergies,
      'medications': medications,
      'medical_history': medicalHistory,
      'insurance': insurance,
      'insurance_id': insuranceId,
      'operation_ot': operationOt,
      'operation_date': operationDate,
      'operation_time': operationTime,
      'operation_doctor': operationDoctor,
      'operation_doctor_role': operationDoctorRole,
      'operation_notes': operationNotes,
    };
  }
}

// ⭐️ NEW REPORT MODEL
class Report {
  final int id;
  final String patientId;
  final String originalName;
  final String filename;
  final int fileSize;
  final String fileType;
  final String description;
  final String fileUrl; // Full URL for direct access
  final String? uploadDate; // Assuming 'upload_date' from DB

  Report({
    required this.id,
    required this.patientId,
    required this.originalName,
    required this.filename,
    required this.fileSize,
    required this.fileType,
    required this.description,
    required this.fileUrl,
    this.uploadDate,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      patientId: json['patient_id'] ?? '',
      originalName: json['original_name'] ?? 'Unknown Report',
      filename: json['filename'] ?? '',
      fileSize: json['file_size'] ?? 0,
      fileType: json['file_type'] ?? 'application/octet-stream',
      description: json['description'] ?? '',
      fileUrl: json['file_url'] ?? '',
      uploadDate: json['upload_date'],
    );
  }
}

// ==================== API SERVICE ====================

class ApiService {
  static const String baseUrl = 'http://192.168.1.230:3000/api';

  // Handle API errors
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'An error occurred');
    }
  }

  // Get all patients
  Future<List<Patient>> getPatients() async {
    final response = await http.get(Uri.parse('$baseUrl/patients'));
    _handleError(response);
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Patient.fromJson(json)).toList();
  }

  // ... (Other Patient CRUD methods remain the same)
  Future<Patient> getPatient(String patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/patients/$patientId'));
    _handleError(response);
    final data = json.decode(response.body);
    return Patient.fromJson(data);
  }

  Future<Patient> addPatient(Patient patient) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(patient.toJson()),
    );
    _handleError(response);
    final data = json.decode(response.body);
    return Patient.fromJson({...patient.toJson(), 'id': data['id']});
  }

  Future<void> updatePatient(String patientId, Patient patient) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(patient.toJson()),
    );
    _handleError(response);
  }

  Future<void> deletePatient(String patientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/patients/$patientId'),
    );
    _handleError(response);
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/debug'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ NEW: Get all reports for a patient
  Future<List<Report>> getReports(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/reports'),
    );

    _handleError(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Report.fromJson(json)).toList();
  }

  // ⭐️ NEW: Download the report file bytes using the correct endpoint
  Future<List<int>> downloadReport(String patientId, int reportId) async {
    // The server-side endpoint is /api/patients/:patientId/reports/:reportId/download
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/reports/$reportId/download'),
    );

    _handleError(response);

    // The server streams the file directly, so we return the raw bytes
    return response.bodyBytes;
  }
}

// ==================== WIDGETS ====================

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

// ... (_PatientListScreenState methods remain the same)
class _PatientListScreenState extends State<PatientListScreen> {
  final ApiService _apiService = ApiService();
  List<Patient> _patients = [];
  bool _isLoading = true;
  String _error = '';
  bool _serverOnline = false;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
    _loadPatients();
  }

  Future<void> _checkServerStatus() async {
    final isOnline = await _apiService.checkServerStatus();
    setState(() {
      _serverOnline = isOnline;
    });
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final patients = await _apiService.getPatients();
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePatient(String patientId, String patientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete $patientName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deletePatient(patientId);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Patient $patientName deleted')));
        _loadPatients(); // Refresh the list
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting patient: $e')));
      }
    }
  }

  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final genderController = TextEditingController();
    final phoneController = TextEditingController();
    final patientIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Patient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patientIdController,
                decoration: const InputDecoration(
                  labelText: 'Patient ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: genderController,
                decoration: const InputDecoration(
                  labelText: 'Gender*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  ageController.text.isEmpty ||
                  genderController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }

              try {
                final patient = Patient(
                  patientId: patientIdController.text.isEmpty
                      ? 'PAT${DateTime.now().millisecondsSinceEpoch}'
                      : patientIdController.text,
                  name: nameController.text,
                  age: int.tryParse(ageController.text) ?? 0,
                  gender: genderController.text,
                  phone: phoneController.text,
                );

                await _apiService.addPatient(patient);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient added successfully')),
                );
                _loadPatients();
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding patient: $e')),
                );
              }
            },
            child: const Text('Add Patient'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      appBar: AppBar(
        title: const Text('Hospital Patients'),
        backgroundColor: const Color(0xFF3D8A8F),
        foregroundColor: Colors.white,
        actions: [
          // Server status indicator
          IconButton(
            icon: Icon(
              _serverOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _serverOnline ? Colors.green : Colors.red,
            ),
            onPressed: _checkServerStatus,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPatients),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Patients',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadPatients,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _patients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Patients Found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first patient using the + button',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showAddPatientDialog,
                    child: const Text('Add First Patient'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColorByIndex(index),
                      child: Text(
                        patient.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      patient.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'ID: ${patient.patientId} • ${patient.age} years • ${patient.gender}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PatientDetailScreen(patient: patient),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deletePatient(patient.patientId, patient.name);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PatientDetailScreen(patient: patient),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Color _getColorByIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }
}

// ==================== PATIENT DETAIL SCREEN ====================

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailScreen({Key? key, required this.patient})
    : super(key: key);

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      appBar: AppBar(
        title: Text(patient.name),
        backgroundColor: const Color(0xFF3D8A8F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient ID Header
            Row(
              children: [
                Center(
                  child: Chip(
                    label: Text(
                      'Patient ID: ${patient.patientId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 20),

                // ⭐️ UPDATED: Button to view list of reports
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientReportsListScreen(
                            patient: patient,
                          ), // Navigate to List Screen
                        ),
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('View Patient Reports'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Basic Information
            _buildSection('Basic Information', [
              _buildInfoRow('Full Name', patient.name),
              _buildInfoRow('Age', '${patient.age} years'),
              _buildInfoRow('Gender', patient.gender),
              _buildInfoRow('Phone', patient.phone),
              _buildInfoRow('Email', patient.email ?? ''),
              _buildInfoRow('Blood Group', patient.bloodGroup ?? ''),
              _buildInfoRow('Address', patient.address ?? ''),
            ]),

            // Emergency Contact
            _buildSection('Emergency Contact', [
              _buildInfoRow('Contact Name', patient.emergencyName ?? ''),
              _buildInfoRow('Contact Number', patient.emergencyContact ?? ''),
            ]),

            // Medical Information
            _buildSection('Medical Information', [
              _buildInfoRow('Allergies', patient.allergies ?? ''),
              _buildInfoRow('Current Medications', patient.medications ?? ''),
              _buildInfoRow('Medical History', patient.medicalHistory ?? ''),
              _buildInfoRow('Insurance Provider', patient.insurance ?? ''),
              _buildInfoRow('Insurance ID', patient.insuranceId ?? ''),
            ]),

            // Operation Details
            if (patient.operationDoctor != null || patient.operationOt != null)
              _buildSection('Operation Details', [
                _buildInfoRow('Operation Theater', patient.operationOt ?? ''),
                _buildInfoRow('Operation Date', patient.operationDate ?? ''),
                _buildInfoRow('Operation Time', patient.operationTime ?? ''),
                _buildInfoRow(
                  'Operating Doctor',
                  patient.operationDoctor ?? '',
                ),
                _buildInfoRow('Doctor Role', patient.operationDoctorRole ?? ''),
                _buildInfoRow('Operation Notes', patient.operationNotes ?? ''),
              ]),

            // Created Date
            if (patient.createdAt != null)
              _buildSection('System Information', [
                _buildInfoRow('Created On', patient.createdAt!),
              ]),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ❌ DELETED: PatientReportScreen is replaced by PatientReportsListScreen

// ⭐️ NEW: Screen to list, download, and open reports
class PatientReportsListScreen extends StatefulWidget {
  final Patient patient;

  const PatientReportsListScreen({super.key, required this.patient});

  @override
  State<PatientReportsListScreen> createState() =>
      _PatientReportsListScreenState();
}

class _PatientReportsListScreenState extends State<PatientReportsListScreen> {
  final ApiService _apiService = ApiService();
  List<Report> _reports = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final reports = await _apiService.getReports(widget.patient.patientId);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reports: $e';
        _isLoading = false;
      });
    }
  }

  // File size utility (uses dart:math.log and dart:math.pow)
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes > 0 ? (log(bytes) / log(1024)) : 0).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // ⭐️ Download and Open Logic (Uses correct ApiService.downloadReport)
  Future<void> _downloadAndOpenReport(Report report) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${report.originalName}...')),
    );

    try {
      // 1. Download file bytes using the correct endpoint
      final bytes = await _apiService.downloadReport(
        widget.patient.patientId,
        report.id,
      );

      // 2. Save the bytes to a temporary local file
      final directory = await getTemporaryDirectory();
      // Use original file name for better compatibility
      final filePath = '${directory.path}/${report.originalName}';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // 3. Use open_filex to launch the file
      final result = await OpenFilex.open(filePath);

      // 4. Handle result
      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${report.originalName} opened successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading/opening report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      appBar: AppBar(
        title: Text('${widget.patient.name} Reports'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            )
          : _reports.isEmpty
          ? Center(child: Text('No reports found for ${widget.patient.name}.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      _getIconForMimeType(report.fileType),
                      color: Colors.blueGrey,
                    ),
                    title: Text(report.originalName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${report.fileType} | ${_formatBytes(report.fileSize)}',
                        ),
                        if (report.description.isNotEmpty)
                          Text(
                            report.description,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download, color: Colors.green),
                      onPressed: () => _downloadAndOpenReport(report),
                    ),
                    onTap: () => _downloadAndOpenReport(report),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconForMimeType(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('text') || mimeType.contains('csv'))
      return Icons.text_snippet;
    if (mimeType.contains('word') || mimeType.contains('document'))
      return Icons.description;
    return Icons.insert_drive_file;
  }
}
