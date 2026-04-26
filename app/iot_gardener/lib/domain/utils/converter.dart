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

  static double? toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      if (value.trim().isEmpty) return null;
      return double.tryParse(value);
    }
    return null;
  }

  static (double?, double?) toRange(dynamic value) {
    if (value is List && value.length == 2) {
      final start = toNullableDouble(value[0]);
      final end = toNullableDouble(value[1]);
      return (start, end);
    }
    return (null, null);
  }
}
