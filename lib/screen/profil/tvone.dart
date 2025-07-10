// import 'dart:convert';

// import 'package:animated_button/animated_button.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_navigation/src/snackbar/snackbar.dart';
// // import 'package:camera/camera.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:flutter_in_app_pip/flutter_in_app_pip.dart';
// import 'package:http/http.dart' as http;
// // List<CameraDescription>? cameras;

// class VideoSwitcherScreen extends StatefulWidget {
//   @override
//   _VideoSwitcherScreenState createState() => _VideoSwitcherScreenState();
// }

// class _VideoSwitcherScreenState extends State<VideoSwitcherScreen>
//     with WidgetsBindingObserver {
//   int selectedIndex = 0;
//   // late CameraController _cameraController;

//   late YoutubePlayerController _youtubeController;

//   final youtubeUrls = [
//     "https://www.youtube.com/watch?v=osgndmRBjsM",
//     "https://www.youtube.com/watch?v=_MTER8jQSFQ",
//     "https://www.youtube.com/watch?v=sPyZRkkxqNs",
//     "https://www.youtube.com/watch?v=lp4eRla1vFg",
//   ];

//   final String baseUrl = 'http://192.168.0.148:5000'; // Your local server IP
//   bool isRecording = false;
//   bool isConnected = false;
//   Future<void> checkConnection() async {
//     final String baseUrl =
//         'http://192.168.0.148:5000'; // or 'http://10.0.2.2:5000' for emulator

//     try {
//       final response = await http.get(Uri.parse('$baseUrl/status'));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           isConnected = data['connected'] ?? false;
//         });
//         print("OBS connected: ${data['connected']}");
//       } else {
//         setState(() => isConnected = false);
//         print("Unexpected status code: ${response.statusCode}");
//       }
//     } catch (e) {
//       setState(() => isConnected = false);
//       print("Connection error: $e");
//     }
//   }

//   Future<void> startRecording() async {
//     print('nsnnss');
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/start_recording'));
//       final data = jsonDecode(response.body);
//       if (data['status'] != null) {
//         setState(() => isRecording = true);
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
//         setState(() => isRecording = false);
//       }
//     } catch (e) {
//       print("Error stopping recording: $e");
//     }
//   }

//   String? selectedScene;
//   Future<void> switchScene(String sceneName) async {
//     try {
//       print("Switching to scene: $sceneName");
//       final response = await http.get(
//           Uri.parse('$baseUrl/switch_scene/${Uri.encodeComponent(sceneName)}'));
//       print("Response: ${response.body}");
//       final data = jsonDecode(response.body);
//       if (data['status'] != null) {
//         setState(() => selectedScene = sceneName);
//       } else {
//         print("Switch error: ${data['error']}");
//       }
//     } catch (e) {
//       print("Error switching scene: $e");
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this); // 👈 Observer added
//     checkConnection();
//     // _initCamera();

//     _youtubeController = YoutubePlayerController(
//       initialVideoId: YoutubePlayer.convertUrlToId(youtubeUrls[0])!,
//       flags: YoutubePlayerFlags(autoPlay: true, mute: false),
//     );

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       try {
//         PictureInPicture.startPiP(
//           pipWidget: PiPWidget(
//             child: PiPContent(),
//             onPiPClose: () => debugPrint('PiP closed'),
//             pipBorderRadius: 10,
//             elevation: 8,
//           ),
//         );
//       } catch (e) {
//         debugPrint('PiP failed: $e');
//       }
//     });
//   }

//   // Future<void> _initCamera() async {
//   //   cameras = await availableCameras();
//   //   if (cameras == null || cameras!.isEmpty) return;
//   //   _cameraController = CameraController(cameras![0], ResolutionPreset.medium);
//   //   await _cameraController.initialize();
//   //   if (mounted) {
//   //     setState(() {
//   //       _isCameraInitialized = true;
//   //     });
//   //   }
//   // }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached) {
//       PictureInPicture.stopPiP();
//       debugPrint("Stopped PiP because app was paused or closed.");
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this); // 👈 Observer removed
//     PictureInPicture.stopPiP(); // 👈 Always stop PiP on dispose
//     // if (_isCameraInitialized) _cameraController.dispose();
//     _youtubeController.dispose();
//     super.dispose();
//   }

