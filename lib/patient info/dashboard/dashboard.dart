import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';

// ==================== DATA MODELS ====================

class Patient {
  final int? id;
  final String patientId;
  final String? patientCategory;
  final String name;
  final int age;
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
  final int? reportCount;

  Patient({
    this.id,
    required this.patientId,
    this.patientCategory,
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
    this.reportCount,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      patientId: json['patient_id'] ?? '',
      patientCategory: json['patient_category'],
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
      reportCount: json['report_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'patient_category': patientCategory,
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

class Report {
  final int id;
  final String patientId;
  final String originalName;
  final String filename;
  final int fileSize;
  final String fileType;
  final String description;
  final String fileUrl;
  final String? uploadDate;

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
  // Update this IP address to match your computer's IP
  static const String baseUrl = 'http://192.168.0.101:3000/api';

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

  // Get single patient
  Future<Patient> getPatient(String patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/patients/$patientId'));
    _handleError(response);
    final data = json.decode(response.body);
    return Patient.fromJson(data);
  }

  // Add new patient
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

  // Update patient
  Future<void> updatePatient(String patientId, Patient patient) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(patient.toJson()),
    );
    _handleError(response);
  }

  // Delete patient
  Future<void> deletePatient(String patientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/patients/$patientId'),
    );
    _handleError(response);
  }

  // Check server status
  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/test'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get all reports for a patient
  Future<List<Report>> getReports(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/reports'),
    );
    _handleError(response);
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Report.fromJson(json)).toList();
  }

  // Download report file
  Future<List<int>> downloadReport(String patientId, int reportId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients/$patientId/reports/$reportId/download'),
    );
    _handleError(response);
    return response.bodyBytes;
  }

  // Get patients with report counts
  Future<List<Patient>> getPatientsWithReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patients-with-reports'),
    );
    _handleError(response);
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Patient.fromJson(json)).toList();
  }
}

// ==================== FILE VIEWER SCREEN ====================

class FileViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String fileType;

  const FileViewerScreen({
    Key? key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
  }) : super(key: key);

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  bool _isLoading = true;
  String? _pdfPath;
  int? _totalPages;
  int _currentPage = 0;
  bool _pdfReady = false;

  @override
  void initState() {
    super.initState();
    _initializeFile();
  }

  void _initializeFile() {
    setState(() {
      _isLoading = false;
      _pdfPath = widget.filePath;
      _pdfReady = true;
    });
  }

  bool get _isPdf => widget.fileType.toLowerCase().contains('pdf');
  bool get _isImage {
    final type = widget.fileType.toLowerCase();
    return type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('png') ||
        type.contains('gif') ||
        type.contains('bmp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(widget.filePath),
            tooltip: 'Open with external app',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isPdf
          ? _buildPdfViewer()
          : _isImage
          ? _buildImageViewer()
          : _buildUnsupportedFileView(),
    );
  }

  Widget _buildPdfViewer() {
    return Column(
      children: [
        if (_totalPages != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: const TextStyle(fontSize: 14),
                ),
                if (_totalPages! > 1)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        onPressed: _currentPage > 0
                            ? () {
                                // You can add page navigation logic here
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: _currentPage < _totalPages! - 1
                            ? () {
                                // You can add page navigation logic here
                              }
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        Expanded(
          child: PDFView(
            filePath: _pdfPath,
            autoSpacing: true,
            enableSwipe: true,
            pageSnap: true,
            swipeHorizontal: false,
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages;
                _pdfReady = true;
              });
            },
            onError: (error) {
              print(error.toString());
            },
            onPageError: (page, error) {
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // You can store the controller for later use
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: FileImage(File(widget.filePath)),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
      initialScale: PhotoViewComputedScale.contained,
      basePosition: Alignment.center,
    );
  }

  Widget _buildUnsupportedFileView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'File Type Not Supported',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'File type: ${widget.fileType}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => OpenFilex.open(widget.filePath),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open with External App'),
          ),
        ],
      ),
    );
  }
}

// ==================== MAIN APP ====================

void main() {
  runApp(const HospitalManagementApp());
}

class HospitalManagementApp extends StatelessWidget {
  const HospitalManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PatientListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== PATIENT LIST SCREEN ====================

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

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
      final patients = await _apiService.getPatientsWithReports();
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
        _loadPatients();
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
                  hintText: 'Auto-generated if empty',
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

  Widget _buildPatientCard(Patient patient, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'ID: ${patient.patientId} • ${patient.age} years • ${patient.gender}',
              style: const TextStyle(fontSize: 14),
            ),
            if (patient.phone.isNotEmpty)
              Text(
                'Phone: ${patient.phone}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (patient.reportCount != null && patient.reportCount! > 0)
              Chip(
                label: Text(
                  '${patient.reportCount} reports',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Colors.blue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailScreen(patient: patient),
                ),
              );
            } else if (value == 'delete') {
              _deletePatient(patient.patientId, patient.name);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailScreen(patient: patient),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      appBar: AppBar(
        title: const Text('Hospital Patients'),
        backgroundColor: const Color(0xFF3D8A8F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _serverOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _serverOnline ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: _checkServerStatus,
            tooltip: _serverOnline ? 'Server Online' : 'Server Offline',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading patients...'),
                ],
              ),
            )
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Patients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add First Patient'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPatients,
              child: ListView.builder(
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  return _buildPatientCard(_patients[index], index);
                },
              ),
            ),
    );
  }
}

