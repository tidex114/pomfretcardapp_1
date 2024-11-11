// card_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pomfretcardapp/pages/config.dart';
import 'package:pomfretcardapp/services/decrypt_with_private_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

class CardPage extends StatefulWidget {
  final String? firstName;
  final String? lastName;

  CardPage({this.firstName, this.lastName});

  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  String? _barcodeData;
  final double cardAspectRatio = 86 / 54;

  @override
  void initState() {
    super.initState();
    loadBarcodeData(_updateBarcodeData);
  }

  Future<void> loadBarcodeData(Function updateBarcodeData) async {
    try {
      final userEmail = await _secureStorage.read(key: 'user_email');
      if (userEmail != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_barcode'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': userEmail, 'public_key': await _secureStorage.read(key: 'public_key')}),
        );
        if (response.statusCode == 200) {
          final encryptedJsonBase64 = json.decode(response.body)['encrypted_json'];
          final decryptedJsonMap = await decryptJsonData(encryptedJsonBase64);

          if (decryptedJsonMap['email'] == userEmail) {
            if (decryptedJsonMap.containsKey('barcode') && decryptedJsonMap['barcode'] is int) {
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
          print('Error: Failed to fetch barcode with status code ${response.statusCode}');
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

  void _updateBarcodeData(String barcodeData) {
    setState(() {
      _barcodeData = barcodeData;
    });
  }

  Future<void> _reloadPage() async {
    setState(() {
      _barcodeData = null; // Clear the barcode data before reloading
    });
    await loadBarcodeData(_updateBarcodeData);
  }

  @override
  Widget build(BuildContext context) {
    final double screenPadding = MediaQuery.of(context).size.width * 0.15; // or another suitable fraction
    final double availableWidth = MediaQuery.of(context).size.width - (screenPadding * 2);
    final double availableHeight = MediaQuery.of(context).size.height - 60 - MediaQuery.of(context).size.height * 0.04;
    final double cardWidth = availableWidth;
    final double cardHeight = cardWidth * cardAspectRatio;

    final double adjustedCardHeight = availableHeight < cardHeight ? availableHeight : cardHeight;
    final double adjustedCardWidth = adjustedCardHeight / cardAspectRatio;
    final double boxHorizontalPadding = adjustedCardWidth * (5 / 54);
    final double barcodeHorizontalPadding = adjustedCardWidth * (11 / 54);

    return RefreshIndicator(
      onRefresh: _reloadPage,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: screenPadding),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.07),
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
                SizedBox(height: adjustedCardHeight * (5 / 86)),
                Container(
                  width: adjustedCardWidth,
                  height: adjustedCardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(adjustedCardWidth * 0.05),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: adjustedCardWidth * 0.05,
                        offset: Offset(0, adjustedCardWidth * 0.03),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: adjustedCardHeight * (5 / 86),
                        left: boxHorizontalPadding,
                        right: boxHorizontalPadding,
                        child: Center(
                          child: Image.asset(
                            'assets/images/pomfret_label.jpg',
                            fit: BoxFit.contain,
                            width: adjustedCardWidth - 2 * boxHorizontalPadding,
                          ),
                        ),
                      ),
                      Positioned(
                        top: adjustedCardHeight * (20 / 86),
                        left: adjustedCardWidth * 0.5 - adjustedCardHeight * (25 / 86) / 2,
                        child: Image.asset(
                          'assets/images/profile_picture.png',
                          height: adjustedCardHeight * (25 / 86),
                          width: adjustedCardHeight * (25 / 86),
                        ),
                      ),
                      Positioned(
                        top: adjustedCardHeight * (49 / 86),
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            "${widget.firstName} ${widget.lastName}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: adjustedCardHeight * (4.5 / 86),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Aeonik',
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: adjustedCardHeight * (55 / 86),
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Student',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: adjustedCardHeight * (3.3 / 86),
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Aeonik',
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: adjustedCardHeight * (25 / 86),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/card_background.png'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.dstATop),
                            ),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(adjustedCardWidth * 0.05),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: boxHorizontalPadding,
                                right: boxHorizontalPadding,
                                bottom: adjustedCardHeight * (5 / 86),
                                child: Container(
                                  height: adjustedCardHeight * (8 / 86),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: barcodeHorizontalPadding,
                                right: barcodeHorizontalPadding,
                                top: adjustedCardHeight * (12.5 / 86),
                                child: (_barcodeData != null && _barcodeData != "Unknown")
                                    ? BarcodeWidget(
                                  barcode: Barcode.code39(),
                                  data: _barcodeData!,
                                  drawText: false,
                                  color: Colors.black,
                                  width: adjustedCardWidth * (32 / 54),
                                  height: adjustedCardHeight * (7 / 86),
                                )
                                    : Center(
                                  child: Text(
                                    'Error: Unable to generate barcode.',
                                    style: TextStyle(
                                      fontFamily: 'Aeonik',
                                      color: Colors.red,
                                      fontSize: adjustedCardHeight * (3 / 86),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}
