import 'package:flutter/material.dart';
import 'card_page.dart';
import 'transactions_page.dart';
import 'profile_page/profile_page.dart';
import '../../services/shared_functions.dart';
import 'package:pomfretcardapp/pages/config.dart';
import '../../theme.dart';

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
  Map<String, String?> _userInfo = {
    'firstName': null,
    'lastName': null,
    'graduationYear': null,
    'email': null,
  };

  @override
  void initState() {
    super.initState();
    _animationController = _sharedFunctions.createAnimationController(this);
    _animation = _sharedFunctions.createAnimation(_animationController);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      await _sharedFunctions.loadUserInfo((firstName, lastName, graduationYear, email) {
        setState(() {
          _userInfo = {
            'firstName': firstName,
            'lastName': lastName,
            'graduationYear': graduationYear?.substring(graduationYear.length - 2),
            'email': email,
          };
        });
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  @override
  void dispose() {
    _sharedFunctions.disposeControllers(_pageController, _animationController);
    super.dispose();
  }

  void _onPageChanged(int index) {
    _sharedFunctions.onPageChanged(
      index,
          (newIndex) => setState(() => _currentIndex = newIndex),
      _animationController,
    );
  }

  void _onBottomNavTapped(int index) {
    _sharedFunctions.onBottomNavTapped(_pageController, index);
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
                      firstName: _userInfo['firstName'],
                      lastName: _userInfo['lastName'],
                      themeNotifier: widget.themeNotifier,
                    ),
                    TransactionPage(themeNotifier: widget.themeNotifier),
                    ProfilePage(
                      firstName: _userInfo['firstName'],
                      lastName: _userInfo['lastName'],
                      graduationYear: _userInfo['graduationYear'],
                      email: _userInfo['email'],
                      themeNotifier: widget.themeNotifier,
                    ),
                  ],
                ),
              ),
            ],
          ),
          CustomAppBar(iconPath: iconPath, appBarColor: appBarColor, isDarkMode: isDarkMode),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  final String iconPath;
  final Color appBarColor;
  final bool isDarkMode;

  const CustomAppBar({
    required this.iconPath,
    required this.appBarColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 12.0, top: MediaQuery.of(context).padding.top + 16),
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
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDarkMode;

  const CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final appBarColor = isDarkMode ? darkTheme.colorScheme.surface : lightTheme.colorScheme.surface;
    final selectedItemColor = isDarkMode ? darkTheme.colorScheme.primary : lightTheme.colorScheme.primary;
    final unselectedItemColor = isDarkMode
        ? darkTheme.colorScheme.onSurface.withOpacity(0.7)
        : lightTheme.colorScheme.onSurface.withOpacity(0.7);

    return Stack(
      children: [
        // Background for straight navigation bar
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: appBarColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 35.0,
                offset: Offset(0, -1), // Shadow going from bottom to top
              ),
            ],
          ),
        ),
        // Navigation items
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.credit_card,
                label: 'Card',
                isSelected: currentIndex == 0,
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history,
                label: 'Transactions',
                isSelected: currentIndex == 1,
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person,
                label: 'Profile',
                isSelected: currentIndex == 2,
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color selectedItemColor,
    required Color unselectedItemColor,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 150),
            height: isSelected ? 6 : 0, // Highlight the selected item
            width: isSelected ? 36 : 0,
            decoration: BoxDecoration(
              color: selectedItemColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Icon(
            icon,
            color: isSelected ? selectedItemColor : unselectedItemColor,
            size: isSelected ? 28 : 24, // Slightly enlarge selected icon
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Aeonik',
              fontWeight: FontWeight.bold,
              fontSize: isSelected ? 16 : 14, // Dynamic font size
              color: isSelected ? selectedItemColor : unselectedItemColor,
            ),
          ),
        ],
      ),
    );
  }
}
