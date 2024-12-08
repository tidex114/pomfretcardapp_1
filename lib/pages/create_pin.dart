import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pin_code_fields/flutter_pin_code_fields.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'verify_pin.dart';

class CreatePinPage extends StatefulWidget {
  final String email;
  final String password;

  CreatePinPage({required this.email, required this.password});
  @override
  _CreatePinPageState createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  String get email => widget.email;
  String get password => widget.password;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isLoading = false;
  String _code = '';
  bool _isSubmitButtonActive = false;

  Future<void> savePin(String pin) async {
    setState(() {
      _isLoading = true;
    });



    setState(() {
      _isLoading = false;
    });

    // Navigate to VerifyPinPage once the PIN is saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PIN Created Successfully!')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => VerifyPinPage(email: email, password: password) // Remove `pin` parameter

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pomfret Card App', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 1),
              Text(
                'Create a 4-Digit PIN',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Create a 4-digit PIN to access the app",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(
                height: 100.0,  // Set desired height for the fields
                child: PinCodeFields(
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  length: 4,
                  fieldBorderStyle: FieldBorderStyle.square,
                  responsive: true,
                  fieldHeight: 60.0,  // Adjust the height here
                  fieldWidth: 60.0,   // Adjust the width here
                  borderWidth: 0,
                  activeBorderColor: Colors.redAccent,
                  activeBackgroundColor: Color(0xFFE1DAE2),
                  borderRadius: BorderRadius.circular(15.0),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  obscureCharacter: "●", // Use a filled circle to represent the digits
                  fieldBackgroundColor: Color(0xFFF6F1F6),
                  onComplete: (output) {
                    setState(() {
                      _code = output;
                      _isSubmitButtonActive = output.length == 4;
                    });
                  },
                  onChange: (output) {
                    setState(() {
                      _isSubmitButtonActive = output.length == 4;
                    });
                  },
                ),
              ),

              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.redAccent)
                  : ElevatedButton(
                onPressed: () {
                  if (_code.length == 4) {
                    savePin(_code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PIN must be 4 digits')),
                    );
                  }
                },
                child: Text('Create PIN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class NotAllowedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Not Allowed'),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'You cannot create an account with this email. Please, contact IT office.',
            style: TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}