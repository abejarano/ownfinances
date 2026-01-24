import "package:intl/intl.dart";

final _dateFormat = DateFormat("dd/MM/yyyy");

String formatMoney(
  num value, {
  bool withSymbol = true,
  String symbol = "R\$",
  String? locale,
}) {
  final format = withSymbol
      ? NumberFormat.currency(locale: locale, symbol: symbol)
      : NumberFormat.currency(locale: locale, symbol: "");

  final formatted = format.format(value);
  return withSymbol ? formatted : formatted.trim();
}

/// Formats value strictly as "CODE 1.234,56"
String formatCurrency(double value, String currencyCode) {
  final validCode = currencyCode.isEmpty ? "BRL" : currencyCode;

  // Use current locale for number format
  final formatter = NumberFormat.currency(symbol: "", decimalDigits: 2);

  final numberPart = formatter.format(value).trim();
  return "$validCode $numberPart";
}

String formatDate(DateTime date) => _dateFormat.format(date);

String formatMonth(DateTime date) => DateFormat("MMMM yyyy").format(date);

double parseMoney(String value) {
  final digitsOnly = value.replaceAll(RegExp(r"[^0-9]"), "");
  if (digitsOnly.isEmpty) return 0;
  return double.parse(digitsOnly) / 100;
}
