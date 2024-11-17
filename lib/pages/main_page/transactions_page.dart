// transaction_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:pomfretcardapp/pages/config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTimeZone();
    _loadStudentId();
  }

  Future<void> _loadStudentId() async {
    studentId = await storage.read(key: 'barcode_data');
    if (studentId != null) {
      _loadInitialTransactions();
    } else {
      print('No student ID found in storage');
    }
  }

  void _initializeTimeZone() {
    tz.initializeTimeZones();
    final location = tz.getLocation('America/New_York');
    DateTime ctTime = tz.TZDateTime.now(location);
    currentTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(ctTime);
    print(currentTimestamp);
  }

  Future<void> _loadInitialTransactions() async {
    await _loadTransactions(DateTime.parse(currentTimestamp), loadMore: false);
  }

  Future<void> _loadTransactions(DateTime timestamp, {bool loadMore = false}) async {
    if (studentId == null) return;

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
        final responseData = json.decode(response.body);
        List<Map<String, dynamic>> newTransactions = List<Map<String, dynamic>>.from(responseData['transactions']);
        hasMore = responseData['has_more'];
        latestTimestamp = DateTime.parse(responseData['latest_timestamp']);
        print("hasmore \$hasMore");
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
      } else {
        setState(() {
          _loadError = true;
        });
      }
    } catch (e) {
      setState(() {
        _loadError = true;
      });
    } finally {
      if (loadMore) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _reloadPage() async {
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
            if (_loadError)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      "Couldn't load transactions",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Aeonik',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            else if (transactions.isEmpty && !_isLoadingMore)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'No transactions to show',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Aeonik',
                        color: Colors.black54,
                      ),
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
