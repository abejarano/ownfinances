class CurrencyUtils {
  static const List<String> commonCurrencies = [
    "BRL",
    "USD",
    "EUR",
    "GBP",
    "COP",
    "ARS",
    "PYG",
    "UYU",
    "VES",
    "USDT",
  ];
  static const Map<String, String> currencyToCountry = {
    "BRL": "BR",
    "VES": "VE",
    "COP": "CO",
    "ARS": "AR",
  };

  static bool isValidCurrency(String code) {
    if (commonCurrencies.contains(code)) return true;
    // Regex: 3-5 chars, uppercase, A-Z only
    return RegExp(r'^[A-Z]{3,5}$').hasMatch(code);
  }

  static String formatCurrencyLabel(String code) {
    switch (code) {
      case "BRL":
        return "R\$ (BRL - Real Brasileiro)";
      case "USD":
        return "\$ (USD - US Dollar)";
      case "EUR":
        return "€ (EUR - Euro)";
      case "GBP":
        return "£ (GBP - Libra Esterlina)";
      case "COP":
        return "COP (Peso Colombiano)";
      case "ARS":
        return "ARS (Peso Argentino)";
      case "PYG":
        return "PYG (Guaraní)";
      case "UYU":
        return "UYU (Peso Uruguayo)";
      case "VES":
        return "VES (Bolívar Venezolano)";
      case "USDT":
        return "USDT (Tether)";
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

  static String? countryCodeForCurrency(String currency) {
    return currencyToCountry[currency];
  }
}
