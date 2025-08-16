import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileForm extends StatefulWidget {
  final Map<String, dynamic>? existingData; // <-- pass existing data from HomeScreen

  const ProfileForm({super.key, this.existingData});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String _selectedGender = "Male"; // default value

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if available
    _nameController = TextEditingController(
        text: widget.existingData != null ? widget.existingData!["name"] : "");
    _ageController = TextEditingController(
        text: widget.existingData != null
            ? (widget.existingData!["age"]?.toString() ?? "")
            : "");
    _weightController = TextEditingController(
        text: widget.existingData != null
            ? (widget.existingData!["weight"]?.toString() ?? "")
            : "");
    _heightController = TextEditingController(
        text: widget.existingData != null
            ? (widget.existingData!["height"]?.toString() ?? "")
            : "");

    _selectedGender = widget.existingData != null
        ? widget.existingData!["gender"] ?? "Male"
        : "Male";
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;

        // Save or update Firestore
        await FirebaseFirestore.instance.collection("profiles").doc(uid).set({
          "name": _nameController.text.trim(),
          "age": int.tryParse(_ageController.text.trim()) ?? 0,
          "gender": _selectedGender,
          "weight": double.tryParse(_weightController.text.trim()) ?? 0,
          "height": double.tryParse(_heightController.text.trim()) ?? 0,
          "updatedAt": FieldValue.serverTimestamp(),
        });

        // Show centered floating snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile saved successfully ✅"),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate back to HomeScreen
        Navigator.pop(context, true); // pass true to indicate updated
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👤 Profile & Settings"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your name" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Please enter your age" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ["Male", "Female", "Other"]
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: "Weight (kg)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: "Height (cm)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Save Profile",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