//   void switchVideo(int index) {
//     setState(() {
//       selectedIndex = index;
//       if (index != 0) {
//         final videoId = YoutubePlayer.convertUrlToId(youtubeUrls[index - 1]);
//         _youtubeController.load(videoId!);
//       }
//     });
//   }

//   Widget getSelectedView() {
//     return YoutubePlayer(controller: _youtubeController);
//   }

//   Widget getThumbnail(int index) {
//     final videoId = YoutubePlayer.convertUrlToId(youtubeUrls[index]);
//     return Image.network(
//       'https://img.youtube.com/vi/$videoId/0.jpg',
//       width: 100,
//       height: 100,
//       fit: BoxFit.cover,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color.fromARGB(255, 42, 107, 230),
//         elevation: 0,
//         title: const Text("WIESPL MEET",
//             style: TextStyle(color: Colors.black, fontSize: 23)),
//         leading: IconButton(
//           onPressed: () {
//             // Navigator.pop(context);
//             checkConnection();
//             // _youtubeController.dispose();
//             try {
//               PictureInPicture.stopPiP();
//               debugPrint('Stopped PiP from back button');
//             } catch (e) {
//               debugPrint('Error stopping PiP: $e');
//             }
//           },
//           icon: const Icon(Icons.arrow_back_ios_new),
//         ),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: MediaQuery.of(context).size.height,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color.fromARGB(255, 42, 107, 230),
//               Color(0xFF22024B),
//             ],
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // const SizedBox(height: 50),
//             Text(
//               isConnected ? '✅ Connected to OBS' : '❌ Not connected to OBS',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: isConnected ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 1000),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // C1 - C4 Buttons Column
//                     Column(
//                       children: [
//                         AnimatedButton(
//                           onPressed: () {
//                             switchScene("Scene 1");
//                             switchVideo(0);
//                           },
//                           color: const Color.fromARGB(119, 63, 147, 216),
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: const Text(
//                             'C1',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         AnimatedButton(
//                           onPressed: () {
//                             switchScene("Scene 2");
//                             switchVideo(1);
//                           },
//                           color: const Color.fromARGB(255, 56, 110, 154),
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: const Text(
//                             'C2',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         AnimatedButton(
//                           onPressed: () {
//                             switchScene("Scene 3");
//                             switchVideo(2);
//                           },
//                           color: Colors.blue,
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: const Text(
//                             'C3',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         AnimatedButton(
//                           onPressed: () {
//                             switchScene("Scene 4");
//                             switchVideo(3);
//                           },
//                           color: const Color.fromARGB(66, 71, 123, 167),
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: const Text(
//                             'C4',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(width: 10),

//                     // Video Container + Thumbnails
//                     Column(
//                       children: [
//                         Container(
//                           width: MediaQuery.of(context).size.width *
//                               0.6, // 60% of screen width
//                           height: 300, // fixed height is usually safer
//                           decoration: BoxDecoration(
//                             color: Colors.grey[900],
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: const [
//                               BoxShadow(
//                                 color: Colors.black26,
//                                 blurRadius: 8,
//                                 offset: Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: getSelectedView(),
//                         ),
//                         const SizedBox(height: 20),
//                         SizedBox(
//                           height: 100,
//                           child: Center(
//                             child: SingleChildScrollView(
//                               scrollDirection: Axis.horizontal,
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children:
//                                     List.generate(youtubeUrls.length, (index) {
//                                   return GestureDetector(
//                                     onTap: () => switchVideo(index),
//                                     child: Container(
//                                       margin: const EdgeInsets.symmetric(
//                                           horizontal: 8),
//                                       decoration: BoxDecoration(
//                                         border: Border.all(
//                                           color: selectedIndex == index
//                                               ? Colors.blue
//                                               : Colors.transparent,
//                                           width: 3,
//                                         ),
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: ClipRRect(
//                                         borderRadius: BorderRadius.circular(12),
//                                         child: Container(
//                                           width: 100,
//                                           height: 100,
//                                           color: Colors.grey[800],
//                                           child: Center(
//                                               child: getThumbnail(index)),
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 }),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(width: 20),

//                     // Right Side Buttons
//                     Column(
//                       children: [
//                         // customButton(
//                         //   'Broadcast',
//                         //   color: const Color.fromARGB(119, 63, 147, 216),
//                         //   onPressed: () {},
//                         // ),
//                         AnimatedButton(
//                           onPressed: () {
//                             Get.snackbar(
//                               "Not implemented",
//                               "!!",
//                               snackPosition: SnackPosition.BOTTOM,
//                               backgroundColor: Colors.red,
//                               colorText: Colors.white,
//                               margin: const EdgeInsets.symmetric(
//                                   horizontal: 50, vertical: 20),
//                               maxWidth: 400,
//                               borderRadius: 10,
//                               snackStyle: SnackStyle.FLOATING,
//                               mainButton: TextButton(
//                                 onPressed: () => Get.back(),
//                                 child: const Text(
//                                   "CLOSE",
//                                   style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             );
//                           },
//                           color: const Color.fromARGB(119, 63, 147, 216),
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: const Text(
//                             'Broadcast',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         AnimatedButton(
//                           onPressed: () {
//                             Get.snackbar(
//                               "Not implemented",
//                               "!!",
//                               snackPosition: SnackPosition.BOTTOM,
//                               backgroundColor: Colors.red,
//                               colorText: Colors.white,
//                               margin: const EdgeInsets.symmetric(
//                                   horizontal: 50, vertical: 20),
//                               maxWidth: 400,
//                               borderRadius: 10,
//                               snackStyle: SnackStyle.FLOATING,
//                               mainButton: TextButton(
//                                 onPressed: () => Get.back(),
//                                 child: const Text(
//                                   "CLOSE",
//                                   style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                             );
//                           },
//                           color: const Color.fromARGB(255, 56, 110, 154),
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: const Text(
//                             'Mirror Screen',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         AnimatedButton(
//                           onPressed: () {
//                             isRecording ? stopRecording() : startRecording();
//                           },
//                           color: isRecording ? Colors.red : Colors.blue,
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: Text(
//                             isRecording ? 'Stop Recording' : 'Start Recording',
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 10,
//                         ),
//                         AnimatedButton(
//                           onPressed: () {
//                             Share.share(
//                                 'Invite to Wiespl Meet: https://wiespl.com/');
//                           },
//                           color: const Color.fromARGB(66, 71, 123, 167),
//                           enabled: true,
//                           disabledColor: Colors.grey,
//                           shadowDegree: ShadowDegree.light,
//                           borderRadius: 8,
//                           duration: 85,
//                           height: 40,
//                           width: 140,
//                           child: const Text(
//                             'Share link',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class PiPContent extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black,
//       alignment: Alignment.center,
//       child: Image.asset(
//         'assets/images/app_logo.png', // <-- Replace with your image path
//         fit: BoxFit.contain,
//         width: 120,
//         height: 120,
//       ),
//     );
//   }
// }

// Widget customButton(
//   String label, {
//   required Color color,
//   required VoidCallback onPressed,
// }) {
//   return Column(
//     children: [
//       AnimatedButton(
//         onPressed: () {},
//         color: color,
//         enabled: true,
//         disabledColor: Colors.grey,
//         shadowDegree: ShadowDegree.light,
//         borderRadius: 8,
//         duration: 85,
//         height: 40,
//         width: 140,
//         child: Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Colors.white,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//       const SizedBox(height: 10),
//     ],
//   );
// }
