import "package:intl/intl.dart";

final _dateFormat = DateFormat("dd/MM/yyyy");
final _monthFormat = DateFormat("MMMM yyyy", "pt_BR");

String formatMoney(num value, {bool withSymbol = true, String symbol = "R\$"}) {
  final format = withSymbol
      ? NumberFormat.currency(locale: "pt_BR", symbol: symbol)
      : NumberFormat.currency(locale: "pt_BR", symbol: "");

  final formatted = format.format(value);
  return withSymbol ? formatted : formatted.trim();
}

/// Formats value strictly as "CODE 1.234,56"
String formatCurrency(double value, String currencyCode) {
  final validCode = currencyCode.isEmpty ? "BRL" : currencyCode;

  // Always use pt_BR for number format (comma decimal, dot thousand) as per App Locale
  final formatter = NumberFormat.currency(
    locale: "pt_BR",
    symbol: "",
    decimalDigits: 2,
  );

  final numberPart = formatter.format(value).trim();
  return "$validCode $numberPart";
}

String formatDate(DateTime date) => _dateFormat.format(date);

String formatMonth(DateTime date) => _monthFormat.format(date);

double parseMoney(String value) {
  final digitsOnly = value.replaceAll(RegExp(r"[^0-9]"), "");
  if (digitsOnly.isEmpty) return 0;
  return double.parse(digitsOnly) / 100;
}
