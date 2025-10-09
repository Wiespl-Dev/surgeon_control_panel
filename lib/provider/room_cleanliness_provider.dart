// providers/room_cleanliness_provider.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

class RoomCleanlinessProvider with ChangeNotifier {
  // Camera state
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  bool _showCameraPreview = false;
  bool _isTakingPhoto = false;
  bool _isDisposing = false;

  // USB Storage state
  String? _usbPath;
  bool _usbConnected = false;
  String _cleanSnapshotPath = '';

  // Getters
  CameraController? get cameraController => _cameraController;
  XFile? get capturedImage => _capturedImage;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get showCameraPreview => _showCameraPreview;
  bool get isTakingPhoto => _isTakingPhoto;
  String? get usbPath => _usbPath;
  bool get usbConnected => _usbConnected;
  String get cleanSnapshotPath => _cleanSnapshotPath;

  // Initialize methods
  Future<void> initializeApp() async {
    await _requestPermissions();
    await _loadUSBPath();
    await _initializeCamera();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.camera,
    ].request();

    if (statuses[Permission.storage]!.isDenied) {
      Fluttertoast.showToast(
        msg: "Storage permission is required for saving photos",
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _loadUSBPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString("usbPath");
    if (savedPath != null && Directory(savedPath).existsSync()) {
      _usbPath = savedPath;
      _usbConnected = true;
      _cleanSnapshotPath = path.join(_usbPath!, 'Clean', 'Snapshot');
      await _createCleanSnapshotFolder();
      notifyListeners();
    }
  }

  Future<void> _createCleanSnapshotFolder() async {
    try {
      if (_cleanSnapshotPath.isNotEmpty) {
        Directory cleanSnapshotDir = Directory(_cleanSnapshotPath);

        if (!await cleanSnapshotDir.exists()) {
          await cleanSnapshotDir.create(recursive: true);
          print('✅ Created folder: $_cleanSnapshotPath');
        } else {
          print('📁 Folder already exists: $_cleanSnapshotPath');
        }

        bool exists = await cleanSnapshotDir.exists();
        if (exists) {
          File testFile = File(
            path.join(_cleanSnapshotPath, 'test_write_permission.txt'),
          );
          await testFile.writeAsString(
            'Test write permission - ${DateTime.now()}',
          );
          await testFile.delete();
          print('✅ Folder is writable: $_cleanSnapshotPath');
        }
      }
    } catch (e) {
      print('❌ Error creating Clean/Snapshot folder: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        _cameraController!.addListener(() {
          if (_cameraController!.value.hasError) {
            print(
              '❌ Camera error: ${_cameraController!.value.errorDescription}',
            );
          }
        });

        await _cameraController!.initialize();

        _isCameraInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error initializing camera: $e");
    }
  }

  // USB Storage methods
  Future<void> selectUSBDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        _usbPath = selectedDirectory;
        _usbConnected = true;
        _cleanSnapshotPath = path.join(_usbPath!, 'Clean', 'Snapshot');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("usbPath", selectedDirectory);

        await _createCleanSnapshotFolder();

        Fluttertoast.showToast(
          msg: "USB Storage Selected: ${path.basename(selectedDirectory)}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        notifyListeners();
      }
    } catch (e) {
      print("Error selecting USB directory: $e");
      Fluttertoast.showToast(
        msg: "Failed to select USB storage",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Camera control methods
  Future<void> takePhoto() async {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        _isTakingPhoto ||
        !_cameraController!.value.isInitialized ||
        _isDisposing) {
      return;
    }

    if (!_usbConnected || _usbPath == null) {
      Fluttertoast.showToast(
        msg: "Please select USB storage first",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    _isTakingPhoto = true;
    notifyListeners();

    try {
      await Future.delayed(Duration(milliseconds: 100));

      final XFile photo = await _cameraController!.takePicture();

      await _stopCameraPreview();

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'Room_Cleanliness_$timestamp.jpg';
      String newPath = path.join(_cleanSnapshotPath, fileName);

      await File(photo.path).copy(newPath);

      try {
        await File(photo.path).delete();
      } catch (e) {
        print('⚠ Could not delete temp file: ${photo.path}');
      }

      _capturedImage = XFile(newPath);
      _showCameraPreview = false;
      _isTakingPhoto = false;
      notifyListeners();
    } catch (e) {
      print("❌ Error taking photo: $e");
      _isTakingPhoto = false;
      notifyListeners();
    }
  }

  Future<void> pickImageFromGallery() async {
    if (!_usbConnected || _usbPath == null) {
      Fluttertoast.showToast(
        msg: "Please select USB storage first",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    if (_showCameraPreview) {
      await _stopCameraPreview();
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'Room_Cleanliness_Gallery_$timestamp.jpg';
      String newPath = path.join(_cleanSnapshotPath, fileName);

      await File(image.path).copy(newPath);

      _capturedImage = XFile(newPath);
      _showCameraPreview = false;
      notifyListeners();
    } else {
      if (_showCameraPreview) {
        await _startCameraPreview();
      }
    }
  }

  Future<void> _stopCameraPreview() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.pausePreview();
      } catch (e) {
        print("Error pausing camera preview: $e");
      }
    }
  }

  Future<void> _startCameraPreview() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isPreviewPaused) {
      try {
        await _cameraController!.resumePreview();
      } catch (e) {
        print("Error resuming camera preview: $e");
      }
    }
  }

  void startCamera() async {
    if (!_isCameraInitialized) {
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initializeCamera();
    }

    _showCameraPreview = true;
    _capturedImage = null;
    notifyListeners();
  }

  void retakePhoto() async {
    _capturedImage = null;
    _showCameraPreview = true;
    notifyListeners();

    await _startCameraPreview();
  }

  void cancelCamera() async {
    await _stopCameraPreview();
    _showCameraPreview = false;
    notifyListeners();
  }

  // Cleanup
  Future<void> disposeCamera() async {
    if (_isDisposing) return;

    _isDisposing = true;

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      print("Error disposing camera: $e");
    } finally {
      _isDisposing = false;
      _isCameraInitialized = false;
    }
  }
}
