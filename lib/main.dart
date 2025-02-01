import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'theme.dart'; // Import your theme file
import 'pages/main_page/profile_page/settings_section.dart'; // Import the settings page
import 'package:provider/provider.dart';
import 'ThemeProvider.dart'; // Import your ThemeProvider class
import 'services/refresh_access_token.dart'; // Import your AuthService class

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

  // Global navigator key to use for dialogs and navigation.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Flag indicating if a network error occurred.
  bool _networkError = false;

  // Cache the Future so the validation is performed once per app start.
  late Future<bool?> _sessionValidationFuture;

  @override
  void initState() {
    super.initState();
    _sessionValidationFuture = _validateSession();
  }

  /// Validates the user session by ensuring all required data is present
  /// and then calling the backend. If the token has expired (reason_code == 5),
  /// an attempt to refresh it is made (only once).
  ///
  /// Returns:
  /// - true: session is valid.
  /// - false: session is invalid (e.g. token expired and not refreshable).
  /// - null: network error occurred.
  Future<bool?> _validateSession({int retryCount = 0}) async {
    try {
      // Read session data from secure storage.
      final firstName = await _secureStorage.read(key: 'first_name');
      final lastName = await _secureStorage.read(key: 'last_name');
      final uid = await _secureStorage.read(key: 'uid');
      final token = await _secureStorage.read(key: 'access_token');

      // Check that all required values are available.
      if (firstName == null || lastName == null || uid == null || token == null) {
        print('Error: Missing session data.');
        return false;
      }

      final fullName = '$firstName $lastName';

      // Call the backend to validate the JWT.
      final response = await http
          .post(
        Uri.parse('${Config.backendUrl}/validate_jwt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'uid': uid,
          'token': token,
        }),
      )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final responseBody = json.decode(response.body);
        // If the reason_code indicates an expired token, try refreshing.
        if (responseBody['reason_code'] == 5) {
          if (retryCount < 1) {
            print('Access token expired. Attempting refresh...');
            // Call refreshAccessToken with a no-op callback.
            await _authService.refreshAccessToken(() {}, context);
            return await _validateSession(retryCount: retryCount + 1);
          } else {
            print('Token refresh already attempted and failed.');
            return false;
          }
        } else {
          print('Error: Unauthorized access. Reason: ${responseBody['reason']}');
        }
      } else {
        print('Error: Unexpected status code ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return false;
    } on SocketException catch (e) {
      print('Network error: $e');
      setState(() {
        _networkError = true;
      });
      _showErrorDialog(
          'Network Error', 'Please check your internet connection and try again.');
      return null; // Indicates a network error.
    } on TimeoutException catch (e) {
      print('Request timeout: $e');
      setState(() {
        _networkError = true;
      });
      _showErrorDialog(
          'Server Timeout', 'The request timed out. Please try again later.');
      return null; // Indicates a network error.
    } on FormatException catch (e) {
      print('Error decoding response: $e');
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      return false;
    }
  }

  /// Displays an error dialog with options to close the app or try again.
  void _showErrorDialog(String title, String message) {
    // Ensure that the dialog uses a context from within the MaterialApp.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogContext = _navigatorKey.currentContext;
      if (dialogContext == null) return;
      showDialog(
        context: dialogContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontFamily: 'Aeonik',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(fontFamily: 'Aeonik'),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Close App',
                  style: TextStyle(fontFamily: 'Aeonik'),
                ),
                onPressed: () {
                  SystemNavigator.pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(fontFamily: 'Aeonik', color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog.
                  setState(() {
                    _networkError = false;
                    _sessionValidationFuture = _validateSession();
                  });
                },
              ),
            ],
          );
        },
      );
    });
  }

  void _toggleTheme() {
    themeNotifier.value =
    themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Pomfret Card App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          themeAnimationDuration: Duration.zero,
          home: FutureBuilder<bool?>(
            future: _sessionValidationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              } else if (snapshot.hasData) {
                if (snapshot.data == true) {
                  return _handleValidatedSession();
                } else if (snapshot.data == false) {
                  return _handleInvalidSession();
                } else {
                  // snapshot.data is null => network error.
                  return _buildLoadingScreen();
                }
              } else {
                // No data received, treat as network error.
                return _buildLoadingScreen();
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

  /// Handles navigation when the session is validated.
  Widget _handleValidatedSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final email = await _secureStorage.read(key: 'user_email');
      if (email != null) {
        _navigatorKey.currentState
            ?.pushReplacement(_buildAnimatedRoute(PinEntryPage()));
      } else {
        _navigatorKey.currentState
            ?.pushReplacement(_buildAnimatedRoute(LoginPage()));
      }
    });
    return _buildLoadingScreen();
  }

  /// Handles navigation when the session is invalid.
  Widget _handleInvalidSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigatorKey.currentState
          ?.pushReplacement(_buildAnimatedRoute(LoginPage()));
    });
    return _buildLoadingScreen();
  }

  /// Builds a simple loading screen.
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

  /// Returns a PageRouteBuilder with a slide transition.
  PageRouteBuilder _buildAnimatedRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide in from the right.
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
