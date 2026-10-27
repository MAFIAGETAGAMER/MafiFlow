import 'finance_core.dart';

/// A deterministic on-device overview, NOT a generative AI model.
/// No API key, internet or external financial-data transfer is required.
String localFinancialReply(Map<String, dynamic> data, String language) {
  final now = DateTime.now();
  final metrics = financialSnapshot(data,
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1));
  final currency = '${data['currency'] ?? 'USD'}';
  String m(double value) => '${value.toStringAsFixed(2)} $currency';
  final lines = <String, List<String>>{
    'es': ['Resumen local (sin IA generativa):', 'Saldo inicial', 'Disponible ahora',
      'Ingresos de este mes', 'Gastos de este mes', 'Ahorro reservado',
      'No tengo acceso a tu banco. Estos datos provienen exclusivamente de este perfil de MafiFlow.'],
    'en': ['Local summary (not generative AI):', 'Starting balance', 'Currently available',
      'Income this month', 'Expenses this month', 'Reserved savings',
      'I cannot access your bank. These figures only use this MafiFlow profile.'],
    'fr': ['Bilan local (sans IA générative) :', 'Solde initial', 'Solde disponible',
      'Revenus du mois', 'Dépenses du mois', 'Épargne réservée',
      'Je ne peux pas accéder à votre banque. Ces données proviennent uniquement de ce profil.'],
    'de': ['Lokale Übersicht (keine generative KI):', 'Anfangssaldo', 'Aktuell verfügbar',
      'Einnahmen dieses Monats', 'Ausgaben dieses Monats', 'Zurückgelegte Ersparnisse',
      'Kein Bankzugriff. Die Zahlen stammen nur aus diesem MafiFlow-Profil.'],
    'bn': ['লোকাল সারাংশ (জেনারেটিভ এআই নয়):', 'প্রারম্ভিক ব্যালেন্স', 'বর্তমান অবশিষ্ট',
      'এই মাসের আয়', 'এই মাসের খরচ', 'সংরক্ষিত সঞ্চয়',
      'ব্যাংক অ্যাক্সেস নেই। শুধুমাত্র এই MafiFlow প্রোফাইলের তথ্য ব্যবহার করা হয়েছে।'],
  };
  final t = lines[language] ?? lines['es']!;
  return '${t[0]}\n\n${t[1]}: ${m(metrics.openingBalance)}\n'
      '${t[2]}: ${m(metrics.available)}\n'
      '${t[3]}: ${m(metrics.periodIncome)}\n'
      '${t[4]}: ${m(metrics.periodExpenses)}\n'
      '${t[5]}: ${m(metrics.reservedSavings)}\n\n${t[6]}';
}

String advisorHttpError(int status, String language) {
  const messages = {
    'es': {401: 'La clave API es inválida o ha caducado. Revisa Ajustes.',
      403: 'El proveedor ha denegado el acceso (403). Puede deberse a tu región, cuenta o permisos. Comprueba las condiciones del proveedor o utiliza el resumen local sin conexión.',
      429: 'Has alcanzado el límite de solicitudes o de crédito del proveedor.'},
    'en': {401: 'The API key is invalid or expired. Check Settings.',
      403: 'The provider denied access (403). Your region, account or permissions may be restricted. Check the provider terms or use the offline local summary.',
      429: 'The provider rate or credit limit has been reached.'},
    'fr': {401: 'Clé API invalide ou expirée. Vérifiez les paramètres.',
      403: 'Accès refusé par le fournisseur (403). Vérifiez les restrictions géographiques ou du compte, ou utilisez le bilan local hors ligne.',
      429: 'Limite de demandes ou de crédit atteinte.'},
    'de': {401: 'API-Schlüssel ungültig oder abgelaufen. Einstellungen prüfen.',
      403: 'Zugriff vom Anbieter verweigert (403). Region und Kontoberechtigungen prüfen oder lokale Offline-Übersicht verwenden.',
      429: 'Anfrage- oder Guthabenlimit beim Anbieter erreicht.'},
    'bn': {401: 'API কী ভুল বা মেয়াদোত্তীর্ণ। সেটিংস দেখুন।',
      403: 'প্রদানকারী অ্যাক্সেস অস্বীকার করেছে (403)। অঞ্চল বা অ্যাকাউন্টের শর্ত দেখুন, অথবা অফলাইন লোকাল সারাংশ ব্যবহার করুন।',
      429: 'প্রদানকারীর অনুরোধ বা ক্রেডিট সীমা শেষ।'},
  };
  final result = (messages[language] ?? messages['es']!)[status];
  if (result != null) return result;
  return {'es': 'Error del proveedor HTTP $status.',
    'en': 'Provider error HTTP $status.', 'fr': 'Erreur fournisseur HTTP $status.',
    'de': 'Anbieterfehler HTTP $status.', 'bn': 'প্রদানকারীর ত্রুটি HTTP $status.'}[language] ?? 'HTTP $status';
}
