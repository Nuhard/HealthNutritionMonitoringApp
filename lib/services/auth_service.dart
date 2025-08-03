import 'package:firebase_auth/firebase_auth.dart';
 
class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
 
  // Signup with email and password

  Future<User?> signUp(String email, String password) async {

    try {

      UserCredential userCred = await _auth.createUserWithEmailAndPassword(

          email: email, password: password);

      return userCred.user;

    } catch (e) {

      print('Signup error: $e');

      return null;

    }

  }
 
  // Login with email and password

  Future<User?> signIn(String email, String password) async {

    try {

      UserCredential userCred = await _auth.signInWithEmailAndPassword(

          email: email, password: password);

      return userCred.user;

    } catch (e) {

      print('Login error: $e');

      return null;

    }

  }
 
  // Sign out

  Future<void> signOut() async {

    await _auth.signOut();

  }

}

 