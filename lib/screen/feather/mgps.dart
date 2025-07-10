import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CardGridScreen extends StatefulWidget {
  const CardGridScreen({super.key});

  @override
  State<CardGridScreen> createState() => _CardGridScreenState();
}

class _CardGridScreenState extends State<CardGridScreen> {
  final List<String> cylinderLabels = [
    'Oxygen',
    'Nitrogen',
    'CO2',
    'Vacuum',
    'Normal Air',
    'Air Bar 3',
    'Air Bar 7',
    'Cylinder 8',
    'Cylinder 9',
  ];

  late WebSocketChannel channel;
  List<bool> cylinderStatus = List.filled(9, false); // default to EMPTY

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.0.100:8080'),
    );

    channel.stream.listen((message) {
      final parsedMap = _parseMessage(message);
      final updatedStatus = List.generate(9, (i) {
        final bit = parsedMap["F_Sensor_${i + 1}_FAULT_BIT"];
        return bit == "1"; // 1 = FULL, 0 = EMPTY
      });

      setState(() {
        cylinderStatus = updatedStatus;
      });
    });
  }

  Map<String, dynamic> _parseMessage(String message) {
    final cleaned = message.replaceFirst('{,', '').replaceAll('}', '');
    final parts = cleaned.split(',');
    final map = <String, dynamic>{};
    for (var part in parts) {
      if (part.contains(':')) {
        final kv = part.split(':');
        map[kv[0].trim()] = kv[1].trim();
      }
    }
    return map;
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const crossAxisCount = 3;
    const cardHeight = 120.0;
    final cardWidth = (screenWidth - 48) / crossAxisCount;
    final aspectRatio = cardWidth / cardHeight;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 112, 143, 214),
              Color.fromARGB(255, 157, 102, 228),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        )),
                    Text(
                      "MGPS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 33,
                      ),
                    ),
                    SizedBox()
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 112, 143, 214),
                      Color.fromARGB(255, 157, 102, 228),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    itemCount: cylinderLabels.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final isFull = cylinderStatus[index];

                      Color bgColor;
                      Color textColor = Colors.white;
                      IconData icon = Icons.gas_meter;

                      switch (cylinderLabels[index].toLowerCase()) {
                        case "nitrogen":
                          bgColor =
                              isFull ? Colors.black : Colors.grey.shade400;
                          textColor = Colors.white;
                          break;
                        case "vacuum":
                          bgColor = isFull
                              ? Colors.yellow.shade700
                              : Colors.grey.shade400;
                          textColor = Colors.white;
                          break;
                        default:
                          bgColor =
                              isFull ? Colors.white : Colors.grey.shade400;
                          textColor = Colors.black;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 36, color: Colors.green),
                            const SizedBox(height: 8),
                            Text(
                              cylinderLabels[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFull ? 'FULL' : 'EMPTY',
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
