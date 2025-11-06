import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surgeon_control_panel/provider/environment_state.dart';
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
  double _sidebarWidth = 250.0;

  // Surgery-related YouTube videos
  final List<String> youtubeUrls = [
    "http://192.168.1.131:9081",
    "http://192.168.1.131:9082",
    "http://192.168.1.131:9083",
    "http://192.168.1.131:9084",
  ];

  // Web controllers
  late WebViewController _obsController;
  late WebViewController _motionEyeController;
  late WebViewController _motionEyeControllerr;
  late WebViewController _motionEyeControllerrr;

  @override
  void initState() {
    super.initState();

    // Initialize environment state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final environmentState = Provider.of<EnvironmentState>(
        context,
        listen: false,
      );
      environmentState.initSharedPreferences();
      environmentState.initUsb();
    });

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
        title: Consumer<EnvironmentState>(
          builder: (context, environmentState, child) {
            return Row(
              children: [
                Text("Surgery Video Grid"),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: environmentState.isConnected
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    environmentState.isConnected ? "Connected" : "Disconnected",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Color.fromARGB(255, 40, 123, 131),
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
            colors: [
              // Color(0xFFFEAC5E), Color(0xFFC779D0)
              Color.fromARGB(255, 40, 123, 131),
              Color.fromARGB(255, 39, 83, 87),
            ],
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
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Consumer<EnvironmentState>(
                  builder: (context, environmentState, child) {
                    return SingleChildScrollView(
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
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Divider(color: Colors.white54),
                            _buildCurrentReadings(
                              environmentState,
                              isSmallScreen,
                            ),
                            Divider(color: Colors.white54),
                            _buildTemperatureControl(
                              environmentState,
                              context,
                              isSmallScreen,
                            ),
                            Divider(color: Colors.white54),
                            _buildHumidityControl(
                              environmentState,
                              context,
                              isSmallScreen,
                            ),
                            Divider(color: Colors.white54),
                            _buildPresetModes(environmentState, isSmallScreen),
                            Divider(color: Colors.white54),
                            _buildUsbControls(
                              environmentState,
                              context,
                              isSmallScreen,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentReadings(
    EnvironmentState environmentState,
    bool isSmall,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Current Readings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Temperature:",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "${environmentState.currentTemperature}°C",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Humidity:",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "${environmentState.currentHumidity}%",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemperatureControl(
    EnvironmentState environmentState,
    BuildContext context,
    bool isSmall,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Set Temperature: ${environmentState.pendingTemperature.toStringAsFixed(1)}°C",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white,
          ),
        ),
        Slider(
          value: environmentState.pendingTemperature,
          min: 15.0,
          max: 35.0,
          divisions: 40,
          label: environmentState.pendingTemperature.toStringAsFixed(1),
          onChanged: (value) {
            environmentState.updatePendingTemperature(value);
          },
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            try {
              environmentState.sendEnvironmentSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Temperature set to ${environmentState.pendingTemperature.toStringAsFixed(1)}°C",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("USB not connected"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: Icon(Icons.thermostat, size: 16),
          label: Text("SET TEMP"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 36),
          ),
        ),
      ],
    );
  }

  Widget _buildHumidityControl(
    EnvironmentState environmentState,
    BuildContext context,
    bool isSmall,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Set Humidity: ${environmentState.pendingHumidity.toStringAsFixed(1)}%",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white,
          ),
        ),
        Slider(
          value: environmentState.pendingHumidity,
          min: 0.0,
          max: 100.0,
          divisions: 100,
          label: environmentState.pendingHumidity.toStringAsFixed(1),
          onChanged: (value) {
            environmentState.updatePendingHumidity(value);
          },
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            try {
              environmentState.sendEnvironmentSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Humidity set to ${environmentState.pendingHumidity.toStringAsFixed(1)}%",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("USB not connected"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: Icon(Icons.water_drop, size: 16),
          label: Text("SET HUMIDITY"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 36),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetModes(EnvironmentState environmentState, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Preset Modes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: Text("Comfort"),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
              onPressed: () => environmentState.setComfortMode(),
            ),
            ActionChip(
              label: Text("Energy Save"),
              backgroundColor: Colors.orange,
              labelStyle: TextStyle(color: Colors.white),
              onPressed: () => environmentState.setEnergySaveMode(),
            ),
            ActionChip(
              label: Text("Away"),
              backgroundColor: Colors.blue,
              labelStyle: TextStyle(color: Colors.white),
              onPressed: () => environmentState.setAwayMode(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsbControls(
    EnvironmentState environmentState,
    BuildContext context,
    bool isSmall,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "USB Controls",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 16,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: environmentState.reconnectUsb,
                icon: Icon(Icons.usb, size: 16),
                label: Text("RECONNECT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(0, 36),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: environmentState.requestStatus,
                icon: Icon(Icons.refresh, size: 16),
                label: Text("STATUS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: Size(0, 36),
                ),
              ),
            ),
          ],
        ),
        if (environmentState.usbStatus.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              environmentState.usbStatus,
              style: TextStyle(color: Colors.white70, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  // Rest of your existing methods (_buildDraggableBox, _buildBoxContent) remain the same
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
