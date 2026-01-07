import "package:intl/intl.dart";

final _currencyFormat = NumberFormat.simpleCurrency(
  locale: "pt_BR",
  name: "R\$",
);
final _dateFormat = DateFormat("dd/MM/yyyy");
final _monthFormat = DateFormat("MMMM yyyy", "pt_BR");

String formatMoney(num value) => _currencyFormat.format(value);

String formatDate(DateTime date) => _dateFormat.format(date);

String formatMonth(DateTime date) => _monthFormat.format(date);

double parseMoney(String value) {
  final digitsOnly = value.replaceAll(RegExp(r"[^0-9]"), "");
  if (digitsOnly.isEmpty) return 0;
  return double.parse(digitsOnly) / 100;
}
