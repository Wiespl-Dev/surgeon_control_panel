import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:surgeon_control_panel/screen/feather/allcctv/allcctv.dart';
import 'package:surgeon_control_panel/screen/rec/recording_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

class VideoSwitcherScreen extends StatefulWidget {
  const VideoSwitcherScreen({super.key});

  @override
  State<VideoSwitcherScreen> createState() => _VideoSwitcherScreenState();
}

class _VideoSwitcherScreenState extends State<VideoSwitcherScreen> {
  int selectedVideoIndex = 0;
  final String baseUrl = 'http://192.168.0.43:5000';
  bool isRecording = false;
  bool isConnected = false;

  // NEW: Full screen state variable
  bool _isFullScreen = false;

  // Recording variables
  String? _usbPath;
  bool _usbConnected = false;
  GlobalKey _repaintKey = GlobalKey();
  List<String> _recordedFiles = [];

  // WebView controllers
  late WebViewController _obsController;
  late WebViewController _motionEyeController;
  late WebViewController _motionEyeControllerr;
  late WebViewController _motionEyeControllerrr;
  int _selectedStreamIndex = 0;

  // Message variables
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String? _lastStatus;
  String? _lastSid;

  // CCTV list for recording selection
  final List<Map<String, dynamic>> cctvList = [
    {'name': 'CCTV 1', 'controller': null, 'url': 'http://192.168.1.248:9081'},
    // {'name': 'CCTV 2', 'controller': null, 'url': 'http://192.168.1.248:9081'},
    // {'name': 'CCTV 3', 'controller': null, 'url': 'http://192.168.1.248:9081'},
    // {'name': 'CCTV 4', 'controller': null, 'url': 'http://192.168.1.248:9081'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize WebView controllers
    _obsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(cctvList[0]['url']));

