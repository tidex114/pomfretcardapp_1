// top_profile_section.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomfretcardapp/pages/login.dart';
import 'package:pomfretcardapp/services/logout.dart';

class TopProfileSection extends StatelessWidget {
  final String? firstName;
  final String? lastName;
  final String? graduationYear;
  final String? email;
  final Uint8List? profileImage;

  TopProfileSection({
    this.firstName,
    this.lastName,
    this.graduationYear,
    this.email,
    this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: profileImage != null ? MemoryImage(profileImage!) : null,
            child: profileImage == null
                ? Icon(
              Icons.person,
              size: 40,
              color: theme.colorScheme.onPrimary,
            )
                : null,
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${firstName ?? "First Name"} ${lastName ?? "Last Name"} ${graduationYear ?? "YY"}'",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Aeonik',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  email ?? 'No email available',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Aeonik',
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await performLogout(context, _secureStorage);
            },
            icon: Icon(Icons.logout, color: theme.colorScheme.primary, size: 28),
          ),
        ],
      ),
    );
  }
}
