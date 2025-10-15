import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  Map<String, List<String>> _foodData = {};
  final List<String> _activities = [
    "run",
    "walk",
    "gym",
    "yoga",
    "swim",
    "cycle",
    "dance",
    "stretch",
    "hike",
    "pilates"
  ];

  // Gamification fields
  int _xp = 0;
  int _level = 1;
  int get _nextLevelXp => _level * 100;

  CollectionReference get _logsCollection =>
      FirebaseFirestore.instance.collection("health_logs");

  @override
  void initState() {
    super.initState();
    _loadFoodData();
    _loadUserProgress();
  }

  Future<void> _loadFoodData() async {
    final jsonString = await rootBundle.loadString('lib/services/food.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    setState(() {
      _foodData = jsonMap.map((key, value) => MapEntry(key, List<String>.from(value)));
    });
  }

  Future<void> _loadUserProgress() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("user_progress")
        .doc(user!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _xp = doc["xp"] ?? 0;
        _level = doc["level"] ?? 1;
      });
    }
  }

  Future<void> _updateUserProgress(int gainedXp) async {
    if (user == null) return;
    int newXp = _xp + gainedXp;
    int newLevel = _level;

    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
    }

    setState(() {
      _xp = newXp;
      _level = newLevel;
    });

    await FirebaseFirestore.instance
        .collection("user_progress")
        .doc(user!.uid)
        .set({
      "xp": newXp,
      "level": newLevel,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// --- Save log ---
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
          await _updateUserProgress(20); // 🎯 +20 XP for new log
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Added successfully! 🎉 +20 XP")),
          );
        } else {
          await _logsCollection.doc(_editingLogId).set(data);
          await _updateUserProgress(10); // 🎯 +10 XP for update
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Updated successfully! +10 XP")),
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

  /// --- Clear form for "Add" ---
  void _clearForm() {
    _mealController.clear();
    _activityController.clear();
    _weightController.clear();
    _notesController.clear();
    _mood = "Happy";
    _selectedDate = DateTime.now();
    _editingLogId = null;
  }

  /// --- Open form for Add/Edit ---
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
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 25,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _editingLogId == null ? "➕ Add Health Log" : "✏️ Edit Health Log",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Date", style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      "${_selectedDate.toLocal()}".split(' ')[0],
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_mealController, "Meal"),
                  const SizedBox(height: 12),
                  _buildTextField(_activityController, "Physical Activity"),
                  const SizedBox(height: 12),
                  _buildTextField(_weightController, "Weight (kg)", isNumber: true),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _mood,
                    dropdownColor: Colors.teal.shade100,
                    items: ["Happy", "Neutral", "Sad", "Tired"]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _mood = val!),
                    decoration: _inputDecoration("Mood"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: _inputDecoration("Notes"),
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: getHealthFeedbackChips({
                      "meal": _mealController.text,
                      "physicalActivity": _activityController.text,
                      "weight": double.tryParse(_weightController.text) ?? 0,
                      "mood": _mood,
                    }),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveLog,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _editingLogId == null ? "Add Log" : "Update Log",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(label),
      style: const TextStyle(color: Colors.white),
      validator: (value) => value!.isEmpty ? "Please enter $label" : null,
    );
  }

  /// --- Structured feedback ---
  List<Widget> getHealthFeedbackChips(Map<String, dynamic> log) {
    String meal = (log["meal"] ?? "").toLowerCase();
    String activity = (log["physicalActivity"] ?? "").toLowerCase();
    double weight = (log["weight"] ?? 0).toDouble();
    String mood = (log["mood"] ?? "neutral").toLowerCase();

    List<String> suggestions = [];

    if (_foodData.isNotEmpty) {
      final hasVegetable = _foodData["vegetables"]!.any((item) => meal.contains(item));
      final hasFruit = _foodData["fruits"]!.any((item) => meal.contains(item));
      final hasProtein = _foodData["proteins"]!.any((item) => meal.contains(item));
      final hasCarb = _foodData["carbs"]!.any((item) => meal.contains(item));
      final hasSnack = _foodData["snacks"]!.any((item) => meal.contains(item));

      if (hasVegetable) suggestions.add("🥦 Nice! Veggies add vitamins.");
      if (hasFruit) suggestions.add("🍎 Fruits boost energy.");
      if (hasProtein) suggestions.add("🍗 Protein helps recovery.");
      if (hasCarb) suggestions.add("🍚 Carbs fuel your day.");
      if (hasSnack) suggestions.add("🍫 Limit snacks for balance.");

      if (!hasVegetable && !hasFruit && !hasProtein && !hasCarb && meal.isNotEmpty) {
        suggestions.add("🥗 Try adding balanced foods.");
      }
    }

    if (_activities.any((a) => activity.contains(a))) {
      suggestions.add("💪 Good job staying active!");
    } else if (activity.isNotEmpty) {
      suggestions.add("🏃 Add more physical activity!");
    }

    if (mood == "sad") {
      suggestions.add("😢 Feeling low? Try meditation or music.");
    } else if (mood == "tired") {
      suggestions.add("😴 Take a short break, maybe a walk.");
    } else if (mood == "neutral") {
      suggestions.add("😐 Balanced mood, keep it steady.");
    } else if (mood == "happy") {
      suggestions.add("😊 Awesome mood! Keep spreading joy.");
    }

    if (weight > 80) {
      suggestions.add("⚖️ Watch calories, try lighter meals.");
    } else if (weight < 50 && weight > 0) {
      suggestions.add("🥗 Eat more nutrient-rich foods.");
    } else if (weight >= 50 && weight <= 80) {
      suggestions.add("✅ Healthy weight, keep it steady.");
    }

    return suggestions
        .map((s) => Chip(
              label: Text(s),
              backgroundColor: Colors.deepPurple.shade100,
            ))
        .toList();
  }

  Widget _buildProgressBar() {
    double progress = _xp / _nextLevelXp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Level $_level Progress",
            style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white24,
          color: Colors.deepPurple,
          minHeight: 8,
        ),
        Text("XP: $_xp / $_nextLevelXp",
            style: const TextStyle(color: Colors.white70)),
      ],
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
        title: const Text(
          "My Health Logs",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade300, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildProgressBar(),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _logsCollection
                    .where("userId", isEqualTo: user!.uid)
                    .orderBy("updatedAt", descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.white)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No health logs yet.\nTap + to add one!",
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    );
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 6),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.restaurant_menu,
                                          color: Colors.teal, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        data["meal"] ?? "",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _openForm(doc: doc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () async {
                                          await _logsCollection
                                              .doc(doc.id)
                                              .delete();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text("Log deleted")),
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.fitness_center,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                        "Activity: ${data["physicalActivity"] ?? ""}"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.monitor_weight,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text("Weight: ${data["weight"] ?? ""} kg"),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.mood,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text("Mood: ${data["mood"] ?? ""}"),
                                ],
                              ),
                              if ((data["notes"] ?? "")
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes,
                                        size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Text(
                                            "Notes: ${data["notes"] ?? ""}")),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: getHealthFeedbackChips(data),
                              ),
                              if (date != null) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    "📅 ${date.toLocal().toString().split(' ')[0]}",
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
