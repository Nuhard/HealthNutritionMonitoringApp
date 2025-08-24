import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});

  @override
  _HealthLogScreenState createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _mealController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _mood = "Happy";
  DateTime _selectedDate = DateTime.now();
  String? _editingLogId;

  CollectionReference get _logsCollection =>
      FirebaseFirestore.instance.collection("health_logs");

  Future<void> _saveLog() async {
    if (_formKey.currentState!.validate() && user != null) {
      final data = {
        "userId": user!.uid,
        "date": _selectedDate,
        "meal": _mealController.text.trim(),
        "physicalActivity": _activityController.text.trim(),
        "weight": double.tryParse(_weightController.text.trim()) ?? 0,
        "mood": _mood,
        "notes": _notesController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      try {
        if (_editingLogId == null) {
          await _logsCollection.add(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Added successfully!")),
          );
        } else {
          await _logsCollection.doc(_editingLogId).set(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Updated successfully!")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }

      _clearForm();
      Navigator.pop(context);
    }
  }

  void _clearForm() {
    _mealController.clear();
    _activityController.clear();
    _weightController.clear();
    _notesController.clear();
    _mood = "Happy";
    _selectedDate = DateTime.now();
    _editingLogId = null;
  }

  void _openForm({DocumentSnapshot? doc}) {
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      _mealController.text = data["meal"] ?? "";
      _activityController.text = data["physicalActivity"] ?? "";
      _weightController.text = (data["weight"] ?? "").toString();
      _notesController.text = data["notes"] ?? "";
      _mood = data["mood"] ?? "Happy";
      _selectedDate = (data["date"] as Timestamp).toDate();
      _editingLogId = doc.id;
    }
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _editingLogId == null ? "Add Health Log" : "Edit Health Log",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Date"),
                  subtitle: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _mealController,
                  decoration: const InputDecoration(
                    labelText: "Meal",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter meal" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _activityController,
                  decoration: const InputDecoration(
                    labelText: "Physical Activity",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter activity" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: "Weight (kg)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? "Please enter weight" : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _mood,
                  items: ["Happy", "Neutral", "Sad"]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _mood = val!),
                  decoration: const InputDecoration(
                    labelText: "Mood",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: "Notes",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveLog,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child:
                      Text(_editingLogId == null ? "Add Log" : "Update Log"),
                )
              ],
            ),
          ),
        ),
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
      appBar: AppBar(
        title: const Text("Health Logs"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _logsCollection
            .where("userId", isEqualTo: user!.uid)
            .orderBy("updatedAt", descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
                child: Text(
              "No health logs yet.\nTap + to add one!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data["date"] as Timestamp?)?.toDate();
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  title: Text(
                    data["meal"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text("Activity: ${data["physicalActivity"] ?? ""}"),
                        Text("Weight: ${data["weight"] ?? ""} kg"),
                        Text("Mood: ${data["mood"] ?? ""}"),
                        Text("Notes: ${data["notes"] ?? ""}"),
                        if (date != null)
                          Text("Date: ${date.toLocal().toString().split(' ')[0]}"),
                      ]),
                  trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _openForm(doc: doc)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}