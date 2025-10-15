import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileForm extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  const ProfileForm({super.key, this.existingData});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String _selectedGender = "Male";

  @override
  void initState() {
    super.initState();

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

        await FirebaseFirestore.instance.collection("profiles").doc(uid).set({
          "name": _nameController.text.trim(),
          "age": int.tryParse(_ageController.text.trim()) ?? 0,
          "gender": _selectedGender,
          "weight": double.tryParse(_weightController.text.trim()) ?? 0,
          "height": double.tryParse(_heightController.text.trim()) ?? 0,
          "updatedAt": FieldValue.serverTimestamp(),
        });

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

        Navigator.pop(context, true);
      }
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: const [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 50, color: Colors.deepPurple),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Profile & Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel("Name"),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(),
                        validator: (value) =>
                            value!.isEmpty ? "Please enter your name" : null,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel("Age"),
                      TextFormField(
                        controller: _ageController,
                        decoration: _inputDecoration(),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? "Please enter your age" : null,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel("Gender"),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
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
                        decoration: _inputDecoration(),
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel("Weight (kg)"),
                      TextFormField(
                        controller: _weightController,
                        decoration: _inputDecoration(),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel("Height (cm)"),
                      TextFormField(
                        controller: _heightController,
                        decoration: _inputDecoration(),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "Save Profile",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
