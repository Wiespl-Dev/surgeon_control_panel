import 'package:flutter/material.dart';
import 'package:analog_clock/analog_clock.dart';
import 'dart:async';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late String _formattedTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _formattedTime = _formatTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _formattedTime = _formatTime(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Analog Clock
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 5),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            height: 100,
            width: 100,
            child: AnalogClock(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              width: 80,
              height: 80,
              isLive: true,
              hourHandColor: Colors.black,
              minuteHandColor: Colors.black,
              secondHandColor: Colors.red,
              showSecondHand: true,
              showNumbers: true,
              showTicks: true,
              datetime: DateTime.now(),
              textScaleFactor: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Digital Clock
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
