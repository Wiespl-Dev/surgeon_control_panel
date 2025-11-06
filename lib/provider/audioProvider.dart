// // audio_provider.dart
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';

// class AudioProvider with ChangeNotifier {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   bool _isMuted = false;
//   bool _isAlertPlaying = false;

//   AudioPlayer get audioPlayer => _audioPlayer;
//   bool get isMuted => _isMuted;
//   bool get isAlertPlaying => _isAlertPlaying;

//   void toggleMute() {
//     _isMuted = !_isMuted;
//     _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
//     notifyListeners();
//   }

//   void setAlertPlaying(bool value) {
//     _isAlertPlaying = value;
//     notifyListeners();
//   }

//   Future<void> stopAudio() async {
//     await _audioPlayer.stop();
//     _isAlertPlaying = false;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     super.dispose();
//   }
// }
