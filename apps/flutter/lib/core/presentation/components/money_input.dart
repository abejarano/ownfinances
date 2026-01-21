import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";

class MoneyInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? helperText;
  final bool enabled;

  const MoneyInput({
    super.key,
    required this.label,
    required this.controller,
    this.helperText,
    this.enabled = true,
  });

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late final NumberFormat _format;

  @override
  void initState() {
    super.initState();
    _format = NumberFormat.simpleCurrency(locale: "pt_BR", name: "R\$");
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [_MoneyInputFormatter(_format)],
      enabled: widget.enabled,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
      ),
    );
  }
}

class _MoneyInputFormatter extends TextInputFormatter {
  final NumberFormat format;

  _MoneyInputFormatter(this.format);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r"\D"), "");
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: "");
    }
    final value = double.parse(digitsOnly) / 100;
    final newText = format.format(value);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
