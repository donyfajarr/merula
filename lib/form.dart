import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'dart:math'; // Import Random for generating random numbers
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class SimpleForm extends StatefulWidget {
  @override
  _SimpleFormState createState() => _SimpleFormState();
}

class _SimpleFormState extends State<SimpleForm> {
  final _formKey = GlobalKey<FormState>(); // Key to uniquely identify the form
  String? _name; // Variable to hold the name input
  int? _number; // Variable to hold the number input

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value; // Save the name value
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _number = int.tryParse(value!); // Save the number value
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save(); // Save the form fields

                    // Get the current user
                    User? user = FirebaseAuth.instance.currentUser;
                    print(FirebaseAuth.instance.currentUser);
                    // Generate a random number
                    int randomNumber = Random().nextInt(
                        100); // Example: random number between 0 and 99

                    // Log to console
                    print(
                        'Name: $_name, Number: $_number, Random Number: $randomNumber');

                    // Add data to Firestore
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('results')
                        .add({
                      'timeDate': Timestamp.now(),
                      'risk': _number,
                      // Include user ID if available
                    }).then((value) {
                      print("User added to Firestore");
                    }).catchError((error) {
                      print("Failed to add user: $error");
                    });

                    // Optionally, you can navigate back or show a success message
                    // Navigator.pop(context);
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Results'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('results')
            .orderBy('timeDate', descending: true) // Show latest results first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final results = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final data = results[index];
              return ListTile(
                title: Text('Risk: ${data['risk']}'),
                subtitle: Text('Date: ${data['timeDate'].toDate()}'),
              );
            },
          );
        },
      ),
    );
  }
}
