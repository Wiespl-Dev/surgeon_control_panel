import 'package:flutter/material.dart';
import 'package:surgeon_control_panel/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HospitalStoreScreen extends StatefulWidget {
  @override
  _HospitalStoreScreenState createState() => _HospitalStoreScreenState();
}

class _HospitalStoreScreenState extends State<HospitalStoreScreen> {
  // Sample hospital store items with descriptions
  final List<HospitalItem> _items = [
    HospitalItem(
      'Syringes',
      'Medical Supplies',
      250,
      Colors.blue,
      'Disposable syringes for injections and fluid administration. Various sizes available.',
    ),
    HospitalItem(
      'Bandages',
      'Wound Care',
      150,
      Colors.red,
      'Sterile bandages for wound dressing and protection. Different sizes and materials.',
    ),
    HospitalItem(
      'Gloves',
      'Protective Gear',
      500,
      Colors.purple,
      'Disposable latex and nitrile gloves for infection control and protection.',
    ),
    HospitalItem(
      'Masks',
      'Protective Gear',
      300,
      Colors.green,
      'Surgical and N95 masks for respiratory protection and infection control.',
    ),
    HospitalItem(
      'Medicines',
      'Pharmacy',
      100,
      Colors.orange,
      'Essential medications including pain relievers, antibiotics, and emergency drugs.',
    ),
    HospitalItem(
      'Thermometers',
      'Diagnostic',
      50,
      Colors.teal,
      'Digital and infrared thermometers for accurate temperature measurement.',
    ),
    HospitalItem(
      'Scissors',
      'Tools',
      75,
      Colors.indigo,
      'Medical-grade scissors for cutting bandages, dressings, and other materials.',
    ),
    HospitalItem(
      'Sanitizers',
      'Hygiene',
      200,
      Colors.amber,
      'Alcohol-based hand sanitizers for maintaining hand hygiene.',
    ),
    HospitalItem(
      'IV Sets',
      'Medical Supplies',
      80,
      Colors.blueAccent,
      'Intravenous administration sets for fluid and medication delivery.',
    ),
    HospitalItem(
      'Gauze',
      'Wound Care',
      120,
      Colors.pink,
      'Sterile gauze pads and rolls for wound cleaning and dressing.',
    ),
    HospitalItem(
      'Stethoscopes',
      'Diagnostic',
      30,
      Colors.deepPurple,
      'Acoustic and electronic stethoscopes for patient assessment.',
    ),
    HospitalItem(
      'Catheters',
      'Medical Supplies',
      60,
      Colors.cyan,
      'Urinary catheters in various sizes for patient care.',
    ),
    HospitalItem(
      'Needles',
      'Medical Supplies',
      180,
      Colors.blueGrey,
      'Hypodermic needles in various gauges for injections and blood draws.',
    ),
    HospitalItem(
      'Swabs',
      'Wound Care',
      220,
      Colors.brown,
      'Sterile cotton swabs for cleaning and applying medications.',
    ),
    HospitalItem(
      'Gowns',
      'Protective Gear',
      90,
      Colors.lightBlue,
      'Disposable isolation gowns for infection control procedures.',
    ),
    HospitalItem(
      'Alcohol Wipes',
      'Hygiene',
      160,
      Colors.lightGreen,
      'Pre-packaged alcohol wipes for surface and skin disinfection.',
    ),
    // Additional items
    HospitalItem(
      'Sutures',
      'Medical Supplies',
      70,
      Colors.deepOrange,
      'Sterile sutures for wound closure in various sizes and materials.',
    ),
    HospitalItem(
      'Tongue Depressors',
      'Tools',
      140,
      Colors.lime,
      'Disposable wooden tongue depressors for oral examinations.',
    ),
    HospitalItem(
      'Blood Pressure Cuffs',
      'Diagnostic',
      45,
      Colors.redAccent,
      'Various sizes of blood pressure cuffs for accurate measurement.',
    ),
    HospitalItem(
      'Oxygen Masks',
      'Medical Supplies',
      60,
      Colors.cyanAccent,
      'Disposable oxygen masks for oxygen therapy delivery.',
    ),
    HospitalItem(
      'Bedpans',
      'Patient Care',
      35,
      Colors.grey,
      'Bedpans for patient hygiene and comfort.',
    ),
    HospitalItem(
      'Urinals',
      'Patient Care',
      40,
      Colors.blueGrey,
      'Portable urinals for patient convenience.',
    ),
    HospitalItem(
      'Specimen Containers',
      'Lab Supplies',
      120,
      Colors.yellow,
      'Sterile containers for collecting and transporting specimens.',
    ),
    HospitalItem(
      'Sharps Containers',
      'Safety',
      25,
      Colors.red,
      'Puncture-resistant containers for safe disposal of sharps.',
    ),
    HospitalItem(
      'Exam Table Paper',
      'Supplies',
      85,
      Colors.white,
      'Disposable paper rolls for examination tables.',
    ),
    HospitalItem(
      'Cotton Balls',
      'Wound Care',
      200,
      Colors.white,
      'Sterile cotton balls for wound cleaning and medication application.',
    ),
    HospitalItem(
      'Adhesive Tape',
      'Wound Care',
      110,
      Colors.grey,
      'Medical adhesive tape for securing dressings and bandages.',
    ),
    HospitalItem(
      'Eye Patches',
      'Wound Care',
      65,
      Colors.black,
      'Disposable eye patches for eye protection and treatment.',
    ),
    HospitalItem(
      'Splints',
      'Orthopedic',
      30,
      Colors.brown,
      'Various types of splints for immobilizing injured limbs.',
    ),
    HospitalItem(
      'Crutches',
      'Mobility',
      15,
      Colors.blueGrey,
      'Adjustable crutches for patient mobility assistance.',
    ),
    HospitalItem(
      'Wheelchairs',
      'Mobility',
      8,
      Colors.blue,
      'Standard and transport wheelchairs for patient mobility.',
    ),
    HospitalItem(
      'Nebulizers',
      'Respiratory',
      12,
      Colors.tealAccent,
      'Nebulizer machines for respiratory medication delivery.',
    ),
    HospitalItem(
      'Oxygen Tanks',
      'Respiratory',
      10,
      Colors.grey,
      'Portable oxygen tanks for oxygen therapy.',
    ),
    HospitalItem(
      'Defibrillators',
      'Emergency',
      5,
      Colors.red,
      'Automated external defibrillators for cardiac emergencies.',
    ),
    HospitalItem(
      'ECG Machines',
      'Diagnostic',
      7,
      Colors.purple,
      'Electrocardiogram machines for heart monitoring.',
    ),
    HospitalItem(
      'Pulse Oximeters',
      'Diagnostic',
      18,
      Colors.red,
      'Devices for measuring blood oxygen saturation levels.',
    ),
    HospitalItem(
      'Hospital Beds',
      'Equipment',
      6,
      Colors.blueGrey,
      'Adjustable hospital beds for patient comfort and care.',
    ),
    HospitalItem(
      'IV Poles',
      'Equipment',
      20,
      Colors.grey,
      'Mobile IV poles for hanging IV bags and pumps.',
    ),
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showItemDetails = false;
  HospitalItem? _selectedItem;

  final List<String> _categories = [
    'All',
    'Medical Supplies',
    'Wound Care',
    'Protective Gear',
    'Pharmacy',
    'Diagnostic',
    'Tools',
    'Hygiene',
    'Patient Care',
    'Lab Supplies',
    'Safety',
    'Supplies',
    'Orthopedic',
    'Mobility',
    'Respiratory',
    'Emergency',
    'Equipment',
  ];

  List<HospitalItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Function to increase item quantity
  void _increaseQuantity(int index) {
    setState(() {
      _items[index] = HospitalItem(
        _items[index].name,
        _items[index].category,
        _items[index].quantity + 1,
        _items[index].color,
        _items[index].description,
      );
    });
  }

  // Function to decrease item quantity
  void _decreaseQuantity(int index) {
    if (_items[index].quantity > 0) {
      setState(() {
        _items[index] = HospitalItem(
          _items[index].name,
          _items[index].category,
          _items[index].quantity - 1,
          _items[index].color,
          _items[index].description,
        );
      });
    }
  }

  // Function to show item details
  void _showDetails(HospitalItem item) {
    setState(() {
      _selectedItem = item;
      _showItemDetails = true;
    });
  }

  // Function to close item details
  void _closeDetails() {
    setState(() {
      _showItemDetails = false;
      _selectedItem = null;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("uniqueCode");
    await prefs.remove("mode");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hospital Store Inventory',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 40, 123, 131),
                Color.fromARGB(255, 39, 83, 87),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,

        elevation: 0,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.add, color: Colors.white, size: 22),
          //   onPressed: () {
          //     // Add new item functionality
          //     _showAddItemDialog();
          //   },
          // ),
        ],
      ),
      body: _showItemDetails && _selectedItem != null
          ? _buildItemDetailView(_selectedItem!)
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 40, 123, 131),
                    Color.fromARGB(255, 39, 83, 87),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  IconButton(
                    onPressed: () {
                      _logout();
                    },
                    icon: Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.blue[800],
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(88, 255, 255, 255),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),

