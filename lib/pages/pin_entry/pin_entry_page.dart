import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pin_entry_controller.dart';
import 'pin_entry_functions.dart';

class PinEntryPage extends StatefulWidget {
  const PinEntryPage({super.key});

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late PinEntryController _pinEntryController;
  late AnimationController _animationController;
  late FlutterSecureStorage _secureStorage;
  bool _isLocked = false;
  bool _isLoading = false;
  bool _isPinValid = false;
  int _lockLevel = 0;
  int _attemptsLeft = 3;
  Duration _remainingLockTime = Duration(seconds: 0);
  String _code = '';

  @override
  void initState() {
    super.initState();
    _pinEntryController = PinEntryController(pinLength: 4);
    _pinEntryController.addListener(_onPinChanged);
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _secureStorage = FlutterSecureStorage();
  }

  @override
  void dispose() {
    _pinEntryController.removeListener(_onPinChanged);
    _pinEntryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPinChanged() {
    setState(() {
      _code = _pinEntryController.enteredPin.join();
    });
    onPinChanged(setState);
  }

  void _onDigitTap(String digit) {
    onDigitTap(digit, _pinEntryController, () async {
      await Future.delayed(Duration(milliseconds: 300));
      _verifyPin();
    });
  }

  void _onDeleteTap() {
    onDeleteTap(_pinEntryController);
  }

  void _lockUser() {
    setState(() {
      _isLocked = true;
      _remainingLockTime = Duration(seconds: 30); // Example lock time
    });
    showLockDialog(context, _remainingLockTime);
  }

  Future<void> _verifyPin() async {
    await verifyPin(
      context: context,
      isLocked: _isLocked,
      isLoading: _isLoading,
      isPinValid: _isPinValid,
      code: _code,
      pinController: _pinEntryController,
      secureStorage: _secureStorage,
      animationController: _animationController,
      lockLevel: _lockLevel,
      attemptsLeft: _attemptsLeft,
      lockUser: _lockUser,
      setState: setState,
    );
  }

  Future<void> _logout() async {
    await logout(context, _secureStorage);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(0, 0),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/pomcard_icon_light.png',
                          width: 133,
                          height: 133,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  constraints: BoxConstraints(
                                    maxWidth: 280,
                                    maxHeight: 430,
                                  ),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 4,
                                        color: Color(0x33000000),
                                        offset: Offset(
                                          0,
                                          2,
                                        ),
                                      )
                                    ],
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFECECEC), Colors.white],
                                      stops: [0, 0.05],
                                      begin: AlignmentDirectional(0, -1),
                                      end: AlignmentDirectional(0, 1),
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: AlignmentDirectional(0, 0),
                                          child: Padding(
                                            padding: EdgeInsetsDirectional.fromSTEB(30, 0, 30, 0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Align(
                                                  alignment: AlignmentDirectional(0, 0),
                                                  child: Text(
                                                    'Security PIN',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 26,
                                                      letterSpacing: 0.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: List.generate(4, (index) {
                                            return AnimatedContainer(
                                              duration: Duration(milliseconds: 150),
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: _pinEntryController.enteredPin.length > index
                                                    ? Colors.black
                                                    : Color(0xFFE0E3E7),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Color(0xFFE0E3E7)),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('1'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '1',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('2'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '2',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('3'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '3',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('4'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '4',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('5'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '5',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('6'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '6',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('7'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '7',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('8'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '8',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('9'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '9',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: () => _onDigitTap('0'),
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Text(
                                                      '0',
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 24,
                                                        letterSpacing: 0.0,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                onTap: _onDeleteTap,
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration: BoxDecoration(),
                                                  child: Align(
                                                    alignment: AlignmentDirectional(0, 0),
                                                    child: Icon(
                                                      Icons.backspace,
                                                      size: 24,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 81,
                                  constraints: BoxConstraints(
                                    maxWidth: 280,
                                    maxHeight: 81,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0x00FFFFFF),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 30),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Divider(
                                          thickness: 2,
                                          color: Color(0xFFE0E3E7),
                                        ),
                                        TextButton(
                                          onPressed: _logout,
                                          child: Text(
                                            'Logout',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Color(0xFFF62828),
                                              fontSize: 16,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}