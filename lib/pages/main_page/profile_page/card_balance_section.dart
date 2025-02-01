import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pomfretcardapp/services/shared_functions.dart';
import '../../../services/showMessage.dart';

class CardBalanceSection extends StatefulWidget {
  @override
  _CardBalanceSectionState createState() => _CardBalanceSectionState();
}

class _CardBalanceSectionState extends State<CardBalanceSection> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final SharedFunctions _sharedFunctions = SharedFunctions();
  String _balanceData = '\$ • • •';
  bool _isBalanceVisible = false;
  bool _isLoading = true;
  bool _isBalanceUpdated = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      await _sharedFunctions.loadBalanceData((balance) async {
        print('Balance fetched: $balance');
        await _secureStorage.write(key: 'balance', value: balance);
        setState(() {
          if (balance == 'Error') {
            _balanceData = '\$ • • •';
            _isError = true;
          } else {
            _balanceData = '\$ ' + balance;
            _isError = false;
          }
          _isLoading = false;
          _isBalanceUpdated = true;
        });
      }, context);
    } catch (e) {
      print('Error loading balance: $e');
      setState(() {
        _balanceData = '\$ • • •';
        _isLoading = false;
        _isBalanceUpdated = false;
        _isError = true;
      });
      showMessage(context, 'Error loading balance: $e', 'error');
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    if (_isBalanceVisible) {
      setState(() {
        _isBalanceVisible = false;
        _balanceData = '\$ • • •';
      });
    } else {
      String? storedBalance = await _secureStorage.read(key: 'balance');
      setState(() {
        _isBalanceVisible = true;
        _balanceData = '\$ $storedBalance' ?? _balanceData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? theme.shadowColor.withOpacity(0.5)
                : Colors.grey.withOpacity(0.5),
            offset: Offset(0, 5),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggleBalanceVisibility,
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: theme.colorScheme.onSurface, size: 21),
                SizedBox(width: 8),
                Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Aeonik',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _toggleBalanceVisibility,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
              height: 50, // Fixed height
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isLoading
                      ? Shimmer.fromColors(
                    baseColor: Color(0xFFFFFFFF)!,
                    highlightColor: Color(0xFF272727)!,
                    child: Text(
                      '\$ • • •',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Aeonik',
                      ),
                    ),
                  )
                      : Text(
                    _isBalanceVisible ? _balanceData : '\$ • • •',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Aeonik',
                    ),
                  ),
                  Row(
                    children: [
                      if (!_isLoading)
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });
                            _loadBalance();
                          },
                        ),
                      if (!_isLoading)
                        Icon(
                          _isError ? Icons.error : Icons.check,
                          color: _isError ? Colors.red : Colors.green,
                          size: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}