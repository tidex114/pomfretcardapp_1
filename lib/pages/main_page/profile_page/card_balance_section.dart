// card_balance_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomfretcardapp/services/shared_functions.dart';

class CardBalanceSection extends StatefulWidget {
  @override
  _CardBalanceSectionState createState() => _CardBalanceSectionState();
}

class _CardBalanceSectionState extends State<CardBalanceSection> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final SharedFunctions _sharedFunctions = SharedFunctions();
  String _balanceData = '\$ • • •';
  bool _isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    await _sharedFunctions.loadBalanceData((balance) async {
      await _secureStorage.write(key: 'balance', value: balance);
      setState(() {
        _balanceData = balance;
      });
    });
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
        _balanceData = storedBalance ?? _balanceData;
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
            child: Text(
              'Balance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Aeonik',
              ),
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _toggleBalanceVisibility,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isBalanceVisible ? _balanceData : '\$ • • •',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Aeonik',
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: theme.colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.add,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
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