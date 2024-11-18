import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'card_page.dart';
import 'transactions_page.dart';
import 'profile_page.dart';
import '../../services/shared_functions.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final SharedFunctions _sharedFunctions = SharedFunctions();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentIndex = 0;
  String? _firstName;
  String? _lastName;
  String? _graduationYear;
  String? _email;

  @override
  void initState() {
    super.initState();
    _animationController = _sharedFunctions.createAnimationController(this);
    _animation = _sharedFunctions.createAnimation(_animationController);
    _sharedFunctions.loadUserInfo(_updateUserInfo);
  }

  void _updateUserInfo(String? firstName, String? lastName,
      String? graduationYear, String? email) {
    setState(() {
      _firstName = firstName;
      _lastName = lastName;
      _graduationYear = graduationYear != null ? graduationYear.substring(
          graduationYear.length - 2) : null;
      _email = email;
    });
  }

  @override
  void dispose() {
    _sharedFunctions.disposeControllers(_pageController, _animationController);
    super.dispose();
  }

  void _onPageChanged(int index) {
    _sharedFunctions.onPageChanged(
        index, (newIndex) => setState(() => _currentIndex = newIndex),
        _animationController);
  }

  void _onBottomNavTapped(int index) {
    _sharedFunctions.onBottomNavTapped(_pageController, index);
  }

  Future<void> _reloadPage() async {
    await _sharedFunctions.loadUserInfo(_updateUserInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.15),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: <Widget>[
                    CardPage(
                      firstName: _firstName,
                      lastName: _lastName,
                    ),
                    TransactionPage(),
                    ProfilePage(
                      firstName: _firstName,
                      lastName: _lastName,
                      graduationYear: _graduationYear,
                      email: _email,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.14,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 30,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
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
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 10.0,
        iconSize: 22.0,
        selectedFontSize: 17.0,
        unselectedFontSize: 14.0,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        selectedLabelStyle: TextStyle(
            fontFamily: 'Aeonik', fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontFamily: 'Aeonik'),
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Card'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}