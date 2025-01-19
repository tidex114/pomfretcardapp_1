import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:pomfretcardapp/pages/config.dart';
import 'package:pomfretcardapp/pages/login.dart';
import 'logout.dart'; // Import the logout.dart file

class AuthService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> refreshAccessToken(Function callback, BuildContext context) async {
    try {
      print('Refreshing access token...');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('Error: Refresh token not found');
        return;
      }

      final response = await http.post(
        Uri.parse('${Config.backendUrl}/refresh_access_token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newAccessToken = responseData['access_token'];
        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        print('Access token refreshed successfully');
        // Call the callback function after refreshing the token
        callback();
      } else {
        final responseData = json.decode(response.body);
        if (responseData['error'] == "Invalid or expired refresh token" || responseData['error'] == "Refresh token has expired"
        ) {
          // Call the logout function
          await performLogout(context, _secureStorage);

          // Show dialog window
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'Session Expired',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Aeonik',
                  ),
                ),
                content: Text(
                  'Your session has expired. Please log in again.',
                  style: TextStyle(
                    fontFamily: 'Aeonik',
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Understood'),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                ],
              );
            },
          );
        } else {
          print('Error: Failed to refresh access token with status code ${response.statusCode}');
          print('Response: ${response.body}');
        }
      }
    } catch (e) {
      print('Error during access token refresh: $e');
    }
  }
}