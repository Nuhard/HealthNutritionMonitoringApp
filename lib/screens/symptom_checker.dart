import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class SymptomInput {
  String? symptomName;
  String severity;
  DateTime onsetDate;

  SymptomInput({this.symptomName, this.severity = 'Mild', DateTime? onsetDate})
      : onsetDate = onsetDate ?? DateTime.now();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  final CollectionReference _symptomsCollection =
      FirebaseFirestore.instance.collection('symptoms');
  final CollectionReference _suggestionsCollection =
      FirebaseFirestore.instance.collection('symptom_suggestions');

  final List<String> predefinedSymptoms = [
    'Fever',
    'Headache',
    'Cough',
    'Fatigue',
    'Nausea',
  ];

  void _showAddSymptomDialog() {
    List<SymptomInput> tempSymptoms = [SymptomInput()];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Center(child: Text("Add Symptoms")),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...tempSymptoms.asMap().entries.map((entry) {
                    final index = entry.key;
                    final symptom = entry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: symptom.symptomName,
                              decoration: InputDecoration(
                                labelText: "Select Symptom",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: predefinedSymptoms
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setStateDialog(() => symptom.symptomName = val),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: symptom.severity,
                              decoration: InputDecoration(
                                labelText: "Severity",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: const ['Mild', 'Moderate', 'Severe']
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setStateDialog(() => symptom.severity = val!),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Onset Date"),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy')
                                    .format(symptom.onsetDate),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: symptom.onsetDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setStateDialog(
                                      () => symptom.onsetDate = picked);
                                }
                              },
                            ),
                            if (tempSymptoms.length > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => setStateDialog(
                                      () => tempSymptoms.removeAt(index)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          setStateDialog(() => tempSymptoms.add(SymptomInput())),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Another Symptom"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255, 242, 240, 241),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (user != null) {
                  for (var symptom in tempSymptoms) {
                    if (symptom.symptomName != null) {
                      await _symptomsCollection.add({
                        "userId": user!.uid,
                        "symptomName": symptom.symptomName!.trim(),
                        "severity": symptom.severity,
                        "onsetDate": symptom.onsetDate,
                        "createdAt": FieldValue.serverTimestamp(),
                      });
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Symptoms added successfully!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Submit All"),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case "Mild":
        return Colors.green.shade100;
      case "Moderate":
        return Colors.orange.shade100;
      case "Severe":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _severityChipColor(String severity) {
    switch (severity) {
      case "Mild":
        return Colors.green.shade700;
      case "Moderate":
        return Colors.orange.shade700;
      case "Severe":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildSymptomCard(Map<String, dynamic> data) {
    final String symptomName = data['symptomName'] ?? '';
    final String severity = data['severity'] ?? 'Mild';

    DateTime onsetDate;
    try {
      onsetDate = (data['onsetDate'] as Timestamp).toDate();
    } catch (_) {
      onsetDate = DateTime.now();
    }

    final Future<QuerySnapshot> future = _suggestionsCollection
        .where("symptomName", isEqualTo: symptomName)
        .limit(1)
        .get();

    return Card(
      color: _severityColor(severity),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: FutureBuilder<QuerySnapshot>(
        future: future,
        builder: (context, sugSnap) {
          if (sugSnap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Loading suggestions..."),
            );
          }

          Map<String, dynamic>? suggestion;
          if (sugSnap.hasData && sugSnap.data!.docs.isNotEmpty) {
            suggestion =
                sugSnap.data!.docs.first.data() as Map<String, dynamic>;
          }

          final String alertMessage = suggestion?['alertMessage'] ??
              "This symptom may need medical attention";
          final List<String> treatments =
              (suggestion?['treatment'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
          final List<String> diet =
              (suggestion?['diet'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];

          IconData? icon;
          Color? iconColor;
          String? tooltipMsg;

          if (severity == "Moderate") {
            icon = Icons.warning_amber_rounded;
            iconColor = Colors.orange.shade700;
            tooltipMsg = "Monitor symptoms. Consult a doctor if it persists.";
          } else if (severity == "Severe") {
            icon = Icons.error_outline_rounded;
            iconColor = Colors.red.shade700;
            tooltipMsg = "Consult a doctor / Medical attention needed";
          }

          return ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    symptomName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: severity == "Severe"
                          ? Colors.red.shade800
                          : severity == "Moderate"
                              ? Colors.orange.shade800
                              : null,
                    ),
                  ),
                ),
                if (icon != null)
                  Tooltip(
                    message: tooltipMsg!,
                    child: Icon(icon, color: iconColor),
                  ),
const SizedBox(width: 8),
Chip(
  backgroundColor: _severityChipColor(severity),
  label: SizedBox(
    width: 80, // fixed width for uniform size
    child: Center(
      child: Text(
        severity,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  ),
),

              ],
            ),
            subtitle: Text(
              "Onset: ${DateFormat('dd MMM yyyy, hh:mm a').format(onsetDate)}",
              style: const TextStyle(color: Color.fromARGB(255, 19, 19, 19)),
            ),
            children: [
              if (severity == "Severe")
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alertMessage,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              if (treatments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "💊 Treatment",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
                ...treatments.map(
                  (t) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.medical_services_outlined,
                        color: Colors.teal),
                    title: Text(t, style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const Divider(thickness: 1, indent: 16, endIndent: 16),
              ],
              if (diet.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "🥗 Diet Tips",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 212, 41, 81),
                      ),
                    ),
                  ),
                ),
                ...diet.map(
                  (d) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.restaurant_outlined,
                        color: Color.fromARGB(255, 212, 41, 81)),
                    title: Text(d, style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const Divider(thickness: 1, indent: 16, endIndent: 16),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user found.")),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade300, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.purple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: const [
                  Icon(Icons.healing, size: 60, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Symptom Checker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Symptom list with gradient
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.purple.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _symptomsCollection
                        .where("userId", isEqualTo: user!.uid)
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                "Error fetching symptoms: ${snapshot.error}"));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(
                            child: Text("No symptoms logged yet."));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (ctx, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          return _buildSymptomCard(data);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // Add Symptom Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _showAddSymptomDialog,
                  icon: const Icon(Icons.add, size: 24),
                  label: const Text(
                    "Add Symptom(s)",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 211, 204, 207),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
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
