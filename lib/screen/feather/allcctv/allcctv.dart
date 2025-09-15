import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DraggableGridScreen extends StatefulWidget {
  @override
  State<DraggableGridScreen> createState() => _DraggableGridScreenState();
}

class _DraggableGridScreenState extends State<DraggableGridScreen> {
  List<_BoxData> boxes = [];
  final int columns = 2;
  final double spacing = 20;

  // Sidebar control variables
  bool _showSidebar = true;
  double _sidebarWidth = 200.0;

  // Temperature and humidity values
  double _temperature = 25.0;
  double _humidity = 60.0;

  // Surgery-related YouTube videos
  final List<String> youtubeUrls = [
    "https://www.youtube.com/watch?v=osgndmRBjsM", // Orthopedic surgery example
    "https://www.youtube.com/watch?v=_MTER8jQSFQ", // Knee replacement surgery
    "https://www.youtube.com/watch?v=sPyZRkkxqNs", // Hip replacement surgery
    "https://www.youtube.com/watch?v=lp4eRla1vFg", // Shoulder surgery
  ];

  // Web controllers
  late WebViewController _obsController;
  late WebViewController _motionEyeController;
  late WebViewController _motionEyeControllerr;
  late WebViewController _motionEyeControllerrr;

  @override
  void initState() {
    super.initState();

    // Web controllers with surgery YouTube videos
    _obsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[0]));

    _motionEyeController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[1]));

    _motionEyeControllerr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[2]));

    _motionEyeControllerrr = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(youtubeUrls[3]));

    // Grid layout setup (4 boxes now)
    for (int i = 0; i < 4; i++) {
      int row = i ~/ columns;
      int col = i % columns;
      double startX = col * (300 + spacing) + spacing;
      double startY = row * (200 + spacing) + spacing;

      boxes.add(
        _BoxData(
          position: Offset(startX, startY),
          size: Size(300, 200),
          type: i == 0
              ? BoxType.obs
              : i == 1
              ? BoxType.motionEye
              : i == 2
              ? BoxType.motionEye2
              : BoxType.motionEye3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text("Surgery Video Grid"),
        backgroundColor: Color(0xFFFEAC5E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSidebar ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showSidebar = !_showSidebar;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEAC5E), Color(0xFFC779D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Main content area
            Expanded(
              child: Stack(
                children: List.generate(boxes.length, (index) {
                  return _buildDraggableBox(index);
                }),
              ),
            ),

            // Sidebar for environment controls
            if (_showSidebar)
              Container(
                width: isSmallScreen ? screenSize.width * 0.7 : _sidebarWidth,
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Environment Controls",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Divider(),
                        _buildTemperatureControl(context, isSmallScreen),
                        Divider(),
                        _buildHumidityControl(context, isSmallScreen),
                        Divider(),
                        _buildPresetModes(isSmallScreen),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureControl(BuildContext context, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Temperature: ${_temperature.toStringAsFixed(1)}°C",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white70,
          ),
        ),
        Slider(
          value: _temperature,
          min: 15.0,
          max: 35.0,
          divisions: 40,
          label: _temperature.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _temperature = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHumidityControl(BuildContext context, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Humidity: ${_humidity.toStringAsFixed(1)}%",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white70,
          ),
        ),
        Slider(
          value: _humidity,
          min: 0.0,
          max: 100.0,
          divisions: 100,
          label: _humidity.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _humidity = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPresetModes(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Preset Modes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: Text("Comfort"),
              onPressed: () {
                setState(() {
                  _temperature = 22.0;
                  _humidity = 50.0;
                });
              },
            ),
            ActionChip(
              label: Text("Energy Save"),
              onPressed: () {
                setState(() {
                  _temperature = 20.0;
                  _humidity = 45.0;
                });
              },
            ),
            ActionChip(
              label: Text("Away"),
              onPressed: () {
                setState(() {
                  _temperature = 18.0;
                  _humidity = 40.0;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDraggableBox(int index) {
    final box = boxes[index];

    return Positioned(
      left: box.position.dx,
      top: box.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            box.position += details.delta;
          });
        },
        child: Stack(
          children: [
            Container(
              width: box.size.width,
              height: box.size.height,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildBoxContent(box),
            ),
            // Resize handle
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    box.size = Size(
                      (box.size.width + details.delta.dx).clamp(150.0, 800.0),
                      (box.size.height + details.delta.dy).clamp(100.0, 800.0),
                    );
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  color: Colors.white,
                  child: Icon(
                    Icons.open_in_full,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // Drag bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: box.size.width,
                height: 30,
                color: Colors.black.withOpacity(0.5),
                alignment: Alignment.center,
                child: Text(
                  "Surgery Video ${index + 1} - Drag here",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxContent(_BoxData box) {
    switch (box.type) {
      case BoxType.obs:
        return WebViewWidget(controller: _obsController);
      case BoxType.motionEye:
        return WebViewWidget(controller: _motionEyeController);
      case BoxType.motionEye2:
        return WebViewWidget(controller: _motionEyeControllerr);
      case BoxType.motionEye3:
        return WebViewWidget(controller: _motionEyeControllerrr);
    }
  }
}

enum BoxType { obs, motionEye, motionEye2, motionEye3 }

class _BoxData {
  Offset position;
  Size size;
  BoxType type;

  _BoxData({required this.position, required this.size, required this.type});
}
