import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomfretcardapp/pages/config.dart';
import 'dart:async';

class ReportBugForm extends StatefulWidget {
  @override
  _ReportBugFormState createState() => _ReportBugFormState();
}

class _ReportBugFormState extends State<ReportBugForm> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final int _subjectLimit = 30;
  final int _descriptionLimit = 1000;
  bool _isSending = false; // Tracks the sending state of the form
  final _secureStorage = FlutterSecureStorage();
  String? _gmail;
  String? _errorMessage;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    _loadGmailFromSecureStorage();
  }

  Future<void> _loadGmailFromSecureStorage() async {
    try {
      String? gmail = await _secureStorage.read(key: 'user_email');
      if (gmail == null) {
        _showErrorMessage('Failed to load Gmail from secure storage');
      } else {
        setState(() {
          _gmail = gmail;
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to load Gmail from secure storage');
    }
  }

  Future<void> _sendBugReport() async {
    if (_subjectController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showErrorMessage('Subject and description cannot be empty');
      return;
    }

    if (_gmail == null) {
      _showErrorMessage('Email is required to send the report');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.backendUrl}/send_report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gmail': _gmail,
          'subject': _subjectController.text,
          'description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessMessage('Report sent successfully');
        Navigator.of(context).pop();
      } else {
        _showErrorMessage('Failed to send the report. Please try again later.');
      }
    } catch (error) {
      _showErrorMessage('An error occurred. Please try again later.');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _showMessage = true;
    });
    _hideMessageAfterDelay();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _hideMessageAfterDelay() {
    Timer(Duration(seconds: 5), () {
      setState(() {
        _showMessage = false;
      });
    });
  }

  bool _isFormValid() {
    return _subjectController.text.isNotEmpty && _descriptionController.text.isNotEmpty && _gmail != null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required int characterLimit,
    required Color balanceFieldColor,
    required Color textColor,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: balanceFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        counterText: '${controller.text.length} / $characterLimit',
        labelStyle: TextStyle(
          fontFamily: 'Aeonik',
          fontSize: 16,
          color: textColor,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Aeonik',
          color: textColor.withOpacity(0.7),
        ),
        counterStyle: TextStyle(
          fontFamily: 'Aeonik',
          fontSize: 12,
          color: textColor.withOpacity(0.7),
        ),
      ),
      style: TextStyle(
        fontFamily: 'Aeonik',
        color: textColor,
        fontSize: 16,
      ),
      maxLength: characterLimit,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceFieldColor = theme.brightness == Brightness.dark
        ? Color(0xFF424242)
        : Colors.grey[200] ?? Colors.grey; // Provide a default color
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final buttonInactiveColor = theme.brightness == Brightness.dark
        ? Colors.grey[850]
        : Colors.grey[300]; // Custom inactive color for light theme
    final buttonInactiveTextColor = theme.brightness == Brightness.dark
        ? Colors.grey
        : Colors.grey[700]; // Custom inactive text color for dark theme

    return Stack(
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: cardColor,
          title: Row(
            children: [
              Icon(Icons.bug_report, color: theme.colorScheme.primary, size: 28),
              SizedBox(width: 10),
              Text(
                'Report a Bug',
                style: TextStyle(
                  fontFamily: 'Aeonik',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 300,
              maxWidth: 600,
              minHeight: 200,
              maxHeight: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _subjectController,
                  labelText: 'Subject',
                  hintText: 'Enter the subject',
                  characterLimit: _subjectLimit,
                  balanceFieldColor: balanceFieldColor,
                  textColor: textColor,
                ),
                SizedBox(height: 10),
                _buildTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Enter the bug description',
                  characterLimit: _descriptionLimit,
                  balanceFieldColor: balanceFieldColor,
                  textColor: textColor,
                  maxLines: 10,
                  minLines: 5,
                ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Aeonik',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ElevatedButton(
                onPressed: _isFormValid() && !_isSending ? _sendBugReport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor: buttonInactiveColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                    color: buttonInactiveTextColor,
                  ),
                ),
                child: _isSending
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Send',
                  style: TextStyle(
                    fontFamily: 'Aeonik',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          bottom: _showMessage ? 0 : -100,
          left: 0,
          right: 0,
          child: _errorMessage != null
              ? Container(
            padding: EdgeInsets.all(10),
            color: Colors.red,
            width: MediaQuery.of(context).size.width,
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          )
              : Container(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}