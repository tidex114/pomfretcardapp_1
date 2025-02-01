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
import 'package:pomfretcardapp/services/refresh_access_token.dart';
import 'package:pomfretcardapp/services/showMessage.dart';
import 'logout.dart';
import 'dart:async';


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

  Future<void> loadBarcodeData(Function updateBarcodeData, BuildContext context) async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final firstName = await _secureStorage.read(key: 'first_name');
      final lastName = await _secureStorage.read(key: 'last_name');
      final publicKey = await _secureStorage.read(key: 'public_key');
      final uid = await _secureStorage.read(key: 'uid');

      if (firstName != null && lastName != null && publicKey != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_barcode'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
          body: json.encode({
            'uid': uid,
            'first_name': firstName,
            'last_name': lastName,
            'public_key': publicKey
          }),
        );

        if (response.statusCode == 200) {
          final encryptedJsonBase64 = json.decode(response.body)['encrypted_json'];
          final decryptedJsonMap = await decryptJsonData(encryptedJsonBase64);

          if (decryptedJsonMap['first_name'] == firstName && decryptedJsonMap['last_name'] == lastName) {
            if (decryptedJsonMap.containsKey('barcode') && decryptedJsonMap['barcode'] is int) {
              final String barcodeData = decryptedJsonMap['barcode'].toString();
              updateBarcodeData(barcodeData);
            } else {
              print('Error: Barcode data is missing or not an integer');
              updateBarcodeData("Unknown");
            }
          } else {
            print('Error: Name mismatch');
            updateBarcodeData("Name mismatch");
          }
        } else if (response.statusCode == 401) {
          print('Error: Unauthorized access.');
          int reason = int.parse(json.decode(response.body)["reason_code"].toString());

          if (reason == 5) { // Assuming reason code 5 indicates token expiration
            await AuthService().refreshAccessToken(() async {
              await loadBarcodeData(updateBarcodeData, context);
            }, context);
          } else {
            updateBarcodeData("Unauthorized access");
          }
        } else {
          print('Error: Failed to fetch barcode with status code ${response.statusCode}. Response: ${response.body}');
          updateBarcodeData("Unknown");
        }
      } else {
        print('Error: User first name or last name not found in secure storage');
        updateBarcodeData("Unknown");
      }
    } catch (e) {
      print('Error during barcode retrieval: $e');
      updateBarcodeData("Unknown");
    }
  }
  Future<void> loadBalanceData(Function updateBalanceData, BuildContext context) async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final firstName = await _secureStorage.read(key: 'first_name');
      final lastName = await _secureStorage.read(key: 'last_name');
      final publicKey = await _secureStorage.read(key: 'public_key');
      final uid = await _secureStorage.read(key: 'uid');

      if (firstName != null && lastName != null && publicKey != null && uid != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_balance'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
          body: json.encode({
            'uid': uid,
            'first_name': firstName,
            'last_name': lastName,
            'public_key': publicKey
          }),
        ).timeout(Duration(seconds: 10)); // Add timeout

        if (response.statusCode == 200) {
          final encryptedJsonBase64 = json.decode(response.body)['encrypted_json'];
          final decryptedJsonMap = await decryptJsonData(encryptedJsonBase64);

          if (decryptedJsonMap['first_name'] == firstName && decryptedJsonMap['last_name'] == lastName) {
            if (decryptedJsonMap.containsKey('remaining_balance')) {
              final String balanceData = decryptedJsonMap['remaining_balance'].toString();
              updateBalanceData(balanceData);
            } else {
              print('Error: Balance data is missing');
              updateBalanceData('Error');
              showMessage(context, 'Error: Balance data is missing', 'error');
            }
          } else {
            print('Error: Name mismatch');
            updateBalanceData('Error');
            showMessage(context, 'Error: Name mismatch', 'error');
          }
        } else if (response.statusCode == 401) {
          print('Error: Unauthorized access.');
          int reason = int.parse(json.decode(response.body)["reason_code"].toString());

          if (reason == 5) {
            await AuthService().refreshAccessToken(() async {
              await loadBalanceData(updateBalanceData, context);
            }, context);
          } else {
            updateBalanceData('Error');
            showMessage(context, 'Error: Unauthorized access', 'error');
          }
        } else {
          print('Error: Failed to fetch balance with status code ${response.statusCode}');
          updateBalanceData('Error');
          showMessage(context, 'Error: Failed to fetch balance', 'error');
        }
      } else {
        print('Error: User first name, last name, public key, or uid not found in secure storage');
        updateBalanceData('Error');
        showMessage(context, 'Error: User data not found in secure storage', 'error');
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      updateBalanceData('Error');
      showMessage(context, 'Network error. Please try again later.', 'error');
    } on TimeoutException catch (e) {
      print('Request timeout: $e');
      updateBalanceData('Error');
      showMessage(context, 'Request timeout. Please try again later.', 'error');
    } catch (e) {
      print('Error during balance retrieval: $e');
      updateBalanceData('Error');
      showMessage(context, 'Error during balance retrieval', 'error');
    }
  }

  Future<void> _savePngToFlutterStorage(Uint8List pngData) async {
    try {
      final secureStorage = FlutterSecureStorage();
      final base64Png = base64Encode(pngData);
      await secureStorage.write(key: 'profile_image', value: base64Png);
    } catch (e) {
      print('Error saving PNG to Flutter Secure Storage: $e');
    }
  }

  Future<void> loadProfileImageData(Function updateProfileImageData, BuildContext context) async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final firstName = await _secureStorage.read(key: 'first_name');
      final lastName = await _secureStorage.read(key: 'last_name');
      final publicKey = await _secureStorage.read(key: 'public_key');
      final uid = await _secureStorage.read(key: 'uid');

      if (firstName != null && lastName != null && publicKey != null && uid != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_profile_image'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
          body: json.encode({
            'uid': uid,
            'first_name': firstName,
            'last_name': lastName,
            'public_key': publicKey
          }),
        );

        if (response.statusCode == 200) {
          final encryptedKeyBase64 = json.decode(response.body)['encrypted_key'];
          final encryptedPhotoBase64 = json.decode(response.body)['encrypted_photo'];
          final decryptedImageData = await decryptPngData(encryptedKeyBase64, encryptedPhotoBase64);

          if (decryptedImageData != null && decryptedImageData is Uint8List) {
            await _savePngToFlutterStorage(decryptedImageData);
            updateProfileImageData(decryptedImageData);
          } else {
            print('Error: Decrypted image data is null or invalid');
            updateProfileImageData(null);
          }
        } else if (response.statusCode == 401) {
          print('Error: Unauthorized access.');
          int reason = int.parse(json.decode(response.body)["reason_code"].toString());

          if (reason == 5) {
            await AuthService().refreshAccessToken(() async {
              await loadProfileImageData(updateProfileImageData, context);
            }, context);
          } else {
            updateProfileImageData(null);
          }
        } else {
          print('Error: Failed to fetch profile picture with status code ${response.statusCode}');
          updateProfileImageData(null);
        }
      } else {
        print('Error: User first name, last name, public key, or uid not found in secure storage');
        updateProfileImageData(null);
      }
    } catch (e) {
      print('Error during profile picture retrieval: $e');
      updateProfileImageData(null);
    }
  }
  Future<Map<String, dynamic>?> getDecryptedTransactions() async {
    try {
      final secureStorage = FlutterSecureStorage();
      final userEmail = await secureStorage.read(key: 'user_email');

      if (userEmail != null) {
        // Make the HTTP request to get encrypted transactions
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_transactions'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': userEmail,
            'public_key': await secureStorage.read(key: 'public_key'),
            'student_id': await secureStorage.read(key: 'student_id'),
            'timestamp': DateTime.now().toIso8601String(), // Example timestamp
          }),
        );

        if (response.statusCode == 200) {

        } else {
          print('Error: Failed to fetch encrypted transactions with status code ${response.statusCode}');
          return null;
        }
      } else {
        print('Error: User email not found in secure storage');
        return null;
      }
    } catch (e) {
      print('Error during encrypted transactions retrieval: $e');
      return null;
    }
  }
}


