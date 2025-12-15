import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInput extends StatelessWidget {
  final TextEditingController controller;

  const PhoneInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 10,
      decoration: const InputDecoration(
        prefixText: '+977 ',
        labelText: 'Phone (10 digits)',
        hintText: '9841000000',
        border: OutlineInputBorder(),
      ),
    );
  }
}
