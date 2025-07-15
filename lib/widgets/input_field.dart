import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final TextEditingController? controller; // Tambahkan controller

  InputField({
    required this.labelText,
    this.obscureText = false,
    this.controller, // Inisialisasi controller
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Gunakan controller
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
      obscureText: obscureText,
    );
  }
}