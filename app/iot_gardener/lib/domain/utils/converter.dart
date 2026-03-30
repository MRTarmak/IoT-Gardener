class Converter {
  static double toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static (double, double) toRange(dynamic value) {
    if (value is List && value.length == 2) {
      final start = toDouble(value[0]);
      final end = toDouble(value[1]);
      return (start, end);
    }
    return (0, 0);
  }
}
