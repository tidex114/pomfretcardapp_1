import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomfretcardapp/pages/main_page/profile_page/top_profile_section.dart';
import 'package:pomfretcardapp/pages/main_page/profile_page/card_balance_section.dart';
import 'package:pomfretcardapp/pages/main_page/profile_page/settings_section.dart';
import 'package:pomfretcardapp/services/shared_functions.dart';

class ProfilePage extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? graduationYear;
  final String? email;

  ProfilePage({this.firstName, this.lastName, this.graduationYear, this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin<ProfilePage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  Uint8List? _profileImage;
  String _balanceData = '\$ • • •';
  final SharedFunctions _sharedFunctions = SharedFunctions();

  @override
  bool get wantKeepAlive => true;

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

  Future<void> _loadBalanceData() async {
    await _sharedFunctions.loadBalanceData((balance) {
      setState(() {
        _balanceData = balance;
      });
    });
  }

  Future<void> _refreshProfilePage() async {
    await _loadProfileImage();
    await _loadBalanceData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refreshProfilePage,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0),
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            TopProfileSection(
              firstName: widget.firstName,
              lastName: widget.lastName,
              graduationYear: widget.graduationYear,
              email: widget.email,
              profileImage: _profileImage,
            ),
            SizedBox(height: 20),
            CardBalanceSection(),
            SizedBox(height: 20),
            SettingsSection(),
          ],
        ),
      ),
    );
  }
}
