// settings_section.dart
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontFamily: 'Aeonik',
              ),
            ),
          ),
          SizedBox(height: 4),
          ListTile(
            leading: Icon(Icons.lock_reset, color: Colors.redAccent),
            title: Text(
              'Reset Password',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontFamily: 'Aeonik',
              ),
            ),
            onTap: () {
              // Navigate to reset password screen
            },
          ),
          ListTile(
            leading: Icon(Icons.brightness_6, color: Colors.redAccent),
            title: Text(
              'Toggle Theme',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontFamily: 'Aeonik',
              ),
            ),
            trailing: Switch(
              value: true,
              onChanged: null,
            ),
          ),
        ],
      ),
    );
  }
}
