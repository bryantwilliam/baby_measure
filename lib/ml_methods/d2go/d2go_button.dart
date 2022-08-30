import 'package:flutter/material.dart';

class D2GoButton extends StatelessWidget {
  const D2GoButton({Key? key, required this.onPressed, required this.text})
      : super(key: key);

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          primary: Colors.grey[300],
          elevation: 0,
        ),
      ),
    );
  }
}
