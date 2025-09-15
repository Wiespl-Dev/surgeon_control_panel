// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Surgeon Control Panel',
//       theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
//       home: const DroidRenderLauncherScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class DroidRenderLauncherScreen extends StatefulWidget {
//   const DroidRenderLauncherScreen({super.key});

//   @override
//   State<DroidRenderLauncherScreen> createState() =>
//       _DroidRenderLauncherScreenState();
// }

// class _DroidRenderLauncherScreenState extends State<DroidRenderLauncherScreen> {
//   bool _isLaunching = false;
//   bool _isInPipMode = false;
//   static const platform = MethodChannel('app_launcher_channel');

//   Future<void> _launchDroidRenderAndEnterPip() async {
//     setState(() {
//       _isLaunching = true;
//     });

//     try {
//       final bool success = await platform.invokeMethod(
//         'launchAppAndEnterPip', // Changed from 'enterPipMode'
//         'com.luolai.droidrender',
//       );

//       if (success) {
//         _showSuccessSnackbar('Opening DroidRender and entering PiP mode...');
//         setState(() {
//           _isInPipMode = true;
//         });
//       } else {
//         _showErrorSnackbar(
//           'Failed to open DroidRender. App may not be installed.',
//         );
//       }
//     } on PlatformException catch (e) {
//       _showErrorSnackbar('Error: ${e.message}');
//     } finally {
//       setState(() {
//         _isLaunching = false;
//       });
//     }
//   }

//   void _showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showSuccessSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Surgeon Control Panel'),
//         backgroundColor: Colors.blue.shade800,
//         foregroundColor: Colors.white,
//         actions: [
//           if (_isInPipMode)
//             const Icon(Icons.picture_in_picture_alt, color: Colors.green),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue.shade50, Colors.white],
//           ),
//         ),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // App Icon
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(25),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.blue.shade200,
//                         blurRadius: 15,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.medical_services,
//                     size: 60,
//                     color: Colors.blue,
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 // App Name
//                 const Text(
//                   'WIESPL',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue,
//                   ),
//                 ),

//                 const SizedBox(height: 8),

//                 // Description
//                 const Text(
//                   '3D DICOM Medical Viewer',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),

//                 const SizedBox(height: 40),

//                 // PiP Status Indicator
//                 if (_isInPipMode)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(25),
//                       border: Border.all(color: Colors.green.shade200),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.picture_in_picture_alt,
//                           color: Colors.green,
//                           size: 20,
//                         ),
//                         SizedBox(width: 8),
//                         Text(
//                           'PiP Mode Active',
//                           style: TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 else
//                   const SizedBox(),

//                 const SizedBox(height: 40),

//                 // Launch Button
//                 ElevatedButton(
//                   onPressed: _isLaunching
//                       ? null
//                       : _launchDroidRenderAndEnterPip,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 20,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 4,
//                   ),
//                   child: _isLaunching
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 3,
//                             valueColor: AlwaysStoppedAnimation(Colors.white),
//                           ),
//                         )
//                       : const Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.open_in_new, size: 24),
//                             SizedBox(width: 12),
//                             Text(
//                               'OPEN & GO TO PIP',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),

//                 const SizedBox(height: 20),

//                 // Instructions
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 20),
//                   child: Text(
//                     'This will open DroidRender and automatically enter Picture-in-Picture mode',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 14,
//                       height: 1.5,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 30),

//                 // PiP Demo Visual
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blue.shade100),
//                   ),
//                   child: const Column(
//                     children: [
//                       Icon(
//                         Icons.picture_in_picture_alt,
//                         size: 40,
//                         color: Colors.blue,
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         'Picture-in-Picture Mode',
//                         style: TextStyle(
//                           color: Colors.blue,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         'Your app will minimize to a small window',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(color: Colors.blue, fontSize: 12),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
