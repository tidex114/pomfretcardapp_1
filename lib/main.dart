import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'pages/verify_pin.dart';
import 'pages/login.dart';
import 'pages/main_page/main_page.dart';
import 'pages/register.dart';
import 'pages/password_reset.dart';
import 'pages/pin_entry/pin_entry_page.dart';
import 'package:pomfretcardapp/pages/config.dart';
import 'theme.dart'; // Import the theme file
import 'pages/main_page/profile_page/settings_section.dart'; // Import the settings page
import 'package:provider/provider.dart';
import 'ThemeProvider.dart'; // Import the ThemeProvider class

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  Future<bool> _isUserLoggedIn() async {
    String? sessionToken = await _secureStorage.read(key: 'session_token');
    print('Debug: Session token found: $sessionToken');
    String? expiresAtStr = await _secureStorage.read(key: 'session_expires_at');
    String? userEmail = await _secureStorage.read(key: 'user_email');

    if (sessionToken != null && expiresAtStr != null && userEmail != null) {
      DateTime expiresAt = DateTime.parse(expiresAtStr);
      if (expiresAt.isAfter(DateTime.now())) {
        // Call the /validate_session route
        bool isValidSession = await _validateSession(sessionToken, userEmail);
        if (!isValidSession) {
          await _clearStorage();
        }
        return isValidSession;
      }
    }
    await _clearStorage();
    return false;
  }

  Future<void> _clearStorage() async {
    await _secureStorage.delete(key: 'session_token');
    await _secureStorage.delete(key: 'session_expires_at');
    await _secureStorage.delete(key: 'user_email');
  }

  Future<bool> _validateSession(String sessionToken, String userEmail) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.backendUrl}/validate_session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_token': sessionToken, 'email': userEmail}),
      );

      if (response.statusCode == 200) {
        // Session is valid
        return true;
      } else {
        // Session is invalid or expired
        return false;
      }
    } catch (e) {
      print('Error validating session: $e');
      return false;
    }
  }

  void _toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Pomfret Card App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          themeAnimationDuration: Duration.zero, // Disable theme animation
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
            '/mainPage': (context) => MainPage(themeNotifier: themeNotifier),
            '/forgot-password': (context) => PasswordResetPage(),
            '/verifyPin': (context) => VerifyPinPage(
              email: ModalRoute.of(context)?.settings.arguments as String? ?? '',
              password: '',
            ),
            '/login': (context) => LoginPage(), // No email parameter needed
            '/settings': (context) => SettingsSection(themeNotifier: themeNotifier), // Add settings route
          },
        );
      },
    );
  }
}