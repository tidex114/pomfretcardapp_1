import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'WelcomeBackPage.dart';
import 'pin_entry_controller.dart';
import 'pin_entry_functions.dart';
import 'package:pomfretcardapp/services/logout.dart';

class PinEntryPage extends StatefulWidget {
  const PinEntryPage({super.key});

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late PinEntryController _pinEntryController;
  late FlutterSecureStorage _secureStorage;

  late AnimationController _animationController;
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  bool _isLocked = false;
  bool _isLoading = false;
  bool _isPinValid = false;
  bool _isWrongPin = false;

  int _lockLevel = 0;
  int _attemptsLeft = 3;
  Duration _remainingLockTime = const Duration(seconds: 0);
  String _code = '';

  @override
  void initState() {
    super.initState();

    _secureStorage = const FlutterSecureStorage();

    _pinEntryController = PinEntryController(pinLength: 4);
    _pinEntryController.addListener(_onPinChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.04, 0),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: const Offset(-0.04, 0),
        ),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.04, 0),
          end: const Offset(0.02, 0),
        ),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ),
        weight: 1,
      ),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _pinEntryController.removeListener(_onPinChanged);
    _pinEntryController.dispose();
    _animationController.dispose();
    _shakeController.dispose();
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
      await Future.delayed(const Duration(milliseconds: 100));
      _verifyPin();
    });
  }

  void _onDeleteTap() {
    onDeleteTap(_pinEntryController);
  }

  void _lockUser() {
    setState(() {
      _isLocked = true;
      _remainingLockTime = const Duration(seconds: 30);
    });
    showLockDialog(context, _remainingLockTime);
  }

  Future<void> _verifyPin() async {
    final bool wasValid = await _callVerifyPinAndReturnResult();

    if (wasValid) {
      if (!mounted) return;

      setState(() {
        _isWrongPin = false;
        _isPinValid = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              WelcomeBackPageWidget(themeNotifier: themeNotifier),
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
      if (!mounted) return;

      setState(() {
        _isWrongPin = true;
      });

      _shakeController.forward(from: 0.0).then((_) async {
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;
        setState(() {
          _isWrongPin = false;
          _pinEntryController.clear();
        });
      });
    }
  }

  Future<bool> _callVerifyPinAndReturnResult() async {
    bool pinValid = false;
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
      setState: (fn) {
        if (!mounted) return;
        setState(() {
          fn();
          pinValid = _isPinValid;
          _attemptsLeft = _attemptsLeft;
        });
      },
    );

    if (pinValid) {
      if (!mounted) return false;
      setState(() => _isWrongPin = false);
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              WelcomeBackPageWidget(themeNotifier: themeNotifier),
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
    }

    return pinValid;
  }

  Future<void> _logout() async {
    await performLogout(context, _secureStorage);
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
            alignment: AlignmentDirectional.center,
            child: Padding(
              padding: const EdgeInsets.all(10),
              // This Column centers everything vertically.
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1) The logo at the top (OUTSIDE the PIN container)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/pomcard_icon_light.png',
                      width: 133,
                      height: 133,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2) The main container with pin indicators & keypad
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 280,
                      maxHeight: 430,
                    ),
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          color: Color(0x33000000),
                          offset: Offset(0, 2),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECECEC), Colors.white],
                        stops: [0, 0.05],
                        begin: AlignmentDirectional(0, -1),
                        end: AlignmentDirectional(0, 1),
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                        // "Security PIN" label
                        const SizedBox(height: 30),
                        const Text(
                          'Security PIN',
                          style: TextStyle(
                            fontFamily: 'Aeonik',
                            fontSize: 26,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // The 4 PIN indicator dots (with shake animation if wrong PIN)
                        SlideTransition(
                          position: _isWrongPin ? _shakeAnimation : AlwaysStoppedAnimation(Offset.zero),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              final bool isFilled = _pinEntryController.enteredPin.length > index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isFilled
                                      ? (_isWrongPin
                                      ? Colors.red
                                      : (_isPinValid ? Colors.green : Colors.black))
                                      : const Color(0xFFE0E3E7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE0E3E7),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const Spacer(),
                        // Keypad rows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _digitButton('1'),
                            _digitButton('2'),
                            _digitButton('3'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _digitButton('4'),
                            _digitButton('5'),
                            _digitButton('6'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _digitButton('7'),
                            _digitButton('8'),
                            _digitButton('9'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Container(
                                height: 60,
                                color: Colors.transparent,
                              ),
                            ),
                            _digitButton('0'),
                            Expanded(
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: _onDeleteTap,
                                child: SizedBox(
                                  height: 60,
                                  child: const Icon(
                                    Icons.backspace,
                                    size: 24,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),

                  // 3) Logout button at the bottom
                  const SizedBox(height: 30),
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 280,
                      maxHeight: 90,
                    ),
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Divider(
                          thickness: 2,
                          color: Color(0xFFE0E3E7),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _logout,
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontFamily: 'Aeonik',
                              color: Color(0xFFF62828),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _digitButton(String digit) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => _onDigitTap(digit),
        child: SizedBox(
          height: 60,
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontFamily: 'Aeonik',
                fontSize: 24,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
