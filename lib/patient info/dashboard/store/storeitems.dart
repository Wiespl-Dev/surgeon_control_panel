import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ==================== DATA MODELS ====================

class StoreItem {
  final int id;
  final String name;
  final String category;
  final int quantity;
  final int minStock;
  final double price;

  StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minStock,
    required this.price,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    return StoreItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      minStock: json['min_stock'] ?? 10,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'min_stock': minStock,
      'price': price,
    };
  }

  bool get isLowStock => quantity <= minStock;
  bool get isOutOfStock => quantity == 0;
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Color get stockStatusColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }
}

class Order {
  final int id;
  final int itemId;
  final String itemName;
  final String otName;
  final int quantity;
  final String urgency;
  final String status;
  final String createdAt;

  Order({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.otName,
    required this.quantity,
    required this.urgency,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      itemId: json['item_id'] ?? 0,
      itemName: json['item_name'] ?? '',
      otName: json['ot_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      urgency: json['urgency'] ?? 'medium',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'ot_name': otName,
      'quantity': quantity,
      'urgency': urgency,
    };
  }

  Color get urgencyColor {
    switch (urgency) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'dispatched':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get urgencyText {
    switch (urgency) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'medium':
        return 'Normal';
      case 'low':
        return 'Low';
      default:
        return 'Normal';
    }
  }

  IconData get urgencyIcon {
    switch (urgency) {
      case 'critical':
        return Icons.warning;
      case 'high':
        return Icons.error_outline;
      case 'medium':
        return Icons.info_outline;
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.info_outline;
    }
  }
}

// ==================== API SERVICE ====================

class ApiService {
  // Update this IP address to match your computer's IP
  static const String baseUrl = 'http://192.168.0.101:3000/api';

  // Handle API errors
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'An error occurred');
    }
  }

  // Get all store items
  Future<List<StoreItem>> getStoreItems() async {
    final response = await http.get(Uri.parse('$baseUrl/items'));
    _handleError(response);
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => StoreItem.fromJson(json)).toList();
  }

  // Get all orders
  Future<List<Order>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));
    _handleError(response);
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Order.fromJson(json)).toList();
  }

  // Create new order
  Future<Order> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(order.toJson()),
    );
    _handleError(response);
    final data = json.decode(response.body);
    return Order.fromJson(data['order']);
  }

  // Update order status
  Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    _handleError(response);
  }

  // Delete order
  Future<void> deleteOrder(int orderId) async {
    final response = await http.delete(Uri.parse('$baseUrl/orders/$orderId'));
    _handleError(response);
  }

  // Update item stock
  Future<void> updateItemStock(int itemId, int quantity) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/items/$itemId/stock'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'quantity': quantity}),
    );
    _handleError(response);
  }

  // Check server status
  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/test'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ==================== MAIN APP ====================

void main() {
  runApp(const HospitalStoreApp());
}

class HospitalStoreApp extends StatelessWidget {
  const HospitalStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Store Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StoreHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== STORE HOME SCREEN ====================

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({Key? key}) : super(key: key);

