import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pin_code_fields/flutter_pin_code_fields.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';  // Added bcrypt package
import 'package:pomfretcardapp/main.dart';
import 'package:pomfretcardapp/pages/create_pin.dart';
import 'package:pomfretcardapp/pages/config.dart';

class VerifyPinPage extends StatefulWidget {
  final String email;
  final String password;

  VerifyPinPage({required this.email, required this.password});

  @override
  _VerifyPinPageState createState() => _VerifyPinPageState();
}

class _VerifyPinPageState extends State<VerifyPinPage> {
  final _pinController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isLoading = false;
  String _code = '';
  bool _isSubmitButtonActive = false;

  Future<void> verifyPin(String pin) async {
    setState(() {
      _isLoading = true;
    });
    String pinSalt = BCrypt.gensalt();
    String passwordSalt = BCrypt.gensalt();
    // Hash the PIN using bcrypt
    String pinHash = BCrypt.hashpw(pin, pinSalt);

    // Hash the password using bcrypt
    String passwordHash = BCrypt.hashpw(widget.password, passwordSalt);

    setState(() {
      _isLoading = false;
    });

    // Call backend to verify the PIN and save the data
    try {
      final response = await http.post(
        Uri.parse('${Config.backendUrl}/verify_pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'pin_hash': pinHash,
          'password_hash': passwordHash,
          'pin_salt': pinSalt,
          'password_salt': passwordSalt
        }),
      );

      if (response.statusCode == 200) {
        await _secureStorage.write(key: 'pin_hash', value: pinHash);
        await _secureStorage.write(key: 'pin_salt', value: pinSalt);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN Verified Successfully!')),
        );
        await loginUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend verification failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> loginUser() async {
    try {
      final saltResponse = await http.post(
        Uri.parse('${Config.backendUrl}/get_salt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      ).timeout(Duration(seconds: 10));

      if (saltResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not retrieve salt. Please try again.')),
        );
        return;
      }

      final saltData = json.decode(saltResponse.body);
      final String salt = saltData['password_salt'];
      print(salt);
      // Hash the password using the retrieved salt
      final String hashedPassword = BCrypt.hashpw(widget.password, salt);
      final response = await http.post(
        Uri.parse('${Config.backendUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'hashed_password': hashedPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String sessionToken = responseData['session_token'];
        DateTime expiresAt = DateTime.now().add(Duration(days: 7));

        await _secureStorage.write(key: 'session_token', value: sessionToken);
        await _secureStorage.write(key: 'session_expires_at', value: expiresAt.toIso8601String());
        await _secureStorage.write(key: 'user_email', value: widget.email);
        await _secureStorage.write(key: 'first_name', value: responseData['first_name']);
        await _secureStorage.write(key: 'last_name', value: responseData['last_name']);
        await _secureStorage.write(key: 'graduation_year', value: responseData['graduation_year'].toString());
        await _secureStorage.write(key: 'barcode', value: responseData['barcode']);
        await _secureStorage.write(key: 'pin_hash', value: responseData['pin_hash']);
        await _secureStorage.write(key: 'pin_salt', value: responseData['pin_salt']);

        Navigator.pushReplacementNamed(context, '/mainPage');
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You need to finish the registration process. Please create a PIN.')),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CreatePinPage(email: widget.email, password: widget.password)),
        );
      } else {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'An error occurred')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during login. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
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
                'Verify your 4-Digit PIN',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Enter your 4-digit PIN to access the app",
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
                    verifyPin(_code);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PIN must be 4 digits')),
                    );
                  }
                },
                child: Text('Verify PIN'),
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
