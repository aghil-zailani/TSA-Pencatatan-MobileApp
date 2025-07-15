import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? buttonColor; // TAMBAHKAN INI
  final Color? textColor;    // TAMBAHKAN INI

  CustomButton({
    required this.onPressed,
    required this.text,
    this.buttonColor, // TAMBAHKAN INI
    this.textColor,   // TAMBAHKAN INI
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor, // Gunakan parameter warna
        foregroundColor: textColor,   // Gunakan parameter warna
        padding: EdgeInsets.symmetric(vertical: 16.0),
        textStyle: TextStyle(fontSize: 18, fontFamily: 'Poppins'), // Pastikan font Poppins di sini
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}