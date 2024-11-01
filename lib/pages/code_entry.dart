import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'create_pin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pin_code_fields/flutter_pin_code_fields.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animations/animations.dart';
import 'package:pomfretcardapp/pages/config.dart';

class CodeEntryPage extends StatefulWidget {
  final String email;
  final String password;

  CodeEntryPage({required this.email, required this.password});

  @override
  _CodeEntryPageState createState() => _CodeEntryPageState();
}

class _CodeEntryPageState extends State<CodeEntryPage> with SingleTickerProviderStateMixin {
  bool _isSubmitButtonActive = false;
  String _code = '';
  bool _isResendButtonActive = false;
  int _timerSeconds = 60;
  Timer? _timer;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isResendButtonActive = false;
      _timerSeconds = 60;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _isResendButtonActive = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResendButtonActive = false;
    });
    _startTimer();
    final url = '${Config.backendUrl}/resend_code';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Verification code resent successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        final message = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $message'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _submitCode() async {
    final code = _code;
    final url = '${Config.backendUrl}/verify_code';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': widget.email,
          'code': code,
          'password': widget.password,
        }),
      );

      if (response.statusCode == 200) {
        final message = jsonDecode(response.body)['message'];
        if (message == "Code verified successfully. User authorized.") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => (CreatePinPage(email: widget.email, password: widget.password))),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotAllowedPage()),
          );
        }
      } else {
        final message = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $message'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      fontFamily: 'Aeonik',
                      color: Colors.black,
                      fontSize: 50,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      height: 0,
                      letterSpacing: 1.38,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Enter Verification Code',
                      style: TextStyle(
                        fontFamily: 'Aeonik',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Please enter the 6-digit code sent to your email.",
                      style: TextStyle(
                        fontFamily: 'Aeonik',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double availableWidth = constraints.maxWidth;
                        double fieldSize = (availableWidth - 3 * 8) / 4 - 32;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: fieldSize,
                              child: PinCodeFields(
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                length: 6,
                                fieldBorderStyle: FieldBorderStyle.square,
                                responsive: false,
                                fieldHeight: fieldSize + 15,
                                fieldWidth: fieldSize,
                                margin: EdgeInsets.all(1.0),
                                borderWidth: 0,
                                activeBorderColor: Colors.redAccent,
                                activeBackgroundColor: Color(0xFFE1DAE2),
                                borderRadius: BorderRadius.circular(15.0),
                                keyboardType: TextInputType.number,
                                obscureText: false,
                                textStyle: TextStyle(
                                  fontFamily: 'Aeonik',
                                  fontSize: 30,
                                ),
                                fieldBackgroundColor: Color(0xFFF6F1F6),
                                onComplete: (output) {
                                  setState(() {
                                    _code = output;
                                    _isSubmitButtonActive = output.length == 6;
                                  });
                                },
                                onChange: (output) {
                                  setState(() {
                                    _isSubmitButtonActive = output.length == 6;
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height:35),
                    _isResendButtonActive
                        ? TextButton(
                      onPressed: _resendCode,
                      child: Text(
                        'Resend Code',
                        style: TextStyle(
                          fontFamily: 'Aeonik',
                          color: Colors.redAccent,
                        ),
                      ),
                    )
                        : Text(
                      'Resend code in $_timerSeconds seconds',
                      style: TextStyle(
                        fontFamily: 'Aeonik',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              _isSubmitButtonActive
                  ? ElevatedButton(
                onPressed: _submitCode,
                child: Text(
                  'Submit Code',
                  style: TextStyle(fontFamily: 'Aeonik'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              )
                  : ElevatedButton(
                onPressed: null,
                child: Text(
                  'Submit Code',
                  style: TextStyle(fontFamily: 'Aeonik'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class NotAllowedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Not Allowed'),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'You cannot create an account with this email. Please, contact IT office.',
            style: TextStyle(
              fontFamily: 'Aeonik',
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
