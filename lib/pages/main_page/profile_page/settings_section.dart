// settings_section.dart
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  SettingsSection({required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? theme.shadowColor.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5),
            offset: Offset(0, 5),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Aeonik',
            ),
          ),
          SizedBox(height: 10),
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Aeonik',
                color: theme.colorScheme.onSurface,
              ),
            ),
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (value) {
              themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ],
      ),
    );
  }
}