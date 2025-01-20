import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:bcrypt/bcrypt.dart';

import 'create_pin.dart';
import 'package:pomfretcardapp/pages/config.dart';
import 'package:pomfretcardapp/services/rsa_key_pair.dart';
import 'package:pomfretcardapp/utils/getDeviceModel.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  bool _isLoading = false;
  bool _isPasswordHidden = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> generateAndStorePrivateKey() async {
    try {
      final keyPair = generateRSAKeyPair();
      final publicKey = keyPair.publicKey;
      final privateKey = keyPair.privateKey;

      final secureStorage = FlutterSecureStorage();

      final publicPem = encodePublicKeyToPem(publicKey);
      final privatePem = encodePrivateKeyToPem(privateKey);

      final userEmail = await secureStorage.read(key: 'user_email');
      if (userEmail != null) {
        await http.post(
          Uri.parse('${Config.backendUrl}/store_public_key'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': userEmail, 'public_key': publicPem}),
        );
        await secureStorage.write(key: 'public_key', value: publicPem);
        await secureStorage.write(key: 'private_key', value: privatePem);
      }
    } catch (e) {
      print('Error during key generation: $e');
      throw Exception('Key generation failed');
    }
  }

  void _login() async {
    setState(() {
      _emailError = _emailController.text.isNotEmpty && !_emailController.text.endsWith('@pomfret.org')
          ? 'Email must be a valid @pomfret.org email'
          : null;
      _passwordError = _passwordController.text.length < 8
          ? 'Password must be at least 8 characters'
          : null;
    });

    if (_emailError == null && _passwordError == null) {
      setState(() {
        _isLoading = true;
      });

      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      try {
        final saltResponse = await http.post(
          Uri.parse('${Config.backendUrl}/get_salt'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email}),
        ).timeout(Duration(seconds: 10));

        if (saltResponse.statusCode == 404) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found')),
          );
          return;
        }

        final saltData = json.decode(saltResponse.body);
        final String? salt = saltData['password_salt'];
        if (salt == null || salt.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found.')),
          );
          return;
        }

        final String hashedPassword = BCrypt.hashpw(password, salt);

        final response = await http.post(
          Uri.parse('${Config.backendUrl}/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'hashed_password': hashedPassword,
            'device_info': await getDeviceModel(),
          }),
        ).timeout(Duration(seconds: 10));
        print(getDeviceModel());
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 403) {
          final responseData = json.decode(response.body);
          if (responseData['message'] == 'User account is frozen. Please contact IT support.') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Your account is frozen. Please contact IT support.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You need to finish the registration process. Please create a PIN.')),
            );
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => CreatePinPage(email: email, password: password))
            );
          }
        } else if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['access_token'] != null && responseData['uid'] != null && responseData["refresh_token"] != null) {

            await _secureStorage.write(key: "uid", value: responseData['uid'].toString());
            await _secureStorage.write(key: 'access_token', value: responseData['access_token']);
            await _secureStorage.write(key: 'refresh_token', value: responseData['refresh_token']);
            await _secureStorage.write(key: 'user_email', value: email);
            await _secureStorage.write(key: 'first_name', value: responseData['first_name']);
            await _secureStorage.write(key: 'last_name', value: responseData['last_name']);
            await _secureStorage.write(key: 'graduation_year', value: responseData['graduation_year'].toString());
            await generateAndStorePrivateKey();

            Navigator.pushReplacementNamed(context, '/pinEntry');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('It seems that the registration process was incomplete. Please create a PIN to finish your registration.')),
            );
          }
        } else {
          final responseData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'An error occurred')),
          );
        }
      } on TimeoutException catch (_) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timeout error. Try again later.')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred during login: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    color: theme.colorScheme.onSurface,
                  ),
                  SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pom',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
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
                            color: theme.colorScheme.primary,
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
              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 450),
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.brightness == Brightness.dark
                            ? theme.shadowColor.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.5),
                        spreadRadius: 0,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sign In",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Aeonik',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          hintText: '@pomfret.org email',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark ? Color(0xFF2F2F2F) : Color(0xFFE0E0E0),
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontFamily: 'Aeonik'),
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
                      SizedBox(height: 24),
                      TextField(
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          hintText: 'Password',
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark ? Color(0xFF2F2F2F) : Color(0xFFE0E0E0),
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontFamily: 'Aeonik'),
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
                          errorText: _passwordError,
                        ),
                      ),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                                fontFamily: 'Aeonik',
                                fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _login,
                        child: Text(
                          'Sign In',
                          style: TextStyle(fontSize: 18, fontFamily: 'Aeonik', fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Don’t have an account? ',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16, fontFamily: 'Aeonik'),
                    children: [
                      TextSpan(
                        text: 'Create one here',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontFamily: 'Aeonik'),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/register');
                          },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}