import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/analytics_screen.dart';

// Services
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'services/appointment_service.dart';

// Providers
import 'providers/health_provider.dart';
import 'providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services
  await NotificationService.instance.initialize();
  SyncService.instance.initConnectivityListener();
  await AppointmentService.instance.loadDoctors();

  // Setup daily reminders
  await NotificationService.instance.setupDailyHealthReminders();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider()),
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
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/appointments': (context) => const AppointmentsScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
        },
      ),
    );
  }
}