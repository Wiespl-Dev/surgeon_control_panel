import 'package:flutter/material.dart';

class SurgeryHistoryPage extends StatefulWidget {
  const SurgeryHistoryPage({Key? key}) : super(key: key);

  @override
  State<SurgeryHistoryPage> createState() => _SurgeryHistoryPageState();
}

class _SurgeryHistoryPageState extends State<SurgeryHistoryPage> {
  final List<String> surgeryRecords = [
    "Appendectomy - 2022",
    "Knee Replacement - 2023",
  ];

  void _addNewSurgeryRecord() {
    setState(() {
      surgeryRecords.add("New Surgery - ${DateTime.now().year}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with gradient
      appBar: AppBar(
        title: const Text(
          'Surgery History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addNewSurgeryRecord,
          ),
        ],
        flexibleSpace: Container(
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
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // Body with gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 112, 143, 214),
              Color.fromARGB(255, 157, 102, 228),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: surgeryRecords.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: Colors.black26,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurpleAccent,
                  child: const Icon(Icons.local_hospital, color: Colors.white),
                ),
                title: Text(
                  surgeryRecords[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  "View details",
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.deepPurple,
                ),
                onTap: () {},
              ),
            );
          },
        ),
      ),
    );
  }
}
