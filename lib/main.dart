import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pages/verify_pin.dart';
import 'pages/login.dart';
import 'pages/main_page.dart';
import 'pages/register.dart';
import 'pages/password_reset.dart'; // Adjust the path if necessary

import 'pages/pin_entry.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<bool> _isUserLoggedIn() async {
    String? sessionToken = await _secureStorage.read(key: 'session_token');
    print('Debug: Session token found: \$sessionToken');
    String? expiresAtStr = await _secureStorage.read(key: 'session_expires_at');
    String? userEmail = await _secureStorage.read(key: 'user_email');

    if (sessionToken != null && expiresAtStr != null && userEmail != null) {
      DateTime expiresAt = DateTime.parse(expiresAtStr);
      if (expiresAt.isAfter(DateTime.now())) {
        // Token exists and is valid
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomfret Card App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: FutureBuilder<bool>(
        future: _isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData && snapshot.data == true) {
            return FutureBuilder<String?> (
              future: _secureStorage.read(key: 'user_email'),
              builder: (context, emailSnapshot) {
                if (emailSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (emailSnapshot.hasData && emailSnapshot.data != null) {
                  return PinEntryPage();
                } else {
                  return LoginPage();
                }
              },
            );
          } else {
            return LoginPage();
          }
        },
      ),
      routes: {
        '/register': (context) => RegisterPage(),
        '/pinEntry': (context) => PinEntryPage(),
        '/mainPage': (context) => MainPage(),
        '/forgot-password': (context) => PasswordResetPage(),
        '/verifyPin': (context) => VerifyPinPage(
            email: ModalRoute.of(context)?.settings.arguments as String? ?? '',
            password: '' // Provide the correct password value here.
        ),        '/login': (context) => LoginPage(),
      },
    );
  }
}