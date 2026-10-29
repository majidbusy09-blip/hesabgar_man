import 'package:flutter_test/flutter_test.dart';
import 'package:hesabgar_man/features.dart';

void main() {
  group('FinanceLogic.depositSimple', () {
    test('ordinary principal and rate', () {
      final r = FinanceLogic.depositSimple(
        principal: 200000000,
        annualRatePercent: 23.5,
      );
      // yearly = 200_000_000 * 23.5 / 100
      expect(r['yearly'], 47000000);
      // daily = yearly / 365
      expect(r['daily'], closeTo(47000000 / 365, 1e-9));
      expect(r['d30'], closeTo((47000000 / 365) * 30, 1e-9));
      expect(r['d31'], closeTo((47000000 / 365) * 31, 1e-9));
    });

    test('zero principal yields zeros', () {
      final r = FinanceLogic.depositSimple(
        principal: 0,
        annualRatePercent: 20,
      );
      expect(r['yearly'], 0);
      expect(r['daily'], 0);
      expect(r['d30'], 0);
      expect(r['d31'], 0);
    });

    test('zero rate yields zero interest', () {
      final r = FinanceLogic.depositSimple(
        principal: 1000000,
        annualRatePercent: 0,
      );
      expect(r['yearly'], 0);
      expect(r['daily'], 0);
    });

    test('negative rate yields zeros per implementation', () {
      final r = FinanceLogic.depositSimple(
        principal: 1000000,
        annualRatePercent: -5,
      );
      expect(r['yearly'], 0);
    });
  });

  group('FinanceLogic.loanSummary', () {
    test('ordinary loan matches amortization', () {
      // Independent calculation: P=10_000_000, annual 18%, n=12
      const p = 10000000.0;
      const annual = 18.0;
      const months = 12;
      final monthlyRate = annual / 100 / 12;
      final factor = powFinance(1 + monthlyRate, months);
      final expectedInstallment =
          p * monthlyRate * factor / (factor - 1);
      final expectedTotal = expectedInstallment * months;
      final expectedInterest = expectedTotal - p;

      final r = FinanceLogic.loanSummary(
        principal: p,
        annualRatePercent: annual,
        months: months,
      );
      expect(r['installment']!, closeTo(expectedInstallment, 1e-6));
      expect(r['total']!, closeTo(expectedTotal, 1e-4));
      expect(r['interest']!, closeTo(expectedInterest, 1e-4));
    });

    test('zero rate divides principal by months', () {
      final r = FinanceLogic.loanSummary(
        principal: 1200000,
        annualRatePercent: 0,
        months: 12,
      );
      expect(r['installment'], 100000);
      expect(r['total'], 1200000);
      expect(r['interest'], 0);
    });

    test('invalid principal or months yields zero installment path', () {
      final a = FinanceLogic.loanSummary(
        principal: 0,
        annualRatePercent: 18,
        months: 12,
      );
      expect(a['installment'], 0);
      expect(a['total'], 0);

      final b = FinanceLogic.loanSummary(
        principal: 1000000,
        annualRatePercent: 18,
        months: 0,
      );
      expect(b['installment'], 0);
    });
  });

  group('FinanceLogic.goldPrice', () {
    test('ordinary gold breakdown', () {
      // price 1_000_000/g, weight 10g, wage 10%, profit 7%, tax 9%
      final r = FinanceLogic.goldPrice(
        pricePerGram: 1000000,
        weightGram: 10,
        wagePercent: 10,
        profitPercent: 7,
        taxPercent: 9,
      );
      expect(r['raw'], 10000000);
      expect(r['wage'], 1000000);
      expect(r['profit'], 700000);
      // tax on wage+profit only
      expect(r['tax'], 153000);
      expect(r['total'], 11853000);
    });

    test('zero weight yields zero totals', () {
      final r = FinanceLogic.goldPrice(
        pricePerGram: 1000000,
        weightGram: 0,
        wagePercent: 10,
        profitPercent: 7,
        taxPercent: 9,
      );
      expect(r['raw'], 0);
      expect(r['total'], 0);
    });

    test('zero price yields zero totals', () {
      final r = FinanceLogic.goldPrice(
        pricePerGram: 0,
        weightGram: 5,
        wagePercent: 10,
        profitPercent: 7,
        taxPercent: 9,
      );
      expect(r['raw'], 0);
      expect(r['total'], 0);
    });
  });
}

/// pow without importing dart:math in a way that shadows — use iterative
double powFinance(double base, int exp) {
  var r = 1.0;
  for (var i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}
