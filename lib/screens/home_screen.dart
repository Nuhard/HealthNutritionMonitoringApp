import 'package:flutter/material.dart';

import '../services/auth_service.dart';
 
class HomeScreen extends StatelessWidget {

  final AuthService _authService = AuthService();
 
  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text('Health & Nutrition Home'),

        actions: [

          IconButton(

            icon: Icon(Icons.logout),

            onPressed: () async {

              await _authService.signOut();

              Navigator.pushReplacementNamed(context, '/login');

            },

          )

        ],

      ),

      body: Center(

        child: Text('Welcome! You are logged in.'),

      ),

    );

  }

}

 