import 'package:flutter/material.dart';
import 'Spin.dart';

/// Button with loading indicator.
/// When a non-null String is passed it will be displayed.
/// When null is passed, a loading indicator is shown instead, and
///   onTap will not be called even if the button is pressed.
class ButtonWithLoading extends StatelessWidget {

  final String? msg;
  final void Function() onTap;

  ButtonWithLoading({required this.msg, required this.onTap});

  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        textStyle: MaterialStateProperty.all(
          TextStyle(
            color: Colors.white
          )
        ),
        backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
      ),
      child: msg is String
        ? Text(msg!)  // Message when provided
        : Spin(30),   // Spinner otherwise
      onPressed: msg is String
        ? onTap : null // only call onTap when not loading
    );
  }

}