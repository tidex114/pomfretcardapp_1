// lib/pages/pin_entry/pin_entry_functions.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'WelcomeBackPage.dart';
import 'pin_entry_controller.dart';
import 'package:pomfretcardapp/pages/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pomfretcardapp/pages/config.dart';

// Assuming you have access to the themeNotifier here
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);




void onDigitTap(String digit, PinEntryController pinEntryController, Function verifyPin) {
  HapticFeedback.lightImpact();
  pinEntryController.addDigit(digit);
  if (pinEntryController.isPinComplete) {
    verifyPin();
  }
}

void onDeleteTap(PinEntryController pinEntryController) {
  HapticFeedback.lightImpact();
  pinEntryController.removeLastDigit();
}

void onPinChanged(StateSetter setState) {
  setState(() {});
}

void showLockDialog(BuildContext context, Duration remainingLockTime) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('App Locked', style: TextStyle(fontFamily: 'Aeonik')),
      content: Text(
        'Too many incorrect attempts. The app is locked for ${remainingLockTime.inSeconds} seconds.',
        style: TextStyle(fontFamily: 'Aeonik'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('OK', style: TextStyle(fontFamily: 'Aeonik')),
        ),
      ],
    ),
  );
}

void showWarningDialogWithTimer(BuildContext context, int lockLevel, StateSetter dialogSetState, Timer countdownTimer, int countdown) {
  IconData consequenceIcon;
  String consequenceText;

  if (lockLevel == 1) {
    consequenceIcon = Icons.timer;
    consequenceText = 'locked for 10 seconds';
  } else if (lockLevel == 2) {
    consequenceIcon = Icons.lock_clock;
    consequenceText = 'locked for 10 seconds';
  } else if (lockLevel >= 3) {
    consequenceIcon = Icons.lock_outline;
    consequenceText = 'frozen indefinitely';
  } else {
    consequenceIcon = Icons.warning;
    consequenceText = 'locked for 10 seconds';
  }

  countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (countdown <= 1) {
      dialogSetState(() {
        countdown = 0;
        timer.cancel();
      });
    } else {
      dialogSetState(() {
        countdown--;
      });
    }
  });

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(consequenceIcon, color: Colors.red),
          SizedBox(width: 8),
          Text('Warning', style: TextStyle(fontFamily: 'Aeonik')),
        ],
      ),
      content: Text(
          'You have only one attempt to unlock the app. If you fail, the account will be $consequenceText.',
          style: TextStyle(fontFamily: 'Aeonik')),
      actions: [
        TextButton(
          onPressed: countdown == 0
              ? () {
            Navigator.of(context).pop();
          }
              : null,
          child: Text('OK ($countdown)', style: TextStyle(fontFamily: 'Aeonik')),
        ),
      ],
    ),
  );
}


Future<void> verifyPin({
  required BuildContext context,
  required bool isLocked,
  required bool isLoading,
  required bool isPinValid,
  required String code,
  required PinEntryController pinController,
  required FlutterSecureStorage secureStorage,
  required AnimationController animationController,
  required int lockLevel,
  required int attemptsLeft,
  required Function lockUser,
  required StateSetter setState,
}) async {
  if (isLocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Too many incorrect attempts. Please try again later.')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });
  try {
    // Make the API call to fetch the salt
    String? uid = await secureStorage.read(key: 'uid');
    final saltResponse = await http.post(
      Uri.parse('${Config.backendUrl}/get_pin_salt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    ).timeout(Duration(seconds: 10));

    // Handle the response
    if (saltResponse.statusCode == 200) {
      final saltData = json.decode(saltResponse.body);
      String salt = saltData['pin_salt'];

      setState(() {
        isLoading = false;
      });

      // Use the salt (e.g., hash the PIN or display a success message)
      print('Salt retrieved successfully: $salt');

      String hashedPin = BCrypt.hashpw(code, salt);

      String? storedUid = await secureStorage.read(key: 'uid');
      if (storedUid == null) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${Config.backendUrl}/validate_pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': storedUid,
          'hashed_pin': hashedPin,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['pin_valid'] == true) {
          setState(() {
            isPinValid = true;
            lockLevel = 0;
            attemptsLeft = 3;
          });
          await secureStorage.delete(key: 'lock_level');
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) => WelcomeBackPageWidget(themeNotifier: themeNotifier),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                final tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                final offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        } else {
          print('Incorrect PIN');
          setState(() {
            isPinValid = false;
            attemptsLeft--;
          });
          pinController.clear();
          if (attemptsLeft <= 0) {
            lockUser();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Incorrect PIN, please try again. Attempts left: $attemptsLeft')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying PIN. Please try again later.')),
        );
      }
    } else if (saltResponse.statusCode == 404) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found or PIN salt not available.')),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      final responseData = json.decode(saltResponse.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'] ?? 'An error occurred.')),
      );
    }
  } on TimeoutException {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('The request timed out. Please try again later.')),
    );
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An unexpected error occurred: $e')),
    );
  }
}
