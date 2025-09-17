// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter_screen_recording/flutter_screen_recording.dart';

// class VideoSwitcherScreen extends StatefulWidget {
//   const VideoSwitcherScreen({super.key});

//   @override
//   State<VideoSwitcherScreen> createState() => _VideoSwitcherScreenState();
// }

// class _VideoSwitcherScreenState extends State<VideoSwitcherScreen> {
//   // Video player variables
//   late VideoPlayerController _videoController;
//   bool _isVideoInitialized = false;
//   GlobalKey _repaintKey = GlobalKey();

//   // Recording variables
//   String? _usbPath;
//   bool _usbConnected = false;
//   bool _isRecording = false;
//   List<String> _recordedFiles = [];
//   Timer? _recordingTimer;
//   int _recordingSeconds = 0;

//   // Other variables
//   final String baseUrl = 'http://192.168.0.43:5000';
//   bool isConnected = false;
//   int _selectedStreamIndex = 0;
//   final TextEditingController _messageController = TextEditingController();
//   bool _isSending = false;
//   String? _lastStatus;
//   String? _lastSid;

//   // List of video URLs for different streams
//   final List<String> videoUrls = [
//     "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
//     "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
//     "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
//     "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//     _loadUSBPath();
//     _requestPermissions();
//     checkConnection();
//   }

//   Future<void> _initializeVideo() async {
//     try {
//       _videoController = VideoPlayerController.networkUrl(
//         Uri.parse(videoUrls[_selectedStreamIndex]),
//       );

//       await _videoController.initialize();
//       setState(() {
//         _isVideoInitialized = true;
//       });

