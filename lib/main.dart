import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,

  );

  runApp(MyApp());

}
 
class MyApp extends StatelessWidget {

  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'Health & Nutrition App',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        primarySwatch: Colors.deepPurple,

      ),

      initialRoute: '/login',

      routes: {

        '/login': (context) => LoginScreen(),

        '/signup': (context) => SignupScreen(),

        '/home': (context) => HomeScreen(),

      },

    );

  }

}
