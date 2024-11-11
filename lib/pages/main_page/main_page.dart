// main_page.dart

import 'package:flutter/material.dart';
import 'card_page.dart';
import 'transactions_page.dart';
import 'profile_page.dart';
import 'main_page_functions.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final MainPageFunctions _functions = MainPageFunctions();
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
    _animationController = _functions.createAnimationController(this);
    _animation = _functions.createAnimation(_animationController);
    _functions.loadUserInfo(_updateUserInfo);
  }

  void _updateUserInfo(String? firstName, String? lastName, String? graduationYear, String? email) {
    setState(() {
      _firstName = firstName;
      _lastName = lastName;
      _graduationYear = graduationYear != null ? graduationYear.substring(graduationYear.length - 2) : null;
      _email = email;
    });
  }

  @override
  void dispose() {
    _functions.disposeControllers(_pageController, _animationController);
    super.dispose();
  }

  void _onPageChanged(int index) {
    _functions.onPageChanged(index, (newIndex) => setState(() => _currentIndex = newIndex), _animationController);
  }

  void _onBottomNavTapped(int index) {
    _functions.onBottomNavTapped(_pageController, index);
  }

  Future<void> _reloadPage() async {
    await _functions.loadUserInfo(_updateUserInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Card'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
