class PdfUtils {
  PdfUtils._();

  static String formatAmount(
    dynamic amount,
    String currency,
  ) {
    if (amount == null) {
      return "0 $currency";
    }

    return "$amount $currency";
  }

  static String formatDate(
    dynamic date,
  ) {
    if (date == null) {
      return "-";
    }

    final value = DateTime.parse(
      date.toString(),
    ).toLocal();

    return "${value.day.toString().padLeft(2, '0')}/"
        "${value.month.toString().padLeft(2, '0')}/"
        "${value.year} "
        "${value.hour.toString().padLeft(2, '0')}:"
        "${value.minute.toString().padLeft(2, '0')}";
  }

  static String yesNo(
    bool value,
  ) {
    return value ? "Oui" : "Non";
  }

  static String emptyIfNull(
    dynamic value,
  ) {
    if (value == null) {
      return "-";
    }

    return value.toString();
  }
}