// top_profile_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import 'package:pomfretcardapp/pages/login.dart';

class TopProfileSection extends StatelessWidget {
  final String? firstName;
  final String? lastName;
  final String? graduationYear;
  final String? email;
  final Uint8List? profileImage;

  TopProfileSection({this.firstName, this.lastName, this.graduationYear, this.email, this.profileImage});

  @override
  Widget build(BuildContext context) {
    final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.redAccent,
            backgroundImage: profileImage != null ? MemoryImage(profileImage!) : null,
            child: profileImage == null
                ? Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
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
                      color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  email ?? 'No email available',
                  style: TextStyle(
                      fontSize: 16, fontFamily: 'Aeonik', color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await _secureStorage.deleteAll();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            icon: Icon(Icons.logout, color: Colors.redAccent, size: 28),
          ),
        ],
      ),
    );
  }
}