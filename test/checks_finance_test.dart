
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/checks.dart';

void main() {
  test('notifId stable across calls', () {
    final a = CheckStore.notifId('chk_12345', 0);
    final b = CheckStore.notifId('chk_12345', 0);
    final c = CheckStore.notifId('chk_12345', 1);
    final d = CheckStore.notifId('chk_other', 0);
    expect(a, b);
    expect(a, isNot(c));
    expect(a, isNot(d));
  });

  test('settled labels for received vs paid', () {
    expect(CheckStatus.label(CheckKind.received, CheckStatus.settled), 'وصول شد');
    expect(CheckStatus.label(CheckKind.paid, CheckStatus.settled), 'پاس شد');
  });
}
