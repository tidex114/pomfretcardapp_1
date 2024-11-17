// card_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/shared_functions.dart';
import 'dart:math';

final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

class CardPage extends StatefulWidget {
  final String? firstName;
  final String? lastName;

  CardPage({this.firstName, this.lastName});

  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> with AutomaticKeepAliveClientMixin<CardPage> {
  String? _barcodeData;
  Uint8List? _profileImage;
  bool _isLoadingBarcode = true;
  bool _isLoadingProfileImage = true;
  final SharedFunctions _sharedFunctions = SharedFunctions();
  final double cardAspectRatio = 86 / 54;
  final List<String> _greetings = [
    "Mr. Rodman's typing...",
    "Tucktime!",
    "Blink if you want a double choc muffin",
    "You're not in the tuck... Are you?",
    "Coffee break!",
    "Free block?"
  ];
  String? _selectedGreeting;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
    _loadGreeting();
    _loadProfileAndBarcode();
  }

  Future<void> _loadStoredData() async {
    final barcodeData = await _secureStorage.read(key: 'barcode_data');
    final base64Png = await _secureStorage.read(key: 'profile_image');

    Uint8List? profileImage;
    if (base64Png != null) {
      profileImage = base64Decode(base64Png);
    }

    setState(() {
      _barcodeData = barcodeData;
      _profileImage = profileImage;
      _isLoadingBarcode = false;
      _isLoadingProfileImage = false;
    });
  }

  Future<void> _loadProfileAndBarcode() async {
    await _sharedFunctions.loadBarcodeData(_updateBarcodeData);
    await _sharedFunctions.loadProfileImageData(_updateProfileImageData);
  }

  Future<void> _reloadPage() async {
    setState(() {
      _barcodeData = null; // Clear the barcode data before reloading
      _profileImage = null; // Clear the profile image data before reloading
      _isLoadingBarcode = true;
      _isLoadingProfileImage = true;
    });
    await _loadProfileAndBarcode();
  }

  void _updateBarcodeData(String barcodeData) {
    setState(() {
      _barcodeData = barcodeData;
      _secureStorage.write(key: 'barcode_data', value: barcodeData);
      _isLoadingBarcode = false;
    });
  }

  void _updateProfileImageData(Uint8List? imageData) {
    setState(() {
      _profileImage = imageData;
      if (imageData != null) {
        _secureStorage.write(
            key: 'profile_image_data', value: base64Encode(imageData));
      }
      _isLoadingProfileImage = false;
    });
  }

  Future<void> _loadGreeting() async {
    final storedGreeting = await _secureStorage.read(key: 'greeting');
    if (storedGreeting != null) {
      setState(() {
        _selectedGreeting = storedGreeting;
      });
    } else {
      _selectedGreeting = _greetings[Random().nextInt(_greetings.length)];
      await _secureStorage.write(key: 'greeting', value: _selectedGreeting!);
      setState(() {}); // Added to update UI with the new greeting
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double screenPadding = MediaQuery.of(context).size.width *
        0.15; // or another suitable fraction
    final double availableWidth =
        MediaQuery.of(context).size.width - (screenPadding * 2);
    final double availableHeight = MediaQuery.of(context).size.height -
        60 -
        MediaQuery.of(context).size.height * 0.04;
    final double cardWidth = availableWidth;
    final double cardHeight = cardWidth * cardAspectRatio;

    final double adjustedCardHeight =
    availableHeight < cardHeight ? availableHeight : cardHeight;
    final double adjustedCardWidth = adjustedCardHeight / cardAspectRatio;
    final double boxHorizontalPadding = adjustedCardWidth * (5 / 54);
    final double barcodeHorizontalPadding = adjustedCardWidth * (11 / 54);
    return RefreshIndicator(
      onRefresh: _reloadPage,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 0, left: 16.0, right: 16.0),
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Text(
                        _selectedGreeting ?? '',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: constraints.maxWidth * 0.065, // Dynamic font size based on card width
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Aeonik',
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  SizedBox(height: 20),
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
                          child: _isLoadingProfileImage
                              ? SizedBox(
                            height: adjustedCardHeight * (25 / 86),
                            width: adjustedCardHeight * (25 / 86),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                              : Opacity(
                            opacity: _profileImage == null ? 0.5 : 1.0,
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.memory(
                                _profileImage!,
                                height: adjustedCardHeight * (25 / 86),
                                width: adjustedCardHeight * (25 / 86),
                                fit: BoxFit.cover,
                              )
                                  : Image.asset(
                                'assets/images/profile_picture.png',
                                height: adjustedCardHeight * (25 / 86),
                                width: adjustedCardHeight * (25 / 86),
                                fit: BoxFit.cover,
                              ),
                            ),
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
                                colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.5),
                                    BlendMode.dstATop),
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
                                  child: _isLoadingBarcode
                                      ? Center(
                                      child: CircularProgressIndicator())
                                      : (_barcodeData != null &&
                                      _barcodeData != "Unknown")
                                      ? GestureDetector(
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
                                    child: BarcodeWidget(
                                      barcode: Barcode.code39(),
                                      data: _barcodeData!,
                                      drawText: false,
                                      color: Colors.black,
                                      width: adjustedCardWidth * (32 / 54),
                                      height: adjustedCardHeight * (7 / 86),
                                    ),
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
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
