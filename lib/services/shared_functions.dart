// shared_functions.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pomfretcardapp/services/decryption_service.dart';
import 'package:pomfretcardapp/pages/config.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


class SharedFunctions {
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

  void disposeControllers(PageController pageController,
      AnimationController animationController) {
    pageController.dispose();
    animationController.dispose();
  }

  void onPageChanged(int index, Function updateCurrentIndex,
      AnimationController animationController) {
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

  Future<void> loadBarcodeData(Function updateBarcodeData) async {
    try {
      final userEmail = await _secureStorage.read(key: 'user_email');
      if (userEmail != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_barcode'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': userEmail,
            'public_key': await _secureStorage.read(key: 'public_key')
          }),
        );
        if (response.statusCode == 200) {
          final encryptedJsonBase64 = json.decode(
              response.body)['encrypted_json'];
          final decryptedJsonMap = await decryptJsonData(encryptedJsonBase64);

          if (decryptedJsonMap['email'] == userEmail) {
            if (decryptedJsonMap.containsKey('barcode') &&
                decryptedJsonMap['barcode'] is int) {
              final String barcodeData = decryptedJsonMap['barcode'].toString();
              updateBarcodeData(barcodeData);
            } else {
              print('Error: Barcode data is missing or not an integer');
              updateBarcodeData("Unknown");
            }
          } else {
            print('Error: Email mismatch');
            updateBarcodeData("Email mismatch");
          }
        } else {
          print(
              'Error: Failed to fetch barcode with status code \${response.statusCode}');
          updateBarcodeData("Unknown");
        }
      } else {
        print('Error: User email not found in secure storage');
        updateBarcodeData("Unknown");
      }
    } catch (e) {
      print('Error during barcode retrieval: $e');
      updateBarcodeData("Unknown");
    }
  }

  Future<void> _savePngToFlutterStorage(Uint8List pngData) async {
    try {
      final secureStorage = FlutterSecureStorage();
      final base64Png = base64Encode(pngData);
      await secureStorage.write(key: 'profile_image', value: base64Png);
      print('PNG image saved to Flutter Secure Storage');
    } catch (e) {
      print('Error saving PNG to Flutter Secure Storage: $e');
    }
  }

  Future<void> loadProfileImageData(Function updateProfileImageData) async {
    try {
      final secureStorage = FlutterSecureStorage();
      final userEmail = await secureStorage.read(key: 'user_email');
      if (userEmail != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_profile_image'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': userEmail,
            'public_key': await secureStorage.read(key: 'public_key')
          }),
        );
        if (response.statusCode == 200) {
          final encryptedKeyBase64 = json.decode(
              response.body)['encrypted_key'];
          final encryptedPhotoBase64 = json.decode(
              response.body)['encrypted_photo'];
          final decryptedImageData = await decryptPngData(
              encryptedKeyBase64, encryptedPhotoBase64);

          if (decryptedImageData != null && decryptedImageData is Uint8List) {
            await _savePngToFlutterStorage(decryptedImageData);
            updateProfileImageData(decryptedImageData);
          } else {
            print('Error: Decrypted image data is null or invalid');
            updateProfileImageData(null);
          }
        } else {
          print(
              'Error: Failed to fetch profile picture with status code ${response
                  .statusCode}');
          updateProfileImageData(null);
        }
      } else {
        print('Error: User email not found in secure storage');
        updateProfileImageData(null);
      }
    } catch (e) {
      print('Error during profile picture retrieval: $e');
      updateProfileImageData(null);
    }
  }
}

