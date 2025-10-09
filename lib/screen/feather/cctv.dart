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
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoSwitcherScreen extends StatefulWidget {
  const VideoSwitcherScreen({super.key});

  @override
  State<VideoSwitcherScreen> createState() => _VideoSwitcherScreenState();
}

class _VideoSwitcherScreenState extends State<VideoSwitcherScreen> {
  // late YoutubePlayerController _controller;

  int selectedVideoIndex = 0;
  final String baseUrl = 'http://192.168.0.43:5000'; // Your local server IP
  bool isRecording = false;
  bool isConnected = false;

  // Recording variables
  String? _usbPath;
  bool _usbConnected = false;
  GlobalKey _repaintKey = GlobalKey();
  Timer? _recordingTimer;
  int _recordingSeconds = 0; // Elapsed recording time
  bool _isRecordingScreen = false;
  List<String> _recordedFiles = [];

  Future<void> checkConnection() async {
    try {
      print("Sending request to $baseUrl/status");

      final response = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(Duration(seconds: 5));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Decoded response: $data");

        setState(() {
          isConnected = data['connected'].toString().toLowerCase() == 'true';
        });

        print("isConnected set to: $isConnected");
      } else {
        setState(() => isConnected = false);
        print("Connection failed with status: ${response.statusCode}");
      }
    } on TimeoutException {
      setState(() => isConnected = false);
      print("Connection timed out - server not responding");
    } catch (e) {
      setState(() => isConnected = false);
      print("Connection error: $e");
    }
  }

  Future<void> startRecording() async {
    print('nsnnss');
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

  String? selectedScene;
  Future<void> switchScene(String sceneName) async {
    try {
      print("Switching to scene: $sceneName");
      final response = await http.get(
        Uri.parse('$baseUrl/switch_scene/${Uri.encodeComponent(sceneName)}'),
      );
      print("Response: ${response.body}");
      final data = jsonDecode(response.body);
      if (data['status'] != null) {
        setState(() => selectedScene = sceneName);
      } else {
        print("Switch error: ${data['error']}");
      }
    } catch (e) {
      print("Error switching scene: $e");
    }
  }

  // Recording Functions
  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    await Permission.microphone.request();
    await Permission.camera.request();
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

  Future<void> _startScreenRecording() async {
    if (!_usbConnected || _usbPath == null) {
      Fluttertoast.showToast(
        msg: "Please select USB storage first",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isRecordingScreen = true;
      _recordingSeconds = 0;
    });

    Fluttertoast.showToast(
      msg: "Screen recording started...",
      gravity: ToastGravity.BOTTOM,
    );

    // In a real implementation, you would use a screen recording package
    // For now, we'll simulate the recording process

    // Start recording timer
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
  }

  Future<void> _stopScreenRecording() async {
    if (!_isRecordingScreen) return;

    setState(() {
      _isRecordingScreen = false;
    });

    _recordingTimer?.cancel();
    _recordingTimer = null;

    // Simulate saving the recording
    try {
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final recordingsDir = Directory(path.join(_usbPath!, 'Recordings'));

      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final outputPath = path.join(recordingsDir.path, fileName);

      // In a real implementation, you would save the actual recording file here
      // For simulation, we'll just create an empty file
      final file = File(outputPath);
      await file.writeAsString("Simulated recording file");

      setState(() {
        _recordedFiles.add(outputPath);
      });

      Fluttertoast.showToast(
        msg: "Recording saved: $fileName",
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to save recording: $e",
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

      // In a real implementation, you would capture the screen using RepaintBoundary
      // For now, we'll simulate it
      final screenshotDir = Directory(path.join(_usbPath!, 'Screenshots'));
      if (!await screenshotDir.exists())
        await screenshotDir.create(recursive: true);

      final fileName =
          'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path.join(screenshotDir.path, fileName));

      // Create a simulated screenshot file
      await file.writeAsString("Simulated screenshot data");

      Fluttertoast.showToast(
        msg: "Screenshot saved: $fileName",
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to capture screenshot: $e",
        gravity: ToastGravity.BOTTOM,
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

    final files = recordingsDir.listSync().whereType<File>().toList();
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
        title: Text("Recorded Files"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileSize = file.lengthSync();
              return ListTile(
                title: Text(path.basename(file.path)),
                subtitle: Text("${fileSize ~/ 1024} KB"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: () {}, // You can implement playback here
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

  late WebViewController _obsController;
  late WebViewController _motionEyeController;
  late WebViewController _motionEyeControllerr;
  late WebViewController _motionEyeControllerrr;
  // late YoutubePlayerController _youtubeController;
  int _selectedStreamIndex = 0; // 0 = OBS, 1 = MotionEye, 2 = YouTube

  final List<String> youtubeUrls = [
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ", // example video
  ];

  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String? _lastStatus;
  String? _lastSid;

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) {
      _showSnackBar('Please enter phone number and message');
      return;
    }

    setState(() {
      _isSending = true;
      _lastStatus = null;
      _lastSid = null;
    });

    // Simulate message sending
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
  void initState() {
    super.initState();
    checkConnection();
    _requestPermissions();
    _loadUSBPath();

    _obsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("http://192.168.0.160:9081"));

    // MotionEye Stream WebView
    _motionEyeController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("http://192.168.0.160:9082"));
    _motionEyeControllerr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("http://192.168.0.160:9083"));
    _motionEyeControllerrr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse("http://192.168.0.160:9084"));
  }

  @override
  void dispose() {
    // _youtubeController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Widget _buildStreamView() {
    switch (_selectedStreamIndex) {
      case 0:
        return RepaintBoundary(
          key: _repaintKey,
          child: WebViewWidget(controller: _obsController),
        );
      case 1:
        return RepaintBoundary(
          key: _repaintKey,
          child: WebViewWidget(controller: _motionEyeController),
        );
      case 2:
        return RepaintBoundary(
          key: _repaintKey,
          child: WebViewWidget(controller: _motionEyeControllerr),
        );
      default:
        return RepaintBoundary(
          key: _repaintKey,
          child: WebViewWidget(controller: _motionEyeControllerrr),
        );
    }
  }

  Widget _buildSwitchButton(String label, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedStreamIndex = index;
        });
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    String timerText =
        "${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      body: Row(
        children: [
          // Left Panel
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
                  // Center(
                  //   child: Text(
                  //     '✅ ${'connect_to'.tr} to WIESPL',
                  //     style: TextStyle(
                  //       fontWeight: FontWeight.bold,
                  //       fontSize: 16,
                  //       color: isConnected ? Colors.green : Colors.green,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: 25),
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
                            "CCTV",
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
                                buildTvItem("${'cctv'.tr}1", 0),
                                buildTvItem("${'cctv'.tr} 2", 1),
                                buildTvItem("${'cctv'.tr} 3", 2),
                                buildTvItem("${'cctv'.tr} 4", 3),
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
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

          // Center Panel
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
                    "Dr. Ajay Kothari",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text("Orthopaedic OT", style: TextStyle(fontSize: 14)),
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
                            buildControlBtn(
                              "start".tr,
                              onPressed: () {
                                print(" pressed");
                                startRecording();
                              },
                            ),
                            buildControlBtn(
                              "stop".tr,
                              onPressed: () {
                                print("STARTTTTT");
                                stopRecording();
                              },
                              icon: isRecording
                                  ? Icons.record_voice_over_rounded
                                  : null,
                            ),
                            // Screen recording buttons
                            buildControlBtn(
                              _isRecordingScreen
                                  ? "Recording... $timerText"
                                  : "Screen Record",
                              onPressed: _isRecordingScreen
                                  ? null
                                  : _startScreenRecording,
                              icon: _isRecordingScreen
                                  ? Icons.circle
                                  : Icons.fiber_manual_record,
                            ),
                            buildControlBtn(
                              "Stop Screen Rec",
                              onPressed: _isRecordingScreen
                                  ? _stopScreenRecording
                                  : null,
                              icon: Icons.stop,
                            ),
                            buildControlBtn(
                              "message".tr,
                              onPressed: () {
                                _showMessageDialog();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            buildControlBtn(
                              "task_ss".tr,
                              icon: Icons.camera_alt,
                              onPressed: _takeScreenshot,
                            ),
                            buildControlBtn(
                              "gallery".tr,
                              icon: Icons.photo_library,
                              onPressed: _viewRecordings,
                            ),
                            buildControlBtn(
                              "USB Storage",
                              icon: Icons.usb,
                              onPressed: _selectUSBDirectory,
                            ),
                            buildControlBtn(
                              "share".tr,
                              icon: Icons.share,
                              onPressed: () {
                                Share.share(
                                  'Invite to Wiespl Meet: https://wiespl.com/',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Panel
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
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DraggableGridScreen(),
                              ),
                            );
                          },
                          child: buildTvItemm("TV 1", 0),
                        ),
                        buildTvItemm("TV 2", 1),
                      ],
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(bottom: 12),
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       // Navigator.push(
                  //       //     context,
                  //       //     MaterialPageRoute(
                  //       //       builder: (context) => YouTubeGridScreen(),
                  //       //     ));
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.green,
                  //     ),
                  //     child: const Text(
                  //       "APPLY",
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildControlBtnn(String label, {IconData? icon}) {
    return SizedBox(
      width: 120,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox(width: 0),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
      ),
    );
  }

  Widget buildControlBtn(
    String label, {
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 120,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox(width: 0),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
      ),
    );
  }

  Widget buildTvItem(String name, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStreamIndex = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text("Playing $name", style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white38),
        ],
      ),
    );
  }

  Widget buildTvItemm(String name, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text("Playing $name", style: const TextStyle(color: Colors.white70)),
        const Divider(color: Colors.white38),
      ],
    );
  }
}
