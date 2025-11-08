import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

// Providers (only using the ones that exist)
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Only initialize mobile-specific services on mobile (not web)
  if (!kIsWeb) {
    // TODO: Initialize services here when running on mobile
    // await NotificationService.instance.initialize();
    // await DatabaseService.instance.database;
    // await AppointmentService.instance.loadDoctors();
    print('Running on mobile - services will be initialized');
  } else {
    print('Running on web - skipping mobile-only services');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: MaterialApp(
        title: 'Health & Nutrition App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/home': (context) => HomeScreen(),
        },
      ),
    );
  }
}