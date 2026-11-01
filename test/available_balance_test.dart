import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/finance_core.dart';

void main() {
  Map<String, dynamic> account() => {
    'opening_balance': 200.0, 'savings_saved': 40.0,
    'savings_goal': 100.0, 'savings_goal_base': 10.0,
    'transactions': [
      {'type': 'Ingreso extra', 'amount': 80.0},
      {'type': 'Gasto', 'amount': 30.0},
    ],
    'savings_history': [{'amount': 40.0, 'kind': 'deposit'}],
  };

  test('corrects current available money without changing savings or income', () {
    final data = account();
    final transactions = data['transactions'];
    final history = data['savings_history'];
    expect(financialSnapshot(data).available, 210);
    correctAvailableBalance(data, 125.50);
    final result = financialSnapshot(data);
    expect(result.available, closeTo(125.50, 0.000001));
    expect(result.reservedSavings, 40);
    expect(result.totalIncome, 80);
    expect(result.totalExpenses, 30);
    expect(data['transactions'], same(transactions));
    expect(data['savings_history'], same(history));
    expect(data['savings_goal_base'], 10);
    correctAvailableBalance(data, 125.50);
    expect(financialSnapshot(data).available, closeTo(125.50, 0.000001));
  });

  test('supports zero and negative current balance and rejects nonfinite input', () {
    final data = account();
    correctAvailableBalance(data, 0);
    expect(financialSnapshot(data).available, 0);
    correctAvailableBalance(data, -25);
    expect(financialSnapshot(data).available, -25);
    final base = data['opening_balance'];
    for (final invalid in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(() => correctAvailableBalance(data, invalid), throwsArgumentError);
      expect(data['opening_balance'], base);
    }
  });
}
