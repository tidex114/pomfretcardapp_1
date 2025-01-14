import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'WelcomeBackPage.dart';
import 'pin_entry_controller.dart';
import 'pin_entry_functions.dart';



class PinEntryPage extends StatefulWidget {
  const PinEntryPage({super.key});

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late PinEntryController _pinEntryController;
  late FlutterSecureStorage _secureStorage;

  // Existing animation controller
  late AnimationController _animationController;

  // Controller + animation for SHAKE
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  bool _isLocked = false;
  bool _isLoading = false;
  bool _isPinValid = false;
  bool _isWrongPin = false; // Track if the current attempt is wrong

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

    // 1) Initialize a controller for shaking the dot row
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // 2) Define a TweenSequence for a multi-phase shake: center → right → left → right → center, etc.
    //    This ensures we have a full “wiggle” effect.
    _shakeAnimation = TweenSequence<Offset>([
      // Move a little to the right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.04, 0),
        ),
        weight: 1,
      ),
      // Then move to the left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: const Offset(-0.04, 0),
        ),
        weight: 2,
      ),
      // Move slightly right again
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.04, 0),
          end: const Offset(0.02, 0),
        ),
        weight: 2,
      ),
      // Return to center
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
    onPinChanged(setState); // from pin_entry_functions.dart
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
      _remainingLockTime = const Duration(seconds: 30); // Example lock time
    });
    showLockDialog(context, _remainingLockTime);
  }

  Future<void> _verifyPin() async {
    final bool wasValid = await _callVerifyPinAndReturnResult();
    if (!wasValid) {
      // 1) Turn on red color
      if (!mounted) return;
      setState(() => _isWrongPin = true);

      // 2) Play the shake animation from the start
      _shakeController.forward(from: 0.0).then((_) async {
        // Optional small wait so the red color is visible briefly
        await Future.delayed(const Duration(milliseconds: 300));

        // 3) Reset red color and clear the PIN
        if (!mounted) return;
        setState(() => _isWrongPin = false);
        _pinEntryController.clear();
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
        if (!mounted) return; // Ensure widget is still mounted
        setState(() {
          fn();
          pinValid = _isPinValid;
          _attemptsLeft = _attemptsLeft; // in case verifyPin updated it
        });
      },
    );

    if (pinValid) {
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
    }

    return pinValid;
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
            alignment: const AlignmentDirectional(0, 0),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // The top logo
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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

                  // The PIN entry UI
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
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
                                // The container that holds the 4 PIN dots + keypad
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
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
                                      )
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
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      // "Security PIN" text
                                      Expanded(
                                        child: Align(
                                          alignment:
                                          const AlignmentDirectional(0, 0),
                                          child: Padding(
                                            padding:
                                            const EdgeInsetsDirectional
                                                .fromSTEB(30, 0, 30, 0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: const [
                                                Align(
                                                  alignment:
                                                  AlignmentDirectional(0, 0),
                                                  child: Text(
                                                    'Security PIN',
                                                    style: TextStyle(
                                                      fontFamily: 'Aeonik',
                                                      fontSize: 26,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // **** The PIN DOTS row ****
                                      // FIX: Expanded first, then SlideTransition inside it
                                      Expanded(
                                        child: SlideTransition(
                                          position: _shakeAnimation,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                            children: List.generate(4, (index) {
                                              final bool isFilled =
                                                  _pinEntryController
                                                      .enteredPin.length >
                                                      index;

                                              return AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  // If dot is filled AND we’re wrongPin => red
                                                  // If dot is filled AND not wrong => black
                                                  // If dot is not filled => grey
                                                  color: isFilled
                                                      ? (_isWrongPin
                                                      ? Colors.red
                                                      : Colors.black)
                                                      : const Color(0xFFE0E3E7),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                    const Color(0xFFE0E3E7),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ),

                                      // The Keypad
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _digitButton('1'),
                                            _digitButton('2'),
                                            _digitButton('3'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _digitButton('4'),
                                            _digitButton('5'),
                                            _digitButton('6'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _digitButton('7'),
                                            _digitButton('8'),
                                            _digitButton('9'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // Empty
                                            Expanded(
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration:
                                                const BoxDecoration(),
                                              ),
                                            ),
                                            // Zero
                                            _digitButton('0'),
                                            // Backspace
                                            Expanded(
                                              child: InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                Colors.transparent,
                                                onTap: _onDeleteTap,
                                                child: Container(
                                                  width: 100,
                                                  height: 100,
                                                  decoration:
                                                  const BoxDecoration(),
                                                  child: const Align(
                                                    alignment:
                                                    AlignmentDirectional(
                                                        0, 0),
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

                                const SizedBox(height: 20),

                                // The bottom "Logout" part
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxWidth: 280,
                                    maxHeight: 90,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0x00FFFFFF),
                                  ),
                                  child: Padding(
                                    padding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0, 0, 0, 30),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
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

  // Helper to make a digit button
  Widget _digitButton(String digit) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => _onDigitTap(digit),
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(),
          child: Align(
            alignment: const AlignmentDirectional(0, 0),
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
