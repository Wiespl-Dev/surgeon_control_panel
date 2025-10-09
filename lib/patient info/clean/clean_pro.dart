// room_cleanliness_container.dart
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:surgeon_control_panel/provider/room_cleanliness_provider.dart';

class RoomCleanlinessContainer extends StatefulWidget {
  @override
  State<RoomCleanlinessContainer> createState() =>
      _RoomCleanlinessContainerState();
}

class _RoomCleanlinessContainerState extends State<RoomCleanlinessContainer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RoomCleanlinessProvider>(
        context,
        listen: false,
      );
      provider.initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(8, 38, 50, 56),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                'assets/marcel-scholte-LPurJnihmQI-unsplash.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          height: 60,
                          width: 450,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              33,
                              255,
                              255,
                              255,
                            ).withOpacity(0.1),
                            border: Border.all(
                              color: const Color.fromARGB(
                                48,
                                255,
                                255,
                                255,
                              ).withOpacity(0.1),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Room Cleanliness Assessment",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: Colors.black26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        height: 580,
                        width: 700,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ],
              ),
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
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Room Clean',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          provider.usbConnected ? Icons.usb : Icons.usb_off,
                          color: provider.usbConnected
                              ? Colors.green
                              : Colors.orange,
                        ),
                        onPressed: () => _showStorageInfo(context),
                        tooltip: 'Storage Information',
                      ),
                      if (!provider.usbConnected)
                        Text(
                          'Select USB',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: _buildMediaArea(provider),
                ),
              ),
              SizedBox(height: 20),
              _buildActionButtons(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaArea(RoomCleanlinessProvider provider) {
    if (provider.showCameraPreview) {
      if (provider.isCameraInitialized &&
          provider.cameraController != null &&
          provider.cameraController!.value.isInitialized) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CameraPreview(provider.cameraController!),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
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
              size: 60,
              color: Colors.white.withOpacity(0.7),
            ),
            SizedBox(height: 10),
            Text(
              'No Photo Taken',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            Text(
              provider.usbConnected
                  ? '✅ Photos will be saved to USB Storage'
                  : '⚠ Please select USB storage first',
              style: TextStyle(
                color: provider.usbConnected ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (!provider.usbConnected)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.usb),
                  label: Text('Select USB Storage'),
                  onPressed: () => provider.selectUSBDirectory(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButtons(RoomCleanlinessProvider provider) {
    if (provider.showCameraPreview) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.cancel, size: 20),
            label: Text('Cancel'),
            onPressed: () => provider.cancelCamera(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: provider.isTakingPhoto
                ? null
                : () => provider.takePhoto(),
            backgroundColor: provider.isTakingPhoto
                ? Colors.grey
                : Colors.white,
            child: provider.isTakingPhoto
                ? CircularProgressIndicator()
                : Icon(Icons.camera_alt, color: Colors.blue, size: 30),
          ),
        ],
      );
    } else if (provider.capturedImage != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.refresh, size: 20),
            label: Text('Retake'),
            onPressed: () => provider.retakePhoto(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.check, size: 20),
            label: Text('Use Photo'),
            onPressed: () => _processPhotoForAssessment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.camera_alt, size: 20),
            label: Text('Take Photo'),
            onPressed: provider.usbConnected
                ? () => provider.startCamera()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.usbConnected
                  ? Colors.blue.withOpacity(0.8)
                  : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.photo_library, size: 20),
            label: Text('Gallery'),
            onPressed: provider.usbConnected
                ? () => provider.pickImageFromGallery()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.usbConnected
                  ? Colors.purple.withOpacity(0.8)
                  : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
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
    _showAssessmentResults(context, provider.capturedImage!.path);
  }

  void _showStorageInfo(BuildContext context) {
    final provider = Provider.of<RoomCleanlinessProvider>(
      context,
      listen: false,
    );
    String path = provider.usbPath ?? "Not selected";
    String cleanSnapshotPath = provider.cleanSnapshotPath;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💾 Storage Type: ${provider.usbConnected ? "USB Storage" : "Not Selected"}',
            ),
            SizedBox(height: 10),
            Text('📁 USB Path: $path'),
            SizedBox(height: 10),
            Text('📸 Save Location: $cleanSnapshotPath'),
            SizedBox(height: 10),
            provider.usbConnected
                ? Text(
                    '✅ USB storage connected and ready',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    '⚠ Please select USB storage to save photos',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.selectUSBDirectory();
            },
            child: Text('Select USB'),
          ),
        ],
      ),
    );
  }

  void _showAssessmentResults(BuildContext context, String filePath) {
    // Keep your existing _showAssessmentResults method, just update the context usage
    // ... (your existing _showAssessmentResults code)
  }

  void _openFileLocation(BuildContext context, String filePath) {
    // Keep your existing _openFileLocation method, just update the context usage
    // ... (your existing _openFileLocation code)
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
