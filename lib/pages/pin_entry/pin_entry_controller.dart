import 'package:flutter/foundation.dart';

class PinEntryController extends ChangeNotifier {
  final int pinLength;
  List<String> _enteredPin = [];

  PinEntryController({required this.pinLength});

  List<String> get enteredPin => List.unmodifiable(_enteredPin);

  bool get isPinComplete => _enteredPin.length == pinLength;

  void addDigit(String digit) {
    if (_enteredPin.length < pinLength) {
      _enteredPin.add(digit);
      notifyListeners();
    }
  }

  void removeLastDigit() {
    if (_enteredPin.isNotEmpty) {
      _enteredPin.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _enteredPin = [];
    notifyListeners();
  }
}