                  // Category Filter
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                            label: Text(
                              category,
                              style: TextStyle(fontSize: 12),
                            ),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : 'All';
                              });
                            },
                            backgroundColor: Colors.transparent,
                            selectedColor: Colors.blue[800],
                            labelStyle: TextStyle(
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Inventory Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filteredItems.length} Items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Total: ${_calculateTotalItems()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grid View with adjusted height
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 112.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85, // Adjusted for taller cards
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final originalIndex = _items.indexWhere(
                            (i) => i.name == item.name,
                          );
                          return _buildItemCard(item, originalIndex);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemCard(HospitalItem item, int index) {
    return GestureDetector(
      onTap: () => _showDetails(item),
      child: SizedBox(
        height: 200, // Fixed card height of 200
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Item Icon
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: item.color,
                    size: 22,
                  ),
                ),

                // Item Name
                Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                // Item Category
                Text(
                  item.category,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                // Quantity
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 13,
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.remove, size: 16),
                        onPressed: () => _decreaseQuantity(index),
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, size: 16),
                        onPressed: () => _increaseQuantity(index),
                        color: Colors.green,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetailView(HospitalItem item) {
    return Container(
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _closeDetails,
                ),
                SizedBox(width: 10),
                Text(
                  'Item Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services,
                  color: item.color,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              item.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text(
              item.category,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 10),
            Text(item.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text(
              'Current Quantity: ${item.quantity}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.remove),
                  label: Text('Decrease'),
                  onPressed: () {
                    final index = _items.indexWhere((i) => i.name == item.name);
                    if (index != -1) _decreaseQuantity(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Increase'),
                  onPressed: () {
                    final index = _items.indexWhere((i) => i.name == item.name);
                    if (index != -1) _increaseQuantity(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Item'),
          content: Text(
            'Functionality to add new items would be implemented here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  int _calculateTotalItems() {
    return _filteredItems.fold(0, (sum, item) => sum + item.quantity);
  }
}

class HospitalItem {
  final String name;
  final String category;
  final int quantity;
  final Color color;
  final String description;

  HospitalItem(
    this.name,
    this.category,
    this.quantity,
    this.color,
    this.description,
  );
}
