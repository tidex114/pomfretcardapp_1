import 'package:flutter/material.dart';
import 'card_page.dart';
import 'transactions_page.dart';
import 'profile_page/profile_page.dart';
import '../../services/shared_functions.dart';
import 'package:pomfretcardapp/pages/config.dart';
import '../../theme.dart'; // Import the theme file

class MainPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  MainPage({required this.themeNotifier});

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
    final isDarkMode = widget.themeNotifier.value == ThemeMode.dark;
    final appBarColor = isDarkMode ? darkTheme.colorScheme.surface : lightTheme.colorScheme.surface;
    final iconPath = isDarkMode
        ? 'assets/images/pomcard_icon_dark.png'
        : 'assets/images/pomcard_icon_light.png';

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [

              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: <Widget>[
                    CardPage(
                      firstName: _firstName,
                      lastName: _lastName,
                      themeNotifier: widget.themeNotifier,
                    ),
                    TransactionPage(themeNotifier: widget.themeNotifier),
                    ProfilePage(
                      firstName: _firstName,
                      lastName: _lastName,
                      graduationYear: _graduationYear,
                      email: _email,
                      themeNotifier: widget.themeNotifier,
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
              decoration: BoxDecoration(
                color: appBarColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 35.0,
                    offset: Offset(0,1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 12.0, top: 80.0), // Add top padding here
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        iconPath,
                        height: 60,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'card',
                        style: TextStyle(
                          color: isDarkMode ? darkTheme.colorScheme.onSurface : lightTheme.colorScheme.onSurface,
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
      bottomNavigationBar: Container(
        color: appBarColor,
        child: BottomNavigationBar(
          elevation: 10.0,
          iconSize: 22.0,
          selectedFontSize: 17.0,
          unselectedFontSize: 14.0,
          selectedItemColor: isDarkMode ? darkTheme.colorScheme.primary : lightTheme.colorScheme.primary,
          unselectedItemColor: isDarkMode ? darkTheme.colorScheme.onSurface.withOpacity(0.7) : lightTheme.colorScheme.onSurface.withOpacity(0.7),
          currentIndex: _currentIndex,
          onTap: _onBottomNavTapped,
          selectedLabelStyle: TextStyle(
              fontFamily: 'Aeonik', fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontFamily: 'Aeonik'),
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Card'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'Transactions'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}