    _motionEyeController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(cctvList[0]['url']));

    _motionEyeControllerr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(cctvList[0]['url']));

    _motionEyeControllerrr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(cctvList[0]['url']));

    // Assign controllers to CCTV list
    cctvList[0]['controller'] = _obsController;

    checkConnection();
    _requestPermissions();
    _loadUSBPath();
  }

  // NEW: Toggle full screen method
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  // NEW: Build full screen view
  Widget _buildFullScreenView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main WebView in full screen
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: _getWebViewByIndex(_selectedStreamIndex),
            ),
          ),

          // Exit full screen button (top right)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.fullscreen_exit,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _toggleFullScreen,
              ),
            ),
          ),

          // Stream name indicator (top left)
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cctvList[_selectedStreamIndex]['name'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Control buttons at bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFullScreenControlBtn(
                    Icons.videocam,
                    "Record",
                    onPressed: _showRecordingSelectionDialog,
                  ),
                  SizedBox(width: 16),
                  _buildFullScreenControlBtn(
                    Icons.camera_alt,
                    "Screenshot",
                    onPressed: _takeScreenshot,
                  ),
                  SizedBox(width: 16),
                  _buildFullScreenControlBtn(
                    Icons.fullscreen_exit,
                    "Exit Full",
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Build control button for full screen mode
  Widget _buildFullScreenControlBtn(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  // If in full screen mode, return the full screen view
  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenView();
    }

    return Scaffold(
      body: Row(
        children: [
          // Left Panel (OR Camera List)
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 40, 123, 131),
                    Color.fromARGB(255, 39, 83, 87),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 40, 123, 131),
                            Color.fromARGB(255, 39, 83, 87),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            "OR Camera",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Divider(color: Colors.white38),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              children: [
                                _buildStreamItem("C arm", 0),
                                // _buildStreamItem("Laproscope", 1),
                                // _buildStreamItem("OT Light Camera", 2),
                                // _buildStreamItem("Navigation system", 3),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "BACK",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Panel (Main Stream View)
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 40, 123, 131),
                    Color.fromARGB(255, 39, 83, 87),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Tn Shukla EYE Hospital",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildStreamView(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // NEW: Added Full Screen button
                            buildControlBtn(
                              "Full Screen",
                              onPressed: _toggleFullScreen,
                              icon: Icons.fullscreen,
                            ),
                            buildControlBtn(
                              "Record CCTV",
                              onPressed: _showRecordingSelectionDialog,
                              icon: Icons.videocam,
                            ),
                            buildControlBtn(
                              "Take Screenshot",
                              icon: Icons.camera_alt,
                              onPressed: _takeScreenshot,
                            ),
                            buildControlBtn(
                              "USB Storage",
                              icon: Icons.usb,
                              onPressed: _selectUSBDirectory,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Panel (TV List)
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 40, 123, 131),
                    Color.fromARGB(255, 39, 83, 87),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0),
                    child: Text(
                      "TV List",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white38),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [InkWell(child: buildTvItemm("Screen 1", 0))],
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

  // ... (Keep all your existing methods below exactly as they are)
  // checkConnection, _showRecordingSelectionDialog, _startCCTVRecording,
  // startRecording, stopRecording, _requestPermissions, _loadUSBPath,
  // _selectUSBDirectory, _takeScreenshot, _viewRecordings, _shareFile,
  // _sendMessage, _showSnackBar, _showMessageDialog, _buildStreamView,
  // _getWebViewByIndex, buildControlBtn, _buildStreamItem, buildTvItemm

  // Existing methods (keep them as they are):
  Future<void> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isConnected = data['connected'].toString().toLowerCase() == 'true';
        });
      } else {
        setState(() => isConnected = false);
      }
    } catch (e) {
      setState(() => isConnected = false);
    }
  }

  void _showRecordingSelectionDialog() {
    if (!_usbConnected || _usbPath == null) {
      Fluttertoast.showToast(
        msg: "Please select USB storage first",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.video_camera_front_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Select CCTV to Record",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      "Choose a camera to start recording",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cctvList.length,
                        itemBuilder: (context, index) {
                          final cctv = cctvList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                cctv['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                "Tap to start recording",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _startCCTVRecording(cctv);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startCCTVRecording(Map<String, dynamic> cctv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingScreen(
          cctvUrl: cctv['url'],
          cctvName: cctv['name'],
          usbPath: _usbPath,
        ),
      ),
    ).then((savedFilePath) {
      if (savedFilePath != null) {
        setState(() {
          _recordedFiles.add(savedFilePath);
        });
        Fluttertoast.showToast(
          msg: "Recording completed and saved!",
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
        );
      }
    });
  }

  Future<void> startRecording() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/start_recording'));
      final data = jsonDecode(response.body);
      if (data['status'] != null) {
        setState(() => isRecording = true);
      }
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stop_recording'));
      final data = jsonDecode(response.body);
      if (data['status'] != null) {
        setState(() => isRecording = false);
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.microphone,
      Permission.camera,
      Permission.systemAlertWindow,
    ].request();

    if (statuses[Permission.storage]!.isDenied) {
      Fluttertoast.showToast(
        msg: "Storage permission is required for recording",
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _loadUSBPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString("usbPath");
    if (savedPath != null && Directory(savedPath).existsSync()) {
      setState(() {
        _usbPath = savedPath;
        _usbConnected = true;
      });
    }
  }

  Future<void> _selectUSBDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        setState(() {
          _usbPath = selectedDirectory;
          _usbConnected = true;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("usbPath", selectedDirectory);

        Fluttertoast.showToast(
          msg: "USB Storage Selected: ${path.basename(selectedDirectory)}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
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

  Future<void> _takeScreenshot() async {
    try {
      if (!_usbConnected || _usbPath == null) {
        Fluttertoast.showToast(
          msg: "Please select USB storage first",
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      await Future.delayed(Duration(milliseconds: 200));

      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception("Failed to capture screenshot bytes");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final screenshotDir = Directory(path.join(_usbPath!, 'Screenshots'));
      if (!await screenshotDir.exists()) {
        await screenshotDir.create(recursive: true);
      }

      final cctvName = cctvList[_selectedStreamIndex]['name'];
      final fileName =
          '${cctvName}_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path.join(screenshotDir.path, fileName));
      await file.writeAsBytes(pngBytes);

      Fluttertoast.showToast(
        msg:
            "Screenshot saved: $fileName\nSize: ${file.lengthSync() ~/ 1024} KB",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print("Failed to capture screenshot: $e");
      Fluttertoast.showToast(
        msg: "Failed to capture screenshot",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _viewRecordings() async {
    if (_usbPath == null || !Directory(_usbPath!).existsSync()) {
      Fluttertoast.showToast(
        msg: "USB storage not available",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final recordingsDir = Directory(path.join(_usbPath!, 'Recordings'));
    if (!recordingsDir.existsSync()) {
      Fluttertoast.showToast(
        msg: "No recordings found",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final files = recordingsDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.mp4'))
        .toList();

    if (files.isEmpty) {
      Fluttertoast.showToast(
        msg: "No recordings found",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Recorded Videos"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileSize = file.lengthSync();
              return ListTile(
                leading: Icon(Icons.videocam, color: Colors.blue),
                title: Text(path.basename(file.path)),
                subtitle: Text("${fileSize ~/ (1024 * 1024)} MB"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () => _shareFile(file),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        file.deleteSync();
                        Navigator.pop(context);
                        _viewRecordings();
                        Fluttertoast.showToast(
                          msg: "File deleted",
                          gravity: ToastGravity.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _shareFile(File file) {
    Share.shareXFiles([XFile(file.path)], text: 'Check out this recording');
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) {
      _showSnackBar('Please enter a message');
      return;
    }

    setState(() {
      _isSending = true;
      _lastStatus = null;
      _lastSid = null;
    });

    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isSending = false;
      _lastStatus = 'Message sent successfully!';
      _lastSid = 'SM1234567890';
    });

    _showSnackBar(_lastStatus!);
    if (_lastSid != null) {
      _messageController.clear();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _lastSid != null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showMessageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New WhatsApp Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    prefixIcon: const Icon(
                      Icons.message,
                      color: Colors.white54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white38,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSending
                        ? null
                        : () async {
                            await _sendMessage();
                            if (!_isSending) Navigator.pop(context);
                          },
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Send Message',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildStreamView() {
    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        color: Colors.black,
        child: _getWebViewByIndex(_selectedStreamIndex),
      ),
    );
  }

  Widget _getWebViewByIndex(int index) {
    switch (index) {
      case 0:
        return WebViewWidget(controller: _obsController);
      case 1:
        return WebViewWidget(controller: _motionEyeController);
      case 2:
        return WebViewWidget(controller: _motionEyeControllerr);
      default:
        return WebViewWidget(controller: _motionEyeControllerrr);
    }
  }

  Widget buildControlBtn(
    String label, {
    IconData? icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 140,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 16, color: color != null ? Colors.white : null)
            : const SizedBox(width: 0),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color != null ? Colors.white : Colors.black),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.white,
          foregroundColor: color != null ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStreamItem(String name, int index) {
    final isSelected = _selectedStreamIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedStreamIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(height: 40),
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.lightGreenAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Text(
            isSelected ? "LIVE" : "Select to view",
            style: TextStyle(
              color: isSelected ? Colors.greenAccent : Colors.white70,
              fontSize: 28,
            ),
          ),
          const Divider(color: Colors.white38),
        ],
      ),
    );
  }

  Widget buildTvItemm(String name, int index) {
    return InkWell(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => DraggableGridScreen()),
        // );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          const Divider(color: Colors.white38),
        ],
      ),
    );
  }
}
