import 'package:flutter_test/flutter_test.dart';
import 'package:iot_gardener/domain/utils/converter.dart';

void main() {
  group('Converter.toDouble', () {
    test('converts num to double', () {
      expect(Converter.toDouble(42), 42.0);
      expect(Converter.toDouble(3.5), 3.5);
    });

    test('converts parsable string to double', () {
      expect(Converter.toDouble('12.25'), 12.25);
    });

    test('returns 0 for non-parsable values', () {
      expect(Converter.toDouble('abc'), 0);
      expect(Converter.toDouble(null), 0);
      expect(Converter.toDouble({'a': 1}), 0);
    });
  });

  group('Converter.toNullableDouble', () {
    test('returns null for null and blank string', () {
      expect(Converter.toNullableDouble(null), isNull);
      expect(Converter.toNullableDouble('  '), isNull);
    });

    test('converts num and parsable string', () {
      expect(Converter.toNullableDouble(7), 7.0);
      expect(Converter.toNullableDouble('7.75'), 7.75);
    });

    test('returns null for non-parsable and unsupported', () {
      expect(Converter.toNullableDouble('bad'), isNull);
      expect(Converter.toNullableDouble([1, 2]), isNull);
    });
  });

  group('Converter.toRange', () {
    test('returns converted tuple for 2-item list', () {
      final range = Converter.toRange(['1.5', 10]);
      expect(range.$1, 1.5);
      expect(range.$2, 10.0);
    });

    test('returns null tuple for invalid values', () {
      expect(Converter.toRange([1]), (null, null));
      expect(Converter.toRange('not a list'), (null, null));
    });
  });
}
