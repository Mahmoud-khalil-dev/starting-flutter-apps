import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/network/json_read.dart';

void main() {
  group('KIT-T9: JsonRead never throws on a wrong type', () {
    test('KIT-T9: string', () {
      expect(JsonRead.string('Dubai'), 'Dubai');
      expect(JsonRead.string('  '), isNull);
      expect(JsonRead.string(12), '12');
      expect(JsonRead.string(null), isNull);
      expect(JsonRead.string(const {'a': 1}), isNull);
    });

    test('integer', () {
      expect(JsonRead.integer(7), 7);
      expect(JsonRead.integer(7.0), 7);
      expect(JsonRead.integer(7.5), isNull);
      expect(JsonRead.integer('42'), 42);
      expect(JsonRead.integer('٤٢'), 42);
      expect(JsonRead.integer('x'), isNull);
      expect(JsonRead.integer(true), isNull);
    });

    test('boolean', () {
      expect(JsonRead.boolean(true), isTrue);
      expect(JsonRead.boolean('false'), isFalse);
      expect(JsonRead.boolean(1), isTrue);
      expect(JsonRead.boolean('yes'), isNull);
    });

    test('map and data', () {
      expect(JsonRead.map(<Object?, Object?>{1: 'a'}), {'1': 'a'});
      expect(JsonRead.map('x'), isNull);
      expect(
        JsonRead.data({
          'data': {'id': 1},
        }),
        {'id': 1},
      );
      expect(JsonRead.data({'data': 'x'}), isNull);
      expect(JsonRead.data(null), isNull);
    });
  });
}