  @override
  _StoreHomeScreenState createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _serverOnline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    final isOnline = await _apiService.checkServerStatus();
    setState(() {
      _serverOnline = isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D8A8F),
      appBar: AppBar(
        title: const Text('Hospital Store'),
        backgroundColor: const Color(0xFF3D8A8F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _serverOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _serverOnline ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: _checkServerStatus,
            tooltip: _serverOnline ? 'Server Online' : 'Server Offline',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StoreInventoryScreen(apiService: _apiService),
          OrdersScreen(apiService: _apiService),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ==================== STORE INVENTORY SCREEN ====================

class StoreInventoryScreen extends StatefulWidget {
  final ApiService apiService;

  const StoreInventoryScreen({Key? key, required this.apiService})
    : super(key: key);

  @override
  _StoreInventoryScreenState createState() => _StoreInventoryScreenState();
}

class _StoreInventoryScreenState extends State<StoreInventoryScreen> {
  List<StoreItem> _items = [];
  List<StoreItem> _filteredItems = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final items = await widget.apiService.getStoreItems();
      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterItems() {
    List<StoreItem> filtered = _items;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.category.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  List<String> get _categories {
    final categories = _items.map((item) => item.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  Widget _buildItemCard(StoreItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: item.stockStatusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: item.stockStatusColor),
          ),
          child: Icon(
            _getItemIcon(item.category),
            color: item.stockStatusColor,
            size: 24,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Category: ${item.category}',
              style: const TextStyle(fontSize: 12),
            ),
            // Text(
            //   'Price: \$${item.price.toStringAsFixed(2)}',
            //   style: const TextStyle(fontSize: 12),
            // ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.stockStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: item.stockStatusColor),
                  ),
                  child: Text(
                    item.stockStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.stockStatusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Stock: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isLowStock ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.isLowStock) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(Min: ${item.minStock})',
                    style: const TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: item.isOutOfStock
              ? null
              : () {
                  _showOrderDialog(item);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: item.isOutOfStock
                ? Colors.grey
                : const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          child: const Text('Order'),
        ),
      ),
    );
  }

  IconData _getItemIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medicines':
        return Icons.medication;
      case 'disposables':
        return Icons.clean_hands;
      case 'dressings':
        return Icons.healing;
      case 'equipment':
        return Icons.medical_services;
      case 'ppe':
        return Icons.health_and_safety;
      default:
        return Icons.inventory;
    }
  }

