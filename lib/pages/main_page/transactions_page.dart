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
  final ValueNotifier<ThemeMode> themeNotifier;

  TransactionPage({required this.themeNotifier});

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
      final firstName = await storage.read(key: 'first_name');
      final lastName = await storage.read(key: 'last_name');
      if (firstName != null && lastName != null && publicKey != null) {
        final response = await http.post(
          Uri.parse('${Config.schoolBackendUrl}/get_transactions'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'student_id': studentId,
            'timestamp': timestamp.toIso8601String(),
            'public_key': publicKey,
            'first_name': firstName,
            'last_name': lastName,
          }),
        );

        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);

          final encryptedData = responseBody['encrypted_data'];
          final encryptedKey = responseBody['encrypted_key'];

          if (encryptedData == null || encryptedKey == null) {
            throw Exception('Encrypted data or key is null');
          }

          final decryptedData = await decryptTransactionData(encryptedKey, encryptedData);
          if (decryptedData == null) {
            throw Exception('Decryption failed');
          }
          final decryptedJson = json.decode(utf8.decode(decryptedData));

          final transactionsData = decryptedJson['transactions'];
          final hasMore = decryptedJson['has_more'];
          final latestTimestampStr = decryptedJson['latest_timestamp'];

          if (transactionsData == null || hasMore == null || latestTimestampStr == null) {
            throw Exception('One of the expected fields is null');
          }

          List<Map<String, dynamic>> newTransactions = List<Map<String, dynamic>>.from(transactionsData);

          setState(() {
            if (loadMore) {
              transactions.addAll(newTransactions);
              _tileExpandedStates = List<bool>.from(_tileExpandedStates)..addAll(List<bool>.filled(newTransactions.length, false));
            } else {
              transactions = newTransactions;
              _tileExpandedStates = List<bool>.filled(newTransactions.length, false);
            }
            this.hasMore = hasMore;
            this.latestTimestamp = DateTime.parse(latestTimestampStr);
            _loadError = false;
          });
        } else if (response.statusCode == 404) {
          setState(() {
            _loadError = true;
            _errorMessage = 'No transactions yet.';
          });
        } else {
          setState(() {
            _loadError = true;
            _errorMessage = 'Could not load transactions. Please try again later.';
          });
        }
      } else {
        print('Error: User first name, last name, or public key not found in secure storage');
        setState(() {
          _loadError = true;
          _errorMessage = 'User first name, last name, or public key not found in secure storage';
        });
      }
    } catch (e) {
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
      ),
      body: RefreshIndicator(
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
                      SizedBox(height: 45.0),
                      Icon(
                        _errorMessage == 'No transactions yet.' ? Icons.info_outline : Icons.warning,
                        color: theme.colorScheme.onSurface,
                        size: 40.0,
                      ),
                      SizedBox(height: 15.0),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Aeonik',
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _isReloading ? null : _reloadPage,
                        child: _isReloading
                            ? CircularProgressIndicator()
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
                          color: theme.colorScheme.onSurface,
                          size: 40.0,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'No transactions yet.',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Aeonik',
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _isReloading ? null : _reloadPage,
                          child: _isReloading
                              ? CircularProgressIndicator()
                              : Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else ...[
                    SizedBox(height: 45.0),
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
                            color: theme.colorScheme.onSurface,
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
                        final locationNames = {
                          6: 'DM processing',
                          7: 'The Tuck',
                          2: 'School Store',
                          1: 'Allowance',
                        };
                        final locationName = locationNames[transaction['location']] ?? 'Unknown Location';
                        final formattedDate = DateFormat('MMM dd, HH:mm:ss').format(DateTime.parse('${transaction['qdate']} ${transaction['time']}'));

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: theme.colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
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
                                  _tileExpandedStates[index] = true;
                                });
                              } else {
                                setState(() {
                                  _tileExpandedStates[index] = false;
                                });
                              }
                            },
                            initiallyExpanded: _tileExpandedStates.length > index ? _tileExpandedStates[index] : false,
                            title: Text(
                              locationName,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Aeonik',
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Aeonik',
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            trailing: Text(
                              '\$${transaction['prices'].split(',').map((price) => double.parse(price)).reduce((a, b) => a + b).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Aeonik',
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            children: <Widget>[
                              ListTile(
                                title: Text(
                                  'Items:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Aeonik',
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _parseItems(transaction['items'], transaction['quantities'], transaction['prices']),
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
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                  ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _parseItems(String itemsString, String quantitiesString, String pricesString) {
    final theme = Theme.of(context);
    List<Widget> itemWidgets = [];
    final items = itemsString.split(',');
    final quantities = quantitiesString.split(',');
    final prices = pricesString.split(',');

    for (int i = 0; i < items.length; i++) {
      final itemName = items[i].trim();
      final itemQuantity = quantities[i].trim();
      final itemPrice = prices[i].trim();
      itemWidgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            itemName,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Aeonik',
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            '$itemQuantity x \$$itemPrice',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Aeonik',
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ));
    }
    return itemWidgets;
  }

  Future<void> _loadMoreTransactions() async {
    if (latestTimestamp != null && hasMore) {
      await _loadTransactions(latestTimestamp, loadMore: true);
    }
  }
}