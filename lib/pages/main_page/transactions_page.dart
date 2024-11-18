// transaction_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:pomfretcardapp/pages/config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomfretcardapp/services/decryption_service.dart';
import 'dart:typed_data';

class TransactionPage extends StatefulWidget {
  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> with AutomaticKeepAliveClientMixin<TransactionPage> {
  List<bool> _tileExpandedStates = [];
  List<Map<String, dynamic>> transactions = [];
  String currentTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  DateTime latestTimestamp = DateTime.now();
  bool _isLoadingMore = false;
  bool hasMore = true;
  final storage = FlutterSecureStorage();
  String? studentId;
  bool _loadError = false;
  String _errorMessage = '';
  bool _isReloading = false;
  bool _isLoadingInitial = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTimeZone();
    _loadStudentId();
  }

  Future<void> _loadStudentId() async {
    try {
      studentId = await storage.read(key: 'barcode_data');
      if (studentId != null) {
        await _loadInitialTransactions();
      } else {
        setState(() {
          _loadError = true;
          _errorMessage = 'No student ID found in storage';
        });
      }
    } catch (e) {
      setState(() {
        _loadError = true;
        _errorMessage = 'Could not load student ID. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  void _initializeTimeZone() {
    try {
      tz.initializeTimeZones();
      final location = tz.getLocation('America/New_York');
      DateTime ctTime = tz.TZDateTime.now(location);
      currentTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(ctTime);
      print(currentTimestamp);
    } catch (e) {
      setState(() {
        _loadError = true;
        _errorMessage = 'Could not initialize time zone. Please try again later.';
      });
    }
  }

  Future<void> _loadInitialTransactions() async {
    await _loadTransactions(DateTime.parse(currentTimestamp), loadMore: false);
  }

  Future<void> _loadTransactions(DateTime timestamp, {bool loadMore = false}) async {
    if (studentId == null) {
      print('Student ID is null. Exiting _loadTransactions.');
      return;
    }

    try {
      if (loadMore) {
        setState(() {
          _isLoadingMore = true;
        });
      }
      final publicKey = await storage.read(key: 'public_key');
      final email = await storage.read(key: 'user_email');

      final response = await http.post(
        Uri.parse('${Config.schoolBackendUrl}/get_transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'timestamp': timestamp.toIso8601String(),
          'public_key': publicKey,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Extract encrypted data from response
        final responseBody = json.decode(response.body);
        final encryptedKeyBase64 = responseBody['encrypted_key'];
        final encryptedJsonBase64 = responseBody['encrypted_data'];

        // Decrypt the JSON data
        final decryptedJsonData = await decryptTransactionData(encryptedKeyBase64, encryptedJsonBase64);

        Map<String, dynamic>? decryptedJson;

        if (decryptedJsonData != null && decryptedJsonData is Uint8List) {
          // Convert Uint8List to a UTF-8 string
          final decryptedJsonString = utf8.decode(decryptedJsonData);

          // Parse the decrypted JSON string into a Map
          decryptedJson = json.decode(decryptedJsonString) as Map<String, dynamic>;
        } else {
          print('Error: Decrypted JSON data is null or invalid');
          setState(() {
            _loadError = true;
            _errorMessage = 'Could not decrypt transaction data. Please try again later.';
          });
          return;
        }

        // Use the decrypted JSON response
        final responseData = decryptedJson;
        List<Map<String, dynamic>> newTransactions = List<Map<String, dynamic>>.from(responseData['transactions']);
        hasMore = responseData['has_more'];
        latestTimestamp = DateTime.parse(responseData['latest_timestamp']);

        setState(() {
          if (loadMore) {
            transactions.addAll(newTransactions);
            _tileExpandedStates = List<bool>.from(_tileExpandedStates)..addAll(List<bool>.filled(newTransactions.length, false));
          } else {
            transactions = newTransactions;
            _tileExpandedStates = List<bool>.filled(newTransactions.length, false);
          }
          _loadError = false;
        });
      } else if (response.statusCode == 404) {
        print('No transactions found. Status code: 404');
        setState(() {
          _loadError = true;
          _errorMessage = 'No transactions yet.';
        });
      } else {
        print('Failed to load transactions. Status code: ${response.statusCode}');
        setState(() {
          _loadError = true;
          _errorMessage = 'Could not load transactions. Please try again later.';
        });
      }
    } catch (e) {
      print('Exception caught during transaction loading: $e');
      setState(() {
        _loadError = true;
        _errorMessage = 'Could not load transactions. Please check your connection.';
      });
    } finally {
      if (loadMore) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      setState(() {
        _isReloading = false;
        _isLoadingInitial = false;
      });
    }
  }


  Future<void> _reloadPage() async {
    setState(() {
      _loadError = false;
      _errorMessage = '';
      _isReloading = true;
    });
    _initializeTimeZone();
    await _loadTransactions(DateTime.parse(currentTimestamp), loadMore: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _reloadPage,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingMore && hasMore && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadMoreTransactions();
          }
          return false;
        },
        child: ListView(
          children: [
            if (_isLoadingInitial)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (_loadError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _errorMessage == 'No transactions yet.' ? Icons.info_outline : Icons.warning,
                      color: Colors.black54,
                      size: 40.0,
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Aeonik',
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _isReloading ? null : _reloadPage,
                      child: _isReloading
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Text('Retry'),
                        ],
                      )
                          : Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (transactions.isEmpty && !_isLoadingMore)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.black54,
                        size: 40.0,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'No transactions yet.',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Aeonik',
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _isReloading ? null : _reloadPage,
                        child: _isReloading
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8.0),
                            Text('Retry'),
                          ],
                        )
                            : Text('Retry'),
                      ),
                    ],
                  ),
                )
              else ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent transactions:',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Aeonik',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: EdgeInsets.symmetric(vertical: 4.0),
                        child: ExpansionTile(
                          key: PageStorageKey<int>(index),
                          onExpansionChanged: (bool expanded) {
                            if (expanded) {
                              setState(() {
                                for (int i = 0; i < _tileExpandedStates.length; i++) {
                                  _tileExpandedStates[i] = i == index;
                                }
                              });
                            }
                          },
                          initiallyExpanded: _tileExpandedStates.length > index ? _tileExpandedStates[index] : false,
                          title: Text(
                            transaction['transaction_place'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Aeonik',
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            transaction['transaction_date'] != null ? DateFormat('E, d MMM HH:mm').format(DateTime.parse(transaction['transaction_date']).toLocal()) : 'Unknown',
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Aeonik',
                              color: Colors.black54,
                            ),
                          ),
                          trailing: Text(
                            '\$${transaction['transaction_sum'] ?? 0.0}',
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Aeonik',
                              color: Colors.black,
                            ),
                          ),
                          children: <Widget>[
                            ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _parseItems(transaction['items'] ?? ''),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (_isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (!hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'You have reached the end',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Aeonik',
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                ],
          ],
        ),
      ),
    );
  }

  List<Widget> _parseItems(String itemsString) {
    if (itemsString.isEmpty) {
      return [
        Text(
          'No items',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Aeonik',
            color: Colors.black54,
          ),
        )
      ];
    }
    List<Widget> itemWidgets = [];
    final items = itemsString.split(', ');
    for (var item in items) {
      final matches = RegExp(r'\{(.*?)\}\{(.*?)\}').firstMatch(item);
      if (matches != null && matches.groupCount == 2) {
        final itemName = matches.group(1) ?? '';
        final itemPrice = matches.group(2) ?? '';
        itemWidgets.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              itemName,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Aeonik',
                color: Colors.black54,
              ),
            ),
            Text(
              '\$$itemPrice',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Aeonik',
                color: Colors.black54,
              ),
            ),
          ],
        ));
      }
    }
    return itemWidgets;
  }

  Future<void> _loadMoreTransactions() async {
    if (latestTimestamp != null && hasMore) {
      await _loadTransactions(latestTimestamp, loadMore: true);
    }
  }
}
