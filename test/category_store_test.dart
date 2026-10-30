import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/features.dart';

void main() {
  group('AppCategory / defaults', () {
    test('defaults include خوراک and حقوق', () {
      final names = CategoryStore.defaults.map((e) => e.name).toSet();
      expect(names.contains('خوراک'), isTrue);
      expect(names.contains('حقوق'), isTrue);
    });

    test('displayName falls back to stored string', () {
      final store = CategoryStore();
      expect(store.displayName('خوراک'), 'خوراک');
      expect(store.displayName('unknown_x'), 'unknown_x');
    });

    test('resolveId maps legacy name to builtin id', () {
      final store = CategoryStore();
      expect(store.resolveId('خوراک', isIncome: false), 'exp_food');
      expect(store.resolveId('حقوق', isIncome: true), 'inc_salary');
    });
  });

  group('Jalali date boundaries', () {
    test('round-trip preserves calendar day', () {
      final j = Jalali(1403, 1, 1);
      final back = Jalali.fromDateTime(j.toDateTime());
      expect(back.year, 1403);
      expect(back.month, 1);
      expect(back.day, 1);
    });

    test('month length farvardin is 31', () {
      expect(Jalali(1403, 1, 1).monthLength, 31);
    });
  });
}
