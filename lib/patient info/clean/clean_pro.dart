import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/patient%20info/clean/cleanll.dart';
import 'package:surgeon_control_panel/provider/room_cleanliness_provider.dart';
import 'dart:io';

// -------------------------------------------------------------------
// 1. Data Model Class (Moved here for organization)
// -------------------------------------------------------------------
class CleaningProtocolItem {
  final int serialNo;
  final String activity;

  // Editable fields:
  String areaEquipment;
  String selectedDisinfectant;
  bool isSignedOff;

  CleaningProtocolItem({
    required this.serialNo,
    required this.activity,
    required this.areaEquipment,
    required this.selectedDisinfectant,
    this.isSignedOff = false,
  });
}

class RoomCleanlinessContainer extends StatefulWidget {
  @override
  State<RoomCleanlinessContainer> createState() =>
      _RoomCleanlinessContainerState();
}

class _RoomCleanlinessContainerState extends State<RoomCleanlinessContainer> {
  // Define a dark, premium color scheme
  static const Color _primaryAccent = Color(0xFF4FC3F7); // Light blue/cyan
  static const Color _darkBackground = Color(
    0xFF1A1A2E,
  ); // Deep dark blue/purple

  // -------------------------------------------------------------------
  // 2. Data Initialization for Cleaning Protocol
  // -------------------------------------------------------------------
  final List<String> _disinfectantOptions = const [
    '--',
    'Hospital-grade',
    'Chlorine/Quaternary',
    'As per manual',
    'Alcohol/EPA approved',
    'Soap/Alcohol rub',
  ];

