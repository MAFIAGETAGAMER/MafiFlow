import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/finance_core.dart';
import 'package:mafiflow/local_advisor.dart';

void main() {
  test('opening balance counts for available but NOT monthly income', () {
    final data = <String, dynamic>{
      'opening_balance': 500, 'currency': 'CUP', 'savings_saved': 50,
      'savings_goal': 400,
      'transactions': [
        {'date': '2026-10-02 10:00:00', 'type': 'Gasto', 'amount': 25},
        {'date': '2026-10-03T10:00:00', 'type': 'Ingreso extra', 'amount': 125},
        {'date': '2026-10-04 09:00:00', 'type': 'Pago mensual', 'amount': 60},
      ],
      'savings_history': [{'date': '2026-10-01', 'amount': 50}],
    };
    final result = financialSnapshot(data,
        start: DateTime(2026, 10), end: DateTime(2026, 11));
    expect(result.available, 490); // 500 + 125 - 25 - 60 - 50
    expect(result.periodIncome, 125);
    expect(result.periodExpenses, 85);
    expect(result.periodSavings, 50);
    expect(result.recurringExpenses, 60);
    expect(result.ordinaryExpenses, 25);
    expect(result.periodNet, -10);
    expect(financeContext(data, now: DateTime(2026, 10, 26)),
        contains('490.00 CUP'));
  });

  test('stats include transactions four days into the selected period', () {
    final values = financialSnapshot({
      'opening_balance': 100,
      'transactions': [
        {'date': '2026-10-22 12:00:00', 'type': 'Gasto', 'amount': 10},
        {'date': '2026-10-26 12:00:00', 'type': 'Gasto', 'amount': 5},
      ],
    }, start: DateTime(2026, 10, 22), end: DateTime(2026, 10, 27));
    expect(values.periodExpenses, 15);
    expect(values.available, 85);
  });

  test('historical month never includes next month income', () {
    final data = {'transactions': [
      {'date': '2026-09-18 09:00:00', 'type': 'Ingreso extra', 'amount': 11},
      {'date': '2026-10-05 09:00:00', 'type': 'Ingreso extra', 'amount': 22},
    ]};
    final old = financialSnapshot(data,
        start: DateTime(2026, 9), end: DateTime(2026, 10));
    expect(old.periodIncome, 11);
    expect(old.totalIncome, 33);
  });

  test('offline advisor is clearly labeled non-generative', () {
    final result = localFinancialReply({
      'opening_balance': 270,
      'currency': 'CUP',
      'transactions': [],
    }, 'es');
    expect(result, contains('sin IA generativa'));
    expect(result, contains('270.00 CUP'));
  });

  test('HTTP 403 error does not display raw HTML', () {
    expect(advisorHttpError(403, 'es'), contains('denegado'));
    expect(advisorHttpError(403, 'en'), isNot(contains('<html>')));
  });
}
