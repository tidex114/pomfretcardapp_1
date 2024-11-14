// profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomfretcardapp/pages/login.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? graduationYear;
  final String? email;

  ProfilePage({this.firstName, this.lastName, this.graduationYear, this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  Uint8List? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final base64Png = await _secureStorage.read(key: 'profile_image');
    Uint8List? profileImage;
    if (base64Png != null) {
      profileImage = base64Decode(base64Png);
    }
    setState(() {
      _profileImage = profileImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0),
      child: Column(
        children: [
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
                  color: Colors.black,
                  fontSize: 50,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Aeonik',
                  fontWeight: FontWeight.w700,
                  height: 0,
                  letterSpacing: 1.38,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTopProfileSection(context),
          SizedBox(height: 20),
          _buildCardBalanceSection(),
          SizedBox(height: 20),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildTopProfileSection(BuildContext context) {
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
            backgroundImage: _profileImage != null ? MemoryImage(_profileImage!) : null,
            child: _profileImage == null
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
                  "${widget.firstName ?? "First Name"} ${widget.lastName ?? "Last Name"} ${widget.graduationYear ?? "YY"}'",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Aeonik',
                      color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  widget.email ?? 'No email available',
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

  Widget _buildCardBalanceSection() {
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
      child: GestureDetector(
        onTap: () {
          // Handle balance visibility toggle if necessary
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  fontFamily: 'Aeonik'),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Color(0xFFE6E7EB),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$ • • •',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontFamily: 'Aeonik'),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: Colors.redAccent,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
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
