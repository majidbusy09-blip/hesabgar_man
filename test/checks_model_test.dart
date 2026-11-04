import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/checks.dart';

void main() {
  group('BankCheck model', () {
    test('round-trip json', () {
      final c = BankCheck(
        id: 'c1',
        kind: CheckKind.received,
        amount: 1500000,
        dueDate: DateTime(2026, 11, 4, 12),
        personName: 'علی',
        status: CheckStatus.pending,
      );
      final j = c.toJson();
      final c2 = BankCheck.fromJson(j);
      expect(c2.id, 'c1');
      expect(c2.amount, 1500000);
      expect(c2.personName, 'علی');
      expect(c2.kind, CheckKind.received);
    });

    test('status labels', () {
      expect(CheckStatus.label(CheckKind.received, CheckStatus.settled),
          'وصول شد');
      expect(CheckStatus.label(CheckKind.paid, CheckStatus.settled), 'پاس شد');
    });

    test('notif ids stable distinct', () {
      final a = CheckStore.notifId('x', 0);
      final b = CheckStore.notifId('x', 1);
      expect(a, CheckStore.notifId('x', 0));
      expect(a, isNot(b));
    });
  });
}
