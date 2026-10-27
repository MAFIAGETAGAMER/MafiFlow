import 'dart:math';

double financeAmount(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse('$value') ?? 0.0;

List<Map<String, dynamic>> financeRecords(dynamic value) => value is List
    ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
    : [];

/// Accept ISO 8601 timestamps and historical SQLite-style dates saved by the app.
DateTime? financeDate(dynamic raw) {
  if (raw == null) return null;
  final text = '$raw'.trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

bool _isIncome(dynamic type) => type == 'Ingreso mensual' || type == 'Ingreso extra';
bool _isExpense(dynamic type) => type == 'Gasto' || type == 'Pago mensual';

class FinancialSnapshot {
  const FinancialSnapshot({
    required this.openingBalance, required this.totalIncome,
    required this.totalExpenses, required this.reservedSavings,
    required this.available, required this.periodIncome,
    required this.periodExpenses, required this.periodSavings,
    required this.recurringExpenses, required this.ordinaryExpenses,
  });
  final double openingBalance;
  final double totalIncome;
  final double totalExpenses;
  final double reservedSavings;
  final double available;
  final double periodIncome;
  final double periodExpenses;
  final double periodSavings;
  final double recurringExpenses;
  final double ordinaryExpenses;
  double get periodNet => periodIncome - periodExpenses - periodSavings;
}

FinancialSnapshot financialSnapshot(Map<String, dynamic> data,
    {DateTime? start, DateTime? end}) {
  var income = 0.0, expenses = 0.0;
  var periodIncome = 0.0, periodExpenses = 0.0;
  var recurring = 0.0, ordinary = 0.0, periodSavings = 0.0;
  for (final item in financeRecords(data['transactions'])) {
    final amount = financeAmount(item['amount']);
    final type = item['type'];
    if (_isIncome(type)) income += amount;
    if (_isExpense(type)) expenses += amount;
    final date = financeDate(item['date']);
    if (date == null || (start != null && date.isBefore(start)) ||
        (end != null && !date.isBefore(end))) continue;
    if (_isIncome(type)) periodIncome += amount;
    if (_isExpense(type)) periodExpenses += amount;
    if (type == 'Pago mensual') recurring += amount;
    if (type == 'Gasto') ordinary += amount;
  }
  for (final item in financeRecords(data['savings_history'])) {
    final date = financeDate(item['date']);
    if (date == null || (start != null && date.isBefore(start)) ||
        (end != null && !date.isBefore(end))) continue;
    periodSavings += financeAmount(item['amount']);
  }
  final opening = financeAmount(data['opening_balance']);
  final reserved = max(0.0, financeAmount(data['savings_saved']));
  return FinancialSnapshot(
    openingBalance: opening, totalIncome: income, totalExpenses: expenses,
    reservedSavings: reserved, available: opening + income - expenses - reserved,
    periodIncome: periodIncome, periodExpenses: periodExpenses,
    periodSavings: periodSavings, recurringExpenses: recurring,
    ordinaryExpenses: ordinary,
  );
}

String financeContext(Map<String, dynamic> data, {DateTime? now}) {
  final date = now ?? DateTime.now();
  final start = DateTime(date.year, date.month);
  final end = DateTime(date.year, date.month + 1);
  final v = financialSnapshot(data, start: start, end: end);
  final currency = '${data['currency'] ?? 'USD'}';
  return '''Figures for ONLY the currently selected personal finance profile; currency $currency.
Starting balance (already held before the app): ${v.openingBalance.toStringAsFixed(2)} $currency (do not mistake for new income).
All-time recorded income: ${v.totalIncome.toStringAsFixed(2)} $currency.
All-time recorded expenses including recurring: ${v.totalExpenses.toStringAsFixed(2)} $currency.
Reserved savings already deducted from spendable money: ${v.reservedSavings.toStringAsFixed(2)} $currency.
CURRENT AVAILABLE BALANCE = starting balance + all-time income - all-time expenses - reserved savings = ${v.available.toStringAsFixed(2)} $currency.
Current month income: ${v.periodIncome.toStringAsFixed(2)} $currency.
Current month expenses: ${v.periodExpenses.toStringAsFixed(2)} $currency, of which recurring ${v.recurringExpenses.toStringAsFixed(2)} $currency.
Current month reserved savings: ${v.periodSavings.toStringAsFixed(2)} $currency.
Savings target: ${financeAmount(data['savings_goal']).toStringAsFixed(2)} $currency.
Do not confuse current month net flow with accumulated available balance. No live bank integration or automatic exchange rate conversion.''';
}
