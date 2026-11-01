import 'dart:math';
import 'finance_core.dart';

/// Mutates only the selected profile's data map. Compatible with v1 backups.
/// Positive history amounts reserve money; negative amounts release money.
enum SavingsAction { deposit, withdraw, spend }

class SavingsOperationException implements Exception {
  SavingsOperationException(this.reason);
  final String reason;
  @override String toString() => reason;
}

double savingsGoalProgress(Map<String, dynamic> data) =>
    max(0.0, financeAmount(data['savings_saved']) -
        financeAmount(data['savings_goal_base']));

bool savingsGoalAchieved(Map<String, dynamic> data) {
  final target = financeAmount(data['savings_goal']);
  return target > 0 && savingsGoalProgress(data) + 0.000001 >= target;
}

String _entryId(DateTime now) =>
    'savings_${now.microsecondsSinceEpoch}';

void _validateAmount(double amount) {
  if (!amount.isFinite || amount <= 0) {
    throw SavingsOperationException('invalid_amount');
  }
}

void performSavingsAction(Map<String, dynamic> data, SavingsAction action,
    double amount, {String category = 'Otro', String note = '', DateTime? at}) {
  _validateAmount(amount);
  final date = at ?? DateTime.now();
  final reserved = financeAmount(data['savings_saved']);
  final available = financialSnapshot(data).available;
  if (action == SavingsAction.deposit && amount > available + 0.000001) {
    throw SavingsOperationException('not_enough_available');
  }
  if (action != SavingsAction.deposit && amount > reserved + 0.000001) {
    throw SavingsOperationException('not_enough_savings');
  }
  final delta = action == SavingsAction.deposit ? amount : -amount;
  final id = _entryId(date);
  final history = financeRecords(data['savings_history']);
  history.add({'id': id, 'date': date.toIso8601String(),
    'amount': delta, 'kind': action.name, 'note': note});
  data['savings_history'] = history;
  data['savings_saved'] = max(0.0, reserved + delta);
  if (action == SavingsAction.spend) {
    final transactions = financeRecords(data['transactions']);
    transactions.add({'id': 'expense_$id', 'date': date.toIso8601String(),
      'type': 'Gasto', 'category': category, 'amount': amount,
      'note': note, 'fund_source': 'savings', 'savings_entry_id': id});
    data['transactions'] = transactions;
  }
}

/// Replace the saved amount to correct mistaken entry, without new income/expense.
/// A signed correction event makes historical stats reconcile correctly.
void correctSavingsBalance(Map<String, dynamic> data, double corrected,
    {DateTime? at}) {
  if (!corrected.isFinite || corrected < 0) {
    throw SavingsOperationException('invalid_amount');
  }
  final previous = financeAmount(data['savings_saved']);
  final delta = corrected - previous;
  if (delta.abs() < 0.000001) return;
  final now = at ?? DateTime.now();
  final history = financeRecords(data['savings_history']);
  history.add({'id': _entryId(now), 'date': now.toIso8601String(),
    'amount': delta, 'kind': 'correction'});
  data['savings_history'] = history;
  data['savings_saved'] = corrected;
}

/// Re-start only the *goal progress*. Previously accumulated savings remain
/// reserved and continue to count against available spendable funds.
void startNewSavingsGoal(Map<String, dynamic> data, double newTarget) {
  _validateAmount(newTarget);
  data['savings_goal_base'] = financeAmount(data['savings_saved']);
  data['savings_goal'] = newTarget;
  // The next month's normal deposit can start against the new target.
}

/// Delete a purchase once, restoring reserved funds if it was paid from savings.
/// Returns false for an invalid index and leaves the profile untouched.
bool removeFinanceTransaction(Map<String, dynamic> data, int index) {
  final transactions = financeRecords(data['transactions']);
  if (index < 0 || index >= transactions.length) return false;
  final entry = transactions[index];
  final linked = entry['savings_entry_id'];
  if (linked is String && linked.isNotEmpty) {
    final history = financeRecords(data['savings_history']);
    final position = history.indexWhere((item) => item['id'] == linked);
    if (position < 0) {
      throw SavingsOperationException('missing_savings_record');
    }
    final delta = financeAmount(history[position]['amount']);
    data['savings_saved'] = max(0.0,
        financeAmount(data['savings_saved']) - delta);
    history.removeAt(position);
    data['savings_history'] = history;
  }
  transactions.removeAt(index);
  data['transactions'] = transactions;
  return true;
}
