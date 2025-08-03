import 'package:flutter/material.dart';
import '../services/auth_service.dart';
 
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
 
  String _email = '';
  String _password = '';
  bool _loading = false;
  String _errorMessage = '';
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter an email' : null,
                      onChanged: (val) {
                        setState(() => _email = val);
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (val) =>
                          val!.length < 6 ? 'Password too short' : null,
                      onChanged: (val) {
                        setState(() => _password = val);
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Login'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _loading = true;
                            _errorMessage = '';
                          });
                          var user = await _authService.signIn(_email, _password);
                          setState(() {
                            _loading = false;
                          });
                          if (user != null) {
                            Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            setState(() {
                              _errorMessage = 'Failed to login';
                            });
                          }
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      child: Text('Don\'t have an account? Sign up'),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}