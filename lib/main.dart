import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'input.dart'; // Import your input.dart file
import 'form.dart'; // Ensure form.dart contains SimpleForm
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Picker and MoveNet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SignInScreen(), // Start with SignInScreen
    );
  }
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Check for null values
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("Error: Access token or ID token is null");
        return;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // This will sign in the user to Firebase with the Google credentials
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Now you can safely print the current user
      User? user = FirebaseAuth.instance.currentUser;
      print(user); // This should not be null

      // If successful, navigate to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (error) {
      print("Error signing in: $error");
    } finally {
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Center(
        child: _isSigningIn
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _signInWithGoogle,
                child: Text('Sign in with Google'),
              ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to MoveNet App'),
      ),
      body: Center(
        child: Column(
          // Use Column to stack widgets vertically
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to ImagePickerScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImagePickerScreen()),
                );
              },
              child: Text('Go to Image Picker'),
            ),
            SizedBox(height: 20), // Space between the buttons
            ElevatedButton(
              onPressed: () {
                // Navigate to SimpleForm
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SimpleForm()),
                );
              },
              child: Text('Go to Simple Form'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResultsScreen()),
                  );
                },
                child: Text('Go To Results'))
          ],
        ),
      ),
    );
  }
}
