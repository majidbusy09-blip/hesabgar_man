import 'dart:math' as math;

class FinanceLogic {
  /// محاسبه قسط ماهانه وام (فرمول amortization)
  /// [principal] مبلغ وام
  /// [annualRatePercent] نرخ سود سالانه به درصد
  /// [months] تعداد اقساط
  static double loanInstallment({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    if (principal <= 0 || months <= 0) return 0;
    if (annualRatePercent <= 0) return principal / months;

    final r = annualRatePercent / 100 / 12;
    final factor = math.pow(1 + r, months);
    return principal * r * factor / (factor - 1);
  }

  /// مجموع پرداختی و سود وام
  static Map<String, double> loanSummary({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    final installment = loanInstallment(
      principal: principal,
      annualRatePercent: annualRatePercent,
      months: months,
    );
    final total = installment * months;
    final interest = total - principal;
    return {
      'installment': installment,
      'total': total,
      'interest': interest,
    };
  }

  /// سود مرکب سپرده
  /// [principal] مبلغ اولیه
  /// [annualRatePercent] نرخ سالانه
  /// [years] مدت به سال
  /// [compoundsPerYear] تعداد مرکب در سال (۱۲ = ماهانه)
  static double compoundInterest({
    required double principal,
    required double annualRatePercent,
    required double years,
    int compoundsPerYear = 12,
  }) {
    if (principal <= 0 || years <= 0) return principal;
    final r = annualRatePercent / 100;
    return principal *
        math.pow(1 + r / compoundsPerYear, compoundsPerYear * years);
  }

  /// مالیات بر ارزش افزوده
  /// [amount] مبلغ قبل از مالیات
  /// [vatPercent] درصد مالیات (پیش‌فرض ۹)
  static Map<String, double> vat({
    required double amount,
    double vatPercent = 9,
  }) {
    final tax = amount * vatPercent / 100;
    return {
      'tax': tax,
      'total': amount + tax,
      'net': amount,
    };
  }

  /// مبلغ بدون مالیات از مبلغ نهایی
  static Map<String, double> reverseVat({
    required double totalWithVat,
    double vatPercent = 9,
  }) {
    final net = totalWithVat / (1 + vatPercent / 100);
    final tax = totalWithVat - net;
    return {
      'tax': tax,
      'total': totalWithVat,
      'net': net,
    };
  }

  /// درصد تغییر
  static double percentChange({
    required double from,
    required double to,
  }) {
    if (from == 0) return 0;
    return ((to - from) / from) * 100;
  }

  /// چند درصد از عدد
  static double percentOf({
    required double value,
    required double percent,
  }) {
    return value * percent / 100;
  }
}
