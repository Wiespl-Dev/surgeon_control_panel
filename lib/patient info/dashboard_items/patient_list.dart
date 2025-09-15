import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:surgeon_control_panel/patient%20info/dashboard_items/user/user_list.dart';

class HISApiService {
  final String baseUrl = "https://hapi.fhir.org/baseR4";

  /// Fetch patients from HIS (FHIR API)
  Future<List<Map<String, dynamic>>> fetchPatients() async {
    final url = Uri.parse("$baseUrl/Patient?_count=10");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract patient entries
      List<Map<String, dynamic>> patients = [];
      if (data['entry'] != null) {
        for (var entry in data['entry']) {
          final resource = entry['resource'];
          patients.add({
            "id": resource['id'],
            "name": resource['name'] != null
                ? resource['name'][0]['given']?.join(" ") ?? "Unknown"
                : "Unknown",
            "gender": resource['gender'] ?? "N/A",
          });
        }
      }
      return patients;
    } else {
      throw Exception("Failed to load patients: ${response.statusCode}");
    }
  }
}

class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final HISApiService apiService = HISApiService();
  late Future<List<Map<String, dynamic>>> patientsFuture;

  @override
  void initState() {
    super.initState();
    patientsFuture = apiService.fetchPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient List")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No patients found"));
          }

          final patients = snapshot.data!;
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                child: ListTile(
                  title: Text(patient['name']),
                  subtitle: Text("Gender: ${patient['gender']}"),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HospitalPortalApp(),
                        ),
                      );
                    },
                    child: Text("#${patient['id']}"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
