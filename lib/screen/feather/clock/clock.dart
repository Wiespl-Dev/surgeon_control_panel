import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/provider/clockprovider.dart';

// class ClockWidget extends StatefulWidget {
//   @override
//   _ClockWidgetState createState() => _ClockWidgetState();
// }

// class _ClockWidgetState extends State<ClockWidget> {
//   late String _currentTime;
//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();
//     _currentTime = _formatTime(DateTime.now());
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       setState(() {
//         _currentTime = _formatTime(DateTime.now());
//       });
//     });
//   }

//   String _formatTime(DateTime time) {
//     return "${time.hour.toString().padLeft(2, '0')} : ${time.minute.toString().padLeft(2, '0')} : ${time.second.toString().padLeft(2, '0')}";
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.black87,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         _currentTime,
//         style: const TextStyle(
//           fontSize: 16,
//           color: Colors.tealAccent,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1,
//         ),
//       ),
//     );
//   }
// }

class ClockDisplay extends StatelessWidget {
  final Color neonColor;

  const ClockDisplay({required this.neonColor});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to rebuild only this specific part of the UI when the ClockProvider changes.
    return Consumer<ClockProvider>(
      builder: (context, clock, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: neonColor.withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Time Display Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Hours and Minutes (Uses data from the Provider)
                      Text(
                        '${clock.hours}:${clock.minutes}', // <--- Provider data
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: neonColor,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: neonColor.withOpacity(0.8),
                              blurRadius: 10,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: neonColor.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Seconds (Uses data from the Provider)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: Text(
                          clock.seconds, // <--- Provider data
                          style: TextStyle(
                            // fontSize: 35,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Date (Uses data from the Provider)
                  Text(
                    clock.dateString, // <--- Provider data
                    style: TextStyle(
                      // fontSize: 16,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