//       _videoController.play();
//       _videoController.setLooping(true);
//     } catch (e) {
//       print("Error initializing video: $e");
//       Fluttertoast.showToast(
//         msg: "Failed to load video",
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   Future<void> _switchVideo(int index) async {
//     if (index == _selectedStreamIndex) return;

//     // Dispose current controller
//     _videoController.dispose();

//     setState(() {
//       _selectedStreamIndex = index;
//       _isVideoInitialized = false;
//     });

//     // Initialize new video
//     await _initializeVideo();
//   }

//   Future<void> checkConnection() async {
//     try {
//       final response = await http
//           .get(Uri.parse('$baseUrl/status'))
//           .timeout(Duration(seconds: 5));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           isConnected = data['connected'].toString().toLowerCase() == 'true';
//         });
//       } else {
//         setState(() => isConnected = false);
//       }
//     } catch (e) {
//       setState(() => isConnected = false);
//     }
//   }

//   Future<void> startRecording() async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/start_recording'));
//       final data = jsonDecode(response.body);
//       if (data['status'] != null) {
//         setState(() => _isRecording = true);
//       }
//     } catch (e) {
//       print("Error starting recording: $e");
//     }
//   }

//   Future<void> stopRecording() async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/stop_recording'));
//       final data = jsonDecode(response.body);
//       if (data['status'] != null) {
//         setState(() => _isRecording = false);
//       }
//     } catch (e) {
//       print("Error stopping recording: $e");
//     }
//   }

//   // Recording Functions
//   Future<void> _requestPermissions() async {
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.storage,
//       Permission.microphone,
//       Permission.camera,
//     ].request();

//     if (statuses[Permission.storage]!.isDenied ||
//         statuses[Permission.microphone]!.isDenied) {
//       Fluttertoast.showToast(
//         msg: "Storage and microphone permissions are required for recording",
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   Future<void> _loadUSBPath() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedPath = prefs.getString("usbPath");
//     if (savedPath != null && Directory(savedPath).existsSync()) {
//       setState(() {
//         _usbPath = savedPath;
//         _usbConnected = true;
//       });
//     }
//   }

//   Future<void> _selectUSBDirectory() async {
//     try {
//       String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
//       if (selectedDirectory != null) {
//         setState(() {
//           _usbPath = selectedDirectory;
//           _usbConnected = true;
//         });

//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString("usbPath", selectedDirectory);

//         Fluttertoast.showToast(
//           msg: "USB Storage Selected: ${path.basename(selectedDirectory)}",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//         );
//       }
//     } catch (e) {
//       print("Error selecting USB directory: $e");
//       Fluttertoast.showToast(
//         msg: "Failed to select USB storage",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   Future<void> _startScreenRecording() async {
//     if (!_usbConnected || _usbPath == null) {
//       Fluttertoast.showToast(
//         msg: "Please select USB storage first",
//         gravity: ToastGravity.BOTTOM,
//       );
//       return;
//     }

//     try {
//       final recordingsDir = Directory(path.join(_usbPath!, 'Recordings'));
//       if (!await recordingsDir.exists()) {
//         await recordingsDir.create(recursive: true);
//       }

//       final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}';

//       bool started = await FlutterScreenRecording.startRecordScreen(fileName);

//       if (started) {
//         setState(() {
//           _isRecording = true;
//           _recordingSeconds = 0;
//         });

//         Fluttertoast.showToast(
//           msg: "Recording started...",
//           gravity: ToastGravity.BOTTOM,
//         );

//         // Start recording timer
//         _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
//           setState(() {
//             _recordingSeconds++;
//           });
//         });
//       } else {
//         Fluttertoast.showToast(
//           msg: "Failed to start recording",
//           gravity: ToastGravity.BOTTOM,
//         );
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error starting recording: $e",
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   Future<void> _stopScreenRecording() async {
//     if (!_isRecording) return;

//     try {
//       String? outputPath = await FlutterScreenRecording.stopRecordScreen;
//       if (outputPath != null) {
//         // Move the file to the specified USB directory
//         final recordingsDir = Directory(path.join(_usbPath!, 'Recordings'));
//         final newFilePath = path.join(
//           recordingsDir.path,
//           'recording_${DateTime.now().millisecondsSinceEpoch}.mp4',
//         );
//         await File(outputPath).copy(newFilePath);
//         await File(outputPath).delete(); // Optional: delete the original file

//         setState(() {
//           _isRecording = false;
//           _recordedFiles.add(newFilePath);
//         });

//         _recordingTimer?.cancel();
//         _recordingTimer = null;

//         Fluttertoast.showToast(
//           msg: "Recording saved: ${path.basename(newFilePath)}",
//           gravity: ToastGravity.BOTTOM,
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: "Failed to save recording",
//           gravity: ToastGravity.BOTTOM,
//         );
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error stopping recording: $e",
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   Future<void> _takeScreenshot() async {
//     try {
//       if (!_usbConnected || _usbPath == null) {
//         Fluttertoast.showToast(
//           msg: "Please select USB storage first",
//           gravity: ToastGravity.BOTTOM,
//         );
//         return;
//       }

//       RenderRepaintBoundary boundary =
//           _repaintKey.currentContext!.findRenderObject()
//               as RenderRepaintBoundary;
//       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData = await image.toByteData(
//         format: ui.ImageByteFormat.png,
//       );
//       if (byteData == null) throw Exception("Failed to capture screenshot");

//       Uint8List pngBytes = byteData.buffer.asUint8List();
//       final screenshotDir = Directory(path.join(_usbPath!, 'Screenshots'));
//       if (!await screenshotDir.exists())
//         await screenshotDir.create(recursive: true);

//       final fileName =
//           'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
//       final file = File(path.join(screenshotDir.path, fileName));
//       await file.writeAsBytes(pngBytes);

//       Fluttertoast.showToast(
//         msg:
//             "Screenshot saved: $fileName\nSize: ${file.lengthSync() ~/ 1024} KB",
//         gravity: ToastGravity.BOTTOM,
//       );
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Failed to capture screenshot: $e",
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   Future<void> _playRecordedVideo(String filePath) async {
//     try {
//       final file = File(filePath);
//       if (!await file.exists()) {
//         Fluttertoast.showToast(
//           msg: "File not found",
//           gravity: ToastGravity.BOTTOM,
//         );
//         return;
//       }

//       final videoController = VideoPlayerController.file(file);
//       await videoController.initialize();

//       // Ensure the controller is properly initialized before showing dialog
//       if (videoController.value.isInitialized) {
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text("Playing Recorded Video"),
//             content: SizedBox(
//               width: 300,
//               height: 200,
//               child: VideoPlayer(videoController),
//             ),
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.play_arrow),
//                 onPressed: () => videoController.play(),
//               ),
//               IconButton(
//                 icon: Icon(Icons.pause),
//                 onPressed: () => videoController.pause(),
//               ),
//               TextButton(
//                 onPressed: () {
//                   videoController.dispose();
//                   Navigator.pop(context);
//                 },
//                 child: Text("Close"),
//               ),
//             ],
//           ),
//         );

//         // Auto-play the video
//         await videoController.play();
//       } else {
//         Fluttertoast.showToast(
//           msg: "Failed to initialize video player",
//           gravity: ToastGravity.BOTTOM,
//         );
//         videoController.dispose();
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Cannot play video: $e",
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }

//   Future<void> _viewRecordings() async {
//     if (_usbPath == null || !Directory(_usbPath!).existsSync()) {
//       Fluttertoast.showToast(
//         msg: "USB storage not available",
//         gravity: ToastGravity.BOTTOM,
//       );
//       return;
//     }

//     final recordingsDir = Directory(path.join(_usbPath!, 'Recordings'));
//     if (!recordingsDir.existsSync()) {
//       Fluttertoast.showToast(
//         msg: "No recordings found",
//         gravity: ToastGravity.BOTTOM,
//       );
//       return;
//     }

//     final files = recordingsDir.listSync().whereType<File>().toList();
//     if (files.isEmpty) {
//       Fluttertoast.showToast(
//         msg: "No recordings found",
//         gravity: ToastGravity.BOTTOM,
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Recorded Files"),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: files.length,
//             itemBuilder: (context, index) {
//               final file = files[index];
//               final fileSize = file.lengthSync();
//               return ListTile(
//                 title: Text(path.basename(file.path)),
//                 subtitle: Text("${fileSize ~/ 1024} KB"),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.play_arrow),
//                       onPressed: () => _playRecordedVideo(file.path),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.delete),
//                       onPressed: () {
//                         file.deleteSync();
//                         Navigator.pop(context);
//                         _viewRecordings();
//                         Fluttertoast.showToast(
//                           msg: "File deleted",
//                           gravity: ToastGravity.BOTTOM,
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.isEmpty) {
//       _showSnackBar('Please enter a message');
//       return;
//     }

//     setState(() {
//       _isSending = true;
//       _lastStatus = null;
//       _lastSid = null;
//     });

//     // Simulate message sending
//     await Future.delayed(Duration(seconds: 2));

//     setState(() {
//       _isSending = false;
//       _lastStatus = 'Message sent successfully!';
//       _lastSid = 'SM1234567890';
//     });

//     _showSnackBar(_lastStatus!);
//     if (_lastSid != null) {
//       _messageController.clear();
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: _lastSid != null ? Colors.green : Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void _showMessageDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'New WhatsApp Message',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.grey),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: _messageController,
//                   decoration: InputDecoration(
//                     labelText: 'Message',
//                     prefixIcon: const Icon(
//                       Icons.message,
//                       color: Colors.white54,
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     filled: true,
//                     fillColor: Colors.white38,
//                   ),
//                   maxLines: 5,
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white54,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     onPressed: _isSending
//                         ? null
//                         : () async {
//                             await _sendMessage();
//                             if (!_isSending) Navigator.pop(context);
//                           },
//                     child: _isSending
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.send, size: 20),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Send Message',
//                                 style: TextStyle(fontSize: 16),
//                               ),
//                             ],
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _videoController.dispose();
//     _recordingTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     String timerText =
//         "${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}";

