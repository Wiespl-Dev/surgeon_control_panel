import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LightControlScreen extends StatefulWidget {
  @override
  State<LightControlScreen> createState() => _LightControlScreenState();
}

class _LightControlScreenState extends State<LightControlScreen> {
  final WebSocketChannel channel =
      WebSocketChannel.connect(Uri.parse('ws://192.168.0.100:8080'));
  Map<String, dynamic>? dataMap;
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    channel.stream.listen((message) {
      setState(() {
        dataMap = _parseMessage(message);
      });
    });
    // Auto-focus the first switch when screen loads
    _focusNodes[0].requestFocus();
  }

  Map<String, dynamic> _parseMessage(String message) {
    final parts = message.replaceFirst('{,', '').replaceAll('}', '').split(',');
    final map = <String, dynamic>{};
    for (var part in parts) {
      if (part.contains(':')) {
        final kv = part.split(':');
        map[kv[0]] = kv[1];
      }
    }
    return map;
  }

  void _updateLight(int index, {bool? isOn, int? intensity}) {
    if (dataMap == null) return;

    if (isOn != null) {
      dataMap!["S_Light_${index}_ON_OFF"] = isOn ? "1" : "0";
    }
    if (intensity != null) {
      dataMap!["S_Light_${index}_Intensity"] =
          intensity.toString().padLeft(3, '0');
    }
    _sendUpdate();
  }

  void _sendUpdate() {
    if (dataMap == null) return;

    final updatedString = "{," +
        dataMap!.entries.map((e) => "${e.key}:${e.value}").join(",") +
        "}";
    channel.sink.add(updatedString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC857), Color(0xFF93278F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      "Lights",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    )
                  ],
                ),
                const Divider(color: Colors.white),
                const SizedBox(height: 10),

                // All lights
                Expanded(
                  child: ListView.builder(
                    itemCount: 4,
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    itemBuilder: (context, index) {
                      final lightIndex = index + 1;
                      final isOn =
                          dataMap?["S_Light_${lightIndex}_ON_OFF"] == "1";
                      final intensity = int.tryParse(
                              dataMap?["S_Light_${lightIndex}_Intensity"] ??
                                  "000") ??
                          0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 20.0),
                        child: Focus(
                          focusNode: _focusNodes[index],
                          autofocus: index == 0,
                          child: Builder(
                            builder: (context) {
                              final isFocused = Focus.of(context).hasFocus;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isFocused
                                        ? Colors.white
                                        : Colors.grey.withOpacity(0.3),
                                    width: isFocused ? 3.0 : 2.0,
                                  ),
                                  boxShadow: isFocused
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Light header row
                                    Row(
                                      children: [
                                        Text(
                                          "Light $lightIndex",
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isOn
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            isOn ? "ON" : "OFF",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        // TV-Optimized Switch
                                        GestureDetector(
                                          onTap: () {
                                            _updateLight(lightIndex,
                                                isOn: !isOn);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            width: 100,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              color: isOn
                                                  ? Colors.green
                                                  : Colors.grey[700],
                                            ),
                                            child: Stack(
                                              children: [
                                                AnimatedPositioned(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  left: isOn ? 50 : 0,
                                                  right: isOn ? 0 : 50,
                                                  child: Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.2),
                                                          blurRadius: 5,
                                                          spreadRadius: 1,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Intensity slider (only when on)
                                    if (isOn) ...[
                                      const SizedBox(height: 30),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderTheme.of(context)
                                                  .copyWith(
                                                activeTrackColor: Colors.white,
                                                inactiveTrackColor:
                                                    Colors.white38,
                                                thumbColor: Colors.white,
                                                trackHeight: 12.0,
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                        enabledThumbRadius:
                                                            16.0),
                                                overlayShape:
                                                    const RoundSliderOverlayShape(
                                                        overlayRadius: 32.0),
                                              ),
                                              child: Slider(
                                                value: intensity.toDouble(),
                                                min: 0,
                                                max: 100,
                                                divisions: 100,
                                                label: "${intensity.toInt()}%",
                                                onChanged: (val) =>
                                                    _updateLight(lightIndex,
                                                        intensity: val.toInt()),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              "${intensity.toInt()}%",
                                              style: const TextStyle(
                                                fontSize: 26,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    channel.sink.close();
    super.dispose();
  }
}
