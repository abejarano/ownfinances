class CurrencyUtils {
  static const List<String> commonCurrencies = [
    "BRL",
    "USD",
    "EUR",
    "GBP",
    "USDT",
    "COP",
  ];

  static bool isValidCurrency(String code) {
    if (commonCurrencies.contains(code)) return true;
    // Regex: 3-5 chars, uppercase, A-Z only
    return RegExp(r'^[A-Z]{3,5}$').hasMatch(code);
  }

  static String formatCurrencyLabel(String code) {
    switch (code) {
      case "BRL":
        return "R\$ (BRL)";
      case "USD":
        return "\$ (USD)";
      case "EUR":
        return "€ (EUR)";
      case "GBP":
        return "£ (GBP)";
      case "COP":
        return "COP";
      default:
        // Rule: Just Code for others/crypto, no descriptive text
        return code;
    }
  }

  static String formatCurrencyWithSymbol(String code, {required String value}) {
    // For lists chips etc
    // This is just a label helper
    return formatCurrencyLabel(code);
  }
}