//     return Scaffold(
//       body: Row(
//         children: [
//           // Left Panel
//           Expanded(
//             flex: 1,
//             child: Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Text(
//                       '✅ ${'connect_to'.tr} to WIESPL',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: isConnected ? Colors.green : Colors.green,
//                       ),
//                     ),
//                   ),

//                   const Divider(color: Colors.white38),
//                   Expanded(
//                     flex: 1,
//                     child: Container(
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                         ),
//                       ),
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 16),
//                           const Text(
//                             "CCTV",
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const Divider(color: Colors.white38),
//                           const SizedBox(height: 12),
//                           Expanded(
//                             child: ListView(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                               ),
//                               children: [
//                                 buildTvItem("${'cctv'.tr}1", 0),
//                                 buildTvItem("${'cctv'.tr} 2", 1),
//                                 buildTvItem("${'cctv'.tr} 3", 2),
//                                 buildTvItem("${'cctv'.tr} 4", 3),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 16.0),
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 40,
//                           vertical: 12,
//                         ),
//                       ),
//                       child: const Text(
//                         "BACK",
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Center Panel - Video Player
//           Expanded(
//             flex: 3,
//             child: Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   const SizedBox(height: 10),
//                   const Text(
//                     "Dr. Ajay Kothari",
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   const Text("Orthopaedic OT", style: TextStyle(fontSize: 14)),
//                   const SizedBox(height: 6),