  final List<CleaningProtocolItem> _protocolItems = [
    CleaningProtocolItem(
      serialNo: 1,
      activity: 'Remove soiled linen/waste',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 2,
      activity: 'Clean & disinfect high-touch surfaces',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 3,
      activity: 'Clean & disinfect door knobs, switches',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 4,
      activity: 'Sweep & mop floor (esp. around operating area)',
      areaEquipment: 'Floor (1.5 m from table)',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 5,
      activity: 'Clean & disinfect anesthesia machine/carts',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 6,
      activity: 'Clean & disinfect patient monitors/IV poles',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 7,
      activity: 'Clean positioners, arm boards, stirrups',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 8,
      activity: 'Change bin liners',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 9,
      activity: 'Perform hand hygiene after cleaning',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 10,
      activity: 'Ventilate room',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
    CleaningProtocolItem(
      serialNo: 11,
      activity: 'Final walkthrough & checklist completion',
      areaEquipment: '--',
      selectedDisinfectant: '--',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RoomCleanlinessProvider>(
        context,
        listen: false,
      );
      // Initialize cameras and check USB status on launch
      provider.initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Full-screen Background Image with Dark Overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                'assets/marcel-scholte-LPurJnihmQI-unsplash.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Darker overlay for better text/glass readability
            Container(color: Colors.black.withOpacity(0.5)),

            // 2. Main Content Area
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // --- Header (Fixed Height) ---
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 20),

                  // Main Content Area with Camera and Table
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Side - Camera Section
                          Expanded(
                            flex: 1,
                            child: _buildGlassContainer(child: _buildContent()),
                          ),
                          const SizedBox(width: 20),

                          // Right Side - Cleaning Protocol Table
                          Expanded(
                            flex: 2,
                            child: _buildGlassContainer(
                              child: _buildCleaningProtocolTable(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Action Buttons (Fixed Height) ---
                  SizedBox(width: 700, child: _buildActionButtons(context)),

                  // Added small spacing at the very bottom
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer({double? height, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryAccent.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: -10,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = Provider.of<RoomCleanlinessProvider>(context);

    return _buildGlassContainer(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back, color: Colors.white),
            ),
            Text(
              "Room Cleanliness Assessment",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            IconButton(
              icon: Icon(
                provider.usbConnected ? Icons.usb : Icons.usb_off,
                color: provider.usbConnected
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                size: 24,
              ),
              onPressed: () => _showStorageInfo(context),
              tooltip: 'Storage Information',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<RoomCleanlinessProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STATUS: ${provider.showCameraPreview
                        ? "Camera Live"
                        : provider.capturedImage != null
                        ? "Photo Ready"
                        : "Awaiting Input"}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _primaryAccent.withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  if (!provider.usbConnected)
                    Text(
                      '⚠ USB Required',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              const Divider(color: Colors.white30, height: 20),

              // Media Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _buildMediaArea(provider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCleaningProtocolTable() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Table Header
          Text(
            'Cleaning Protocol Checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      _primaryAccent.withOpacity(0.2),
                    ),
                    columnSpacing: 12.0,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 80,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'No.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Cleaning Activity',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Area/Equipment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Disinfectant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Sign-off',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    rows: _protocolItems.map((item) {
                      return DataRow(
                        cells: [
                          // Serial No.
                          DataCell(
                            Text(
                              item.serialNo.toString(),
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),

                          // Cleaning Activity (Read-only)
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(
                                item.activity,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),

                          // Area/Equipment (TextFormField)
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                initialValue: item.areaEquipment,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _primaryAccent,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.4),
                                ),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white,
                                ),
                                onChanged: (newValue) {
                                  setState(() {
                                    item.areaEquipment = newValue;
                                  });
                                },
                              ),
                            ),
                          ),

                          // Disinfectant Used (DropdownButtonFormField)
                          DataCell(
                            SizedBox(
                              width: 140,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _primaryAccent,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.4),
                                ),
                                value: item.selectedDisinfectant,
                                dropdownColor: _darkBackground,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white,
                                ),
                                items: _disinfectantOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    item.selectedDisinfectant =
                                        newValue ?? _disinfectantOptions.first;
                                  });
                                },
                              ),
                            ),
                          ),

                          // Sign-off (Checkbox)
                          DataCell(
                            Consumer<RoomCleanlinessProvider>(
                              builder: (context, provider, child) {
                                return Checkbox(
                                  value: item.isSignedOff,
                                  checkColor: Colors.black,
                                  fillColor:
                                      MaterialStateProperty.resolveWith<Color>((
                                        Set<MaterialState> states,
                                      ) {
                                        if (states.contains(
                                          MaterialState.selected,
                                        )) {
                                          return _primaryAccent;
                                        }
                                        return Colors.white30;
                                      }),
                                  onChanged: (bool? newValue) async {
                                    if (newValue == true &&
                                        provider.usbConnected) {
                                      // Auto-take photo when checkbox is checked
                                      await _autoTakePhotoForActivity(
                                        provider,
                                        item,
                                      );
                                    }
                                    setState(() {
                                      item.isSignedOff = newValue ?? false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // Submit Button
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // Log the final data
              print('--- Final Protocol Data ---');
              for (var item in _protocolItems) {
                print(
                  'No: ${item.serialNo} | Activity: ${item.activity} | Area: ${item.areaEquipment} | Disinfectant: ${item.selectedDisinfectant} | Signed Off: ${item.isSignedOff ? "OK" : "NOT OK"}',
                );
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CleanControlApp()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cleaning Protocol Data Collected!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Submit Protocol Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _autoTakePhotoForActivity(
    RoomCleanlinessProvider provider,
    CleaningProtocolItem item,
  ) async {
    if (!provider.usbConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select USB storage first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ensure camera is started
    if (!provider.showCameraPreview) {
      provider.startCamera();
      // Wait for camera to initialize
      await Future.delayed(Duration(milliseconds: 1000));
    }

    // Take photo with activity name as filename
    final String fileName =
        '${item.serialNo}_${_sanitizeFileName(item.activity)}.jpg';

    try {
      await provider.takePhotoWithCustomName(fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo saved for: ${item.activity}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _sanitizeFileName(String input) {
    // Remove or replace characters that are not allowed in filenames
    return input
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '_',
        ) // Replace invalid filename characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .replaceAll(
          RegExp(r'_+'),
          '_',
        ) // Replace multiple underscores with single
        .trim()
        .toLowerCase();
  }

  Widget _buildMediaArea(RoomCleanlinessProvider provider) {
    if (provider.showCameraPreview) {
      if (provider.isCameraInitialized && provider.cameraController != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AspectRatio(
            aspectRatio: provider.cameraController!.value.aspectRatio,
            child: CameraPreview(provider.cameraController!),
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _primaryAccent),
              const SizedBox(height: 20),
              Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );
      }
    } else if (provider.capturedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(provider.capturedImage!.path),
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Ready for Room Assessment',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              provider.usbConnected
                  ? 'Photos will be saved to USB Storage'
                  : '⚠ Please select USB storage first to enable photo capture.',
              style: TextStyle(
                color: provider.usbConnected
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (!provider.usbConnected)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: _buildGlassButton(
                  label: 'Select USB Storage',
                  icon: Icons.usb,
                  color: Colors.orange,
                  onPressed: () => _selectUSBAndStartCamera(provider),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return _buildGlassButton(
      label: label,
      icon: icon,
      color: color,
      onPressed: onPressed,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final provider = Provider.of<RoomCleanlinessProvider>(
      context,
      listen: false,
    );

    if (provider.showCameraPreview) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Cancel',
            Icons.cancel,
            Colors.red,
            () => provider.cancelCamera(),
          ),
          FloatingActionButton(
            onPressed: provider.isTakingPhoto
                ? null
                : () => provider.takePhoto(),
            backgroundColor: provider.isTakingPhoto
                ? Colors.grey
                : _primaryAccent,
            child: provider.isTakingPhoto
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.camera, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 120),
        ],
      );
    } else if (provider.capturedImage != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Retake Photo',
            Icons.refresh,
            Colors.orange,
            () => provider.retakePhoto(),
          ),
          _buildActionButton(
            'Use Photo',
            Icons.check,
            Colors.green,
            () => _processPhotoForAssessment(context),
          ),
        ],
      );
    } else {
      // Only show "Take Photo" button when USB is connected
      return Center(
        child: _buildActionButton(
          'Take Photo',
          Icons.camera_alt,
          Colors.blue,
          provider.usbConnected ? () => provider.startCamera() : null,
        ),
      );
    }
  }

  void _processPhotoForAssessment(BuildContext context) {
    final provider = Provider.of<RoomCleanlinessProvider>(
      context,
      listen: false,
    );
    if (provider.capturedImage == null) return;
    print('Processing photo for assessment: ${provider.capturedImage!.path}');
  }

  void _selectUSBAndStartCamera(RoomCleanlinessProvider provider) async {
    // First select USB directory
    await provider.selectUSBDirectory();

    // If USB is successfully connected, automatically start the camera
    if (provider.usbConnected) {
      // Add a small delay to ensure USB selection is complete
      await Future.delayed(Duration(milliseconds: 500));
      provider.startCamera();
    }
  }

  void _showStorageInfo(BuildContext context) {
    final provider = Provider.of<RoomCleanlinessProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkBackground,
        title: Text(
          'Storage Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💾 Storage Type: ${provider.usbConnected ? "USB Storage" : "Not Selected"}',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              '📁 USB Path: ${provider.usbPath ?? "Not selected"}',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: _primaryAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectUSBAndStartCamera(provider);
            },
            child: Text('Select USB', style: TextStyle(color: _primaryAccent)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final provider = Provider.of<RoomCleanlinessProvider>(
      context,
      listen: false,
    );
    provider.disposeCamera();
    super.dispose();
  }
}
