import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPFields extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const OTPFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (i) {
        return SizedBox(
          width: 45,
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(counterText: ''),
            onChanged: (v) {
              if (v.isNotEmpty && i < controllers.length - 1) {
                FocusScope.of(context).requestFocus(focusNodes[i + 1]);
              }
              if (v.isEmpty && i > 0) {
                FocusScope.of(context).requestFocus(focusNodes[i - 1]);
              }
            },
          ),
        );
      }),
    );
  }
}
