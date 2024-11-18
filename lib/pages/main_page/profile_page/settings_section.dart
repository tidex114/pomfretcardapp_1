// settings_section.dart
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.settings, color: Colors.redAccent),
            title: Text(
              'Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'Aeonik'),
            ),
            onTap: () {
              // Navigate to settings screen
            },
          ),
          ListTile(
            leading: Icon(Icons.lock_reset, color: Colors.redAccent),
            title: Text(
              'Reset Password',
              style: TextStyle(
                  fontSize: 18, color: Colors.black, fontFamily: 'Aeonik'),
            ),
            onTap: () {
              // Navigate to reset password screen
            },
          ),
        ],
      ),
    );
  }
}
