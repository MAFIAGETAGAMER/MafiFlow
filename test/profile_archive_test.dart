import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/profile_archive.dart';

void main() {
  const defaults = <String, dynamic>{
    'opening_balance': 0.0, 'transactions': [], 'ai_history': [],
    'ai_api_key': '', 'currency': 'USD', 'setup_completed': false,
  };

  test('legacy account survives migration intact', () {
    final raw = jsonEncode({
      'opening_balance': 340,
      'transactions': [{'date': '2026-10-25', 'amount': 12, 'type': 'Gasto'}],
      'ai_api_key': 'old-secret', 'currency': 'CAD', 'setup_completed': true,
    });
    final archive = ProfileArchive.fromLegacy(raw, defaults);
    expect(archive.profiles.length, 1);
    expect(archive.active.data['opening_balance'], 340);
    expect((archive.active.data['transactions'] as List).length, 1);
    final roundtrip = ProfileArchive.decode(archive.encode(), defaults);
    expect(roundtrip.active.data['opening_balance'], 340);
    expect(roundtrip.active.data['ai_api_key'], 'old-secret');
  });

  test('currency, balance, history and expenses are isolated by profile', () {
    final archive = ProfileArchive.fromLegacy(null, defaults);
    archive.active.data['opening_balance'] = 500;
    archive.active.data['transactions'] = [{'type': 'Gasto', 'amount': 3}];
    final created = archive.create('Cuba', defaults);
    created.data['currency'] = 'CUP';
    created.data['opening_balance'] = 20;
    created.data['ai_history'] = [{'role': 'user', 'content': 'Hi'}];
    created.data['transactions'] = [{'type': 'Gasto', 'amount': 9}];
    archive.switchTo('profile_1');
    expect(archive.active.data['opening_balance'], 500);
    expect(archive.active.data['currency'], 'USD');
    expect((archive.active.data['transactions'] as List).first['amount'], 3);
    expect(archive.active.data['ai_history'], isEmpty);
    final restored = ProfileArchive.decode(archive.encode(), defaults);
    restored.switchTo(created.id);
    expect(restored.active.data['currency'], 'CUP');
    expect((restored.active.data['transactions'] as List).first['amount'], 9);
  });

  test('exports never include API keys from any profile', () {
    final archive = ProfileArchive.fromLegacy(null, defaults);
    archive.active.data['ai_api_key'] = 'SECRET_ONE';
    archive.create('Second', defaults).data['ai_api_key'] = 'SECRET_TWO';
    final exported = archive.encode(omitSecrets: true);
    expect(exported, isNot(contains('SECRET_ONE')));
    expect(exported, isNot(contains('SECRET_TWO')));
    expect(ProfileArchive.decode(exported, defaults).profiles.length, 2);
  });

  test('only profile cannot be deleted', () {
    final archive = ProfileArchive.fromLegacy(null, defaults);
    expect(() => archive.remove('profile_1'), throwsStateError);
    archive.create('Second', defaults);
    archive.remove('profile_1');
    expect(archive.profiles.length, 1);
  });

  test('malformed archives and duplicates fail without data loss', () {
    expect(() => ProfileArchive.decode('{oops', defaults), throwsFormatException);
    final bad = jsonEncode({
      'version': 1,
      'active_profile_id': 'a',
      'profiles': [
        {'id': 'a', 'name': 'One', 'data': {}},
        {'id': 'a', 'name': 'Two', 'data': {}},
      ],
    });
    expect(() => ProfileArchive.decode(bad, defaults), throwsFormatException);
  });
}
