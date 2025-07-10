import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:share_plus/share_plus.dart';
import 'package:surgeon_control_panel/screen/feather/allcctv/allcctv.dart';
import 'package:surgeon_control_panel/screen/message_server/messageserver.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

class VideoSwitcherScreen extends StatefulWidget {
  const VideoSwitcherScreen({super.key});

  @override
  State<VideoSwitcherScreen> createState() => _VideoSwitcherScreenState();
}

class _VideoSwitcherScreenState extends State<VideoSwitcherScreen> {
  final List<String> youtubeUrls = [
    "https://www.youtube.com/watch?v=osgndmRBjsM",
    "https://www.youtube.com/watch?v=_MTER8jQSFQ",
    "https://www.youtube.com/watch?v=sPyZRkkxqNs",
    "https://www.youtube.com/watch?v=lp4eRla1vFg",
  ];

  late YoutubePlayerController _controller;

  int selectedVideoIndex = 0;
  final String baseUrl = 'http://192.168.0.100:5000'; // Your local server IP
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

    final response = await TwilioService.sendWhatsAppMessage(
      phoneNumber: '918075613583',
      message: _messageController.text,
    );

    setState(() {
      _isSending = false;
      if (response['success'] == true) {
        _lastStatus = 'Message sent successfully!';
        _lastSid = response['sid'];
      } else {
        _lastStatus =
            response['error'] ??
            response['message'] ??
            'Failed to send message';
      }
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
    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(
        youtubeUrls[selectedVideoIndex],
      )!,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(); // 👈 Observer removed
    _controller.dispose();
    super.dispose();
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
                      isConnected
                          ? '✅ Connected to OBS'
                          : '❌ Not connected to OBS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: const Text(
                      "TV List",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white38),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoGridScreen(),
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

                  // YouTube Player
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: YoutubePlayer(
                        controller: _controller,
                        showVideoProgressIndicator: true,
                      ),
                    ),
                  ),
                  // ElevatedButton(onPressed: () {}, child: Text("kkkk")),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 1");
                        },
                        child: Text(
                          "1",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 2");
                        },
                        child: Text(
                          "2",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 3");
                        },
                        child: Text(
                          "3",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 4");
                        },
                        child: Text(
                          "4",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 5");
                        },
                        child: Text(
                          "5",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 6");
                        },
                        child: Text(
                          "6",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 7");
                        },
                        child: Text(
                          "7",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 8");
                        },
                        child: Text(
                          "8",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 9");
                        },
                        child: Text(
                          "9",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 10");
                        },
                        child: Text(
                          "10",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 11");
                        },
                        child: Text(
                          "11",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 12");
                        },
                        child: Text(
                          "12",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 13");
                        },
                        child: Text(
                          "13",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 14");
                        },
                        child: Text(
                          "14",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // In your parent widget
                      TextButton(
                        onPressed: () {
                          switchScene("Scene 15");
                        },
                        child: Text(
                          "15",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Buttons
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
                              "START",
                              onPressed: () {
                                print(" pressed");
                                startRecording();
                              },
                            ),
                            buildControlBtn(
                              "STOP",
                              onPressed: () {
                                print(" pgggggggggressed");
                                stopRecording();
                              },
                              icon: isRecording
                                  ? Icons.record_voice_over_rounded
                                  : null,
                            ),
                            // buildControlBtnn("STOP"),

                            // buildControlBtnn("MESSAGE"),
                            buildControlBtn(
                              "MESSAGE",
                              onPressed: () {
                                print(" pressed");
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
                              "TAKE SS",
                              icon: Icons.camera_alt,
                              onPressed: () {
                                print("nnnnn");
                              },
                            ),
                            buildControlBtnn(
                              "GALLERY",
                              icon: Icons.photo_library,
                            ),
                            // buildControlBtnn("SHARE", icon: Icons.share),
                            buildControlBtn(
                              "SHARE",
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        buildTvItem("CCTV 1", 0),
                        buildTvItem("CCTV 2", 1),
                        buildTvItem("CCTV 3", 2),
                        buildTvItem("CCTV 4", 3),
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
          selectedVideoIndex = index;
          _controller.load(YoutubePlayer.convertUrlToId(youtubeUrls[index])!);
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
