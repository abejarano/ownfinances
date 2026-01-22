import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:intl/intl.dart";

class MoneyInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? helperText;
  final bool enabled;
  final String currencySymbol;

  const MoneyInput({
    super.key,
    required this.label,
    required this.controller,
    this.helperText,
    this.enabled = true,
    this.currencySymbol = "R\$",
  });

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late NumberFormat _format;

  @override
  void initState() {
    super.initState();
    _updateFormat();
  }

  @override
  void didUpdateWidget(MoneyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currencySymbol != widget.currencySymbol) {
      _updateFormat();
    }
  }

  void _updateFormat() {
    // simpleCurrency uses the 'name' property as the currency symbol if provided.
    // We keep pt_BR locale for comma/dot formatting but change the symbol.
    _format = NumberFormat.simpleCurrency(
      locale: "pt_BR",
      name: widget.currencySymbol,
    );
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
