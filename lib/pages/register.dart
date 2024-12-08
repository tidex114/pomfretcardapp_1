import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pomfretcardapp/pages/code_entry.dart';  // Import the CodeEntryPage
import 'package:pomfretcardapp/pages/config.dart';
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  bool _isSubmitButtonActive = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordHidden = true;
  bool _isRepeatPasswordHidden = true;
  String? _emailError;
  String? _passwordMatchError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkInputValidity);
    _passwordController.addListener(_checkInputValidity);
    _repeatPasswordController.addListener(_checkInputValidity);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  // Check if the passwords match and are valid
  void _checkInputValidity() {
    setState(() {
      _emailError = _emailController.text.isNotEmpty &&
          !_emailController.text.endsWith('@pomfret.org')
          ? 'Email must be a valid @pomfret.org email'
          : null;
      _passwordMatchError =
      _passwordController.text != _repeatPasswordController.text
          ? 'Passwords do not match'
          : null;
      _isSubmitButtonActive =
          _passwordController.text == _repeatPasswordController.text &&
              _passwordController.text.length >=
                  8 && // Ensure password is at least 8 characters
              _emailError == null;
    });
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    final url = '${Config.backendUrl}/register';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'password': password, // Send email and password securely
        }),
      );

      if (response.statusCode == 200) {
        // After successful registration, navigate to CodeEntryPage to verify the code
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
              CodeEntryPage(email: email, password: password)),
        );
      } else {
        final message = jsonDecode(response.body)['message'];
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/pomcard_icon.svg',
                    height: 60,
                  ),
                  SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pom',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 50,
                            fontFamily: 'Aeonik',
                            fontWeight: FontWeight.w700,
                            height: 0,
                            letterSpacing: 1.38,
                          ),
                        ),
                        TextSpan(
                          text: 'card',
                          style: TextStyle(
                            color: Color(0xFFED4747),
                            fontSize: 50,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Aeonik',
                            fontWeight: FontWeight.w700,
                            height: 0,
                            letterSpacing: 1.38,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 0,
                      blurRadius: 7,
                      offset: Offset(0, 3), // Only bottom shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sign up",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Aeonik',
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                        hintText: '@pomfret.org email',
                        filled: true,
                        fillColor: Color(0xFFE1DAE2),
                        hintStyle: TextStyle(color: Color(0xFF57636C), fontFamily: 'Aeonik'),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _emailError,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _isPasswordHidden,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        hintText: 'Password',
                        filled: true,
                        fillColor: Color(0xFFE1DAE2),
                        hintStyle: TextStyle(color: Color(0xFF57636C), fontFamily: 'Aeonik'),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordHidden ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isPasswordHidden = !_isPasswordHidden;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _repeatPasswordController,
                      obscureText: _isRepeatPasswordHidden,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                        hintText: 'Confirm Password',
                        filled: true,
                        fillColor: Color(0xFFE1DAE2),
                        hintStyle: TextStyle(color: Color(0xFF57636C), fontFamily: 'Aeonik'),
                        suffixIcon: IconButton(
                          icon: Icon(_isRepeatPasswordHidden ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isRepeatPasswordHidden = !_isRepeatPasswordHidden;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_passwordController.text.length < 8) // Show message if password is too short
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Password must be at least 8 characters long',
                            style: TextStyle(color: Colors.red, fontFamily: 'Aeonik'),
                          ),
                        ),
                      ),
                    if (_passwordMatchError != null) // Show message if passwords do not match
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _passwordMatchError!,
                            style: TextStyle(color: Colors.red, fontFamily: 'Aeonik'),
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _isSubmitButtonActive
                          ? _submitRegistration
                          : null,
                      child: Text(
                        'Sign up',
                        style: TextStyle(fontSize: 18, fontFamily: 'Aeonik', fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red, fontFamily: 'Aeonik'),
                          ),
                        ),
                      ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Aeonik'),
                    children: [
                      TextSpan(
                        text: 'Sign In here',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Aeonik'),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/login');
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
