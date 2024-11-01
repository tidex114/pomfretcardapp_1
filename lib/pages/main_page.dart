import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:pomfretcardapp/pages/login.dart';
import 'package:pomfretcardapp/pages/config.dart';
import 'package:pomfretcardapp/services/decrypt_with_private_key.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final List<String> _greetings = [
    "Mr. Rodman's typing...",
    "Tucktime!",
    "Blink if you want a double choc muffin",
    "You're not in the tuck... Are you?",
    "Coffee break!",
    "Free block?"
  ];
  String? _selectedGreeting;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String? _firstName;
  String? _lastName;
  String? _graduationYear;
  String? _barcodeData;
  String? _email;
  double? _balance = 123.45;
  bool _isBalanceVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedGreeting = _greetings[DateTime.now().millisecondsSinceEpoch % _greetings.length];
    _loadUserInfo();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  Future<void> _loadUserInfo() async {
    String? firstName = await _secureStorage.read(key: 'first_name');
    String? lastName = await _secureStorage.read(key: 'last_name');
    String? graduationYear = await _secureStorage.read(key: 'graduation_year');
    String? email = await _secureStorage.read(key: 'user_email');

    setState(() {
      _firstName = firstName;
      _lastName = lastName;
      _graduationYear = graduationYear?.substring(graduationYear.length - 2);
      _email = email;
    });

    await _loadBarcodeData();
  }

  Future<void> _loadBarcodeData() async {
    try {
      final secureStorage = FlutterSecureStorage();
      final userEmail = await secureStorage.read(key: 'user_email');
      if (userEmail != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_barcode'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': userEmail, 'public_key': await secureStorage.read(key: 'public_key')}),
        );
        if (response.statusCode == 200) {
          final encryptedJsonBase64 = json.decode(response.body)['encrypted_json'];
          final decryptedJsonMap = await decryptJsonData(encryptedJsonBase64);

          if (decryptedJsonMap['email'] == userEmail) {
            setState(() {
              _barcodeData = decryptedJsonMap['barcode'];
            });
          } else {
            setState(() {
              _barcodeData = "Email mismatch";
            });
          }
        } else {
          setState(() {
            _barcodeData = "Unknown";
          });
        }
      } else {
        setState(() {
          _barcodeData = "Unknown";
        });
      }
    } catch (e) {
      print('Error during barcode retrieval: $e');
      setState(() {
        _barcodeData = "Unknown";
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _animationController.forward(from: 0);
    });
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(index,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _reloadPage() async {
    await _loadUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _reloadPage,
            child: _buildCardSection(),
          ),
          RefreshIndicator(
            onRefresh: _reloadPage,
            child: _buildTransactionsSection(),
          ),
          RefreshIndicator(
            onRefresh: _reloadPage,
            child: _buildProfilePage(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: _onBottomNavTapped,
            selectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red, fontFamily: 'Aeonik'),
            unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Aeonik'),
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    'assets/images/id-card-vertical.svg',
                    width: 28,
                    height: 28,
                    color: _currentIndex == 0 ? Colors.red : Colors.black,
                  ),
                  label: 'Card'
              ),
              BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    'assets/images/history.svg',
                    width: 28,
                    height: 28,
                    color: _currentIndex == 1 ? Colors.red : Colors.black,
                  ),
                  label: 'Transactions'
              ),
              BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    'assets/images/profile-user-account.svg',
                    width: 28,
                    height: 28,
                    color: _currentIndex == 2 ? Colors.red : Colors.black,
                  ),
                  label: 'Profile'
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
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
          _buildTopProfileSection(),
          SizedBox(height: 20),
          _buildCardBalanceSection(),
          SizedBox(height: 20),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildTopProfileSection() {
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
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_firstName ?? "First Name"} ${_lastName ?? "Last Name"} ${_graduationYear ?? "YY"}'",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Aeonik', color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  _email ?? 'No email available',
                  style: TextStyle(fontSize: 16, fontFamily: 'Aeonik', color: Colors.black54),
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
          setState(() {
            _isBalanceVisible = !_isBalanceVisible;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.black, fontFamily: 'Aeonik'),
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
                    _isBalanceVisible ? '\$${_balance?.toStringAsFixed(2) ?? '0.00'}' : '\$ • • •',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _isBalanceVisible ? Colors.black : Colors.grey, fontFamily: 'Aeonik'),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Aeonik'),
            ),
            onTap: () {
              // Navigate to settings screen
            },
          ),
          ListTile(
            leading: Icon(Icons.lock_reset, color: Colors.redAccent),
            title: Text(
              'Reset Password',
              style: TextStyle(fontSize: 18, color: Colors.black, fontFamily: 'Aeonik'),
            ),
            onTap: () {
              // Navigate to reset password screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/pomcard_icon.svg',
                height: 60,
              ),
              SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pom',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 50,
                        fontFamily: 'Aeonik',
                        fontWeight: FontWeight.w700,
                        height: 0,
                        letterSpacing: 1.38,
                      ),
                    ),
                    TextSpan(
                      text: 'card',
                      style: TextStyle(
                        color: Color(0xFFED4747),
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
              )
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Text(
            _selectedGreeting ?? '',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.027,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Aeonik',
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Container(
            height: 500,
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 5,
                  blurRadius: 15,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: MediaQuery.of(context).size.height * 0.00001),
                      Text(
                        'POMFRET',
                        style: GoogleFonts.notoSerif(
                            fontSize: MediaQuery.of(context).size.height * 0.059,
                            fontWeight: FontWeight.normal,
                            letterSpacing: MediaQuery.of(context).size.width * 0.001,
                            color: Colors.black),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.00001),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.008,
                        width: MediaQuery.of(context).size.width * 0.6,
                        color: Colors.red,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.2,
                        width: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/profile_picture.png'), // Placeholder for profile image
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      Text(
                        "${_firstName ?? "First Name"} ${_lastName ?? "Last Name"}",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Roboto', color: Colors.black),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.003),
                      Text(
                        'Student',
                        style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.023, fontFamily: 'OpenSans', color: Colors.black87),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                      if (_barcodeData != null)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierColor: Colors.black.withOpacity(0.5),
                              builder: (BuildContext context) {
                                return Stack(
                                  children: [
                                    BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ),
                                    Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          child: BarcodeWidget(
                                            barcode: Barcode.code39(), // Choose the barcode type here
                                            data: _barcodeData!,
                                            width: MediaQuery.of(context).size.width * 0.6,
                                            height: MediaQuery.of(context).size.height * 0.15,
                                            drawText: false, // Don't draw the barcode value
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: Icon(Icons.close, size: 24, color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(10),
                            child: BarcodeWidget(
                              barcode: Barcode.code39(), // Choose the barcode type here
                              data: _barcodeData!,
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.height * 0.05,
                              drawText: false, // Don't draw the barcode value
                              color: Colors.black,
                            ),
                          ),
                        )
                      else
                        Text('Generating Barcode...', style: TextStyle(fontFamily: 'Aeonik')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return RefreshIndicator(
      onRefresh: _reloadPage,
      child: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    height: 1.0,
                    letterSpacing: 1.38,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.0),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent transactions:',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Aeonik',
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: 10, // Replace with actual transaction count
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                margin: EdgeInsets.symmetric(vertical: 4.0),
                child: ExpansionTile(
                  key: PageStorageKey<int>(index),
                  onExpansionChanged: (bool expanded) {
                    if (expanded) {
                      for (int i = 0; i < 10; i++) {
                        if (i != index) {
                          setState(() {
                            _tileExpandedStates[i] = false;
                          });
                        }
                      }
                    }
                  },
                  initiallyExpanded: _tileExpandedStates[index],
                  title: Text(index % 2 == 0 ? 'School Store' : 'The Tuck', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Aeonik', color: Colors.black)),
                  subtitle: Text('October 10, 19:59', style: TextStyle(fontSize: 17, fontFamily: 'Aeonik', color: Colors.black54)),
                  trailing: Text('\$${index * 5}.00', style: TextStyle(fontSize: 17, fontFamily: 'Aeonik', color: Colors.black)),
                  children: <Widget>[
                    ListTile(
                      title: Text('Item 1', style: TextStyle(fontSize: 16, fontFamily: 'Aeonik', color: Colors.black)),
                      subtitle: Text('Description of Item 1', style: TextStyle(fontSize: 16, fontFamily: 'Aeonik', color: Colors.black54)),
                      trailing: Text('\$10.00', style: TextStyle(fontSize: 14, fontFamily: 'Aeonik', color: Colors.black)),
                    ),
                    ListTile(
                      title: Text('Item 2', style: TextStyle(fontSize: 16, fontFamily: 'Aeonik', color: Colors.black)),
                      subtitle: Text('Description of Item 2', style: TextStyle(fontSize: 14, fontFamily: 'Aeonik', color: Colors.black54)),
                      trailing: Text('\$15.00', style: TextStyle(fontSize: 14, fontFamily: 'Aeonik', color: Colors.black)),
                    ),
                    ListTile(
                      title: Text('Item 3', style: TextStyle(fontSize: 16, fontFamily: 'Aeonik', color: Colors.black)),
                      subtitle: Text('Description of Item 3', style: TextStyle(fontSize: 14, fontFamily: 'Aeonik', color: Colors.black54)),
                      trailing: Text('\$20.00', style: TextStyle(fontSize: 14, fontFamily: 'Aeonik', color: Colors.black)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<bool> _tileExpandedStates = List<bool>.filled(10, false);

  void setState(void Function() fn) {
    fn();
  }


}
