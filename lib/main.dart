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
import 'services/refresh_access_token.dart'; // Import the AuthService class

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
  final AuthService _authService = AuthService();

  Future<bool> _validateSession() async {
    try {
      final fullName = '${await _secureStorage.read(key: 'first_name')} ${await _secureStorage.read(key: 'last_name')}';
      final uid = await _secureStorage.read(key: 'uid');
      final token = await _secureStorage.read(key: 'access_token');

      if (token == null) {
        print('Error: Access token is null');
        return false;
      }

      final response = await http.post(
        Uri.parse('${Config.backendUrl}/validate_jwt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'uid': uid,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final responseBody = json.decode(response.body);
        if (responseBody['reason_code'] == 5) {
          print('Access token expired. Attempting refresh...');
          await _authService.refreshAccessToken(() async => null, context);
          return await _validateSession(); // Retry session validation after token refresh
        } else {
          print('Error: Unauthorized access. Reason: ${responseBody['reason']}');
        }
      } else {
        print('Error: Unexpected status code ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return false;
    } on http.ClientException catch (e) {
      print('Network error: $e');
      return false;
    } on FormatException catch (e) {
      print('Error decoding response: $e');
      return false;
    } catch (e) {
      print('Unexpected error: $e');
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
          themeAnimationDuration: Duration.zero,
          home: FutureBuilder<bool>(
            future: _validateSession(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              } else if (snapshot.hasData && snapshot.data == true) {
                return _handleValidatedSession(context);
              } else {
                return _handleInvalidSession(context);
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
            '/login': (context) => LoginPage(),
            '/settings': (context) => SettingsSection(themeNotifier: themeNotifier),
          },
        );
      },
    );
  }

  // Handles navigation when the session is validated
  Widget _handleValidatedSession(BuildContext context) {
    Future.microtask(() async {
      final email = await _secureStorage.read(key: 'user_email');
      if (email != null) {
        Navigator.pushReplacement(
          context,
          _buildAnimatedRoute(PinEntryPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          _buildAnimatedRoute(LoginPage()),
        );
      }
    });
    return _buildLoadingScreen(); // Placeholder while navigating
  }

  // Handles navigation when the session is invalid
  Widget _handleInvalidSession(BuildContext context) {
    Future.microtask(() {
      Navigator.pushReplacement(
        context,
        _buildAnimatedRoute(LoginPage()),
      );
    });
    return _buildLoadingScreen(); // Placeholder while navigating
  }

  // Helper function for loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/pomcard_icon_light.png',
              width: 150,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for animated route transitions
  PageRouteBuilder _buildAnimatedRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide in from the right
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
