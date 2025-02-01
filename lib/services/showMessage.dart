import 'package:flutter/material.dart';

void showMessage(BuildContext context, String message, String messageType) {
  Color backgroundColor;
  Color textColor;

  switch (messageType) {
    case 'success':
      backgroundColor = Colors.green;
      textColor = Colors.black;
      break;
    case 'warning':
      backgroundColor = Colors.orange;
      textColor = Colors.black;
      break;
    case 'error':
    default:
      backgroundColor = Colors.red;
      textColor = Colors.white;
      break;
  }

  final snackBar = SnackBar(
    content: Text(
      message,
      style: TextStyle(color: textColor),
    ),
    backgroundColor: backgroundColor,
    duration: Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}