import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/finance_core.dart';
import 'package:mafiflow/savings_operations.dart';
import 'package:mafiflow/profile_archive.dart';

void main() {
  Map<String, dynamic> account({double opening = 200, double saved = 30}) => {
    'opening_balance': opening,
    'savings_saved': saved,
    'savings_opening': saved,
    'savings_opening_known': true,
    'savings_goal': 40.0,
    'savings_goal_base': 0.0,
    'transactions': <Map<String, dynamic>>[],
    'savings_history': <Map<String, dynamic>>[],
    'currency': 'CAD',
  };

  test('starting savings never counts as a new income', () {
    final data = account();
    final snapshot = financialSnapshot(data);
    expect(snapshot.openingBalance, 200);
    expect(snapshot.reservedSavings, 30);
    expect(snapshot.available, 170);
    expect(snapshot.totalIncome, 0);
    expect(financeContext(data), contains('30.00 CAD'));
    expect(financeContext(data), contains('when this profile was set up'));
  });

  test('transfers change reserved vs available without creating income', () {
    final data = account();
    performSavingsAction(data, SavingsAction.deposit, 10,
        at: DateTime(2026, 10, 28, 12));
    expect(financialSnapshot(data).available, 160);
    expect(data['savings_saved'], 40);
    expect(savingsGoalAchieved(data), isTrue);
    performSavingsAction(data, SavingsAction.withdraw, 5,
        at: DateTime(2026, 10, 28, 13));
    expect(financialSnapshot(data).available, 165);
    expect(data['savings_saved'], 35);
    expect(savingsGoalAchieved(data), isFalse);
    expect(financialSnapshot(data).totalIncome, 0);
  });

  test('purchase from savings counts as expense but is not double-charged', () {
    final data = account();
    performSavingsAction(data, SavingsAction.spend, 12, category: 'Comida',
        note: 'From piggy bank', at: DateTime(2026, 10, 28, 14));
    final snapshot = financialSnapshot(data,
        start: DateTime(2026, 10), end: DateTime(2026, 11));
    expect(snapshot.available, 170); // 200 - 12 expense - 18 saved
    expect(snapshot.totalExpenses, 12);
    expect(snapshot.periodExpenses, 12);
    expect(snapshot.periodSavings, -12);
    expect(snapshot.periodNet, 0);
    expect(data['savings_saved'], 18);
    expect((data['transactions'] as List).length, 1);
    expect(removeFinanceTransaction(data, 0), isTrue);
    expect(data['savings_saved'], 30);
    expect(financialSnapshot(data).available, 170);
    expect((data['transactions'] as List), isEmpty);
    expect((data['savings_history'] as List), isEmpty);
  });

  test('cannot withdraw more than saved or deposit more than available', () {
    final data = account();
    expect(() => performSavingsAction(data, SavingsAction.withdraw, 40),
        throwsA(isA<SavingsOperationException>()));
    expect(() => performSavingsAction(data, SavingsAction.deposit, 171),
        throwsA(isA<SavingsOperationException>()));
    expect(() => performSavingsAction(data, SavingsAction.deposit, -10),
        throwsA(isA<SavingsOperationException>()));
    expect(data['savings_saved'], 30);
    expect(data['savings_history'], isEmpty);
  });

  test('correction is a dated signed savings adjustment, never income', () {
    final data = account();
    correctSavingsBalance(data, 10, at: DateTime(2026, 10, 28));
    expect(data['savings_saved'], 10);
    expect(financialSnapshot(data).available, 190);
    expect((data['savings_history'] as List).single['amount'], -20);
    expect(financialSnapshot(data).totalIncome, 0);
    correctSavingsBalance(data, 10);
    expect((data['savings_history'] as List).length, 1);
    expect(() => correctSavingsBalance(data, -1),
        throwsA(isA<SavingsOperationException>()));
  });

  test('new goal resets only progress, never underlying saved money', () {
    final data = account(saved: 40);
    expect(savingsGoalAchieved(data), isTrue);
    startNewSavingsGoal(data, 50);
    expect(data['savings_saved'], 40);
    expect(savingsGoalProgress(data), 0);
    expect(savingsGoalAchieved(data), isFalse);
    expect(financialSnapshot(data).available, 160);
    performSavingsAction(data, SavingsAction.deposit, 20,
        at: DateTime(2026, 10, 28));
    expect(savingsGoalProgress(data), 20);
    expect(data['savings_saved'], 60);
    expect(financialSnapshot(data).available, 140);
  });

  test('erase active profile does not modify other profiles', () {
    final defaults = account(opening: 0, saved: 0)..['setup_completed'] = false;
    final archive = ProfileArchive.fromLegacy(null, defaults);
    archive.active.data['opening_balance'] = 1000;
    archive.active.data['savings_saved'] = 50;
    final second = archive.create('Secondary', defaults);
    second.data['opening_balance'] = 200;
    second.data['savings_saved'] = 30;
    second.data['setup_completed'] = true;
    archive.resetActive(defaults);
    expect(archive.active.id, second.id);
    expect(archive.active.data['opening_balance'], 0);
    expect(archive.active.data['savings_saved'], 0);
    expect(archive.active.data['setup_completed'], false);
    archive.switchTo('profile_1');
    expect(archive.active.data['opening_balance'], 1000);
    expect(archive.active.data['savings_saved'], 50);
    final decoded = ProfileArchive.decode(archive.encode(), defaults);
    expect(decoded.profiles.length, 2);
    decoded.switchTo(second.id);
    expect(decoded.active.data['savings_saved'], 0);
  });
}
