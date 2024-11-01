import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pin_code_fields/flutter_pin_code_fields.dart';
import 'login.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animations/animations.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pomfretcardapp/pages/config.dart';

class PinEntryPage extends StatefulWidget {
  @override
  _PinEntryPageState createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isLoading = false;
  String _code = '';
  bool _isPinValid = false;
  late AnimationController _animationController;
  int _attemptsLeft = 3;
  Duration _lockDuration = Duration.zero;
  Timer? _realTimeTimer;
  Duration _remainingLockTime = Duration.zero;
  bool _lockDialogShown = false;
  int _lockLevel = 0;
  bool _isLocked = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _initializeLockState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _realTimeTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLockState() async {
    String? lockDurationStr = await _secureStorage.read(key: 'lock_duration');
    String? lockTimeStr = await _secureStorage.read(key: 'lock_time');
    String? lockLevelStr = await _secureStorage.read(key: 'lock_level');

    if (lockLevelStr != null) {
      _lockLevel = int.parse(lockLevelStr);
      _attemptsLeft = 1;
    } else {
      _attemptsLeft = 3;
    }

    if (lockDurationStr != null && lockTimeStr != null) {
      Duration storedDuration = Duration(seconds: int.parse(lockDurationStr));
      DateTime lockTime = DateTime.parse(lockTimeStr);
      DateTime unlockTime = lockTime.add(storedDuration);

      if (DateTime.now().isBefore(unlockTime)) {
        setState(() {
          _isLocked = true;
          _remainingLockTime = unlockTime.difference(DateTime.now());
        });

        _startRealTimeTimer();
        _showLockDialog();
      } else {
        _isLocked = false;
        await _secureStorage.delete(key: 'lock_duration');
        await _secureStorage.delete(key: 'lock_time');
        _attemptsLeft = _lockLevel == 0 ? 3 : 1;
        _showWarningDialogWithTimer();
      }
    }
  }