// ==================== PATIENT DETAIL SCREEN ====================

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailScreen({Key? key, required this.patient})
    : super(key: key);

  Widget _buildInfoRow(String label, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isImportant ? FontWeight.w500 : FontWeight.normal,
                color: isImportant ? Colors.blue[800] : Colors.black87,
              ),
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
                color: Color(0xFF2196F3),
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
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        title: Text(patient.name),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient ID Header
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient ID: ${patient.patientId}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          if (patient.reportCount != null &&
                              patient.reportCount! > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${patient.reportCount} medical reports available',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PatientReportsScreen(patient: patient),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('View Reports'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Basic Information
            _buildSection('Basic Information', [
              _buildInfoRow('Full Name', patient.name, isImportant: true),
              _buildInfoRow('Age', '${patient.age} years', isImportant: true),
              _buildInfoRow('Gender', patient.gender, isImportant: true),
              _buildInfoRow('Phone', patient.phone, isImportant: true),
              _buildInfoRow('Email', patient.email ?? ''),
              _buildInfoRow('Blood Group', patient.bloodGroup ?? ''),
              _buildInfoRow('Address', patient.address ?? ''),
              _buildInfoRow(
                'Patient Category',
                patient.patientCategory ?? 'General',
              ),
            ]),

            // Emergency Contact
            if (patient.emergencyContact != null ||
                patient.emergencyName != null)
              _buildSection('Emergency Contact', [
                _buildInfoRow('Contact Name', patient.emergencyName ?? ''),
                _buildInfoRow('Contact Number', patient.emergencyContact ?? ''),
              ]),

            // Medical Information
            _buildSection('Medical Information', [
              _buildInfoRow('Allergies', patient.allergies ?? 'None recorded'),
              _buildInfoRow(
                'Current Medications',
                patient.medications ?? 'None recorded',
              ),
              _buildInfoRow(
                'Medical History',
                patient.medicalHistory ?? 'None recorded',
              ),
              _buildInfoRow(
                'Insurance Provider',
                patient.insurance ?? 'Not specified',
              ),
              _buildInfoRow(
                'Insurance ID',
                patient.insuranceId ?? 'Not specified',
              ),
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

            // System Information
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

// ==================== PATIENT REPORTS SCREEN ====================

class PatientReportsScreen extends StatefulWidget {
  final Patient patient;

  const PatientReportsScreen({super.key, required this.patient});

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
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

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes > 0 ? (log(bytes) / log(1024)) : 0).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _downloadAndOpenReport(Report report) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${report.originalName}...')),
    );

    try {
      final bytes = await _apiService.downloadReport(
        widget.patient.patientId,
        report.id,
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${report.originalName}';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Check if it's a PDF or image to use internal viewer
      final isPdf = report.fileType.toLowerCase().contains('pdf');
      final isImage =
          report.fileType.toLowerCase().contains('jpg') ||
          report.fileType.toLowerCase().contains('jpeg') ||
          report.fileType.toLowerCase().contains('png');

      if (isPdf || isImage) {
        // Use internal viewer for PDFs and images
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileViewerScreen(
              filePath: filePath,
              fileName: report.originalName,
              fileType: report.fileType,
            ),
          ),
        );
      } else {
        // Use external app for other file types
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open file: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  IconData _getIconForMimeType(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('text') || mimeType.contains('csv'))
      return Icons.text_snippet;
    if (mimeType.contains('word') || mimeType.contains('document'))
      return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getColorForMimeType(String mimeType) {
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('image')) return Colors.green;
    if (mimeType.contains('text') || mimeType.contains('csv'))
      return Colors.blue;
    if (mimeType.contains('word') || mimeType.contains('document'))
      return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        title: Text('${widget.patient.name} - Reports'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadReports,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Reports Found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No medical reports available for ${widget.patient.name}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getColorForMimeType(
                          report.fileType,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForMimeType(report.fileType),
                        color: _getColorForMimeType(report.fileType),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      report.originalName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${report.fileType.split('/').last.toUpperCase()} • ${_formatBytes(report.fileSize)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (report.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              report.description,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (report.uploadDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Uploaded: ${report.uploadDate!.split(' ')[0]}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download, color: Colors.green),
                      onPressed: () => _downloadAndOpenReport(report),
                      tooltip: 'Download and Open',
                    ),
                    onTap: () => _downloadAndOpenReport(report),
                  ),
                );
              },
            ),
    );
  }
}
