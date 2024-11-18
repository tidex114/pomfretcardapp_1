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
    print('Loading balance...');
    await _sharedFunctions.loadBalanceData((balance) async {
      print('Balance loaded: $balance');
      await _secureStorage.write(key: 'balance', value: balance);
      setState(() {
        _balanceData = balance;
      });
    });
  }

  Future<void> _toggleBalanceVisibility() async {
    print('Toggling balance visibility...');
    if (_isBalanceVisible) {
      print('Hiding balance');
      setState(() {
        _isBalanceVisible = false;
        _balanceData = '\$ • • •';
      });
    } else {
      print('Showing balance');
      String? storedBalance = await _secureStorage.read(key: 'balance');
      print('Stored balance: $storedBalance');
      setState(() {
        _isBalanceVisible = true;
        _balanceData = storedBalance ?? _balanceData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 5),
            blurRadius: 10,
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
                  color: Colors.black,
                  fontFamily: 'Aeonik'),
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _toggleBalanceVisibility,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: Color(0xFFE6E7EB),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isBalanceVisible ? _balanceData :'\$ • • •',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Aeonik'),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: Colors.redAccent,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
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
