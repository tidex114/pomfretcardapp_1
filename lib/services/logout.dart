import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:pomfretcardapp/pages/config.dart';
import 'package:pomfretcardapp/pages/login.dart'; // Import your LoginPage

Future<bool> performLogout(BuildContext context, FlutterSecureStorage secureStorage) async {
  try {
    // Read UID from secure storage
    String? uid = await secureStorage.read(key: 'uid');

    if (uid == null) {
      print('UID not found. Please log in again.');
      return false; // Indicate failure
    }

    // Call the logout route
    final response = await http.post(
      Uri.parse('${Config.backendUrl}/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      // Clear all secure storage data
      await secureStorage.deleteAll();
      print('Successfully logged out.');

      // Redirect to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );

      return true; // Indicate success
    } else {
      final responseData = jsonDecode(response.body);
      print('Logout failed: ${responseData['message']}');
      return false; // Indicate failure
    }
  } on TimeoutException {
    print('The logout request timed out.');
    return false; // Indicate failure
  } catch (e) {
    print('An error occurred during logout: $e');
    return false; // Indicate failure
  }
}