//                   // Video Player
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: RepaintBoundary(
//                         key: _repaintKey,
//                         child: _isVideoInitialized
//                             ? AspectRatio(
//                                 aspectRatio: _videoController.value.aspectRatio,
//                                 child: VideoPlayer(_videoController),
//                               )
//                             : Center(child: CircularProgressIndicator()),
//                       ),
//                     ),
//                   ),

//                   // Video Controls
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.replay_10),
//                         onPressed: () => _videoController.seekTo(
//                           _videoController.value.position -
//                               Duration(seconds: 10),
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(
//                           _videoController.value.isPlaying
//                               ? Icons.pause
//                               : Icons.play_arrow,
//                         ),
//                         onPressed: () => setState(() {
//                           _videoController.value.isPlaying
//                               ? _videoController.pause()
//                               : _videoController.play();
//                         }),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.forward_10),
//                         onPressed: () => _videoController.seekTo(
//                           _videoController.value.position +
//                               Duration(seconds: 10),
//                         ),
//                       ),
//                     ],
//                   ),

//                   // Recording Controls
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 8,
//                     ),
//                     child: Column(
//                       children: [
//                         Wrap(
//                           alignment: WrapAlignment.center,
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: [
//                             buildControlBtn(
//                               "start".tr,
//                               onPressed: () {
//                                 startRecording();
//                               },
//                             ),
//                             buildControlBtn(
//                               "stop".tr,
//                               onPressed: () {
//                                 stopRecording();
//                               },
//                               icon: _isRecording
//                                   ? Icons.record_voice_over_rounded
//                                   : null,
//                             ),
//                             buildControlBtn(
//                               _isRecording
//                                   ? "Recording... $timerText"
//                                   : "Screen Record",
//                               onPressed: _isRecording
//                                   ? null
//                                   : _startScreenRecording,
//                               icon: _isRecording
//                                   ? Icons.circle
//                                   : Icons.fiber_manual_record,
//                             ),
//                             buildControlBtn(
//                               "Stop Screen Rec",
//                               onPressed: _isRecording
//                                   ? _stopScreenRecording
//                                   : null,
//                               icon: Icons.stop,
//                             ),
//                             buildControlBtn(
//                               "message".tr,
//                               onPressed: () {
//                                 _showMessageDialog();
//                               },
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Wrap(
//                           alignment: WrapAlignment.center,
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: [
//                             buildControlBtn(
//                               "task_ss".tr,
//                               icon: Icons.camera_alt,
//                               onPressed: _takeScreenshot,
//                             ),
//                             buildControlBtn(
//                               "gallery".tr,
//                               icon: Icons.photo_library,
//                               onPressed: _viewRecordings,
//                             ),
//                             buildControlBtn(
//                               "USB Storage",
//                               icon: Icons.usb,
//                               onPressed: _selectUSBDirectory,
//                             ),
//                             buildControlBtn(
//                               "share".tr,
//                               icon: Icons.share,
//                               onPressed: () {
//                                 Share.share(
//                                   'Invite to Wiespl Meet: https://wiespl.com/',
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Right Panel
//           Expanded(
//             flex: 1,
//             child: Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 16),
//                   const Padding(
//                     padding: EdgeInsets.only(top: 24.0),
//                     child: Text(
//                       "TV List",
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   const Divider(color: Colors.white38),
//                   const SizedBox(height: 12),
//                   Expanded(
//                     child: ListView(
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       children: [
//                         buildTvItemm("TV 1", 0),
//                         buildTvItemm("TV 2", 1),
//                         buildTvItemm("TV 3", 2),
//                         buildTvItemm("TV 4", 3),
//                       ],
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 12),
//                     child: ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                       ),
//                       child: const Text(
//                         "APPLY",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildControlBtn(
//     String label, {
//     IconData? icon,
//     VoidCallback? onPressed,
//   }) {
//     return SizedBox(
//       width: 120,
//       child: ElevatedButton.icon(
//         onPressed: onPressed,
//         icon: icon != null ? Icon(icon, size: 16) : const SizedBox(width: 0),
//         label: Text(label, overflow: TextOverflow.ellipsis),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.white,
//           foregroundColor: Colors.black,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(30),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//         ),
//       ),
//     );
//   }

//   Widget buildTvItem(String name, int index) {
//     return InkWell(
//       onTap: () {
//         _switchVideo(index);
//       },
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             name,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           Text("Playing $name", style: const TextStyle(color: Colors.white70)),
//           const Divider(color: Colors.white38),
//         ],
//       ),
//     );
//   }

//   Widget buildTvItemm(String name, int index) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           name,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text("Playing $name", style: const TextStyle(color: Colors.white70)),
//         const Divider(color: Colors.white38),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:share_plus/share_plus.dart';
import 'package:surgeon_control_panel/screen/feather/allcctv/allcctv.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;

class VideoSwitcherScreen extends StatefulWidget {
  const VideoSwitcherScreen({super.key});

  @override
  State<VideoSwitcherScreen> createState() => _VideoSwitcherScreenState();
}

class _VideoSwitcherScreenState extends State<VideoSwitcherScreen> {
  // Surgery-related YouTube videos
  final List<String> youtubeUrls = [
    "https://www.youtube.com/watch?v=osgndmRBjsM", // Orthopedic surgery example
    "https://www.youtube.com/watch?v=_MTER8jQSFQ", // Knee replacement surgery
    "https://www.youtube.com/watch?v=sPyZRkkxqNs", // Hip replacement surgery
    "https://www.youtube.com/watch?v=lp4eRla1vFg", // Shoulder surgery
  ];

  // late YoutubePlayerController _controller;

  int selectedVideoIndex = 0;
  final String baseUrl = 'http://192.168.0.43:5000'; // Your local server IP
  bool isRecording = false;
  bool isConnected = false;
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

  // late final WebViewController _controllerr;
  late WebViewController _obsController;
  late WebViewController _motionEyeController;
  late WebViewController _motionEyeControllerr;
  late WebViewController _motionEyeControllerrr;

  late YoutubePlayerController _youtubeController;
  int _selectedStreamIndex = 0; // 0 = OBS, 1 = MotionEye, 2 = YouTube

  // final TextEditingController _phoneController = TextEditingController();
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
              // color: Colors.white,
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
                // const SizedBox(height: 20),
                // TextField(
                //   controller: _phoneController,
                //   decoration: InputDecoration(
                //     labelText: 'Phone Number',
                //     hintText: '+91 8075613583',
                //     prefixIcon: const Icon(Icons.phone, color: Colors.white54),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     filled: true,
                //     fillColor: Colors.white38,
                //   ),
                //   keyboardType: TextInputType.phone,
                // ),
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

    // Initialize YouTube player with the first surgery video
    _youtubeController = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(youtubeUrls[0])!,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );

    // Initialize webview controllers with YouTube URLs
    _obsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[0]));

    // MotionEye Stream WebView replaced with surgery videos
    _motionEyeController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[1]));

    _motionEyeControllerr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[2]));

    _motionEyeControllerrr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[3]));
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  Widget _buildStreamView() {
    switch (_selectedStreamIndex) {
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
    return Scaffold(
      body: Row(
        children: [
          // Left Panel
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '✅ ${'connect_to'.tr} to WIESPL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isConnected ? Colors.green : Colors.green,
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white38),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
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
                  colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
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
                            // buildControlBtnn("STOP"),

                            // buildControlBtnn("MESSAGE"),
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
                            // buildControlBtnn("TAKE SS", icon: Icons.camera_alt),
                            buildControlBtn(
                              "task_ss".tr,
                              icon: Icons.camera_alt,
                              onPressed: () {},
                            ),
                            buildControlBtnn(
                              "gallery".tr,
                              icon: Icons.photo_library,
                            ),
                            // buildControlBtnn("SHARE", icon: Icons.share),
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
                  colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
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
                  // const Text(
                  //   "CCTV",
                  //   style: TextStyle(
                  //     fontSize: 20,
                  //     fontWeight: FontWeight.bold,
                  //     color: Colors.white,
                  //   ),
                  // ),
                  const Divider(color: Colors.white38),
                  const SizedBox(height: 12),

                  // Expanded(
                  //   child: ListView(
                  //     padding: const EdgeInsets.symmetric(horizontal: 12),
                  //     children: [
                  //       buildTvItem("CCTV 1", 0),
                  //       buildTvItem("CCTV 2", 1),
                  //       buildTvItem("CCTV 3", 2),
                  //       buildTvItem("CCTV 4", 3),
                  //     ],
                  //   ),
                  // ),
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
                        buildTvItemm("TV 2", 1), // This one does nothing on tap
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => YouTubeGridScreen(),
                        //     ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "APPLY",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

        // print("kkdkdkkd");
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
