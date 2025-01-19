import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/shared_functions.dart';
import 'dart:math';

class CardPage extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final ValueNotifier<ThemeMode> themeNotifier;

  CardPage({this.firstName, this.lastName, required this.themeNotifier});

  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> with AutomaticKeepAliveClientMixin<CardPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
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
    _setInitialLoadingStates();
    _loadStoredData();
    _loadGreeting();
  }

  void _setInitialLoadingStates() {
    setState(() {
      _isLoadingBarcode = true;
      _isLoadingProfileImage = true;
    });
  }

  Future<void> _loadStoredData() async {
    setState(() {
      _isLoadingBarcode = true;
      _isLoadingProfileImage = true;
    });
    final barcodeData = await _secureStorage.read(key: 'barcode_data');
    final base64Png = await _secureStorage.read(key: 'profile_image');

    if (barcodeData == null || base64Png == null) {
      await _loadProfileAndBarcode();
    } else {
      setState(() {
        _barcodeData = barcodeData;
        _profileImage = base64Decode(base64Png);
        _isLoadingBarcode = false;
        _isLoadingProfileImage = false;
      });
    }
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
        _secureStorage.write(key: 'profile_image', value: base64Encode(imageData));
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
      setState(() {});
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final double screenPadding = MediaQuery.of(context).size.width * 0.15; // or another suitable fraction
    final double availableWidth = MediaQuery.of(context).size.width - (screenPadding * 2);
    final double availableHeight = MediaQuery.of(context).size.height - 60 - MediaQuery.of(context).size.height * 0.04;
    final double cardWidth = availableWidth;
    final double cardHeight = cardWidth * cardAspectRatio;

    final double adjustedCardHeight = availableHeight < cardHeight ? availableHeight : cardHeight;
    final double adjustedCardWidth = adjustedCardHeight / cardAspectRatio;
    final double boxHorizontalPadding = adjustedCardWidth * (5 / 54);
    final double barcodeHorizontalPadding = adjustedCardWidth * (11 / 54);
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Page'),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadPage,
        child: Padding(
          padding: EdgeInsets.only(top: kToolbarHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 0, left: 16.0, right: 16.0),
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 50),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 20), // Adjusted height
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Text(
                            _selectedGreeting ?? '',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface, // Use theme color
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
                                  ? Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: adjustedCardHeight * (25 / 86),
                                  width: adjustedCardHeight * (25 / 86),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
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
                                child: _isLoadingProfileImage
                                    ? Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Container(
                                      width: adjustedCardWidth * 0.6,
                                      height: adjustedCardHeight * (4.5 / 86),
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                    : Text(
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
                                child: _isLoadingProfileImage
                                    ? Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Container(
                                      width: adjustedCardWidth * 0.4,
                                      height: adjustedCardHeight * (3.3 / 86),
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                                    : Text(
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
                                          ? Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Container(
                                            width: adjustedCardWidth * (32 / 54),
                                            height: adjustedCardHeight * (7 / 86),
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
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
                                                        color: Colors.white, // Set background color to white
                                                        child: BarcodeWidget(
                                                          barcode: Barcode.code39(),
                                                          data: "00000",//_barcodeData!
                                                          drawText: false,
                                                          color: Colors.black,
                                                          width: adjustedCardWidth * (32 / 54),
                                                          height: adjustedCardHeight * (25 / 86),
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
                                                        color: Colors.transparent,
                                                        child: Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 30,
                                                        ),
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
                                          data: "00000",//_barcodeData!,
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
        ),
      ),
    );
  }
}