  void _showOrderDialog(StoreItem item) {
    final quantityController = TextEditingController(text: '1');
    String selectedOT = 'OT-1';
    String selectedUrgency = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Order ${item.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Available Stock: ${item.quantity}'),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity*',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedOT,
                  decoration: const InputDecoration(
                    labelText: 'OT Location*',
                    border: OutlineInputBorder(),
                  ),
                  items: ['OT-1', 'OT-2', 'OT-3', 'Emergency OT', 'Cardiac OT']
                      .map((ot) => DropdownMenuItem(value: ot, child: Text(ot)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedOT = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedUrgency,
                  decoration: const InputDecoration(
                    labelText: 'Urgency Level*',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'low',
                      child: Row(
                        children: [
                          Icon(Icons.low_priority, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('Low Priority'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.yellow),
                          const SizedBox(width: 8),
                          const Text('Normal'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text('High Priority'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Critical'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedUrgency = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                if (quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                    ),
                  );
                  return;
                }

                if (quantity > item.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Only ${item.quantity} items available'),
                    ),
                  );
                  return;
                }

                try {
                  final order = Order(
                    id: 0,
                    itemId: item.id,
                    itemName: item.name,
                    otName: selectedOT,
                    quantity: quantity,
                    urgency: selectedUrgency,
                    status: 'pending',
                    createdAt: '',
                  );

                  await widget.apiService.createOrder(order);
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order placed for ${item.name}')),
                  );

                  // Update local stock
                  final updatedItem = StoreItem(
                    id: item.id,
                    name: item.name,
                    category: item.category,
                    quantity: item.quantity - quantity,
                    minStock: item.minStock,
                    price: item.price,
                  );

                  setState(() {
                    final index = _items.indexWhere((i) => i.id == item.id);
                    if (index != -1) {
                      _items[index] = updatedItem;
                    }
                    _filterItems();
                  });
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error placing order: $e')),
                  );
                }
              },
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search items...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterItems();
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Category:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                        _filterItems();
                      },
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 4,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blue,
                      ),
                      dropdownColor: Colors.white,
                      hint: const Text('Select category'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Statistics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildStatCard(
                'Total Items',
                _items.length.toString(),
                Icons.inventory,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Low Stock',
                _items.where((item) => item.isLowStock).length.toString(),
                Icons.warning,
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Out of Stock',
                _items.where((item) => item.isOutOfStock).length.toString(),
                Icons.error,
                Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Items List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadItems,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filteredItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No items found'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadItems,
                  child: ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(_filteredItems[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== ORDERS SCREEN ====================

class OrdersScreen extends StatefulWidget {
  final ApiService apiService;

  const OrdersScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedStatus = 'All';
  String _selectedUrgency = 'All';
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'dispatched':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.black87;
    }
  }

  String _capitalizee(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'low':
        return Colors.green.shade700;
      case 'medium':
        return Colors.blue.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'critical':
        return Colors.red.shade700;
      default:
        return Colors.black87;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final orders = await widget.apiService.getOrders();
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterOrders() {
    List<Order> filtered = _orders;

    // Apply status filter
    if (_selectedStatus != 'All') {
      filtered = filtered
          .where((order) => order.status == _selectedStatus)
          .toList();
    }

    // Apply urgency filter
    if (_selectedUrgency != 'All') {
      filtered = filtered
          .where((order) => order.urgency == _selectedUrgency)
          .toList();
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await widget.apiService.updateOrderStatus(order.id, newStatus);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
      _loadOrders(); // Refresh orders
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    }
  }

  Future<void> _deleteOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete order for ${order.itemName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deleteOrder(order.id);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order deleted for ${order.itemName}')),
        );
        _loadOrders(); // Refresh orders
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting order: $e')));
      }
    }
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: order.urgencyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: order.urgencyColor),
          ),
          child: Icon(order.urgencyIcon, color: order.urgencyColor, size: 24),
        ),
        title: Text(
          order.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('OT: ${order.otName}'),
            Text('Quantity: ${order.quantity}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: order.urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: order.urgencyColor),
                  ),
                  child: Text(
                    order.urgencyText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: order.urgencyColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: order.statusColor),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: order.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (order.createdAt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ordered: ${order.createdAt.split(' ')[0]}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'dispatch') {
              _updateOrderStatus(order, 'dispatched');
            } else if (value == 'complete') {
              _updateOrderStatus(order, 'completed');
            } else if (value == 'cancel') {
              _updateOrderStatus(order, 'cancelled');
            } else if (value == 'delete') {
              _deleteOrder(order);
            }
          },
          itemBuilder: (context) {
            final menuItems = <PopupMenuEntry<String>>[];

            if (order.status == 'pending') {
              menuItems.add(
                const PopupMenuItem(
                  value: 'dispatch',
                  child: Text('Mark as Dispatched'),
                ),
              );
              menuItems.add(
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text('Cancel Order'),
                ),
              );
            } else if (order.status == 'dispatched') {
              menuItems.add(
                const PopupMenuItem(
                  value: 'complete',
                  child: Text('Mark as Completed'),
                ),
              );
            }

            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem(value: 'delete', child: Text('Delete Order')),
            );

            return menuItems;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              SizedBox(
                width: 300,
                // height: 200,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    // labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items:
                      ['All', 'pending', 'dispatched', 'completed', 'cancelled']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status == 'All'
                                    ? 'Status'
                                    : _capitalize(status),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _filterOrders();
                  },
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  elevation: 2,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 300,
                // height: 200,
                child: DropdownButtonFormField<String>(
                  value: _selectedUrgency,
                  decoration: InputDecoration(
                    // labelText: 'Urgency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.blue.shade700,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),

                  items: ['All', 'low', 'medium', 'high', 'critical']
                      .map(
                        (urgency) => DropdownMenuItem(
                          value: urgency,
                          child: Row(
                            children: [
                              if (urgency != 'All') ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getUrgencyColor(urgency),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                urgency == 'All'
                                    ? 'Urgency'
                                    : _capitalizee(urgency),
                                style: TextStyle(
                                  color: _getUrgencyColor(urgency),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUrgency = value!;
                    });
                    _filterOrders();
                  },
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),

        // Statistics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildOrderStatCard(
                'Total',
                _orders.length.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildOrderStatCard(
                'Pending',
                _orders
                    .where((order) => order.status == 'pending')
                    .length
                    .toString(),
                Icons.pending,
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildOrderStatCard(
                'Completed',
                _orders
                    .where((order) => order.status == 'completed')
                    .length
                    .toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Orders List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filteredOrders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders found'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrders[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
