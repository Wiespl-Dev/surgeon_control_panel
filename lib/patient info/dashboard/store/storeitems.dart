import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- Theme Definition ---
const Color kPrimaryColor = Color(0xFF00796B); // Teal 700 - Professional
const Color kUrgentColor = Color(0xFFD32F2F); // Red 700
const Color kMediumColor = Color(0xFFFFA000); // Amber 700
const Color kLowColor = Color(0xFF43A047); // Green 700
const Color kSuccessColor = Colors.green;
const Color kErrorColor = Colors.red;

class HospitalApp extends StatefulWidget {
  @override
  _HospitalAppState createState() => _HospitalAppState();
}

class _HospitalAppState extends State<HospitalApp> {
  final String serverUrl = 'http://192.168.1.230:3000';
  List<dynamic> items = [];
  bool isLoading = false;
  String status = 'Initializing...';
  bool isConnected = false;

  // Map to store the selected quantity for each item (Key: item id, Value: quantity)
  Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    // Automatically connect to the server when the app starts
    connectToServer();
  }

  // --- Data & Connection Functions ---

  void _initializeQuantities() {
    final Map<int, int> newQuantities = {};
    for (var item in items) {
      int itemId = item['id'];
      // Initialize to 1, or preserve previous count if it exists
      newQuantities[itemId] = _quantities[itemId] ?? 1;
    }
    _quantities = newQuantities;
  }

  Future<void> connectToServer() async {
    if (!isLoading && !isConnected) {
      setState(() {
        isLoading = true;
        status = 'Attempting to connect to server...';
      });
    }

    try {
      final testResponse = await http
          .get(Uri.parse('$serverUrl/api/test'))
          .timeout(Duration(seconds: 5));

      if (testResponse.statusCode == 200) {
        setState(() {
          isConnected = true;
          status = '✅ Connected to server!';
        });
        await loadItems();
      } else {
        setState(() {
          isConnected = false;
          status = '❌ Server error: ${testResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isConnected = false;
        status = '❌ Cannot connect to server: ${e.toString().split(':')[0]}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadItems() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/api/items'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          items = data;
          status = '✅ Loaded ${items.length} inventory items.';
          _initializeQuantities(); // Initialize quantities after load
        });
      }
    } catch (e) {
      setState(() {
        status = 'Error loading items: ${e.toString().split(':')[0]}';
      });
    }
  }

  Future<void> placeOrder(int itemId, String itemName, String urgency) async {
    final int quantityToOrder = _quantities[itemId] ?? 1;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Placing $urgency order for $quantityToOrder x $itemName...',
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final response = await http
          .post(
            Uri.parse('$serverUrl/api/orders'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'item_id': itemId,
              'item_name': itemName,
              'ot_name': 'Flutter App',
              'quantity': quantityToOrder,
              'urgency': urgency.toLowerCase(),
            }),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ $quantityToOrder x $itemName ordered successfully!',
            ),
            backgroundColor: kSuccessColor,
          ),
        );
        await loadItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Order failed: Server responded with ${response.statusCode}',
            ),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Failed to place order: ${e.toString().split(':')[0]}',
          ),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Store',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        appBarTheme: AppBarTheme(backgroundColor: kPrimaryColor, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF3D8A8F),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context), // 👈 goes back
          ),
          title: const Text(
            'Inventory & Ordering System',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF3D8A8F),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: isConnected ? loadItems : connectToServer,
              tooltip: isConnected ? 'Refresh Inventory' : 'Connect',
            ),
          ],
        ),

        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildConnectionCard(),
              SizedBox(height: 20),

              if (isConnected) _buildInventoryHeader(),

              if (isConnected) _buildItemList(),

              if (isLoading && !isConnected) _buildLoadingState(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  // Widget _buildConnectionCard() {
  //   Color cardColor = isConnected
  //       ? kSuccessColor
  //       : (status.contains('❌') ? kErrorColor : kPrimaryColor);
  //   String statusText = isConnected
  //       ? 'Connected'
  //       : (status.contains('❌') ? 'Connection Failed' : 'Disconnected');
  //   IconData statusIcon = isConnected
  //       ? Icons.cloud_done
  //       : (status.contains('❌') ? Icons.error : Icons.cloud_off);

  //   return Card(
  //     elevation: 4,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(12),
  //         color: cardColor,
  //       ),
  //       padding: EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(statusIcon, color: Colors.white),
  //               SizedBox(width: 10),
  //               Text(
  //                 statusText,
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 18,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 8),
  //           Text(status, style: TextStyle(color: Colors.white70)),
  //           SizedBox(height: 4),
  //           Text(
  //             'Server: 192.168.1.230:3000',
  //             style: TextStyle(fontSize: 12, color: Colors.white54),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(status),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Inventory Items',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
          ),
        ),
        Text(
          'Total items: ${items.length}',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildItemList() {
    if (items.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'No items found in inventory.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: loadItems,
        color: kPrimaryColor,
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final int quantity = item['quantity'] ?? 0;
            final String price = item['price']?.toString() ?? 'N/A';
            final int itemId = item['id'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                child: ListTile(
                  // 🐛 FIX: Reduced vertical padding to prevent RenderFlex overflow
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 16,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                    child: Icon(Icons.healing_sharp, color: kPrimaryColor),
                  ),
                  title: Text(
                    item['name'] ?? 'Unknown Item',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock: $quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: quantity < 5 ? kUrgentColor : kPrimaryColor,
                        ),
                      ),
                      Text(
                        'Price: \$$price',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: Container(
                    width: 160,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildQuantitySelector(itemId),
                        // 🐛 FIX: Reduced vertical spacing
                        SizedBox(height: 4),
                        // Urgency Buttons in a Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildUrgencyButton(
                              item,
                              'Urgent',
                              kUrgentColor,
                              45,
                            ),
                            _buildUrgencyButton(
                              item,
                              'Medium',
                              kMediumColor,
                              45,
                            ),
                            _buildUrgencyButton(item, 'Low', kLowColor, 45),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget for the Plus/Minus quantity control
  Widget _buildQuantitySelector(int itemId) {
    int currentQuantity = _quantities[itemId] ?? 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Qty:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        // Minus Button
        SizedBox(
          width: 30,
          height: 30,
          child: IconButton(
            icon: Icon(Icons.remove, size: 18),
            padding: EdgeInsets.zero,
            onPressed: () {
              if (currentQuantity > 1) {
                setState(() {
                  _quantities[itemId] = currentQuantity - 1;
                });
              }
            },
          ),
        ),
        // Quantity Display
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            '$currentQuantity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Plus Button
        SizedBox(
          width: 30,
          height: 30,
          child: IconButton(
            icon: Icon(Icons.add, size: 18),
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _quantities[itemId] = currentQuantity + 1;
              });
            },
          ),
        ),
      ],
    );
  }

  // Widget for a single urgency button
  Widget _buildUrgencyButton(
    dynamic item,
    String label,
    Color color,
    double width,
  ) {
    return SizedBox(
      height: 20, // 🐛 FIX: Reduced height to prevent overflow
      width: width,
      child: ElevatedButton(
        onPressed: () => placeOrder(item['id'], item['name'], label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(label),
      ),
    );
  }
}