  void _startRealTimeTimer() {
    _realTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingLockTime = _remainingLockTime - Duration(seconds: 1);
        if (_remainingLockTime <= Duration.zero) {
          _isLocked = false;
          _realTimeTimer?.cancel();
          _secureStorage.delete(key: 'lock_duration');
          _secureStorage.delete(key: 'lock_time');
          _attemptsLeft = _lockLevel == 0 ? 3 : 1;
          _showWarningDialogWithTimer();
        }
      });
    });
  }

  Future<void> _verifyPin() async {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Too many incorrect attempts. Please try again later.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? storedPinHash = await _secureStorage.read(key: 'pin_hash');
    setState(() {
      _isLoading = false;
    });

    if (storedPinHash == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying PIN. Please try again later.')),
      );
      return;
    }

    bool isPinValid = BCrypt.checkpw(_code, storedPinHash);

    setState(() {
      _isPinValid = isPinValid;
      if (_isPinValid) {
        _animationController.forward();
      }
    });

    if (isPinValid) {
      _lockLevel = 0;
      _attemptsLeft = 3;
      await _secureStorage.delete(key: 'lock_level');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN Verified!')),
      );
      await Future.delayed(Duration(milliseconds: 300));
      await Future.delayed(Duration(milliseconds: 1500));
      Navigator.pushReplacementNamed(context, '/mainPage');
    } else {
      _attemptsLeft--;
      _pinController.clear();
      if (_attemptsLeft <= 0) {
        _lockUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect PIN, please try again. Attempts left: $_attemptsLeft')),
        );
      }
    }
  }

  void _lockUser() async {
    if (_lockLevel == 0) {
      _lockDuration = Duration(seconds: 10);
      _lockLevel++;
    } else if (_lockLevel == 1) {
      _lockDuration = Duration(seconds: 10);
      _lockLevel++;
    } else if (_lockLevel == 2) {
      _lockDuration = Duration(seconds: 10);
      _lockLevel++;
    } else {
      _lockDuration = Duration(seconds: 10);
      await _notifyAccountFrozenBackend();
      _lockLevel++;
    }

    setState(() {
      _isLocked = true;
      _remainingLockTime = _lockDuration;
    });

    await _secureStorage.write(key: 'lock_duration', value: _lockDuration.inSeconds.toString());
    await _secureStorage.write(key: 'lock_time', value: DateTime.now().toIso8601String());
    await _secureStorage.write(key: 'lock_level', value: _lockLevel.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Too many incorrect attempts. Try again in ${_lockDuration.inSeconds} seconds.')),
    );

    _startRealTimeTimer();
    _showLockDialog();
  }

  Future<void> _notifyAccountFrozenBackend() async {
    String? userEmail = await _secureStorage.read(key: 'user_email');
    if (userEmail != null) {
      try {
        final response = await http.post(
          Uri.parse('${Config.backendUrl}/account_freeze'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': userEmail}),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Your account has been frozen. Please contact IT support.')),
          );
          _logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error freezing account. Please try again later.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error freezing account. Please try again later.')),
        );
      }
    }
  }

  void _showLockDialog() {
    if (_lockDialogShown) return;
    _lockDialogShown = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Account Locked', style: TextStyle(fontFamily: 'Aeonik')),
        content: Text(
          'Too many incorrect attempts. The app is locked for ${_remainingLockTime.inSeconds} seconds.',
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
    ).then((_) {
      _lockDialogShown = false;
    });
  }

  void _showWarningDialogWithTimer() {
    IconData consequenceIcon;
    String consequenceText;

    if (_lockLevel == 1) {
      consequenceIcon = Icons.timer;
      consequenceText = 'locked for 10 seconds';
    } else if (_lockLevel == 2) {
      consequenceIcon = Icons.lock_clock;
      consequenceText = 'locked for 10 seconds';
    } else if (_lockLevel >= 3) {
      consequenceIcon = Icons.lock_outline;
      consequenceText = 'frozen indefinitely';
    } else {
      consequenceIcon = Icons.warning;
      consequenceText = 'locked for 10 seconds';
    }

    int countdown = 5;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, StateSetter dialogSetState) {
          _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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

          return AlertDialog(
            title: Row(
              children: [
                Icon(consequenceIcon, color: Colors.red),
                SizedBox(width: 8),
                Text('Warning', style: TextStyle(fontFamily: 'Aeonik')),
              ],
            ),
            content: Text(
              'You have only one attempt to unlock the app. If you fail, the account will be $consequenceText.',
              style: TextStyle(fontFamily: 'Aeonik'),
            ),
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
          );
        },
      ),
    );
  }

  void _logout() async {
    await _secureStorage.delete(key: 'session_token');
    await _secureStorage.delete(key: 'session_expires_at');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
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
                  Text(
                    'card',
                    style: TextStyle(
                      color: Colors.black,
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
              SizedBox(height: 30),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0.0, 0.0),
                        end: Offset(-1.0, 0.0),
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Icon(
                        Icons.lock,
                        key: ValueKey<bool>(false),
                        color: Colors.grey,
                        size: 100,
                      ),
                    ),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(1.5, 0.0),
                        end: Offset(0.0, 0.0),
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_open,
                        key: ValueKey<bool>(true),
                        color: Colors.green,
                        size: 100,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              LayoutBuilder(
                builder: (context, constraints) {
                  double availableWidth = constraints.maxWidth - 7.5;
                  double fieldSize = (availableWidth - 3 * 8) / 4 - 7.5;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: fieldSize,
                        child: PinCodeFields(
                          controller: _pinController,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          length: 4,
                          fieldBorderStyle: FieldBorderStyle.square,
                          responsive: false,
                          fieldHeight: fieldSize,
                          fieldWidth: fieldSize,
                          margin: EdgeInsets.all(2.0),
                          borderWidth: 0,
                          activeBorderColor: Colors.redAccent,
                          activeBackgroundColor: Color(0xFFE1DAE2),
                          borderRadius: BorderRadius.circular(20.0),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          obscureCharacter: "●",
                          textStyle: TextStyle(fontSize: 30),
                          fieldBackgroundColor: _isLocked ? Colors.grey : Color(0xFFF6F1F6),
                          enabled: !_isLocked,
                          onComplete: (output) async {
                            setState(() {
                              _code = output;
                            });
                            await Future.delayed(Duration(milliseconds: 300));
                            _verifyPin();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 40),
              if (_isLocked)
                Center(
                  child: Text(
                    'Locked. Try again in ${_remainingLockTime.inMinutes}:${(_remainingLockTime.inSeconds % 60).toString().padLeft(2, '0')} minutes',
                    style: TextStyle(fontSize: 18, color: Colors.redAccent, fontFamily: 'Aeonik'),
                  ),
                ),
              SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(color: Colors.grey, thickness: 1.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('or', style: TextStyle(color: Colors.grey, fontFamily: 'Aeonik')),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey, thickness: 1.0),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Center(
                child: TextButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 18, fontFamily: 'Aeonik', fontWeight: FontWeight.bold, color: Color(0xFFFF5252)),
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
