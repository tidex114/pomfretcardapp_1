// lib/pages/pin_entry/pin_entry_functions.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'WelcomeBackPage.dart';
import 'pin_entry_controller.dart';
import 'package:pomfretcardapp/pages/login.dart';

// Assuming you have access to the themeNotifier here
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);


Future<void> logout(BuildContext context, FlutterSecureStorage secureStorage) async {
  await secureStorage.delete(key: 'session_token');
  await secureStorage.delete(key: 'session_expires_at');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
  );
}

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

  String? storedPinHash = await secureStorage.read(key: 'pin_hash');
  setState(() {
    isLoading = false;
  });

  if (storedPinHash == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error verifying PIN. Please try again later.')),
    );
    return;
  }

  bool pinValid = BCrypt.checkpw(code, storedPinHash);
  print(code);
  print(storedPinHash);

  setState(() {
    isPinValid = pinValid;
    if (isPinValid) {
      animationController.forward();
    }
  });

  if (pinValid) {
    lockLevel = 0;
    attemptsLeft = 3;
    await secureStorage.delete(key: 'lock_level');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PIN Verified!')),
    );
    await Future.delayed(Duration(milliseconds: 300));
    await Future.delayed(Duration(milliseconds: 1500));
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        // Increase this Duration to slow down the slide-in
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => WelcomeBackPageWidget(themeNotifier: themeNotifier,),
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
    attemptsLeft--;
    pinController.clear();
    if (attemptsLeft <= 0) {
      lockUser();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect PIN, please try again. Attempts left: $attemptsLeft')),
      );
    }
  }
}