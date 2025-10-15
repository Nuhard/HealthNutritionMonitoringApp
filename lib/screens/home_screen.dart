import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/sync_provider.dart';
import 'profile_screen.dart';
import 'health_log.dart';
import 'symptom_checker.dart';
import 'appointments_screen.dart';
import '../widgets/sync_status_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  bool profileExists = false;
  bool isLoading = true;
  Map<String, dynamic>? profileData;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkProfile();

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();

    // Trigger sync when home screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SyncProvider>(context, listen: false).checkUnsyncedItems();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          Text("Hello,",
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          Text(user?.displayName ?? user?.email ?? "User",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              )),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(profileData!["name"] ?? "",
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.cake, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 5),
          Text("Age: ${profileData!["age"] ?? '-'}"),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.person, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 5),
          Text("Gender: ${profileData!["gender"] ?? '-'}"),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.monitor_weight, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 5),
          Text("Weight: ${profileData!["weight"] ?? '-'} kg"),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.height, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 5),
          Text("Height: ${profileData!["height"] ?? '-'} cm"),
        ]),
      ],
    );
  }

  Widget _buildCustomCard({
    required Color avatarColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: avatarColor,
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios,
                  size: 28, color: Colors.deepPurple),
              onPressed: onPressed,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
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
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      "🌱 Welcome to your Health Dashboard",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 244, 242, 242),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Your health is your greatest wealth. 🌿",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Track your habits, stay active, and nourish your body and mind daily to feel your best!",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ✅ NEW: Sync Status Widget
              const SyncStatusWidget(),

              const SizedBox(height: 5),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.deepPurple.shade200,
                        child: const Icon(Icons.person,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _buildProfileCard()),
                      IconButton(
                        icon: Icon(
                          profileExists ? Icons.edit : Icons.add,
                          color: Colors.deepPurple,
                        ),
                        tooltip:
                            profileExists ? "Edit Profile" : "Create Profile",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ProfileForm(existingData: profileData)),
                          ).then((_) => _checkProfile());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _buildCustomCard(
                avatarColor: Colors.orange.shade400,
                icon: Icons.health_and_safety,
                title: "Health Logs",
                subtitle: "Track your meals, activity, weight & mood daily.",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HealthLogScreen()),
                  );
                },
              ),
              _buildCustomCard(
                avatarColor: Colors.red.shade400,
                icon: Icons.medical_services,
                title: "Symptom Checker",
                subtitle: "Log symptoms & check severity.",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SymptomCheckerScreen()),
                  );
                },
              ),
              // ✅ NEW: Appointments Button
              _buildCustomCard(
                avatarColor: Colors.blue.shade400,
                icon: Icons.calendar_month,
                title: "Appointments",
                subtitle: "Book consultations with doctors.",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AppointmentsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}