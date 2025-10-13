// recording_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:path/path.dart' as path;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingScreen extends StatefulWidget {
  final String cctvUrl;
  final String cctvName;
  final String? usbPath;

  const RecordingScreen({
    Key? key,
    required this.cctvUrl,
    required this.cctvName,
    required this.usbPath,
  }) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  String? _currentRecordingPath;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    // Initialize WebView controller with the provided URL
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.cctvUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print("Page started loading: $url");
          },
          onPageFinished: (url) {
            print("Page finished loading: $url");
          },
          onWebResourceError: (error) {
            print("WebView error: ${error.description}");
          },
        ),
      );

    // Start recording after a short delay to ensure WebView is loaded
    Future.delayed(Duration(seconds: 2), () {
      _startRecording();
    });
  }

  Future<void> _startRecording() async {
    if (widget.usbPath == null) {
      Fluttertoast.showToast(
        msg: "USB storage not available",
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    try {
      final recordingsDir = Directory(path.join(widget.usbPath!, 'Recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final fileName =
          '${widget.cctvName}_recording_${DateTime.now().millisecondsSinceEpoch}';

      print("Starting recording for: ${widget.cctvName}");
      print("URL: ${widget.cctvUrl}");

      bool started = await FlutterScreenRecording.startRecordScreen(fileName);

      if (started) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });

        Fluttertoast.showToast(
          msg: "Recording ${widget.cctvName}...",
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
        );

        // Start recording timer
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed to start recording",
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print("Error starting recording: $e");
      Fluttertoast.showToast(
        msg: "Error starting recording: $e",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      print("Stopping recording...");
      String? outputPath = await FlutterScreenRecording.stopRecordScreen;

      if (outputPath != null && File(outputPath).existsSync()) {
        print("Original recording path: $outputPath");

        // Move the file to USB directory
        final recordingsDir = Directory(
          path.join(widget.usbPath!, 'Recordings'),
        );
        final newFilePath = path.join(
          recordingsDir.path,
          '${widget.cctvName}_recording_${DateTime.now().millisecondsSinceEpoch}.mp4',
        );

        print("Moving recording to: $newFilePath");
        await File(outputPath).copy(newFilePath);
        await File(outputPath).delete(); // Clean up original file

        _currentRecordingPath = newFilePath;

        Fluttertoast.showToast(
          msg: "Recording saved: ${path.basename(newFilePath)}",
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
        );
      } else {
        print("No output file received or file doesn't exist");
        Fluttertoast.showToast(
          msg: "Failed to save recording - no output file",
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print("Error stopping recording: $e");
      Fluttertoast.showToast(
        msg: "Error stopping recording: $e",
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Return to previous screen
      Navigator.pop(context, _currentRecordingPath);
    }
  }

  String _formatTime(int seconds) {
    return "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen WebView
          Positioned.fill(child: WebViewWidget(controller: _webViewController)),

          // Recording overlay
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                // color: Colors.red.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text(
                      "REC ${_formatTime(_recordingSeconds)} - ${widget.cctvName}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.fiber_smart_record_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator while WebView loads
          Positioned.fill(
            child: _isRecording
                ? SizedBox()
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          "Loading ${widget.cctvName}...",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Recording will start automatically",
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
          ),

          // Stop button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: Icon(Icons.stop, size: 24),
                label: Text(
                  "STOP RECORDING",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D8A8F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
              ),
            ),
          ),

          // Back button (optional)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: _stopRecording,
            ),
          ),
        ],
      ),
    );
  }
}
