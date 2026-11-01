import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/category_order.dart';

void main() {
  test('custom categories precede Other without changing saved IDs', () {
    expect(otherLast(['Comida', 'Otro', 'Mascotas', 'Otro']),
        ['Comida', 'Mascotas', 'Otro']);
    expect(otherLast(['Mascotas']), ['Mascotas']);
    expect(otherLast([]), isEmpty);
  });
  test('Other is last even when it is the largest chart category', () {
    final entries = <String, double>{'Comida': 5, 'Otro': 100, 'Mascotas': 10}
        .entries.toList()..sort(compareCategoryEntries);
    expect(entries.map((e) => e.key), ['Mascotas', 'Comida', 'Otro']);
  });
}
