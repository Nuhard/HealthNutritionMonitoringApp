import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool profileExists = false;
  bool isLoading = true;
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("profiles")
          .doc(user!.uid)
          .get();

      setState(() {
        profileExists = doc.exists;
        profileData = doc.data();
        isLoading = false;
      });
    }
  }

  Widget _buildProfileCard() {
    if (!profileExists || profileData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hello,", style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          Text(user?.displayName ?? user?.email ?? "User",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              )),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(profileData!["name"] ?? "",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[800])),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.cake, size: 16, color: Colors.grey[700]),
            SizedBox(width: 5),
            Text("Age: ${profileData!["age"] ?? '-'}"),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey[700]),
            SizedBox(width: 5),
            Text("Gender: ${profileData!["gender"] ?? '-'}"),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.monitor_weight, size: 16, color: Colors.grey[700]),
            SizedBox(width: 5),
            Text("Weight: ${profileData!["weight"] ?? '-'} kg"),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.height, size: 16, color: Colors.grey[700]),
            SizedBox(width: 5),
            Text("Height: ${profileData!["height"] ?? '-'} cm"),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Health & Nutrition'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 30),
            Text(
              "Welcome to your Health & Nutrition dashboard 🌱",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.teal.shade200,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    SizedBox(width: 15),
                    Expanded(child: _buildProfileCard()),
                    IconButton(
                      icon: Icon(
                        profileExists ? Icons.edit : Icons.add,
                        color: Colors.teal[800],
                      ),
                      tooltip: profileExists ? "Edit Profile" : "Create Profile",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileForm(
                                  existingData: profileData)), // pass existing data
                        ).then((_) => _checkProfile()); // refresh after save
                      },
                    ),
                  ],
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}

