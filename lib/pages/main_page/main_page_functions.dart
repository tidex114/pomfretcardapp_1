// main_page_functions.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pomfretcardapp/pages/config.dart';
import 'package:pomfretcardapp/services/decrypt_with_private_key.dart';

class MainPageFunctions {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> loadUserInfo(Function updateUserInfo) async {
    String? firstName = await _secureStorage.read(key: 'first_name');
    String? lastName = await _secureStorage.read(key: 'last_name');
    String? graduationYear = await _secureStorage.read(key: 'graduation_year');
    String? email = await _secureStorage.read(key: 'user_email');

    updateUserInfo(firstName, lastName, graduationYear, email);

  }

  AnimationController createAnimationController(TickerProvider vsync) {
    return AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: vsync,
    );
  }

  Animation<double> createAnimation(AnimationController controller) {
    return Tween<double>(begin: 0, end: 1).animate(controller);
  }

  void disposeControllers(PageController pageController, AnimationController animationController) {
    pageController.dispose();
    animationController.dispose();
  }

  void onPageChanged(int index, Function updateCurrentIndex, AnimationController animationController) {
    updateCurrentIndex(index);
    animationController.forward(from: 0);
  }

  void onBottomNavTapped(PageController pageController, int index) {
    pageController.animateToPage(index,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> reloadPage(Function loadUserInfo) async {
    await loadUserInfo();
  }
}
