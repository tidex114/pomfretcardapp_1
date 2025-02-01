import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

import 'package:pomfretcardapp/pages/config.dart';
import 'package:pomfretcardapp/services/decryption_service.dart';
import 'package:pomfretcardapp/services/refresh_access_token.dart';
import 'package:pomfretcardapp/services/showMessage.dart'; // your showMessage function

class TransactionPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  TransactionPage({required this.themeNotifier});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with AutomaticKeepAliveClientMixin<TransactionPage> {
  // -- Data & State --
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String? studentId;
  List<Map<String, dynamic>> transactions = [];
  List<bool> _tileExpandedStates = [];
  DateTime latestTimestamp = DateTime.now();
  bool hasMore = true;

  // -- Loading states --
  bool _isLoadingInitial = true;  // true = show shimmer until fetch completes
  bool _isLoadingMore = false;    // loading additional data at end of list
  bool _isReloading = false;      // user pulling down to refresh
  bool _loadError = false;        // track if an error happened (snack bar shown)

  // -- Timestamp for requests --
  String currentTimestamp =
  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTimeZone();
    _loadStudentId(); // Kicks off the initial fetch
  }

  // -------------------------------------------
  // Time Zone Initialization
  // -------------------------------------------
  void _initializeTimeZone() {
    try {
      tz.initializeTimeZones();
      final location = tz.getLocation('America/New_York');
      DateTime ctTime = tz.TZDateTime.now(location);
      currentTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(ctTime);
    } catch (e) {
      _loadError = true;
      showMessage(
        context,
        'Could not initialize time zone. Please try again later.',
        'error',
      );
    }
  }

  // -------------------------------------------
  // Load Student ID
  // -------------------------------------------
  Future<void> _loadStudentId() async {
    try {
      studentId = await storage.read(key: 'barcode_data');
      if (studentId == null) {
        _loadError = true;
        showMessage(context, 'No student ID found in storage', 'error');
      } else {
        // If student ID is found, go fetch transactions
        await _loadInitialTransactions();
      }
    } catch (e) {
      _loadError = true;
      showMessage(
        context,
        'Could not load student ID. Please check your connection.',
        'error',
      );
    } finally {
      // We set _isLoadingInitial = false in _loadInitialTransactions()
      // so that shimmer remains until the first load completes.
    }
  }

  // -------------------------------------------
  // Load Initial Transactions
  // -------------------------------------------
  Future<void> _loadInitialTransactions() async {
    print('[_loadInitialTransactions] Starting...');

    // Artificial delay: wait 2 seconds to show shimmer long enough
    await Future.delayed(const Duration(seconds: 2));

    // Now load the transactions
    await _loadTransactions(DateTime.parse(currentTimestamp), loadMore: false);

    setState(() {
      _isLoadingInitial = false;
      print('[_loadInitialTransactions] Done. Shimmer set to false.');
    });
  }


  // -------------------------------------------
  // Load Transactions (Core network logic)
  // -------------------------------------------
  Future<void> _loadTransactions(DateTime timestamp, {bool loadMore = false}) async {
    if (studentId == null) {
      print('[Error] Student ID is null. Exiting _loadTransactions.');
      return;
    }

    try {
      if (loadMore) {
        setState(() {
          _isLoadingMore = true;
        });
      }

      final accessToken = await storage.read(key: 'access_token');
      final publicKey = await storage.read(key: 'public_key');
      final firstName = await storage.read(key: 'first_name');
      final lastName = await storage.read(key: 'last_name');
      final uid = await storage.read(key: 'uid');

      if (accessToken == null ||
          publicKey == null ||
          firstName == null ||
          lastName == null ||
          uid == null) {
        _loadError = true;
        showMessage(
          context,
          'Required user data not found in secure storage',
          'error',
        );
        return;
      }

      print('[_loadTransactions] about to fetch transactions. loadMore=$loadMore, isLoadingInitial=$_isLoadingInitial');

      // -- Perform network request with a 10-second timeout --
      final response = await http
          .post(
        Uri.parse('${Config.schoolBackendUrl}/get_transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'student_id': studentId,
          'timestamp': timestamp.toIso8601String(),
          'public_key': publicKey,
          'first_name': firstName,
          'last_name': lastName,
          'uid': uid,
        }),
      )
          .timeout(const Duration(seconds: 10)); // 10-second timeout

      // -- Handle the response --
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final encryptedData = responseBody['encrypted_data'];
        final encryptedKey = responseBody['encrypted_key'];

        if (encryptedData == null || encryptedKey == null) {
          throw Exception('Encrypted data or key is null');
        }

        final decryptedData =
        await decryptTransactionData(encryptedKey, encryptedData);
        if (decryptedData == null) {
          throw Exception('Decryption failed');
        }

        final decryptedJson = json.decode(utf8.decode(decryptedData));
        final transactionsData = decryptedJson['transactions'];
        final hasMoreResult = decryptedJson['has_more'];
        final latestTimestampStr = decryptedJson['latest_timestamp'];

        if (transactionsData == null ||
            hasMoreResult == null ||
            latestTimestampStr == null) {
          throw Exception('One of the expected fields is null');
        }

        List<Map<String, dynamic>> newTransactions =
        List<Map<String, dynamic>>.from(transactionsData);

        setState(() {
          _loadError = false;
          hasMore = hasMoreResult;
          latestTimestamp = DateTime.parse(latestTimestampStr);

          if (loadMore) {
            transactions.addAll(newTransactions);
            _tileExpandedStates = List<bool>.from(_tileExpandedStates)
              ..addAll(List<bool>.filled(newTransactions.length, false));
          } else {
            transactions = newTransactions;
            _tileExpandedStates =
            List<bool>.filled(newTransactions.length, false);
          }
        });
      } else if (response.statusCode == 401) {
        // Unauthorized
        final reason =
        int.parse(json.decode(response.body)["reason_code"].toString());
        if (reason == 5) {
          // Attempt token refresh
          await AuthService().refreshAccessToken(() async {
            await _loadTransactions(timestamp, loadMore: loadMore);
          }, context);
        } else {
          _loadError = true;
          showMessage(context, 'Unauthorized access', 'error');
        }
      } else {
        // Some other error
        _loadError = true;
        showMessage(
          context,
          'Could not load transactions. Please try again later.',
          'error',
        );
      }
    } on TimeoutException {
      // We specifically caught a timeout
      _loadError = true;
      showMessage(context, 'Connection timed out. Please try again.', 'error');
    } catch (e) {
      // Other exceptions
      _loadError = true;
      showMessage(
        context,
        'Could not load transactions. Please check your connection.',
        'error',
      );
    } finally {
      if (loadMore) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      setState(() {
        _isReloading = false;
      });
    }
  }

  // -------------------------------------------
  // Pull-to-refresh
  // -------------------------------------------
  Future<void> _reloadPage() async {
    print('[_reloadPage] Called. Setting shimmer to true.');
    setState(() {
      _isReloading = true;
      _isLoadingInitial = true;
      transactions.clear();
      _tileExpandedStates = []; // Instead of _tileExpandedStates.clear();
    });

    // Re-init the time zone so we refresh currentTimestamp
    _initializeTimeZone();

    await _loadTransactions(DateTime.parse(currentTimestamp), loadMore: false);

    // Once done, hide the shimmer again
    setState(() {
      _isLoadingInitial = false;
      print('[_reloadPage] Reload done. Shimmer set to false.');
    });
  }

  // -------------------------------------------
  // Infinite Scroll: Load More
  // -------------------------------------------
  Future<void> _loadMoreTransactions() async {
    if (hasMore) {
      await _loadTransactions(latestTimestamp, loadMore: true);
    }
  }

  // -------------------------------------------
  // Building the UI
  // -------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      // We keep the RefreshIndicator so user can pull-to-refresh at any time
      body: RefreshIndicator(
        onRefresh: _reloadPage,
        child: _buildTransactionList(),
      ),
    );
  }

  /// The main list, which includes "Recent transactions:" at all times,
  /// plus either the shimmer placeholders or the real items.
  Widget _buildTransactionList() {
    final theme = Theme.of(context);

    print('[_buildTransactionList] isLoadingInitial=$_isLoadingInitial');

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Load more when scrolled to the bottom
        if (!_isLoadingMore &&
            hasMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreTransactions();
        }
        return false;
      },
      child: ListView(
        children: [
          const SizedBox(height: 45.0),
          // Always show this label:
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          const SizedBox(height: 8.0),

          // If we're in the *initial* load, show the shimmer placeholders:
          if (_isLoadingInitial) ...[
            _buildShimmerLoadingScreen(theme),
          ] else ...[
            // Otherwise, show actual transactions or "No transactions yet."
            if (transactions.isEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No transactions yet.',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Aeonik',
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              // Show actual transactions
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final locationNames = {
                    6: 'DM processing',
                    7: 'The Tuck',
                    2: 'School Store',
                    1: 'Allowance',
                  };
                  final locationName =
                      locationNames[transaction['location']] ??
                          'Unknown Location';
                  final qdate = transaction['qdate'] ?? '';
                  final timeStr = transaction['time'] ?? '';
                  final fullDateStr = '$qdate $timeStr';

                  DateTime parsedDate;
                  try {
                    parsedDate = DateTime.parse(fullDateStr);
                  } catch (_) {
                    // fallback if parsing fails
                    parsedDate = DateTime.now();
                  }

                  final formattedDate =
                  DateFormat('MMM dd, HH:mm:ss').format(parsedDate);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey<int>(index),
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _tileExpandedStates[index] = expanded;
                        });
                      },
                      initiallyExpanded: _tileExpandedStates.length > index
                          ? _tileExpandedStates[index]
                          : false,
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
                        _getTransactionTotal(transaction['prices']),
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
                            children: _parseItems(
                              transaction['items'] ?? '',
                              transaction['quantities'] ?? '',
                              transaction['prices'] ?? '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            // Show "loading more" indicator at the bottom
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            // End-of-list indicator
            if (!hasMore && transactions.isNotEmpty)
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
    );
  }

  /// 9 Shimmer Skeleton Tiles with more obvious colors
  Widget _buildShimmerLoadingScreen(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              /// Use the requested colors here
              baseColor: const Color(0xFFFFFFFF),   // pure white
              highlightColor: const Color(0xFF444444), // a lighter gray than #272727

              period: const Duration(milliseconds: 1500), // speed of the shimmer
              child: Container(
                height: 70, // same height as a typical transaction tile
              ),
            ),
          );
        },
      ),
    );
  }




  // -------------------------------------------
  // Utility: Parse items / quantities / prices
  // -------------------------------------------
  List<Widget> _parseItems(
      String itemsString,
      String quantitiesString,
      String pricesString,
      ) {
    final theme = Theme.of(context);
    List<Widget> itemWidgets = [];

    final items = itemsString.split(',');
    final quantities = quantitiesString.split(',');
    final prices = pricesString.split(',');

    for (int i = 0; i < items.length; i++) {
      final itemName = items[i].trim();
      final itemQuantity = (i < quantities.length) ? quantities[i].trim() : '1';
      final itemPrice = (i < prices.length) ? prices[i].trim() : '0.00';

      itemWidgets.add(
        Row(
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
        ),
      );
    }
    return itemWidgets;
  }

  // -------------------------------------------
  // Utility: Get total from 'prices' string
  // -------------------------------------------
  String _getTransactionTotal(String pricesString) {
    try {
      final prices = pricesString.split(',');
      final total = prices.map((p) => double.parse(p)).reduce((a, b) => a + b);
      return '\$${total.toStringAsFixed(2)}';
    } catch (e) {
      return '\$0.00';
    }
  }
}
