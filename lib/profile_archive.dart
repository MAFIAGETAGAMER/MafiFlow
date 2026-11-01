import 'dart:convert';

/// Versioned local archive. Each profile holds an independent financial ledger.
/// The pre-update `mafiflow_data` key is never deleted by migration.
class FinanceProfile {
  FinanceProfile({required this.id, required this.name, required this.data});
  final String id;
  String name;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson({bool omitSecrets = false}) {
    final values = Map<String, dynamic>.from(data);
    if (omitSecrets) values['ai_api_key'] = '';
    return {'id': id, 'name': name, 'data': values};
  }
}

class ProfileArchive {
  ProfileArchive({required this.profiles, required this.activeId});
  final List<FinanceProfile> profiles;
  String activeId;

  static Map<String, dynamic> _copy(Map<String, dynamic> data) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);

  static Map<String, dynamic> _merge(
          Map<String, dynamic> defaults, Map source) =>
      {..._copy(defaults), ..._copy(Map<String, dynamic>.from(source))};

  static ProfileArchive fromLegacy(
      String? legacy, Map<String, dynamic> defaults) {
    Map<String, dynamic> original = _copy(defaults);
    if (legacy != null && legacy.trim().isNotEmpty) {
      final parsed = jsonDecode(legacy);
      if (parsed is! Map) throw const FormatException('Invalid legacy backup');
      original = _merge(defaults, parsed);
      // Preserve the existing app's backwards-compatibility setup behavior.
      if (!parsed.containsKey('setup_completed') ||
          (parsed['setup_completed'] == true &&
              (((parsed['transactions'] is List) &&
                      (parsed['transactions'] as List).isNotEmpty) ||
                  _amount(parsed['monthly_income']) > 0 ||
                  ((parsed['monthly_payments'] is List) &&
                      (parsed['monthly_payments'] as List).isNotEmpty)))) {
        original['setup_completed'] = true;
      }
    }
    return ProfileArchive(
      profiles: [FinanceProfile(id: 'profile_1', name: 'Perfil 1', data: original)],
      activeId: 'profile_1',
    );
  }

  static double _amount(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static ProfileArchive decode(String raw, Map<String, dynamic> defaults) {
    final parsed = jsonDecode(raw);
    if (parsed is! Map || parsed['version'] != 1 || parsed['profiles'] is! List) {
      throw const FormatException('Invalid profile archive');
    }
    final entries = <FinanceProfile>[];
    final ids = <String>{};
    for (final item in parsed['profiles'] as List) {
      if (item is! Map || item['data'] is! Map || item['id'] is! String ||
          item['name'] is! String || (item['id'] as String).isEmpty ||
          (item['name'] as String).trim().isEmpty || !ids.add(item['id'] as String)) {
        throw const FormatException('Invalid or duplicate profile');
      }
      entries.add(FinanceProfile(
        id: item['id'] as String,
        name: item['name'] as String,
        data: _merge(defaults, item['data'] as Map),
      ));
    }
    final selected = parsed['active_profile_id'];
    if (entries.isEmpty || selected is! String || !ids.contains(selected)) {
      throw const FormatException('Missing active profile');
    }
    return ProfileArchive(profiles: entries, activeId: selected);
  }

  FinanceProfile get active =>
      profiles.firstWhere((profile) => profile.id == activeId);

  FinanceProfile create(String name, Map<String, dynamic> defaults) {
    final label = name.trim();
    if (label.isEmpty) throw ArgumentError('Profile name required');
    var counter = 1;
    while (profiles.any((p) => p.id == 'profile_$counter')) {counter++;}
    final created = FinanceProfile(
      id: 'profile_$counter', name: label, data: _copy(defaults),
    );
    profiles.add(created);
    activeId = created.id;
    return created;
  }

  void switchTo(String id) {
    if (!profiles.any((p) => p.id == id)) throw ArgumentError('Unknown profile');
    activeId = id;
  }

  void rename(String id, String name) {
    if (name.trim().isEmpty) throw ArgumentError('Profile name required');
    profiles.firstWhere((p) => p.id == id).name = name.trim();
  }

  void remove(String id) {
    if (profiles.length == 1) throw StateError('Last profile cannot be deleted');
    profiles.removeWhere((p) => p.id == id);
    if (activeId == id) activeId = profiles.first.id;
  }

  String encode({bool omitSecrets = false}) => jsonEncode({
    'version': 1,
    'active_profile_id': activeId,
    'profiles': profiles.map((p) => p.toJson(omitSecrets: omitSecrets)).toList(),
  });
}
