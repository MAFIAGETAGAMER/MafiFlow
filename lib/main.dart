import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const MafiFlowApp()); }
const green = Color(0xFF168657);
const expenseRed = Color(0xFFE76F6F);
const defaults = <String, dynamic>{
  'monthly_income': 0.0, 'rent': 0.0, 'savings_goal': 0.0,
  'income_frequency': 'monthly', 'income_start_date': '', 'income_processed_dates': [],
  'monthly_savings': 0.0, 'savings_saved': 0.0, 'savings_processed_months': [], 'savings_history': [],
  'transactions': [], 'monthly_payments': [], 'processed_months': [],
  'custom_categories': [], 'hidden_categories': [], 'ai_provider': 'OpenAI', 'ai_api_key': '',
  'ai_model': '', 'ai_base_url': '', 'ai_history': [], 'setup_completed': false, 'currency': 'USD', 'opening_balance': 0.0,
  'language': 'es', 'theme': 'light'
};
const labels = <String, Map<String,String>>{
  'es': {'home':'Inicio','moves':'Movimientos','monthly':'Pagos','stats':'Estadísticas','ai':'Consejero IA','settings':'Ajustes','balance':'Disponible','income':'Ingresos','expenses':'Gastos','savings':'Meta de ahorro','add':'Agregar','delete':'Eliminar','save':'Guardar','category':'Categoría','amount':'Cantidad','note':'Nota','name':'Nombre','send':'Enviar','wait':'La IA está preparando tu respuesta','providerWait':'Esperando respuesta del proveedor','noData':'Todavía no hay datos','monthIncome':'Ingreso recurrente automático','provider':'Proveedor de IA','model':'Modelo','key':'Clave API','import':'Importar JSON desde portapapeles','export':'Copiar copia de seguridad JSON','confirm':'¿Reemplazar todos los datos de este dispositivo?','yes':'Reemplazar','cancel':'Cancelar','settingsSaved':'Ajustes guardados','invalid':'Cantidad o formato no válido','type':'Tipo','extra':'Ingreso extra','expense':'Gasto','payment':'Pago recurrente','active':'Activo','paused':'Pausado','language':'Idioma','theme':'Tema','dark':'Oscuro','light':'Claro','newPayment':'Nuevo pago recurrente','noKey':'Configura tu clave API en Ajustes.','custom':'URL personalizada','goal':'Ahorro objetivo','error':'Error','loading':'Conectando','backup':'Copia de seguridad copiada (sin clave API)','imported':'Datos importados','recents':'Últimos movimientos','calculator':'Calculadora'},
  'en': {'home':'Home','moves':'Transactions','monthly':'Payments','stats':'Statistics','ai':'AI Advisor','settings':'Settings','balance':'Available','income':'Income','expenses':'Expenses','savings':'Savings goal','add':'Add','delete':'Delete','save':'Save','category':'Category','amount':'Amount','note':'Note','name':'Name','send':'Send','wait':'AI is preparing your response','providerWait':'Waiting for provider response','noData':'No data yet','monthIncome':'Automatic recurring income','provider':'AI provider','model':'Model','key':'API key','import':'Import JSON from clipboard','export':'Copy JSON backup','confirm':'Replace all data on this device?','yes':'Replace','cancel':'Cancel','settingsSaved':'Settings saved','invalid':'Invalid amount or format','type':'Type','extra':'Extra income','expense':'Expense','payment':'Recurring payment','active':'Active','paused':'Paused','language':'Language','theme':'Theme','dark':'Dark','light':'Light','newPayment':'New recurring payment','noKey':'Configure your API key in Settings.','custom':'Custom URL','goal':'Savings goal','error':'Error','loading':'Connecting','backup':'Backup copied (without API key)','imported':'Data imported','recents':'Recent transactions','calculator':'Calculator'}
};
const additionalLabels=<String,Map<String,String>>{
'fr':{'home':'Accueil','moves':'Mouvements','monthly':'Paiements','stats':'Statistiques','ai':'Conseiller IA','settings':'Paramètres','balance':'Disponible','income':'Revenus','expenses':'Dépenses','savings':'Objectif d’épargne','add':'Ajouter','delete':'Supprimer','save':'Enregistrer','category':'Catégorie','amount':'Montant','note':'Note','name':'Nom','send':'Envoyer','wait':'L’IA prépare votre réponse','providerWait':'En attente du fournisseur','noData':'Aucune donnée','monthIncome':'Revenu récurrent automatique','provider':'Fournisseur IA','model':'Modèle','key':'Clé API','import':'Importer JSON','export':'Copier la sauvegarde JSON','confirm':'Remplacer toutes les données ?','yes':'Remplacer','cancel':'Annuler','settingsSaved':'Paramètres enregistrés','invalid':'Montant invalide','type':'Type','extra':'Revenu supplémentaire','expense':'Dépense','payment':'Paiement récurrent','active':'Actif','paused':'Suspendu','language':'Langue','theme':'Thème','dark':'Sombre','light':'Clair','newPayment':'Nouveau paiement récurrent','noKey':'Configurez la clé API dans les paramètres.','custom':'URL personnalisée','goal':'Objectif d’épargne','error':'Erreur','loading':'Connexion','backup':'Sauvegarde copiée','imported':'Données importées','recents':'Dernières opérations'},
'de':{'home':'Start','moves':'Buchungen','monthly':'Zahlungen','stats':'Statistiken','ai':'KI-Berater','settings':'Einstellungen','balance':'Verfügbar','income':'Einnahmen','expenses':'Ausgaben','savings':'Sparziel','add':'Hinzufügen','delete':'Löschen','save':'Speichern','category':'Kategorie','amount':'Betrag','note':'Notiz','name':'Name','send':'Senden','wait':'KI bereitet die Antwort vor','providerWait':'Warte auf Anbieter','noData':'Noch keine Daten','monthIncome':'Automatisches wiederkehrendes Einkommen','provider':'KI-Anbieter','model':'Modell','key':'API-Schlüssel','import':'JSON importieren','export':'JSON-Sicherung kopieren','confirm':'Alle Daten ersetzen?','yes':'Ersetzen','cancel':'Abbrechen','settingsSaved':'Gespeichert','invalid':'Ungültiger Betrag','type':'Typ','extra':'Zusätzliches Einkommen','expense':'Ausgabe','payment':'Wiederkehrende Zahlung','active':'Aktiv','paused':'Pausiert','language':'Sprache','theme':'Design','dark':'Dunkel','light':'Hell','newPayment':'Neue wiederkehrende Zahlung','noKey':'API-Schlüssel in Einstellungen eintragen.','custom':'Eigene URL','goal':'Sparziel','error':'Fehler','loading':'Verbinden','backup':'Sicherung kopiert','imported':'Daten importiert','recents':'Letzte Buchungen'},
'bn':{'home':'হোম','moves':'লেনদেন','monthly':'মাসিক পেমেন্ট','stats':'পরিসংখ্যান','ai':'এআই পরামর্শক','settings':'সেটিংস','balance':'অবশিষ্ট','income':'আয়','expenses':'খরচ','savings':'সঞ্চয়ের লক্ষ্য','add':'যোগ করুন','delete':'মুছুন','save':'সংরক্ষণ','category':'বিভাগ','amount':'পরিমাণ','note':'নোট','name':'নাম','send':'পাঠান','wait':'এআই উত্তর প্রস্তুত করছে','providerWait':'সেবাদাতার উত্তরের অপেক্ষায়','noData':'কোনো তথ্য নেই','monthIncome':'নিয়মিত আয়','provider':'এআই প্রদানকারী','model':'মডেল','key':'এপিআই কী','import':'JSON আমদানি','export':'JSON ব্যাকআপ কপি','confirm':'সব তথ্য বদলাবেন?','yes':'বদলান','cancel':'বাতিল','settingsSaved':'সেটিংস সংরক্ষিত','invalid':'ভুল পরিমাণ','type':'ধরন','extra':'অতিরিক্ত আয়','expense':'খরচ','payment':'নিয়মিত পেমেন্ট','active':'সক্রিয়','paused':'বন্ধ','language':'ভাষা','theme':'থিম','dark':'ডার্ক','light':'লাইট','newPayment':'নতুন নিয়মিত পেমেন্ট','noKey':'সেটিংসে এপিআই কী দিন।','custom':'কাস্টম URL','goal':'সঞ্চয়ের লক্ষ্য','error':'ত্রুটি','loading':'সংযোগ','backup':'ব্যাকআপ কপি হয়েছে','imported':'তথ্য আমদানি হয়েছে','recents':'সাম্প্রতিক লেনদেন'}
};
const featureLabels = <String,Map<String,String>>{
  'es': {'automaticSavings': 'Ahorro mensual automático', 'chargeDay': 'Día de cobro mensual', 'chargeDayHint': 'Se descontará automáticamente en ese día de cada mes.', 'chargeDaySubtitle': 'Día {day} de cada mes', 'changeDay': 'Cambiar día', 'payAmount': 'Cantidad que recibes por pago', 'payFrequency': '¿Cada cuánto cobras?', 'freqDaily': 'Diariamente', 'freqWeekly': 'Semanalmente', 'freqBiweekly': 'Cada 2 semanas', 'freqMonthly': 'Mensualmente', 'monthlySavings': 'Ahorro mensual', 'monthlySavingsHint': 'Cada mes se reservará automáticamente esta cantidad del dinero disponible, hasta alcanzar la meta.', 'pasteJsonHint': 'Pega aquí tu copia de seguridad JSON', 'pasteClipboard': 'Pegar desde portapapeles', 'invalidBackup': 'El JSON no es válido o no contiene datos de MafiFlow.', 'importBackup': 'Importar copia de seguridad','freqTwoMonths': 'Cada 2 meses','freqThreeMonths': 'Cada 3 meses','recurringPayments': 'Pagos recurrentes','newRecurringPayment': 'Nuevo pago recurrente','paymentFrequency': '¿Cada cuánto se repite este pago?','recurringDay': 'Día del pago','recurringDayHint': 'El día elegido determina el primer vencimiento; después se repite según la frecuencia.','editSchedule': 'Editar frecuencia y día','firstPaymentDate': 'Fecha del primer pago','weeklyDateHint': 'Se repetirá cada 7 o 14 días desde esta fecha','dailyDateHint': 'Comienza hoy y se repite todos los días'},
  'en': {'automaticSavings': 'Automatic monthly savings', 'chargeDay': 'Monthly charge day', 'chargeDayHint': 'The payment will be deducted automatically on this day each month.', 'chargeDaySubtitle': 'Day {day} of each month', 'changeDay': 'Change day', 'payAmount': 'Amount received per payday', 'payFrequency': 'How often are you paid?', 'freqDaily': 'Daily', 'freqWeekly': 'Weekly', 'freqBiweekly': 'Every 2 weeks', 'freqMonthly': 'Monthly', 'monthlySavings': 'Monthly savings', 'monthlySavingsHint': 'Each month, this amount will automatically be reserved from your available balance until you reach your goal.', 'pasteJsonHint': 'Paste your JSON backup here', 'pasteClipboard': 'Paste from clipboard', 'invalidBackup': 'Invalid JSON or not a MafiFlow backup.', 'importBackup': 'Import backup','freqTwoMonths': 'Every 2 months','freqThreeMonths': 'Every 3 months','recurringPayments': 'Recurring payments','newRecurringPayment': 'New recurring payment','paymentFrequency': 'How often does this payment repeat?','recurringDay': 'Payment day','recurringDayHint': 'The selected day sets the first due date; subsequent payments follow the frequency.','editSchedule': 'Edit frequency and day','firstPaymentDate': 'First payment date','weeklyDateHint': 'Repeats every 7 or 14 days from this date','dailyDateHint': 'Starts today and repeats daily'},
  'fr': {'automaticSavings': 'Épargne mensuelle automatique', 'chargeDay': 'Jour du prélèvement mensuel', 'chargeDayHint': 'Le paiement sera prélevé automatiquement ce jour-là chaque mois.', 'chargeDaySubtitle': 'Jour {day} de chaque mois', 'changeDay': 'Modifier le jour', 'payAmount': 'Montant reçu par paie', 'payFrequency': 'À quelle fréquence êtes-vous payé ?', 'freqDaily': 'Chaque jour', 'freqWeekly': 'Chaque semaine', 'freqBiweekly': 'Toutes les 2 semaines', 'freqMonthly': 'Chaque mois', 'monthlySavings': 'Épargne mensuelle', 'monthlySavingsHint': 'Chaque mois, ce montant sera automatiquement réservé sur votre solde disponible jusqu’à atteindre votre objectif.', 'pasteJsonHint': 'Collez votre sauvegarde JSON ici', 'pasteClipboard': 'Coller depuis le presse-papiers', 'invalidBackup': 'JSON invalide ou sauvegarde MafiFlow non reconnue.', 'importBackup': 'Importer la sauvegarde','freqTwoMonths': 'Tous les 2 mois','freqThreeMonths': 'Tous les 3 mois','recurringPayments': 'Paiements récurrents','newRecurringPayment': 'Nouveau paiement récurrent','paymentFrequency': 'À quelle fréquence ce paiement se répète-t-il ?','recurringDay': 'Jour du paiement','recurringDayHint': 'Le jour choisi définit la première échéance, puis la fréquence s’applique.','editSchedule': 'Modifier la fréquence et le jour','firstPaymentDate': 'Date du premier paiement','weeklyDateHint': 'Répétition tous les 7 ou 14 jours à partir de cette date','dailyDateHint': 'Commence aujourd’hui et se répète chaque jour'},
  'de': {'automaticSavings': 'Automatisches monatliches Sparen', 'chargeDay': 'Monatlicher Abbuchungstag', 'chargeDayHint': 'Die Zahlung wird jeden Monat automatisch an diesem Tag abgebucht.', 'chargeDaySubtitle': 'Tag {day} jedes Monats', 'changeDay': 'Tag ändern', 'payAmount': 'Betrag pro Gehaltszahlung', 'payFrequency': 'Wie oft wirst du bezahlt?', 'freqDaily': 'Täglich', 'freqWeekly': 'Wöchentlich', 'freqBiweekly': 'Alle 2 Wochen', 'freqMonthly': 'Monatlich', 'monthlySavings': 'Monatlicher Sparbetrag', 'monthlySavingsHint': 'Jeden Monat wird dieser Betrag automatisch vom verfügbaren Guthaben zurückgelegt, bis das Sparziel erreicht ist.', 'pasteJsonHint': 'JSON-Sicherung hier einfügen', 'pasteClipboard': 'Aus Zwischenablage einfügen', 'invalidBackup': 'Ungültiges JSON oder keine MafiFlow-Sicherung.', 'importBackup': 'Sicherung importieren','freqTwoMonths': 'Alle 2 Monate','freqThreeMonths': 'Alle 3 Monate','recurringPayments': 'Wiederkehrende Zahlungen','newRecurringPayment': 'Neue wiederkehrende Zahlung','paymentFrequency': 'Wie oft wird diese Zahlung wiederholt?','recurringDay': 'Zahlungstag','recurringDayHint': 'Der gewählte Tag bestimmt die erste Fälligkeit; danach gilt das Intervall.','editSchedule': 'Intervall und Tag ändern','firstPaymentDate': 'Datum der ersten Zahlung','weeklyDateHint': 'Wiederholt sich ab diesem Datum alle 7 oder 14 Tage','dailyDateHint': 'Beginnt heute und wiederholt sich täglich'},
  'bn': {'automaticSavings': 'স্বয়ংক্রিয় মাসিক সঞ্চয়', 'chargeDay': 'মাসিক টাকা কাটার দিন', 'chargeDayHint': 'প্রতি মাসে এই দিনে স্বয়ংক্রিয়ভাবে টাকা কাটা হবে।', 'chargeDaySubtitle': 'প্রতি মাসের {day} তারিখ', 'changeDay': 'দিন পরিবর্তন', 'payAmount': 'প্রতি বেতনে প্রাপ্ত অর্থ', 'payFrequency': 'কত ঘন ঘন বেতন পান?', 'freqDaily': 'প্রতিদিন', 'freqWeekly': 'প্রতি সপ্তাহে', 'freqBiweekly': 'প্রতি ২ সপ্তাহে', 'freqMonthly': 'প্রতি মাসে', 'monthlySavings': 'মাসিক সঞ্চয়', 'monthlySavingsHint': 'লক্ষ্য পূরণ না হওয়া পর্যন্ত প্রতি মাসে উপলব্ধ ব্যালেন্স থেকে এই পরিমাণ স্বয়ংক্রিয়ভাবে সঞ্চয় করা হবে।', 'pasteJsonHint': 'এখানে JSON ব্যাকআপ পেস্ট করুন', 'pasteClipboard': 'ক্লিপবোর্ড থেকে পেস্ট করুন', 'invalidBackup': 'অবৈধ JSON বা MafiFlow ব্যাকআপ নয়।', 'importBackup': 'ব্যাকআপ আমদানি করুন','freqTwoMonths': 'প্রতি ২ মাসে','freqThreeMonths': 'প্রতি ৩ মাসে','recurringPayments': 'নিয়মিত পেমেন্ট','newRecurringPayment': 'নতুন নিয়মিত পেমেন্ট','paymentFrequency': 'এই পেমেন্ট কত ঘন ঘন হবে?','recurringDay': 'পেমেন্টের দিন','recurringDayHint': 'নির্বাচিত দিন প্রথম পেমেন্টের তারিখ নির্ধারণ করে; এরপর নির্ধারিত বিরতিতে হবে।','editSchedule': 'সময়সূচি ও দিন পরিবর্তন','firstPaymentDate': 'প্রথম পেমেন্টের তারিখ','weeklyDateHint': 'এই তারিখ থেকে প্রতি ৭ বা ১৪ দিনে পুনরাবৃত্তি হবে','dailyDateHint': 'আজ থেকে প্রতিদিন পুনরাবৃত্তি হবে'}
};
const improvedLabels = <String,Map<String,String>>{
'es': {'opening':'Saldo inicial','currency':'Moneda','manageCategories':'Administrar categorías','newCategory':'Nueva categoría','categoriesHint':'Elige una categoría','categoryName':'Nombre de categoría','removeCategory':'Eliminar categoría','restoreCategories':'Restablecer categorías','categoryInUse':'Esta categoría se usa en movimientos anteriores; los registros no se borrarán.','chartType':'Tipo de gráfica','distribution':'Distribución de gastos','monthlyTrend':'Comparación mensual','categoryShares':'Gastos por categoría','monthComparison':'Comparación con el mes anterior','previousMonth':'Mes anterior','currentMonth':'Mes actual','spendingChange':'Variación de gastos','incomeChange':'Variación de ingresos','noPrevious':'Sin datos del mes anterior','barChart':'Barras','pieChart':'Circular','lineChart':'Líneas','share':'del gasto','expenseCategories':'Categorías de gastos','editCategories':'Editar categorías'},
'en': {'opening':'Opening balance','currency':'Currency','manageCategories':'Manage categories','newCategory':'New category','categoriesHint':'Choose a category','categoryName':'Category name','removeCategory':'Remove category','restoreCategories':'Restore categories','categoryInUse':'Past transactions using this category will be preserved.','chartType':'Chart type','distribution':'Expense distribution','monthlyTrend':'Monthly comparison','categoryShares':'Expenses by category','monthComparison':'Compared with previous month','previousMonth':'Previous month','currentMonth':'Current month','spendingChange':'Expense change','incomeChange':'Income change','noPrevious':'No data for previous month','barChart':'Bars','pieChart':'Pie','lineChart':'Line','share':'of expenses','expenseCategories':'Expense categories','editCategories':'Edit categories'},
'fr': {'opening':'Solde initial','currency':'Devise','manageCategories':'Gérer les catégories','newCategory':'Nouvelle catégorie','categoriesHint':'Choisir une catégorie','categoryName':'Nom de catégorie','removeCategory':'Supprimer la catégorie','restoreCategories':'Réinitialiser les catégories','categoryInUse':'Les anciennes opérations seront conservées.','chartType':'Type de graphique','distribution':'Répartition des dépenses','monthlyTrend':'Comparaison mensuelle','categoryShares':'Dépenses par catégorie','monthComparison':'Par rapport au mois précédent','previousMonth':'Mois précédent','currentMonth':'Mois actuel','spendingChange':'Variation des dépenses','incomeChange':'Variation des revenus','noPrevious':'Aucune donnée du mois précédent','barChart':'Barres','pieChart':'Camembert','lineChart':'Courbe','share':'des dépenses','expenseCategories':'Catégories de dépenses','editCategories':'Modifier les catégories','calculator':'Calculatrice'},
'de': {'opening':'Anfangssaldo','currency':'Währung','manageCategories':'Kategorien verwalten','newCategory':'Neue Kategorie','categoriesHint':'Kategorie auswählen','categoryName':'Kategoriename','removeCategory':'Kategorie entfernen','restoreCategories':'Kategorien zurücksetzen','categoryInUse':'Frühere Buchungen bleiben erhalten.','chartType':'Diagrammtyp','distribution':'Ausgabenverteilung','monthlyTrend':'Monatsvergleich','categoryShares':'Ausgaben nach Kategorie','monthComparison':'Vergleich zum Vormonat','previousMonth':'Vormonat','currentMonth':'Aktueller Monat','spendingChange':'Ausgabenänderung','incomeChange':'Einnahmenänderung','noPrevious':'Keine Daten im Vormonat','barChart':'Balken','pieChart':'Kreis','lineChart':'Linie','share':'der Ausgaben','expenseCategories':'Ausgabenkategorien','editCategories':'Kategorien bearbeiten','calculator':'Rechner'},
'bn': {'opening':'প্রারম্ভিক ব্যালেন্স','currency':'মুদ্রা','manageCategories':'বিভাগ পরিচালনা','newCategory':'নতুন বিভাগ','categoriesHint':'বিভাগ বেছে নিন','categoryName':'বিভাগের নাম','removeCategory':'বিভাগ মুছুন','restoreCategories':'বিভাগ পুনরুদ্ধার','categoryInUse':'আগের লেনদেনগুলো সংরক্ষিত থাকবে।','chartType':'চার্টের ধরন','distribution':'খরচের বিভাজন','monthlyTrend':'মাসিক তুলনা','categoryShares':'বিভাগভিত্তিক খরচ','monthComparison':'আগের মাসের তুলনায়','previousMonth':'আগের মাস','currentMonth':'চলতি মাস','spendingChange':'খরচের পরিবর্তন','incomeChange':'আয়ের পরিবর্তন','noPrevious':'আগের মাসের তথ্য নেই','barChart':'বার','pieChart':'পাই','lineChart':'লাইন','share':'খরচের','expenseCategories':'খরচের বিভাগ','editCategories':'বিভাগ সম্পাদনা','calculator':'ক্যালকুলেটর'}
};
const helpLabels = <String,Map<String,String>>{
  'es': {'helpCenter': 'Centro de ayuda','reportBug': 'Reportar un error','suggestFeature': 'Sugerir una función','faq': 'Preguntas frecuentes','describeBug': 'Describe lo ocurrido','whereBug': '¿Dónde ocurrió?','sendEmail': 'Enviar por correo','emailPrivacy': 'Se abrirá tu aplicación de correo. Adjunta allí una captura si lo deseas. No incluimos datos financieros ni claves API.','emailFailed': 'No se pudo abrir el correo. Escribe a mafistudio.dev@gmail.com','faqDataQ': '¿Dónde se guardan mis datos?','faqDataA': 'En este dispositivo. Puedes exportar una copia de seguridad desde Ajustes.','faqPaymentsQ': '¿Cuándo se registran los pagos recurrentes?','faqPaymentsA': 'Al abrir MafiFlow, se registran los pagos vencidos desde la fecha de inicio seleccionada.','faqAiQ': '¿Cómo funciona el asesor de IA?','faqAiA': 'Es opcional. Necesitas configurar tu propia clave API.','faqStatsQ': '¿Las estadísticas incluyen los pagos nuevos?','faqStatsA': 'Sí. Las estadísticas utilizan los movimientos registrados, incluidos los pagos recurrentes y los ingresos automáticos.','firstPaymentDate': 'Fecha del primer pago','dateHint': 'Elige una fecha de inicio en el calendario.','describeIdea': 'Describe tu sugerencia','message': 'Escribe tu mensaje','sendSuggestion': 'Enviar sugerencia','sendReport': 'Enviar informe','helpFeedback': 'Ayuda y comentarios','emailConfirm': 'Tu mensaje se prepara en el correo; confirma el envío allí.'},
  'en': {'helpCenter': 'Help center','reportBug': 'Report a bug','suggestFeature': 'Suggest a feature','faq': 'Frequently asked questions','describeBug': 'Describe what happened','whereBug': 'Where did it happen?','sendEmail': 'Send by email','emailPrivacy': 'Your email app will open. Attach a screenshot there if you wish. Financial data and API keys are not included.','emailFailed': 'Could not open email. Write to mafistudio.dev@gmail.com','faqDataQ': 'Where is my data stored?','faqDataA': 'On this device. You can export a backup from Settings.','faqPaymentsQ': 'When are recurring payments recorded?','faqPaymentsA': 'When you open MafiFlow, due payments are recorded from the selected start date.','faqAiQ': 'How does the AI advisor work?','faqAiA': 'It is optional. You must configure your own API key.','faqStatsQ': 'Do statistics include new payments?','faqStatsA': 'Yes. Statistics use recorded transactions, including recurring payments and automatic income.','firstPaymentDate': 'First payment date','dateHint': 'Choose a start date from the calendar.','describeIdea': 'Describe your suggestion','message': 'Write your message','sendSuggestion': 'Send suggestion','sendReport': 'Send report','helpFeedback': 'Help & feedback','emailConfirm': 'Your email app prepares the message; confirm sending there.'},
  'fr': {'helpCenter': 'Centre d’aide','reportBug': 'Signaler un problème','suggestFeature': 'Suggérer une fonctionnalité','faq': 'Questions fréquentes','describeBug': 'Décrivez le problème','whereBug': 'Où est-ce arrivé ?','sendEmail': 'Envoyer par e-mail','emailPrivacy': 'Votre application e-mail va s’ouvrir. Vous pourrez joindre une capture. Aucune donnée financière ni clé API n’est incluse.','emailFailed': 'Impossible d’ouvrir l’e-mail. Écrivez à mafistudio.dev@gmail.com','faqDataQ': 'Où sont stockées mes données ?','faqDataA': 'Sur cet appareil. Exportez une sauvegarde dans les paramètres.','faqPaymentsQ': 'Quand les paiements récurrents sont-ils enregistrés ?','faqPaymentsA': 'À l’ouverture de MafiFlow, les paiements dus depuis la date choisie sont enregistrés.','faqAiQ': 'Comment fonctionne le conseiller IA ?','faqAiA': 'Il est facultatif et nécessite votre propre clé API.','faqStatsQ': 'Les statistiques incluent-elles les nouveaux paiements ?','faqStatsA': 'Oui. Elles utilisent les transactions enregistrées, y compris les paiements récurrents et les revenus automatiques.','firstPaymentDate': 'Date du premier paiement','dateHint': 'Choisissez la date de début dans le calendrier.','describeIdea': 'Décrivez votre suggestion','message': 'Écrivez votre message','sendSuggestion': 'Envoyer la suggestion','sendReport': 'Envoyer le signalement','helpFeedback': 'Aide et commentaires','emailConfirm': 'Le message sera préparé dans votre messagerie ; confirmez son envoi.'},
  'de': {'helpCenter': 'Hilfe-Center','reportBug': 'Fehler melden','suggestFeature': 'Funktion vorschlagen','faq': 'Häufige Fragen','describeBug': 'Was ist passiert?','whereBug': 'Wo ist es passiert?','sendEmail': 'Per E-Mail senden','emailPrivacy': 'Deine E-Mail-App wird geöffnet. Du kannst dort einen Screenshot anhängen. Finanzdaten und API-Schlüssel werden nicht übermittelt.','emailFailed': 'E-Mail konnte nicht geöffnet werden. Schreibe an mafistudio.dev@gmail.com','faqDataQ': 'Wo werden meine Daten gespeichert?','faqDataA': 'Auf diesem Gerät. In den Einstellungen kannst du ein Backup exportieren.','faqPaymentsQ': 'Wann werden wiederkehrende Zahlungen gebucht?','faqPaymentsA': 'Beim Öffnen von MafiFlow werden fällige Zahlungen ab dem gewählten Startdatum gebucht.','faqAiQ': 'Wie funktioniert der KI-Berater?','faqAiA': 'Er ist optional und benötigt deinen eigenen API-Schlüssel.','faqStatsQ': 'Enthalten die Statistiken neue Zahlungen?','faqStatsA': 'Ja. Die Statistik verwendet gebuchte Transaktionen, einschließlich wiederkehrender Zahlungen und automatischer Einnahmen.','firstPaymentDate': 'Datum der ersten Zahlung','dateHint': 'Wähle das Startdatum im Kalender.','describeIdea': 'Beschreibe deinen Vorschlag','message': 'Schreibe deine Nachricht','sendSuggestion': 'Vorschlag senden','sendReport': 'Fehlerbericht senden','helpFeedback': 'Hilfe und Feedback','emailConfirm': 'Die Nachricht wird in deiner E-Mail-App vorbereitet; bestätige dort den Versand.'},
  'bn': {'helpCenter': 'সহায়তা কেন্দ্র','reportBug': 'সমস্যা জানান','suggestFeature': 'নতুন ফিচারের পরামর্শ','faq': 'সাধারণ প্রশ্ন','describeBug': 'কী ঘটেছে লিখুন','whereBug': 'কোথায় ঘটেছে?','sendEmail': 'ইমেইলে পাঠান','emailPrivacy': 'ইমেইল অ্যাপ খুলবে। চাইলে সেখানে স্ক্রিনশট যোগ করুন। আর্থিক তথ্য বা API কী পাঠানো হবে না।','emailFailed': 'ইমেইল খোলা যায়নি। লিখুন: mafistudio.dev@gmail.com','faqDataQ': 'আমার তথ্য কোথায় থাকে?','faqDataA': 'এই ডিভাইসে। সেটিংস থেকে ব্যাকআপ রপ্তানি করতে পারেন।','faqPaymentsQ': 'নিয়মিত পেমেন্ট কখন যোগ হয়?','faqPaymentsA': 'MafiFlow খুললে নির্বাচিত শুরুর তারিখ থেকে বকেয়া পেমেন্ট যোগ হয়।','faqAiQ': 'AI পরামর্শক কীভাবে কাজ করে?','faqAiA': 'এটি ঐচ্ছিক। নিজের API কী দিতে হবে।','faqStatsQ': 'নতুন পেমেন্ট কি পরিসংখ্যানে আসে?','faqStatsA': 'হ্যাঁ। পরিসংখ্যান সংরক্ষিত লেনদেন, নিয়মিত পেমেন্ট ও স্বয়ংক্রিয় আয় ব্যবহার করে।','firstPaymentDate': 'প্রথম পেমেন্টের তারিখ','dateHint': 'ক্যালেন্ডার থেকে শুরুর তারিখ বেছে নিন।','describeIdea': 'আপনার পরামর্শ লিখুন','message': 'আপনার বার্তা লিখুন','sendSuggestion': 'পরামর্শ পাঠান','sendReport': 'সমস্যা পাঠান','helpFeedback': 'সহায়তা ও মতামত','emailConfirm': 'ইমেইল অ্যাপে বার্তা তৈরি হবে; সেখান থেকে পাঠানো নিশ্চিত করুন।'},
};
const categoryTranslations = <String,Map<String,String>>{
'Comida':{'es':'Comida','en':'Food','fr':'Alimentation','de':'Lebensmittel','bn':'খাবার'},
'Transporte':{'es':'Transporte','en':'Transport','fr':'Transport','de':'Transport','bn':'পরিবহন'},
'Vivienda':{'es':'Vivienda','en':'Housing','fr':'Logement','de':'Wohnen','bn':'বাসস্থান'},
'Servicios':{'es':'Servicios','en':'Utilities','fr':'Services','de':'Nebenkosten','bn':'ইউটিলিটি'},
'Salud':{'es':'Salud','en':'Health','fr':'Santé','de':'Gesundheit','bn':'স্বাস্থ্য'},
'Entretenimiento':{'es':'Entretenimiento','en':'Entertainment','fr':'Loisirs','de':'Unterhaltung','bn':'বিনোদন'},
'Compras':{'es':'Compras','en':'Shopping','fr':'Achats','de':'Einkäufe','bn':'কেনাকাটা'},
'Educación':{'es':'Educación','en':'Education','fr':'Éducation','de':'Bildung','bn':'শিক্ষা'},
'Otro':{'es':'Otro','en':'Other','fr':'Autre','de':'Sonstiges','bn':'অন্যান্য'},
'Ingreso mensual':{'es':'Ingreso mensual','en':'Monthly income','fr':'Revenu mensuel','de':'Monatseinkommen','bn':'মাসিক আয়'},
'Pago mensual':{'es':'Pago mensual','en':'Monthly payment','fr':'Paiement mensuel','de':'Monatszahlung','bn':'মাসিক পেমেন্ট'}
};
const defaultCategories=['Comida','Transporte','Vivienda','Servicios','Salud','Entretenimiento','Compras','Educación','Otro'];

String wizardFirstRecurringDate(int day,String frequency){
  final now=DateTime.now();
  final today=DateTime(now.year,now.month,now.day);
  if(frequency=='daily'||frequency=='weekly'||frequency=='biweekly')return '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
  final last=DateTime(today.year,today.month+1,0).day;
  var due=DateTime(today.year,today.month,min(day,last));
  if(due.isBefore(today)){
    final next=DateTime(today.year,today.month+1,1);
    due=DateTime(next.year,next.month,min(day,DateTime(next.year,next.month+1,0).day));
  }
  return '${due.year}-${due.month.toString().padLeft(2,'0')}-${due.day.toString().padLeft(2,'0')}';
}
String monthNow() { final d=DateTime.now(); return '${d.year}-${d.month.toString().padLeft(2,'0')}'; }
// Helpers for the statistics screen.
String monthAt(int offset) {
  final now = DateTime.now();
  final target = DateTime(now.year, now.month + offset, 1);
  return '${target.year}-${target.month.toString().padLeft(2, '0')}';
}
String previousMonth() => monthAt(-1);
String percentChange(double current, double previous) {
  if (previous == 0) return current == 0 ? '0%' : '—';
  final change = ((current - previous) / previous) * 100;
  return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
}

String stampNow() => DateTime.now().toIso8601String().replaceFirst('T',' ').substring(0,19);
double number(dynamic n) => n is num ? n.toDouble() : double.tryParse('$n') ?? 0;
String activeCurrency='USD';
String money(num v) => '${{'USD':'\$','CAD':'CA\$','EUR':'€','GBP':'£','BDT':'৳','CUP':'CUP '}[activeCurrency]??'\$'}${v.toStringAsFixed(2)}';
List<Map<String,dynamic>> records(dynamic v) => v is List ? v.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList() : [];

class MafiFlowApp extends StatefulWidget { const MafiFlowApp({super.key}); @override State<MafiFlowApp> createState()=>_MafiFlowAppState(); }
class _MafiFlowAppState extends State<MafiFlowApp> {
  final navKey=GlobalKey<NavigatorState>();
  final messengerKey=GlobalKey<ScaffoldMessengerState>();
  BuildContext get dialogContext => navKey.currentState!.context;

  Map<String,dynamic> data=Map<String,dynamic>.from(defaults);
  bool ready=false; int tab=0;
  String t(String key)=> helpLabels['${data['language']}']?[key] ?? featureLabels['${data['language']}']?[key] ?? improvedLabels['${data['language']}']?[key] ?? (additionalLabels[data['language']] ?? labels[data['language']] ?? labels['es']!)[key] ?? labels['en']![key] ?? key;
  String catName(String category)=>categoryTranslations[category]?['${data['language']}']??category;
  String transactionTitle(Map<String,dynamic> x) {
    final category='${x['category']??x['type']??''}';
    final type='${x['type']??''}';
    if(type=='Ingreso extra' && (category=='Ingreso extra'||category.isEmpty))return t('extra');
    if(type=='Ingreso mensual' && (category=='Ingreso mensual'||category.isEmpty))return t('monthIncome');
    if(type=='Pago mensual' && (category=='Pago mensual'||category.isEmpty))return t('payment');
    if(type=='Gasto' && (category=='Gasto'||category.isEmpty))return t('expense');
    return catName(category);
  }
  String transactionNote(Map<String,dynamic> x) {
    final note='${x['note']??''}';
    if(note.startsWith('Ingreso automático (') && note.endsWith(')')){
      final frequency=note.substring('Ingreso automático ('.length,note.length-1);
      final lang='${data['language']??'es'}';
      const translations={
        'es':['Ingreso automático','Diariamente','Semanalmente','Cada 2 semanas','Mensualmente'],
        'en':['Automatic income','Daily','Weekly','Every 2 weeks','Monthly'],
        'fr':['Revenu automatique','Chaque jour','Chaque semaine','Toutes les 2 semaines','Chaque mois'],
        'de':['Automatische Einnahme','Täglich','Wöchentlich','Alle 2 Wochen','Monatlich'],
        'bn':['স্বয়ংক্রিয় আয়','প্রতিদিন','প্রতি সপ্তাহে','প্রতি ২ সপ্তাহে','প্রতি মাসে']
      };
      final words=translations[lang]??translations['es']!;
      final index={'daily':1,'weekly':2,'biweekly':3,'monthly':4}[frequency];
      return '${words[0]} (${index==null?frequency:words[index]})';
    }
    if(note=='Ingreso recurrente automático')return t('monthIncome');
    return note;
  }
  List<String> get categories {final hidden=(data['hidden_categories'] as List? ?? []).map((e)=>'$e').toSet();final custom=(data['custom_categories'] as List? ?? []).map((e)=>'$e').where((e)=>e.trim().isNotEmpty);return {...defaultCategories,...custom}.where((e)=>!hidden.contains(e)).toList();}
  String chartMode='pie';
  List<Map<String,dynamic>> get tx=>records(data['transactions']);
  List<Map<String,dynamic>> get payments=>records(data['monthly_payments']);
  bool get dark=>data['theme']=='dark';
  @override void initState(){super.initState();load();}
  Future<void> load() async {final p=await SharedPreferences.getInstance(); final raw=p.getString('mafiflow_data'); if(raw!=null){try{final obj=jsonDecode(raw); if(obj is Map){data={...defaults,...Map<String,dynamic>.from(obj)}; if(!obj.containsKey('setup_completed') || (obj['setup_completed']==true && (records(obj['transactions']).isNotEmpty || number(obj['monthly_income'])>0 || records(obj['monthly_payments']).isNotEmpty))) data['setup_completed']=true;}}catch(_){}} if(data['setup_completed']==true){applyMonthly();applySavingsMonthly();} if(mounted)setState(()=>ready=true);}
  Future<void> persistWithoutRebuild() async {final p=await SharedPreferences.getInstance(); await p.setString('mafiflow_data',jsonEncode(data));}
  void refreshAfterDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }
  Future<void> save() async {
    await persistWithoutRebuild();
    if (mounted) refreshAfterDialog();
  }
  // Register income on its actual payday, independently of opening balance.
  // Monthly legacy data keeps its existing first-of-month behavior.
  void applyIncomeSchedule(){
    final amount=number(data['monthly_income']);
    if(amount<=0)return;
    final now=DateTime.now();
    final today=DateTime(now.year,now.month,now.day);
    final freq='${data['income_frequency']??'monthly'}';
    final raw='${data['income_start_date']??''}';
    DateTime start=DateTime(now.year,now.month,1);
    if(raw.isNotEmpty){
      final parsed=DateTime.tryParse(raw);
      if(parsed!=null)start=DateTime(parsed.year,parsed.month,parsed.day);
    }
    if(start.isAfter(today))return;
    final done=List<String>.from((data['income_processed_dates'] as List?)??[]);
    final seen=done.toSet();
    final list=tx;
    // Do not duplicate income from the old monthly processing system.
    final existing=list.where((x)=>x['type']=='Ingreso mensual' && x['auto_month']!=null).map((x)=>'${x['auto_month']}-01').toSet();
    DateTime cursor=start;
    int count=0;
    while(!cursor.isAfter(today) && count<3660){
      final key='${cursor.year}-${cursor.month.toString().padLeft(2,'0')}-${cursor.day.toString().padLeft(2,'0')}';
      if(!seen.contains(key) && !existing.contains(key)){
        list.add({'date':'$key 09:00:00','type':'Ingreso mensual','category':'Ingreso mensual','amount':amount,'note':'Ingreso automático ($freq)','auto_income_date':key});
        done.add(key);seen.add(key);
      }
      count++;
      if(freq=='daily'){cursor=cursor.add(const Duration(days:1));}
      else if(freq=='weekly'){cursor=cursor.add(const Duration(days:7));}
      else if(freq=='biweekly'){cursor=cursor.add(const Duration(days:14));}
      else {
        final interval=freq=='two_months'?2:freq=='three_months'?3:1;
        final nextMonth=DateTime(cursor.year,cursor.month+interval,1);
        final lastDay=DateTime(nextMonth.year,nextMonth.month+1,0).day;
        cursor=DateTime(nextMonth.year,nextMonth.month,start.day>lastDay?lastDay:start.day);
      }
    }
    data['transactions']=list;
    data['income_processed_dates']=done;
  }
  // Keep the original internal transaction type for compatibility with existing balances.
  String frequencyLabel(String freq) => t({
    'daily':'freqDaily','weekly':'freqWeekly','biweekly':'freqBiweekly',
    'monthly':'freqMonthly','two_months':'freqTwoMonths','three_months':'freqThreeMonths',
  }[freq] ?? 'freqMonthly');

  List<DropdownMenuItem<String>> frequencyOptions() => [
    for(final f in ['daily','weekly','biweekly','monthly','two_months','three_months'])
      DropdownMenuItem(value:f,child:Text(frequencyLabel(f))),
  ];

  // Calendar-month intervals stay anchored to the chosen day (29/30/31 are
  // clamped in short months); weekly intervals use 7/14 actual days.
  DateTime recurringDue(DateTime anchor,int day,String frequency,int index){
    if(frequency=='daily')return anchor.add(Duration(days:index));
    if(frequency=='weekly')return anchor.add(Duration(days:7*index));
    if(frequency=='biweekly')return anchor.add(Duration(days:14*index));
    final months=frequency=='two_months'?2:frequency=='three_months'?3:1;
    final month=DateTime(anchor.year,anchor.month+months*index,1);
    final last=DateTime(month.year,month.month+1,0).day;
    return DateTime(month.year,month.month,min(day,last));
  }

  DateTime firstRecurringDate(DateTime today,int day,String frequency){
    if(frequency=='daily'||frequency=='weekly'||frequency=='biweekly')return today;
    final last=DateTime(today.year,today.month+1,0).day;
    var candidate=DateTime(today.year,today.month,min(day,last));
    if(candidate.isBefore(today)){
      final next=DateTime(today.year,today.month+1,1);
      candidate=DateTime(next.year,next.month,min(day,DateTime(next.year,next.month+1,0).day));
    }
    return candidate;
  }

  // Each recurring bill is charged on its own selected day.
  // A payment created today starts no earlier than today, avoiding retroactive charges.
  void applyMonthly(){
    final now=DateTime.now();
    final today=DateTime(now.year,now.month,now.day);
    final list=tx;
    final bills=payments;
    bool changed=false;
    for(int i=0;i<bills.length;i++){
      final p=bills[i];
      if(p['id']==null){p['id']='bill_${DateTime.now().microsecondsSinceEpoch}_$i';changed=true;}
      final id='${p['id']}';
      final day=number(p['day']).toInt().clamp(1,31);
      if(p['day']!=day){p['day']=day;changed=true;}
      final frequency='${p['frequency']??'monthly'}';
      if(p['frequency']==null){p['frequency']='monthly';changed=true;}
      if(p['start_date']==null){
        // Legacy records have already been processed; don't charge retroactively.
        p['start_date']=dateOnly(today);changed=true;
      }
      if(p['active']==false)continue;
      final amount=number(p['amount']);
      if(amount<=0)continue;
      final rawStart=DateTime.tryParse('${p['start_date']}');
      if(rawStart==null)continue;
      final start=DateTime(rawStart.year,rawStart.month,rawStart.day);
      if(start.isAfter(today))continue;
      // Existing monthly bills keep their previous calendar-month behavior.
      // New weekly/daily bills start at the explicitly selected first due date.
      final first=frequency=='monthly'||frequency=='two_months'||frequency=='three_months'
        ? DateTime(start.year,start.month,1) : start;
      for(int n=0;n<3660;n++){
        final due=recurringDue(first,day,frequency,n);
        if(due.isAfter(today))break;
        if(due.isBefore(start))continue;
        final dueKey=dateOnly(due);
        final monthKey='${due.year}-${due.month.toString().padLeft(2,'0')}';
        final exists=list.any((x)=>x['type']=='Pago mensual' && (
          (x['auto_bill_id']==id && (x['auto_due_date']==dueKey ||
            (x['auto_due_date']==null && x['auto_month']==monthKey && frequency=='monthly'))) ||
          (frequency=='monthly' && x['auto_bill_id']==null && x['auto_month']==monthKey && x['note']=='${p['name']??''}')
        ));
        if(!exists){
          list.add({'date':'$dueKey 09:00:00','type':'Pago mensual',
            'category':'Pago mensual','amount':amount,'note':'${p['name']??''}',
            'auto_month':monthKey,'auto_due_date':dueKey,'auto_bill_id':id});
          changed=true;
        }
      }
    }
    if(changed){data['monthly_payments']=bills;data['transactions']=list;}
    applyIncomeSchedule();
    save();
  }
  String dateOnly(DateTime d)=>'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  // Reserve savings once per calendar month, without exceeding the target.
  // This is a budgeting reserve, not a real bank transfer.
  void applySavingsMonthly(){
    final month=monthNow();
    final done=List<String>.from((data['savings_processed_months'] as List?)??[]);
    if(done.contains(month))return;
    final goal=number(data['savings_goal']);
    final saved=number(data['savings_saved']);
    final monthly=number(data['monthly_savings']);
    if(goal<=0||monthly<=0||saved>=goal)return;
    final amount=min(monthly,goal-saved);
    data['savings_saved']=saved+amount;
    final history=records(data['savings_history']);
    if(!history.any((e)=>e['month']==month)){
      history.add({'month':month,'date':'$month-01','amount':amount});
      data['savings_history']=history;
    }
    data['savings_last_amount']=amount;
    data['savings_last_month']=month;
    done.add(month);
    data['savings_processed_months']=done;
    save();
  }
  double savingsForMonth(String month)=>data['savings_last_month']==month?number(data['savings_last_amount']):0;
  ({double income,double spent,double balance}) totals([String? month]) {final list=tx.where((e)=>'${e['date']??''}'.startsWith(month??monthNow()));double inc=0,spent=0;
    for(final e in list){final v=number(e['amount']);if(e['type']=='Ingreso extra'||e['type']=='Ingreso mensual'){inc+=v;}else if(e['type']=='Gasto'||e['type']=='Pago mensual'){spent+=v;}}
    // The opening balance is the real amount already owned at setup.
    // It is never an income transaction. Available balance is cumulative,
    // while income and expenses above are month-specific for statistics.
    final all=tx;
    final totalIncome=all.where((e)=>e['type']=='Ingreso mensual'||e['type']=='Ingreso extra').fold<double>(0,(sum,e)=>sum+number(e['amount']));
    final totalSpent=all.where((e)=>e['type']=='Gasto'||e['type']=='Pago mensual').fold<double>(0,(sum,e)=>sum+number(e['amount']));
    return (income:inc,spent:spent,balance:number(data['opening_balance'])+totalIncome-totalSpent-number(data['savings_saved'])); }
  void notice(String text){messengerKey.currentState?.showSnackBar(SnackBar(content:Text(text)));}
  Widget card(Widget child)=>Card(margin:const EdgeInsets.symmetric(vertical:7),child:Padding(padding:const EdgeInsets.all(16),child:child));
  Widget heading(String text)=>Padding(padding:const EdgeInsets.only(top:12,bottom:8),child:Text(text,style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:dark?Colors.white:Colors.black87)));
  @override Widget build(BuildContext context){final lang='${data['language']}';activeCurrency='${data['currency']??'USD'}';return MaterialApp(navigatorKey:navKey,scaffoldMessengerKey:messengerKey,debugShowCheckedModeBanner:false,title:'MafiFlow',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:green),useMaterial3:true),darkTheme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:green,brightness:Brightness.dark),useMaterial3:true),themeMode:dark?ThemeMode.dark:ThemeMode.light,home:!ready?const Scaffold(body:Center(child:CircularProgressIndicator())):data['setup_completed']!=true?WelcomeWizard(onComplete:(v) async {data.addAll(v);data['setup_completed']=true;applyMonthly();applySavingsMonthly();await save();}):Builder(builder:(shellContext)=>Scaffold(appBar:AppBar(title:Row(children:[Image.asset('assets/logo.png',height:34),const SizedBox(width:10),const Text('MafiFlow')]),actions:[IconButton(tooltip:t('helpCenter'),icon:const Icon(Icons.help_outline),onPressed:()=>Navigator.of(dialogContext).push(MaterialPageRoute(builder:(_)=>MafiHelpCenter(language:'${data['language']}')))),IconButton(tooltip:t('calculator'),icon:const Icon(Icons.calculate_outlined),onPressed:()=>showDialog(context:dialogContext,builder:(_)=>CalculatorDialog(title:t('calculator')))),IconButton(icon:const Icon(Icons.settings),onPressed:()=>setState(()=>tab=5))]),body:SafeArea(child:LayoutBuilder(builder:(ctx,box){final content=IndexedStack(index:tab,children:[home(),transactions(),monthly(),stats(),Advisor(data:data,lang:lang,onSave:save),settings()]);return content;})),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),labelBehavior:NavigationDestinationLabelBehavior.onlyShowSelected,destinations:[NavigationDestination(icon:const Icon(Icons.home_outlined),label:t('home')),NavigationDestination(icon:const Icon(Icons.receipt_long),label:t('moves')),NavigationDestination(icon:const Icon(Icons.event_repeat),label:t('monthly')),NavigationDestination(icon:const Icon(Icons.pie_chart_outline),label:t('stats')),NavigationDestination(icon:const Icon(Icons.smart_toy_outlined),label:t('ai')),NavigationDestination(icon:const Icon(Icons.settings_outlined),label:t('settings'))]))));}
  Widget scroll(List<Widget> widgets)=>ListView(padding:const EdgeInsets.all(16),children:widgets);
  Widget stat(String label,double value,IconData icon,Color color)=>card(Row(children:[Icon(icon,color:color),const SizedBox(width:14),Expanded(child:Text(label)),Text(money(value),style:TextStyle(fontWeight:FontWeight.bold,fontSize:19,color:color))]));
  Widget home(){
    final v=totals();
    final saved=number(data['savings_saved']);
    final goal=number(data['savings_goal']);
    final monthlySaving=number(data['monthly_savings']);
    final progress=goal>0?(saved/goal).clamp(0.0,1.0).toDouble():0.0;
    return scroll([
      heading(t('home')),
      stat(t('balance'),v.balance,Icons.account_balance_wallet,v.balance<0?expenseRed:green),
      stat(t('income'),v.income,Icons.trending_up,green),
      stat(t('expenses'),v.spent,Icons.trending_down,expenseRed),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          const Icon(Icons.savings,color:Colors.blue),
          const SizedBox(width:14),
          Expanded(child:Text(t('savings'))),
          Text(money(goal),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:19,color:Colors.blue)),
        ]),
        const SizedBox(height:12),
        Text('${money(saved)} / ${money(goal)}'),
        const SizedBox(height:8),
        LinearProgressIndicator(value:progress),
      ])),
      card(Row(children:[
        const Icon(Icons.calendar_month_outlined,color:Colors.blue),
        const SizedBox(width:14),
        Expanded(child:Text(t('automaticSavings'))),
        Text(money(monthlySaving),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:19,color:Colors.blue)),
      ])),
      heading(t('recents')),
      ...tx.reversed.take(7).map(tile),
    ]);
  }
  Widget tile(Map<String,dynamic> x,{VoidCallback? onDelete}) {final plus=x['type']=='Ingreso mensual'||x['type']=='Ingreso extra';return card(ListTile(contentPadding:EdgeInsets.zero,title:Text(transactionTitle(x)),subtitle:Text('${x['date']??''}\n${transactionNote(x)}'),isThreeLine:true,trailing:Row(mainAxisSize:MainAxisSize.min,children:[Text('${plus?'+':'−'}${money(number(x['amount']))}',style:TextStyle(color:plus?green:expenseRed,fontWeight:FontWeight.bold)),if(onDelete!=null)IconButton(onPressed:onDelete,icon:const Icon(Icons.delete_outline))])));}
  Future<void> addTransaction() async {
    String type='Gasto';
    String category=categories.isEmpty?'Otro':categories.first;
    final amount=TextEditingController(),note=TextEditingController();
    bool transactionAdded=false;
    await showDialog(context:dialogContext,builder:(c)=>StatefulBuilder(builder:(c,update)=>AlertDialog(
      title:Text(t('add')),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(initialValue:type,items:['Gasto','Ingreso extra'].map((e)=>DropdownMenuItem(value:e,child:Text(e=='Gasto'?t('expense'):t('extra')))).toList(),onChanged:(v)=>update(()=>type=v!)),
        if(type=='Gasto') DropdownButtonFormField<String>(key:ValueKey(category),initialValue:categories.contains(category)?category:null,decoration:InputDecoration(labelText:t('category')),isExpanded:true,items:categories.map((e)=>DropdownMenuItem(value:e,child:Text(catName(e)))).toList(),onChanged:(v)=>update(()=>category=v??'Otro')),
        TextButton.icon(onPressed:()async{await manageCategories();if(c.mounted)update((){if(!categories.contains(category))category=categories.isEmpty?'Otro':categories.first;});},icon:const Icon(Icons.tune),label:Text(t('editCategories'))),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:t('amount'))),
        TextField(controller:note,decoration:InputDecoration(labelText:t('note')))
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(t('cancel'))),FilledButton(onPressed:(){
        final n=double.tryParse(amount.text.replaceAll(',','.'));
        if(n==null||n<=0||!n.isFinite){notice(t('invalid'));return;}
        data['transactions']=[...tx,{'date':stampNow(),'type':type,'category':type=='Gasto'?category:'Ingreso extra','amount':n,'note':note.text}];
        transactionAdded=true;
        Navigator.pop(c);
      },child:Text(t('save')))]
    )));
    if (transactionAdded) {
      await save();
    } else {
      refreshAfterDialog();
    }
    WidgetsBinding.instance.addPostFrameCallback((_){amount.dispose();note.dispose();});
  }
  Future<void> manageCategories() async {
    final controller=TextEditingController();
    await showDialog(context:dialogContext,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(
      title:Text(t('manageCategories')),
      content:SizedBox(width:380,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:controller,decoration:InputDecoration(labelText:t('categoryName'))),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:(){final name=controller.text.trim();if(name.isEmpty)return;final hidden=(data['hidden_categories'] as List? ?? []).map((e)=>'$e').toList();hidden.remove(name);data['hidden_categories']=hidden;if(!defaultCategories.contains(name)){data['custom_categories']={...(data['custom_categories'] as List? ?? []).map((e)=>'$e'),name}.toList();}controller.clear();update((){});persistWithoutRebuild();},icon:const Icon(Icons.add),label:Text(t('newCategory'))),
        ...categories.map((name)=>ListTile(dense:true,title:Text(catName(name)),trailing:IconButton(tooltip:t('removeCategory'),icon:const Icon(Icons.delete_outline),onPressed:(){if(defaultCategories.contains(name)){data['hidden_categories']={...(data['hidden_categories'] as List? ?? []).map((e)=>'$e'),name}.toList();}else{data['custom_categories']=(data['custom_categories'] as List? ?? []).where((e)=>'$e'!=name).toList();}update((){});persistWithoutRebuild();}))),
        TextButton.icon(onPressed:(){data['hidden_categories']=[];update((){});persistWithoutRebuild();},icon:const Icon(Icons.restore),label:Text(t('restoreCategories'))),
        Text(t('categoryInUse'),style:const TextStyle(fontSize:12))
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('save')))]
    )));
    WidgetsBinding.instance.addPostFrameCallback((_){controller.dispose();});
    refreshAfterDialog();
  }
  Widget transactions()=>scroll([heading(t('moves')),FilledButton.icon(onPressed:addTransaction,icon:const Icon(Icons.add),label:Text(t('add'))),...tx.reversed.map((x)=>tile(x,onDelete:(){final list=tx;// compare values as records() creates copies
    final i=list.indexWhere((v)=>v['date']==x['date']&&v['amount']==x['amount']&&v['type']==x['type']&&v['note']==x['note']);if(i>=0)list.removeAt(i);data['transactions']=list;save();}))]);
  Future<void> addPayment()async {
    final name=TextEditingController(),amount=TextEditingController();
    int selectedDay=DateTime.now().day;
    String selectedFrequency='monthly';
    DateTime firstPaymentDate=DateTime.now();
    await showDialog(context:dialogContext,builder:(c)=>StatefulBuilder(builder:(context,setDialogState)=>AlertDialog(
      title:Text(t('newRecurringPayment')),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:InputDecoration(labelText:t('name'))),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:t('amount'))),
        DropdownButtonFormField<String>(isExpanded:true,initialValue:selectedFrequency,
          decoration:InputDecoration(labelText:t('paymentFrequency')),
          items:frequencyOptions(),onChanged:(v)=>setDialogState(()=>selectedFrequency=v??'monthly')),
        if(selectedFrequency=='daily')
          Text(t('dailyDateHint'),style:Theme.of(context).textTheme.bodySmall)
        else ...[
          ListTile(contentPadding:EdgeInsets.zero,title:Text(t('firstPaymentDate')),
            subtitle:Text(dateOnly(firstPaymentDate)),trailing:const Icon(Icons.calendar_today),
            onTap:()async{final d=await showDatePicker(context:context,initialDate:firstPaymentDate,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setDialogState((){firstPaymentDate=d;selectedDay=d.day;});}),
          Text(t('dateHint'),style:Theme.of(context).textTheme.bodySmall),
        ],
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(t('cancel'))),
        FilledButton(onPressed:(){final n=double.tryParse(amount.text.replaceAll(',','.'));
          if(n==null||n<=0||!n.isFinite||name.text.trim().isEmpty){notice(t('invalid'));return;}
          final now=DateTime.now();
          final first=selectedFrequency=='daily'?DateTime(now.year,now.month,now.day):firstPaymentDate;
          data['monthly_payments']=[...payments,{'name':name.text.trim(),'amount':n,'active':true,'day':first.day,'frequency':selectedFrequency,'start_date':dateOnly(first)}];
          Navigator.pop(c);applyMonthly();
        },child:Text(t('save')))])));
    name.dispose();amount.dispose();
  }
  Widget monthly()=>scroll([heading(t('recurringPayments')),
    FilledButton.icon(onPressed:addPayment,icon:const Icon(Icons.add),label:Text(t('newRecurringPayment'))),
    ...payments.asMap().entries.map((e)=>card(ListTile(
      title:Text('${e.value['name']}'),
      subtitle:Text("${money(number(e.value['amount']))} · ${frequencyLabel('${e.value['frequency']??'monthly'}')} · ${['daily','weekly','biweekly'].contains('${e.value['frequency']??'monthly'}')?'': '${t('recurringDay')} ${number(e.value['day']).toInt().clamp(1,31)}'}"),
      leading:Switch(value:e.value['active']!=false,onChanged:(v){final list=payments;list[e.key]['active']=v;if(v){final now=DateTime.now();list[e.key]['start_date']=dateOnly(firstRecurringDate(DateTime(now.year,now.month,now.day),number(list[e.key]['day']).toInt().clamp(1,31),'${list[e.key]['frequency']??'monthly'}'));}data['monthly_payments']=list;applyMonthly();}),
      trailing:Row(mainAxisSize:MainAxisSize.min,children:[
        IconButton(tooltip:t('editSchedule'),icon:const Icon(Icons.edit_calendar_outlined),onPressed:()async{
          int selectedDay=number(e.value['day']).toInt().clamp(1,31);
          String selectedFrequency='${e.value['frequency']??'monthly'}';
          DateTime firstPaymentDate=DateTime.tryParse('${e.value['start_date']}')??DateTime.now();
          if(firstPaymentDate.isBefore(DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day)))firstPaymentDate=DateTime.now();
          await showDialog(context:dialogContext,builder:(c)=>StatefulBuilder(builder:(context,setDialogState)=>AlertDialog(
            title:Text(t('editSchedule')),
            content:Column(mainAxisSize:MainAxisSize.min,children:[
              DropdownButtonFormField<String>(isExpanded:true,initialValue:selectedFrequency,decoration:InputDecoration(labelText:t('paymentFrequency')),items:frequencyOptions(),onChanged:(v)=>setDialogState(()=>selectedFrequency=v??'monthly')),
              if(selectedFrequency=='daily') Text(t('dailyDateHint'))
              else ...[
                ListTile(contentPadding:EdgeInsets.zero,title:Text(t('firstPaymentDate')),subtitle:Text(dateOnly(firstPaymentDate)),trailing:const Icon(Icons.calendar_today),onTap:()async{final d=await showDatePicker(context:context,initialDate:firstPaymentDate,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setDialogState((){firstPaymentDate=d;selectedDay=d.day;});}),
                Text(t('dateHint')),
              ],
            ]),
            actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(t('cancel'))),FilledButton(onPressed:(){
              final list=payments;list[e.key]['day']=firstPaymentDate.day;list[e.key]['frequency']=selectedFrequency;
              final now=DateTime.now();
              list[e.key]['start_date']=dateOnly(selectedFrequency=='daily'?DateTime(now.year,now.month,now.day):firstPaymentDate);
              data['monthly_payments']=list;Navigator.pop(c);applyMonthly();
            },child:Text(t('save')))])));
        }),
        IconButton(icon:const Icon(Icons.delete_outline),onPressed:(){final list=payments;list.removeAt(e.key);data['monthly_payments']=list;save();})
      ]))))]);
  String statsPeriod='monthly';
  DateTime _periodStart(DateTime date, String period) {
    final d=DateTime(date.year,date.month,date.day);
    if(period=='daily')return d;
    if(period=='weekly')return d.subtract(Duration(days:d.weekday-1));
    if(period=='yearly')return DateTime(d.year);
    return DateTime(d.year,d.month);
  }
  DateTime _periodShift(DateTime date,int shift,String period) {
    if(period=='daily')return DateTime(date.year,date.month,date.day+shift);
    if(period=='weekly')return DateTime(date.year,date.month,date.day+7*shift);
    if(period=='yearly')return DateTime(date.year+shift);
    return DateTime(date.year,date.month+shift);
  }
  String _periodLabel(DateTime d,String period) {
    if(period=='daily')return '${d.day}/${d.month}';
    if(period=='weekly')return '${d.day}/${d.month}';
    if(period=='yearly')return '${d.year}';
    return '${d.month}/${d.year%100}';
  }
  ({double income,double spent,double savings}) _periodTotals(DateTime start,DateTime end) {
    double income=0,spent=0,savings=0;
    for(final item in tx){
      final raw='${item['date']??''}';
      final date=DateTime.tryParse(raw);
      if(date==null||date.isBefore(start)||!date.isBefore(end))continue;
      final amount=number(item['amount']);
      switch('${item['type']}'){
        case 'Ingreso mensual':
        case 'Ingreso extra': income+=amount;break;
        case 'Gasto':
        case 'Pago mensual': spent+=amount;break;
      }
    }
    for(final entry in records(data['savings_history'])){
      final date=DateTime.tryParse('${entry['date']??''}');
      if(date!=null&&!date.isBefore(start)&&date.isBefore(end)){
        savings+=number(entry['amount']);
      }
    }
    return (income:income,spent:spent,savings:savings);
  }
  String _analyticsText(String key){
    final lang='${data['language']??'es'}';
    const dictionary=<String,Map<String,String>>{
      'es':{'overview':'Resumen del período','savings':'Ahorro reservado','available':'Saldo disponible','balanceTrend':'Evolución del saldo','savingsTrend':'Ahorro acumulado','recurring':'Pagos recurrentes realizados','ordinary':'Otros gastos','net':'Resultado del período','savingsGoal':'Progreso de la meta','legacy':'El ahorro anterior a esta versión no tiene fechas individuales; se incluye en el total, no en las barras históricas.','noHistory':'Todavía no hay reservas de ahorro fechadas.'},
      'en':{'overview':'Period summary','savings':'Reserved savings','available':'Available balance','balanceTrend':'Balance over time','savingsTrend':'Accumulated savings','recurring':'Recurring payments made','ordinary':'Other expenses','net':'Period net','savingsGoal':'Savings goal progress','legacy':'Older savings have no individual dates; they are included in the total but not historical bars.','noHistory':'No dated savings deposits yet.'},
      'fr':{'overview':'Résumé de la période','savings':'Épargne réservée','available':'Solde disponible','balanceTrend':'Évolution du solde','savingsTrend':'Épargne cumulée','recurring':'Paiements récurrents effectués','ordinary':'Autres dépenses','net':'Résultat de la période','savingsGoal':'Progression de l’objectif','legacy':'L’épargne ancienne ne possède pas de dates individuelles.','noHistory':'Pas encore d’épargne datée.'},
      'de':{'overview':'Zeitraumübersicht','savings':'Zurückgelegtes Spargeld','available':'Verfügbares Guthaben','balanceTrend':'Kontostandverlauf','savingsTrend':'Angespartes Guthaben','recurring':'Ausgeführte Dauerzahlungen','ordinary':'Sonstige Ausgaben','net':'Ergebnis des Zeitraums','savingsGoal':'Sparziel-Fortschritt','legacy':'Ältere Ersparnisse haben keine einzelnen Datumsangaben.','noHistory':'Noch keine datierten Sparbeträge.'},
      'bn':{'overview':'সময়ের সারাংশ','savings':'সঞ্চিত অর্থ','available':'উপলব্ধ ব্যালেন্স','balanceTrend':'ব্যালেন্সের পরিবর্তন','savingsTrend':'মোট সঞ্চয়','recurring':'নিয়মিত পেমেন্ট','ordinary':'অন্যান্য খরচ','net':'সময়ের ফলাফল','savingsGoal':'সঞ্চয় লক্ষ্যের অগ্রগতি','legacy':'পুরোনো সঞ্চয়ের পৃথক তারিখ নেই।','noHistory':'এখনো তারিখসহ সঞ্চয় নেই।'}
    };
    return dictionary[lang]?[key]??dictionary['es']![key]??key;
  }
  double _balanceAt(DateTime exclusiveEnd){
    double balance=number(data['opening_balance']);
    for(final item in tx){
      final date=DateTime.tryParse('${item['date']??''}');
      if(date==null||!date.isBefore(exclusiveEnd))continue;
      final amount=number(item['amount']);
      if(item['type']=='Ingreso mensual'||item['type']=='Ingreso extra')balance+=amount;
      if(item['type']=='Gasto'||item['type']=='Pago mensual')balance-=amount;
    }
    // Older reserved savings are undated; treat them as an opening adjustment,
    // without inventing historical deposits or counting them as expenses.
    final history=records(data['savings_history']);
    final dated=history.fold<double>(0,(v,e)=>v+number(e['amount']));
    balance-=max(0.0,number(data['savings_saved'])-dated);
    for(final entry in history){
      final date=DateTime.tryParse('${entry['date']??''}');
      if(date!=null&&date.isBefore(exclusiveEnd))balance-=number(entry['amount']);
    }
    return balance;
  }
  double _savingsAt(DateTime exclusiveEnd){
    final history=records(data['savings_history']);
    final dated=history.fold<double>(0,(v,e)=>v+number(e['amount']));
    double value=max(0.0,number(data['savings_saved'])-dated);
    for(final entry in history){
      final date=DateTime.tryParse('${entry['date']??''}');
      if(date!=null&&date.isBefore(exclusiveEnd))value+=number(entry['amount']);
    }
    return value;
  }
  Widget stats(){
    final now=DateTime.now();
    final current=_periodStart(now,statsPeriod);
    final priorStart=_periodShift(current,-1,statsPeriod);
    final v=_periodTotals(current,_periodShift(current,1,statsPeriod));
    final prior=_periodTotals(priorStart,current);
    final income=max(0.0,v.income),spent=max(0.0,v.spent),sum=income+spent;
    final byCategory=<String,double>{};
    for(final x in tx){
      final date=DateTime.tryParse('${x['date']??''}');
      if(date==null||date.isBefore(current)||!date.isBefore(_periodShift(current,1,statsPeriod)))continue;
      if(x['type']!='Gasto'&&x['type']!='Pago mensual')continue;
      final n=max(0.0,number(x['amount']));
      if(n>0)byCategory.update('${x['category']??'Otro'}',(old)=>old+n,ifAbsent:()=>n);
    }
    final colors=[green,expenseRed,Colors.blue,Colors.orange,Colors.purple,Colors.teal,Colors.pink,Colors.amber,Colors.indigo];
    final items=byCategory.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final expenseTotal=items.fold<double>(0,(v,e)=>v+e.value);
    final count=statsPeriod=='daily'?7:statsPeriod=='weekly'?8:6;
    final periods=List.generate(count,(i)=>_periodShift(current,i-count+1,statsPeriod));
    final series=periods.map((p)=>_periodTotals(p,_periodShift(p,1,statsPeriod))).toList();
    final maxValue=max(1.0,series.fold<double>(0,(v,e)=>max(v,max(e.income,e.spent))))*1.2;
    final periodEnd=_periodShift(current,1,statsPeriod);
    double recurring=0,ordinary=0;
    for(final item in tx){
      final date=DateTime.tryParse('${item['date']??''}');
      if(date==null||date.isBefore(current)||!date.isBefore(periodEnd))continue;
      if(item['type']=='Pago mensual')recurring+=number(item['amount']);
      if(item['type']=='Gasto')ordinary+=number(item['amount']);
    }
    final goal=number(data['savings_goal']);
    final saved=number(data['savings_saved']);
    final savingsRatio=goal>0?(saved/goal).clamp(0.0,1.0).toDouble():0.0;
    final balanceSeries=periods.map((p)=>_balanceAt(_periodShift(p,1,statsPeriod))).toList();
    final savingSeries=periods.map((p)=>_savingsAt(_periodShift(p,1,statsPeriod))).toList();
    final hasSavingsHistory=records(data['savings_history']).isNotEmpty;
    final language='${data['language']??'es'}';
    final names=<String,List<String>>{
      'es':['Diario','Semanal','Mensual','Anual'],
      'en':['Daily','Weekly','Monthly','Yearly'],
      'fr':['Jour','Semaine','Mois','Année'],
      'de':['Tag','Woche','Monat','Jahr'],
      'bn':['দৈনিক','সাপ্তাহিক','মাসিক','বার্ষিক']
    };
    final periodNames=names[language]??names['es']!;
    return scroll([
      heading(t('stats')),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(language=='es'?'Ver estadísticas por':language=='en'?'View statistics by':'Periodo / Period',style:Theme.of(dialogContext).textTheme.titleMedium),
        const SizedBox(height:10),
        Wrap(spacing:6,runSpacing:6,children:List.generate(4,(i){
          final key=['daily','weekly','monthly','yearly'][i];
          return ChoiceChip(label:Text(periodNames[i]),selected:statsPeriod==key,onSelected:(_)=>setState(()=>statsPeriod=key));
        }))
      ])),
      stat(t('income'),v.income,Icons.arrow_upward,green),
      stat(t('expenses'),v.spent,Icons.arrow_downward,expenseRed),
      heading(_analyticsText('overview')),
      stat(_analyticsText('available'),_balanceAt(periodEnd),Icons.account_balance_wallet,green),
      stat(_analyticsText('savings'),v.savings,Icons.savings,Colors.blue),
      stat(_analyticsText('recurring'),recurring,Icons.event_repeat,Colors.orange),
      stat(_analyticsText('ordinary'),ordinary,Icons.shopping_cart_outlined,expenseRed),
      stat(_analyticsText('net'),v.income-v.spent-v.savings,Icons.account_balance,Colors.teal),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(_analyticsText('savingsGoal'),style:Theme.of(dialogContext).textTheme.titleMedium),
        const SizedBox(height:10),
        Text('${money(saved)} / ${money(goal)}'),
        const SizedBox(height:8),LinearProgressIndicator(value:savingsRatio),
        const SizedBox(height:8),Text('${(savingsRatio*100).toStringAsFixed(1)}%'),
      ])),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(_analyticsText('balanceTrend'),style:Theme.of(dialogContext).textTheme.titleMedium),
        const SizedBox(height:16),
        SizedBox(height:190,child:LineChart(LineChartData(
          minY:min(0.0,balanceSeries.reduce(min))*1.1,
          maxY:max(1.0,balanceSeries.reduce(max))*1.1,
          lineBarsData:[LineChartBarData(spots:List.generate(count,(i)=>FlSpot(i.toDouble(),balanceSeries[i])),color:green,barWidth:3,isCurved:false,dotData:const FlDotData(show:true))],
          titlesData:FlTitlesData(topTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),leftTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,reservedSize:30,interval:1,getTitlesWidget:(value,meta){final i=value.toInt();return i>=0&&i<count&&value==i.toDouble()?Text(_periodLabel(periods[i],statsPeriod),style:const TextStyle(fontSize:9)):const SizedBox.shrink();})))
        ))),
      ])),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(_analyticsText('savingsTrend'),style:Theme.of(dialogContext).textTheme.titleMedium),
        const SizedBox(height:12),
        if(!hasSavingsHistory)Text(_analyticsText('noHistory')) else SizedBox(height:190,child:LineChart(LineChartData(
          minY:0,maxY:max(1.0,savingSeries.reduce(max))*1.2,
          lineBarsData:[LineChartBarData(spots:List.generate(count,(i)=>FlSpot(i.toDouble(),savingSeries[i])),color:Colors.blue,barWidth:3,isCurved:false,dotData:const FlDotData(show:true))],
          titlesData:FlTitlesData(topTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),leftTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,reservedSize:30,interval:1,getTitlesWidget:(value,meta){final i=value.toInt();return i>=0&&i<count&&value==i.toDouble()?Text(_periodLabel(periods[i],statsPeriod),style:const TextStyle(fontSize:9)):const SizedBox.shrink();})))
        ))),
        if(number(data['savings_saved'])>records(data['savings_history']).fold<double>(0,(a,e)=>a+number(e['amount']))+0.001)
          Padding(padding:const EdgeInsets.only(top:8),child:Text(_analyticsText('legacy'),style:Theme.of(dialogContext).textTheme.bodySmall)),
      ])),

      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(t('monthComparison'),style:Theme.of(dialogContext).textTheme.titleMedium),const SizedBox(height:12),
        Row(children:[Expanded(child:Text(t('spendingChange'))),Text(percentChange(v.spent,prior.spent),style:TextStyle(color:v.spent>prior.spent?expenseRed:green,fontWeight:FontWeight.bold))]),
        const SizedBox(height:8),Row(children:[Expanded(child:Text(t('incomeChange'))),Text(percentChange(v.income,prior.income),style:const TextStyle(fontWeight:FontWeight.bold))]),
        if(prior.spent==0&&prior.income==0)Padding(padding:const EdgeInsets.only(top:8),child:Text(t('noPrevious'),style:Theme.of(dialogContext).textTheme.bodySmall))
      ])),
      card(Column(children:[
        Text(t('distribution'),style:Theme.of(dialogContext).textTheme.titleMedium),const SizedBox(height:12),
        SizedBox(height:200,child:sum<=0?Center(child:Text(t('noData'))):PieChart(PieChartData(sections:[
          if(income>0)PieChartSectionData(value:income,color:green,title:'${(100*income/sum).round()}%',radius:72),
          if(spent>0)PieChartSectionData(value:spent,color:expenseRed,title:'${(100*spent/sum).round()}%',radius:72)
        ],sectionsSpace:2,centerSpaceRadius:30)))
      ])),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(t('monthlyTrend'),style:Theme.of(dialogContext).textTheme.titleMedium),const SizedBox(height:8),
        SegmentedButton<String>(showSelectedIcon:false,segments:[ButtonSegment(value:'bar',label:Text(t('barChart'))),ButtonSegment(value:'line',label:Text(t('lineChart')))],selected:{chartMode=='line'?'line':'bar'},onSelectionChanged:(v)=>setState(()=>chartMode=v.first)),
        const SizedBox(height:18),
        SizedBox(height:230,child:chartMode=='line'?LineChart(LineChartData(
          minY:0,maxY:maxValue,
          lineBarsData:[LineChartBarData(spots:List.generate(count,(i)=>FlSpot(i.toDouble(),series[i].income)),color:green,isCurved:false,barWidth:3,dotData:const FlDotData(show:true)),LineChartBarData(spots:List.generate(count,(i)=>FlSpot(i.toDouble(),series[i].spent)),color:expenseRed,isCurved:false,barWidth:3,dotData:const FlDotData(show:true))],
          titlesData:FlTitlesData(topTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),leftTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,reservedSize:30,interval:1,getTitlesWidget:(value,meta){final i=value.toInt();return i>=0&&i<count&&value==i.toDouble()?Text(_periodLabel(periods[i],statsPeriod),style:const TextStyle(fontSize:9)):const SizedBox.shrink();})))
        )):BarChart(BarChartData(
          maxY:maxValue,alignment:BarChartAlignment.spaceAround,
          barGroups:List.generate(count,(i)=>BarChartGroupData(x:i,barRods:[BarChartRodData(toY:series[i].income,color:green,width:statsPeriod=='weekly'?7:9),BarChartRodData(toY:series[i].spent,color:expenseRed,width:statsPeriod=='weekly'?7:9)])),
          titlesData:FlTitlesData(topTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),leftTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,reservedSize:30,interval:1,getTitlesWidget:(value,meta){final i=value.toInt();return i>=0&&i<count&&value==i.toDouble()?Text(_periodLabel(periods[i],statsPeriod),style:const TextStyle(fontSize:9)):const SizedBox.shrink();})))
        ))),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.circle,color:green,size:12),const SizedBox(width:4),Text(t('income')),const SizedBox(width:18),Icon(Icons.circle,color:expenseRed,size:12),const SizedBox(width:4),Text(t('expenses'))])
      ])),
      heading(t('categoryShares')),
      if(items.isEmpty)card(Text(t('noData'))) else card(Column(children:[
        SizedBox(height:220,child:PieChart(PieChartData(centerSpaceRadius:28,sectionsSpace:2,sections:List.generate(items.length,(i)=>PieChartSectionData(value:items[i].value,color:colors[i%colors.length],radius:76,title:'${(100*items[i].value/expenseTotal).round()}%'))))),
        ...List.generate(items.length,(i)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[Icon(Icons.circle,color:colors[i%colors.length],size:13),const SizedBox(width:8),Expanded(child:Text(catName(items[i].key))),Text('${(100*items[i].value/expenseTotal).toStringAsFixed(1)}%  ·  ${money(items[i].value)}')]))),
      ]))
    ]);
  }

  Future<void> importBackup() async {
    final editor=TextEditingController();
    try {
      final clipboard=await Clipboard.getData('text/plain');
      if(clipboard?.text!=null)editor.text=clipboard!.text!;
    } catch (_) {}
    if(!mounted){editor.dispose();return;}
    final raw=await showDialog<String>(context:dialogContext,builder:(c)=>AlertDialog(
      title:Text(t('importBackup')),
      content:SizedBox(width:500,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:editor,maxLines:9,minLines:4,decoration:InputDecoration(hintText:t('pasteJsonHint'),border:const OutlineInputBorder())),
        TextButton.icon(onPressed:()async{final clip=await Clipboard.getData('text/plain');if(clip?.text!=null)editor.text=clip!.text!;},icon:const Icon(Icons.paste),label:Text(t('pasteClipboard'))),
        if(Platform.isWindows) TextButton.icon(onPressed:()async{
          try {
            const group=XTypeGroup(label:'JSON',extensions:['json']);
            final file=await openFile(acceptedTypeGroups:[group]);
            if(file!=null)editor.text=await file.readAsString();
          } catch (_) { if(c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(t('invalidBackup')))); }
        },icon:const Icon(Icons.folder_open),label:Text({'es':'Abrir archivo JSON','en':'Open JSON file','fr':'Ouvrir un fichier JSON','de':'JSON-Datei öffnen','bn':'JSON ফাইল খুলুন'}['${data['language']}']??'Abrir archivo JSON'))
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(t('cancel'))),FilledButton(onPressed:()=>Navigator.pop(c,editor.text),child:Text(t('import')))]));
    editor.dispose();
    if(raw==null||raw.trim().isEmpty)return;
    try {
      var clean=raw.trim().replaceFirst('\uFEFF','');
      if(clean.startsWith('```')){
        clean=clean.replaceFirst(RegExp(r'^```(?:json)?\s*',caseSensitive:false),'').replaceFirst(RegExp(r'\s*```$'),'').trim();
      }
      final decoded=jsonDecode(clean);
      if(decoded is! Map)throw const FormatException('Expected object');
      final obj=Map<String,dynamic>.from(decoded);
      // Accept old backups that omit transactions, but reject arbitrary JSON.
      const fields=['transactions','monthly_payments','monthly_income','opening_balance','savings_goal','monthly_savings','currency','language','setup_completed'];
      if(!fields.any(obj.containsKey))throw const FormatException('Not a MafiFlow backup');
      for(final key in ['transactions','monthly_payments','savings_history']){
        if(obj.containsKey(key)&&obj[key] is! List)throw const FormatException('Invalid list');
      }
      if(!mounted)return;
      final ok=await showDialog<bool>(context:dialogContext,builder:(c)=>AlertDialog(title:Text(t('importBackup')),content:Text(t('confirm')),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(t('cancel'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(t('yes')))]));
      if(ok!=true||!mounted)return;
      final replacement={...defaults,...obj};
      // Do not run scheduled charges on imported data before saving it.
      setState(()=>data=replacement);
      await save();
      notice(t('imported'));
    } catch (_) {if(mounted)notice(t('invalidBackup'));}
  }
  Widget settings()=>SettingsPanel(
    active:tab==5, data:data, t:t, scrollBuilder:scroll, cardBuilder:card, headingBuilder:heading,
    onManageCategories:manageCategories, onImportBackup:importBackup,
    onExportBackup:() async {
      final copy=Map<String,dynamic>.from(data)..['ai_api_key']='';
      final jsonText=const JsonEncoder.withIndent('  ').convert(copy);
      await Clipboard.setData(ClipboardData(text:jsonText));
      if(Platform.isWindows) {
        try {
          const group=XTypeGroup(label:'JSON',extensions:['json']);
          final location=await getSaveLocation(suggestedName:'MafiFlow-backup.json',acceptedTypeGroups:[group]);
          if(location!=null) await File(location.path).writeAsString(jsonText,flush:true);
        } catch (_) { /* The clipboard backup remains available. */ }
      }
      notice(t('backup'));
    },
    onSave:(values) async {
      data.addAll(values);
      applySavingsMonthly();
      await save();
      notice(t('settingsSaved'));
    },
    onInvalid:()=>notice(t('invalid')),
  );

}


// Keep the form state alive while other tabs rebuild. Never recreate text
// controllers during build: doing so discarded edits when a field lost focus.
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key,required this.active,required this.data,required this.t,
    required this.scrollBuilder,required this.cardBuilder,required this.headingBuilder,
    required this.onManageCategories,required this.onImportBackup,
    required this.onExportBackup,required this.onSave,required this.onInvalid});
  final bool active;
  final Map<String,dynamic> data;
  final String Function(String) t;
  final Widget Function(List<Widget>) scrollBuilder;
  final Widget Function(Widget) cardBuilder;
  final Widget Function(String) headingBuilder;
  final VoidCallback onManageCategories;
  final Future<void> Function() onImportBackup;
  final Future<void> Function() onExportBackup;
  final Future<void> Function(Map<String,dynamic>) onSave;
  final VoidCallback onInvalid;
  @override State<SettingsPanel> createState()=>_SettingsPanelState();
}
class _SettingsPanelState extends State<SettingsPanel> {
  late final TextEditingController income,goal,monthlySavings,api,model,url;
  DateTime incomePayday=DateTime.now();
  late String currency,incomeFrequency,provider,lang,theme;
  @override void initState(){
    super.initState();
    income=TextEditingController();
    goal=TextEditingController();
    monthlySavings=TextEditingController();
    api=TextEditingController();
    model=TextEditingController();
    url=TextEditingController();
    restoreSavedSettings();
  }
  // Load the last committed values, discarding any unsaved draft.
  // Only call when leaving/re-entering Settings, not during typing.
  void restoreSavedSettings(){
    final d=widget.data;
    income.text='${d['monthly_income']??0}';
    goal.text='${d['savings_goal']??0}';
    monthlySavings.text='${d['monthly_savings']??0}';
    api.text='${d['ai_api_key']??''}';
    model.text='${d['ai_model']??''}';
    url.text='${d['ai_base_url']??''}';
    currency='${d['currency']??'USD'}';
    incomeFrequency='${d['income_frequency']??'monthly'}';
    incomePayday=DateTime.tryParse('${d['income_start_date']??''}')??DateTime.now();
    provider='${d['ai_provider']??'OpenAI'}';
    lang='${d['language']??'es'}';
    theme='${d['theme']??'light'}';
  }
  @override void didUpdateWidget(covariant SettingsPanel oldWidget){
    super.didUpdateWidget(oldWidget);
    // IndexedStack keeps Settings alive while another tab is selected.
    // When the tab changes, reload only committed data, never drafts.
    if(oldWidget.active != widget.active || !identical(oldWidget.data,widget.data)){
      restoreSavedSettings();
    }
  }
  @override void dispose(){for(final c in [income,goal,monthlySavings,api,model,url]){c.dispose();}super.dispose();}
  double? amount(String raw){final v=double.tryParse(raw.trim().replaceAll(',','.'));return v!=null&&v.isFinite&&v>=0?v:null;}
  Future<void> submit() async {
    final inc=amount(income.text),sav=amount(goal.text),monthly=amount(monthlySavings.text);
    if(inc==null||sav==null||monthly==null){widget.onInvalid();return;}
    await widget.onSave({
      'monthly_income':inc,'income_frequency':incomeFrequency,
      'income_start_date':'${incomePayday.year}-${incomePayday.month.toString().padLeft(2,'0')}-${incomePayday.day.toString().padLeft(2,'0')}',
      'savings_goal':sav,'monthly_savings':monthly,'currency':currency,
      'ai_provider':provider,'ai_api_key':api.text.trim(),
      'ai_model':model.text.trim(),'ai_base_url':url.text.trim(),
      'language':lang,'theme':theme,
    });
  }
  @override Widget build(BuildContext context){
    String t(String k)=>widget.t(k);
    return widget.scrollBuilder([
      widget.headingBuilder(t('settings')),
      widget.cardBuilder(Column(children:[
        TextField(controller:income,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:t('payAmount'))),
        DropdownButtonFormField<String>(isExpanded:true,key:ValueKey('frequency-$incomeFrequency'),initialValue:['daily','weekly','biweekly','monthly','two_months','three_months'].contains(incomeFrequency)?incomeFrequency:'monthly',decoration:InputDecoration(labelText:t('payFrequency')),items:[DropdownMenuItem(value:'daily',child:Text(t('freqDaily'))),DropdownMenuItem(value:'weekly',child:Text(t('freqWeekly'))),DropdownMenuItem(value:'biweekly',child:Text(t('freqBiweekly'))),DropdownMenuItem(value:'monthly',child:Text(t('freqMonthly'))),DropdownMenuItem(value:'two_months',child:Text(t('freqTwoMonths'))),DropdownMenuItem(value:'three_months',child:Text(t('freqThreeMonths')))],onChanged:(v)=>setState((){final next=v??'monthly';if(next!=incomeFrequency){incomeFrequency=next;incomePayday=DateTime.now();}})),
        if(incomeFrequency!='daily')ListTile(contentPadding:EdgeInsets.zero,title:Text(t('firstPaymentDate')),subtitle:Text('${incomePayday.year}-${incomePayday.month.toString().padLeft(2,'0')}-${incomePayday.day.toString().padLeft(2,'0')}'),trailing:const Icon(Icons.calendar_today),onTap:()async{final d=await showDatePicker(context:context,initialDate:incomePayday,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setState(()=>incomePayday=d);}),
        TextField(controller:goal,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:t('goal'))),
        TextField(controller:monthlySavings,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:t('monthlySavings'))),
        Text(t('monthlySavingsHint')),
        // Opening balance is set only in the onboarding wizard. Do not edit it here.
        DropdownButtonFormField<String>(key:ValueKey('currency-$currency'),initialValue:currency,decoration:InputDecoration(labelText:t('currency')),items:['USD','CAD','EUR','GBP','BDT','CUP'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>currency=v??'USD')),
        DropdownButtonFormField<String>(key:ValueKey('provider-$provider'),initialValue:['OpenAI','NVIDIA','Custom'].contains(provider)?provider:'OpenAI',decoration:InputDecoration(labelText:t('provider')),items:['OpenAI','NVIDIA','Custom'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>provider=v??'OpenAI')),
        TextField(controller:api,obscureText:true,decoration:InputDecoration(labelText:t('key'))),
        TextField(controller:model,decoration:InputDecoration(labelText:t('model'))),
        if(provider=='Custom') TextField(controller:url,decoration:InputDecoration(labelText:t('custom'))),
        DropdownButtonFormField<String>(key:ValueKey('language-$lang'),initialValue:const ['es','en','fr','de','bn'].contains(lang)?lang:'es',decoration:InputDecoration(labelText:t('language')),items:const [DropdownMenuItem(value:'es',child:Text('Español')),DropdownMenuItem(value:'en',child:Text('English')),DropdownMenuItem(value:'fr',child:Text('Français')),DropdownMenuItem(value:'de',child:Text('Deutsch')),DropdownMenuItem(value:'bn',child:Text('বাংলা'))],onChanged:(v)=>setState(()=>lang=v??'es')),
        DropdownButtonFormField<String>(key:ValueKey('theme-$theme'),initialValue:theme,decoration:InputDecoration(labelText:t('theme')),items:[DropdownMenuItem(value:'light',child:Text(t('light'))),DropdownMenuItem(value:'dark',child:Text(t('dark')))],onChanged:(v)=>setState(()=>theme=v??'light')),
        const SizedBox(height:12),FilledButton(onPressed:submit,child:Text(t('save')))
      ])),
      widget.cardBuilder(Column(children:[
        ListTile(leading:const Icon(Icons.help_outline),title:Text(t('helpCenter')),onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>MafiHelpCenter(language:'${widget.data['language']}')))),
        ListTile(leading:const Icon(Icons.category_outlined),title:Text(t('manageCategories')),onTap:widget.onManageCategories),
        ListTile(leading:const Icon(Icons.copy),title:Text(t('export')),onTap:widget.onExportBackup),
        ListTile(leading:const Icon(Icons.download),title:Text(t('import')),onTap:widget.onImportBackup),
      ])),
    ]);
  }
}

class Advisor extends StatefulWidget {final Map<String,dynamic> data;final String lang;final Future<void> Function() onSave;const Advisor({super.key,required this.data,required this.lang,required this.onSave});@override State<Advisor> createState()=>_AdvisorState();}
class _AdvisorState extends State<Advisor> {
  final input=TextEditingController();final scroll=ScrollController();bool busy=false;String response='';String status='';http.Client? client;Timer? waitTimer;
  String get wait=>({'es':'La IA está preparando tu respuesta','en':'AI is preparing your response','fr':'L’IA prépare votre réponse','de':'KI bereitet die Antwort vor','bn':'এআই উত্তর প্রস্তুত করছে'}[widget.lang]??'AI is preparing your response');
  String get providerWait=>({'es':'Esperando respuesta del proveedor','en':'Waiting for provider response','fr':'En attente du fournisseur','de':'Warte auf Anbieter','bn':'সেবাদাতার উত্তরের অপেক্ষায়'}[widget.lang]??'Waiting for provider response');
  @override void dispose(){waitTimer?.cancel();client?.close();input.dispose();scroll.dispose();super.dispose();}
  void bottom(){WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);});}
  Future<void> send()async {final question=input.text.trim();if(question.isEmpty||busy)return;final key='${widget.data['ai_api_key']??''}'.trim();if(key.isEmpty){setState(()=>status=widget.lang=='es'?'Configura tu clave API en Ajustes.':'Configure your API key in Settings.');return;}
    input.clear();final history=records(widget.data['ai_history']);history.add({'role':'user','content':question});widget.data['ai_history']=history;await widget.onSave();setState((){busy=true;response='';status='$wait…';});bottom();
    var dots=0;waitTimer=Timer.periodic(const Duration(milliseconds:450),(_){if(mounted&&busy&&response.isEmpty){setState(()=>status='${status.startsWith(providerWait)?providerWait:wait}${'.'*(++dots%4)}');}});
    final provider='${widget.data['ai_provider']??'OpenAI'}';String base=provider=='NVIDIA'?'https://integrate.api.nvidia.com/v1':provider=='Custom'?'${widget.data['ai_base_url']??''}':'https://api.openai.com/v1';base=base.replaceAll(RegExp(r'/$'),'');final model='${widget.data['ai_model']??''}'.trim().isNotEmpty?'${widget.data['ai_model']}':provider=='NVIDIA'?'meta/llama-3.1-8b-instruct':'gpt-4o-mini';
    try{final totals=<String,double>{'income':0,'expenses':0};final m=monthNow();for(final tx in records(widget.data['transactions'])){if(!'${tx['date']??''}'.startsWith(m))continue;final v=number(tx['amount']);if(tx['type']=='Ingreso extra'||tx['type']=='Ingreso mensual'){totals['income']=totals['income']!+v;}else if(tx['type']=='Gasto'||tx['type']=='Pago mensual'){totals['expenses']=totals['expenses']!+v;}}
      final messages=[{'role':'system','content':'You are a helpful financial budgeting assistant. Respond in ${{'es':'Spanish','en':'English','fr':'French','de':'German','bn':'Bengali'}[widget.lang]??'English'}. Current month income ${totals['income']}, expenses ${totals['expenses']}, savings goal ${widget.data['savings_goal']}. Be concise and avoid pretending to know missing information.'},...history.take(20).map((e)=>{'role':e['role'],'content':e['content']})];
      client=http.Client();final req=http.Request('POST',Uri.parse('$base/chat/completions'));req.headers.addAll({'Authorization':'Bearer $key','Content-Type':'application/json','Accept':'text/event-stream'});req.body=jsonEncode({'model':model,'messages':messages,'stream':true,'max_tokens':1000});final res=await client!.send(req).timeout(const Duration(seconds:35));if(res.statusCode<200||res.statusCode>=300){final err=await res.stream.bytesToString();throw Exception('HTTP ${res.statusCode}: ${err.length>240?err.substring(0,240):err}');}
      if(mounted)setState(()=>status='$providerWait…');
      await for(final line in res.stream.transform(utf8.decoder).transform(const LineSplitter())){if(!line.startsWith('data:'))continue;final raw=line.substring(5).trim();if(raw=='[DONE]')break;try{final decoded=jsonDecode(raw);final choices=decoded['choices'];if(choices is List&&choices.isNotEmpty){final delta=choices[0]['delta'];final piece=delta is Map?delta['content']:null;if(piece is String&&piece.isNotEmpty&&mounted){setState((){response+=piece;status='';});bottom();}}}catch(_){}}
      if(response.trim().isEmpty)throw Exception(widget.lang=='es'?'El proveedor no envió texto.':'Provider returned no text.');history.add({'role':'assistant','content':response});widget.data['ai_history']=history;await widget.onSave();
    }catch(e){if(mounted)setState(()=>status='${widget.lang=='es'?'Error':'Error'}: $e');}finally{waitTimer?.cancel();client?.close();client=null;if(mounted)setState(()=>busy=false);bottom();}
  }
  @override Widget build(BuildContext context){final history=records(widget.data['ai_history']);return Column(children:[Expanded(child:ListView(controller:scroll,padding:const EdgeInsets.all(16),children:[for(final msg in history)Align(alignment:msg['role']=='user'?Alignment.centerRight:Alignment.centerLeft,child:Card(color:msg['role']=='user'?Theme.of(context).colorScheme.primaryContainer:null,child:Padding(padding:const EdgeInsets.all(12),child:Text('${msg['content']??''}')))),if(busy||status.isNotEmpty)Align(alignment:Alignment.centerLeft,child:Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(response.isNotEmpty)Text(response),if(status.isNotEmpty)Row(mainAxisSize:MainAxisSize.min,children:[if(busy)const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)),const SizedBox(width:8),Flexible(child:Text(status))])]))))])),Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:input,enabled:!busy,maxLines:3,minLines:1,decoration:InputDecoration(hintText:{'es':'Escríbele a tu consejero','en':'Ask your advisor','fr':'Écrivez à votre conseiller','de':'Frage deinen Finanzberater','bn':'আপনার পরামর্শককে জিজ্ঞাসা করুন'}[widget.lang]??'Ask your advisor',border:const OutlineInputBorder()))),const SizedBox(width:8),IconButton.filled(onPressed:busy?null:send,icon:const Icon(Icons.send))]))]);}
}


// Onboarding is shown only on fresh installations, before the first monthly entry.
class WelcomeWizard extends StatefulWidget {
  final Future<void> Function(Map<String,dynamic>) onComplete;
  const WelcomeWizard({super.key,required this.onComplete});
  @override State<WelcomeWizard> createState()=>_WelcomeWizardState();
}
class _WelcomeWizardState extends State<WelcomeWizard> {
  int step=0;String language='es',currency='USD',incomeFrequency='monthly';DateTime payday=DateTime(DateTime.now().year,DateTime.now().month+1,1);
  final income=TextEditingController(text:'0'),opening=TextEditingController(text:'0'),goal=TextEditingController(text:'0'),monthlySavings=TextEditingController(text:'0');
  final Set<TextEditingController> selectedOnFirstFocus={};
  void selectInitialZero(TextEditingController controller){
    if(selectedOnFirstFocus.add(controller)&&controller.text=='0'){
      controller.selection=TextSelection(baseOffset:0,extentOffset:controller.text.length);
    }
  }
  int paymentDay=DateTime.now().day;String paymentFrequency='monthly';DateTime firstBillDate=DateTime.now();
  final name=TextEditingController(),payment=TextEditingController();
  final List<Map<String,dynamic>> bills=[];
  @override void dispose(){income.dispose();opening.dispose();goal.dispose();monthlySavings.dispose();name.dispose();payment.dispose();super.dispose();}
  String word(String es,String en,String fr,String de,String bn)=>{'es':es,'en':en,'fr':fr,'de':de,'bn':bn}[language]??es;
  double? parse(String v){final x=double.tryParse(v.trim().replaceAll(',','.'));return x!=null&&x.isFinite&&x>=0?x:null;}
  void next(){
    if((step==1&&(parse(income.text)==null||parse(opening.text)==null)) ||
       (step==2&&(parse(goal.text)==null||parse(monthlySavings.text)==null))){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(word('Introduce cantidades válidas','Enter valid amounts','Montants invalides','Ungültige Beträge','সঠিক পরিমাণ দিন'))));
      return;
    }
    if(step<3){setState(()=>step++);return;}
    // Save the payment being typed even when the user skips Add payment.
    final pendingName=name.text.trim();
    final pendingAmount=parse(payment.text);
    if(pendingName.isNotEmpty||payment.text.trim().isNotEmpty){
      if(pendingName.isEmpty||pendingAmount==null||pendingAmount<=0){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(word('Completa el nombre y el importe del pago, o deja ambos vacíos.','Complete the payment name and amount, or leave both blank.','Complétez le paiement ou laissez les deux champs vides.','Zahlung vervollständigen oder beide Felder leer lassen.','পেমেন্টের তথ্য পূরণ করুন বা ফাঁকা রাখুন।'))));
        return;
      }
      bills.add({'name':pendingName,'amount':pendingAmount,'active':true,'day':paymentDay,'frequency':paymentFrequency,'start_date':paymentFrequency=='daily'?wizardFirstRecurringDate(paymentDay,'daily'):'${firstBillDate.year}-${firstBillDate.month.toString().padLeft(2,'0')}-${firstBillDate.day.toString().padLeft(2,'0')}'});
      name.clear();payment.clear();paymentDay=DateTime.now().day;paymentFrequency='monthly';
    }
    widget.onComplete({'language':language,'currency':currency,'monthly_income':parse(income.text)??0,'income_frequency':incomeFrequency,'income_start_date':payday.toIso8601String().substring(0,10),'opening_balance':parse(opening.text)??0,'savings_goal':parse(goal.text)??0,'monthly_savings':parse(monthlySavings.text)??0,'monthly_payments':bills});
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('MafiFlow')),body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:540),child:ListView(padding:const EdgeInsets.all(24),children:[LinearProgressIndicator(value:(step+1)/4),const SizedBox(height:28),Text(word('¡Bienvenido a MafiFlow!','Welcome to MafiFlow!','Bienvenue sur MafiFlow !','Willkommen bei MafiFlow!','MafiFlow-তে স্বাগতম!'),style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:22),
    if(step==0)...[Text(word('Elige idioma y moneda','Choose language and currency','Choisissez langue et devise','Sprache und Währung wählen','ভাষা ও মুদ্রা নির্বাচন করুন')),DropdownButtonFormField<String>(initialValue:language,items:const [DropdownMenuItem(value:'es',child:Text('Español')),DropdownMenuItem(value:'en',child:Text('English')),DropdownMenuItem(value:'fr',child:Text('Français')),DropdownMenuItem(value:'de',child:Text('Deutsch')),DropdownMenuItem(value:'bn',child:Text('বাংলা'))],onChanged:(v)=>setState(()=>language=v??'es')),DropdownButtonFormField<String>(initialValue:currency,items:['USD','CAD','EUR','GBP','BDT','CUP'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>currency=v??'USD'))],
    if(step==1)...[Text(word('Configura tus finanzas iniciales','Set up your starting finances','Configurez vos finances','Finanzen einrichten','প্রাথমিক অর্থ সেট করুন')),TextField(controller:income,onTap:()=>selectInitialZero(income),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:word('Cantidad que recibes por pago','Amount per payday','Montant par paie','Betrag pro Zahlung','প্রতি বেতনের পরিমাণ'))),DropdownButtonFormField<String>(isExpanded:true,initialValue:incomeFrequency,decoration:InputDecoration(labelText:word('¿Cada cuánto cobras?','How often are you paid?','À quelle fréquence êtes-vous payé ?','Wie oft wirst du bezahlt?','কত ঘন ঘন বেতন পান?')),items:[DropdownMenuItem(value:'daily',child:Text(word('Diariamente','Daily','Chaque jour','Täglich','প্রতিদিন'))),DropdownMenuItem(value:'weekly',child:Text(word('Semanalmente','Weekly','Chaque semaine','Wöchentlich','প্রতি সপ্তাহে'))),DropdownMenuItem(value:'biweekly',child:Text(word('Cada 2 semanas','Every 2 weeks','Toutes les 2 semaines','Alle 2 Wochen','প্রতি ২ সপ্তাহে'))),DropdownMenuItem(value:'monthly',child:Text(word('Mensualmente','Monthly','Chaque mois','Monatlich','প্রতি মাসে'))),DropdownMenuItem(value:'two_months',child:Text(word('Cada 2 meses','Every 2 months','Tous les 2 mois','Alle 2 Monate','প্রতি ২ মাসে'))),DropdownMenuItem(value:'three_months',child:Text(word('Cada 3 meses','Every 3 months','Tous les 3 mois','Alle 3 Monate','প্রতি ৩ মাসে')))],onChanged:(v)=>setState(()=>incomeFrequency=v??'monthly')),const SizedBox(height:8),ListTile(contentPadding:EdgeInsets.zero,title:Text(word('Fecha del próximo cobro','Next payday','Date du premier paiement','Erster Zahltag','প্রথম বেতনের তারিখ')),subtitle:Text('${payday.year}-${payday.month.toString().padLeft(2,'0')}-${payday.day.toString().padLeft(2,'0')}'),trailing:const Icon(Icons.calendar_today),onTap:()async{final chosen=await showDatePicker(context:context,initialDate:payday,firstDate:DateTime(2020),lastDate:DateTime(2100));if(chosen!=null)setState(()=>payday=chosen);}),TextField(controller:opening,onTap:()=>selectInitialZero(opening),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:word('Saldo disponible ahora (no se suma al salario)','Available balance now (not added to salary)','Solde actuel (pas un revenu)','Aktueller Kontostand (kein Einkommen)','বর্তমান ব্যালেন্স')))],
    if(step==2)...[TextField(controller:monthlySavings,onTap:()=>selectInitialZero(monthlySavings),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:word('¿Cuánto quieres ahorrar al mes?','How much to save monthly?','Combien épargner par mois ?','Monatlicher Sparbetrag','মাসিক সঞ্চয়'))),TextField(controller:goal,onTap:()=>selectInitialZero(goal),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:word('¿Cuál es tu objetivo total de ahorro?','Total savings target','Objectif total d’épargne','Gesamtsparziel','মোট সঞ্চয়ের লক্ষ্য'))),const SizedBox(height:12),Text(word('Mensualmente este dinero se descontará automáticamente del dinero disponible hasta llegar a tu objetivo.','Each month this amount will automatically be deducted from available money until you reach your goal.','Chaque mois, ce montant sera déduit de votre solde disponible jusqu’à votre objectif.','Jeden Monat wird dieser Betrag vom verfügbaren Geld abgezogen, bis das Ziel erreicht ist.','লক্ষ্য পূরণ না হওয়া পর্যন্ত প্রতি মাসে উপলব্ধ অর্থ থেকে এই পরিমাণ বাদ যাবে।'))],
    if(step==3)...[Text(word('Agrega tus gastos fijos (opcional)','Add recurring expenses (optional)','Ajoutez les dépenses récurrentes','Wiederkehrende Ausgaben','নিয়মিত খরচ যোগ করুন')),TextField(controller:name,decoration:InputDecoration(labelText:word('Nombre del gasto','Expense name','Nom de la dépense','Ausgabenname','খরচের নাম'))),TextField(controller:payment,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:word('Cantidad por pago','Amount per payment','Montant par paiement','Betrag pro Zahlung','প্রতি পেমেন্টের পরিমাণ'))),DropdownButtonFormField<String>(isExpanded:true,key:ValueKey('wizard-payment-$paymentFrequency'),initialValue:paymentFrequency,decoration:InputDecoration(labelText:word('¿Cada cuánto se repite este pago?','How often does this payment repeat?','À quelle fréquence ce paiement se répète-t-il ?','Wie oft wird diese Zahlung wiederholt?','এই পেমেন্ট কত ঘন ঘন হবে?')),items:[DropdownMenuItem(value:'daily',child:Text(word('Diariamente','Daily','Chaque jour','Täglich','প্রতিদিন'))),DropdownMenuItem(value:'weekly',child:Text(word('Semanalmente','Weekly','Chaque semaine','Wöchentlich','প্রতি সপ্তাহে'))),DropdownMenuItem(value:'biweekly',child:Text(word('Cada 2 semanas','Every 2 weeks','Toutes les 2 semaines','Alle 2 Wochen','প্রতি ২ সপ্তাহে'))),DropdownMenuItem(value:'monthly',child:Text(word('Mensualmente','Monthly','Chaque mois','Monatlich','প্রতি মাসে'))),DropdownMenuItem(value:'two_months',child:Text(word('Cada 2 meses','Every 2 months','Tous les 2 mois','Alle 2 Monate','প্রতি ২ মাসে'))),DropdownMenuItem(value:'three_months',child:Text(word('Cada 3 meses','Every 3 months','Tous les 3 mois','Alle 3 Monate','প্রতি ৩ মাসে')))],onChanged:(v)=>setState(()=>paymentFrequency=v??'monthly')),
    if(paymentFrequency=='daily') Text(word('Comienza hoy y se repite todos los días','Starts today and repeats daily','Commence aujourd’hui et se répète chaque jour','Beginnt heute und wiederholt sich täglich','আজ থেকে প্রতিদিন পুনরাবৃত্তি হবে'))
    else ListTile(title:Text(word('Fecha del primer pago','First payment date','Date du premier paiement','Datum der ersten Zahlung','প্রথম পেমেন্টের তারিখ')),subtitle:Text('${firstBillDate.year}-${firstBillDate.month.toString().padLeft(2,'0')}-${firstBillDate.day.toString().padLeft(2,'0')}'),trailing:const Icon(Icons.calendar_today),onTap:()async{final d=await showDatePicker(context:context,initialDate:firstBillDate,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setState((){firstBillDate=d;paymentDay=d.day;});}),const SizedBox(height:8),TextButton.icon(onPressed:(){final n=parse(payment.text);if(name.text.trim().isEmpty||n==null||n<=0)return;setState((){bills.add({'name':name.text.trim(),'amount':n,'active':true,'day':paymentDay,'frequency':paymentFrequency,'start_date':paymentFrequency=='daily'?wizardFirstRecurringDate(paymentDay,'daily'):'${firstBillDate.year}-${firstBillDate.month.toString().padLeft(2,'0')}-${firstBillDate.day.toString().padLeft(2,'0')}'});name.clear();payment.clear();paymentDay=DateTime.now().day;paymentFrequency='monthly';});},icon:const Icon(Icons.add),label:Text(word('Agregar pago','Add payment','Ajouter','Hinzufügen','যোগ করুন'))),...bills.map((b)=>ListTile(title:Text('${b['name']}'),trailing:Text('${b['amount']}')))],
    const SizedBox(height:30),Row(children:[if(step>0)TextButton(onPressed:()=>setState(()=>step--),child:Text(word('Atrás','Back','Retour','Zurück','পেছনে'))),const Spacer(),FilledButton(onPressed:next,child:Text(step==3?word('Empezar','Get started','Commencer','Starten','শুরু করুন'):word('Continuar','Continue','Continuer','Weiter','চালিয়ে যান')))])]))));
}

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key, required this.title});
  final String title;
  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

// Parses arithmetic without evaluating source code. Supports operator precedence,
// parentheses, unary minus and percentage.
class _MafiCalculatorParser {
  _MafiCalculatorParser(this.source);
  final String source;
  int index = 0;

  void skipSpaces() {
    while (index < source.length && source[index] == ' ') { index++; }
  }
  bool take(String character) {
    skipSpaces();
    if (index < source.length && source[index] == character) {
      index++;
      return true;
    }
    return false;
  }
  double parse() {
    final result = addition();
    skipSpaces();
    if (index != source.length || !result.isFinite) {
      throw const FormatException('Invalid expression');
    }
    return result;
  }
  double addition() {
    var result = multiplication();
    while (true) {
      if (take('+')) { result += multiplication(); }
      else if (take('−')) { result -= multiplication(); }
      else { return result; }
    }
  }
  double multiplication() {
    var result = unary();
    while (true) {
      if (take('×')) { result *= unary(); }
      else if (take('÷')) { result /= unary(); }
      else { return result; }
    }
  }
  double unary() {
    if (take('−')) return -unary();
    if (take('+')) return unary();
    var result = primary();
    while (take('%')) { result /= 100; }
    return result;
  }
  double primary() {
    if (take('(')) {
      final result = addition();
      if (!take(')')) throw const FormatException('Missing closing parenthesis');
      return result;
    }
    skipSpaces();
    final start = index;
    var hasDot = false;
    while (index < source.length) {
      final c = source[index];
      if (c == '.') {
        if (hasDot) break;
        hasDot = true;
        index++;
      } else if ('0123456789'.contains(c)) {
        index++;
      } else { break; }
    }
    if (start == index) throw const FormatException('Missing number');
    return double.parse(source.substring(start, index));
  }
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String expression = '';
  bool justCalculated = false;

  String format(double value) {
    if (!value.isFinite) return 'Error';
    if (value == 0) return '0';
    if (value.abs() < 1e13 && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    final formatted = value.toStringAsPrecision(12);
    if (formatted.contains('e') || formatted.contains('E')) return formatted;
    return formatted.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String get preview {
    if (expression.isEmpty) return '';
    try { return format(_MafiCalculatorParser(expression).parse()); }
    on FormatException { return ''; }
    catch (_) { return ''; }
  }

  void press(String key) {
    setState(() {
      if (key == 'C') { expression = ''; justCalculated = false; return; }
      if (key == '⌫') {
        if (expression.isNotEmpty) expression = expression.substring(0, expression.length - 1);
        justCalculated = false;
        return;
      }
      if (key == '=') {
        final answer = preview;
        if (answer.isNotEmpty && answer != 'Error') {
          expression = answer.startsWith('-') ? '−${answer.substring(1)}' : answer;
          justCalculated = true;
        }
        return;
      }
      if (key == '()') {
        final opening = '('.allMatches(expression).length;
        final closing = ')'.allMatches(expression).length;
        final shouldClose = opening > closing && expression.isNotEmpty &&
            (RegExp(r'[0-9)%]$').hasMatch(expression));
        expression += shouldClose ? ')' : '(';
        justCalculated = false;
        return;
      }
      final isOperator = ['+', '−', '×', '÷'].contains(key);
      if (justCalculated && !isOperator && key != '%') expression = '';
      justCalculated = false;
      if (isOperator) {
        if (expression.isEmpty) {
          if (key == '−') expression = '−';
          return;
        }
        if (['+', '−', '×', '÷'].any((op) => expression.endsWith(op))) {
          expression = expression.substring(0, expression.length - 1) + key;
        } else { expression += key; }
        return;
      }
      if (key == '.') {
        final last = expression.split(RegExp(r'[+−×÷()%]')).last;
        if (last.contains('.')) return;
        if (last.isEmpty) expression += '0';
      }
      if (key == '%' && (expression.isEmpty || !RegExp(r'[0-9)]$').hasMatch(expression))) return;
      expression += key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF101012) : const Color(0xFFF8F9FA);
    final normal = isDark ? const Color(0xFF1D1D20) : const Color(0xFFE7E9EC);
    final operation = isDark ? const Color(0xFF303033) : const Color(0xFFD6DADF);
    const accent = Color(0xFF188B7E);
    final danger = isDark ? const Color(0xFFE97579) : const Color(0xFFB32632);
    final foreground = isDark ? Colors.white : const Color(0xFF17191C);
    final muted = isDark ? Colors.white70 : const Color(0xFF525861);
    final rows = <List<String>>[
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['()', '0', '.', '='],
    ];

    final viewport = MediaQuery.sizeOf(context);
    // The dialog must fit inside the real viewport, including on small phones
    // and on Windows when the window is resized.
    final dialogWidth = min(410.0, max(0.0, viewport.width - 32.0));
    final dialogHeight = max(0.0, viewport.height - 48.0);
    const padding = 16.0;
    const gap = 8.0;
    final availableKeypadWidth = max(0.0, dialogWidth - padding * 2);
    final widthLimited = max(0.0, (availableKeypadWidth - gap * 3) / 4);
    // Account for the title, expression, live result, vertical padding and gaps.
    // If the window becomes extremely short, scrolling is available instead.
    final heightLimited = max(0.0, (dialogHeight - 180.0 - gap * 4) / 5);
    final buttonSize = min(78.0, min(widthLimited, max(28.0, heightLimited)));
    final iconSize = (buttonSize * 0.32).clamp(12.0, 27.0);
    final textSize = (buttonSize * 0.43).clamp(12.0, 33.0);

    // The whole display is bounded. FittedBox scales the *text itself*, not
    // only its surrounding rectangle, when the expression becomes long.
    Widget adaptiveNumber(String value, {required double fontSize,
      required double height, required Color color}) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: fontSize, color: color),
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: dialogHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Text(widget.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 20))),
                IconButton(onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: muted)),
              ]),
              const SizedBox(height: 8),
              adaptiveNumber(expression.isEmpty ? '0' : expression,
                fontSize: 38, height: 46, color: foreground),
              adaptiveNumber(preview,
                fontSize: 21, height: 27, color: muted),
              const SizedBox(height: 12),
              for (var r = 0; r < rows.length; r++) ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: buttonSize, height: buttonSize,
                      child: Material(
                        color: rows[r][i] == '=' ? accent : (i == 3 ? operation : normal),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => press(rows[r][i]),
                          child: Center(child: rows[r][i] == '⌫'
                            ? Icon(Icons.backspace_outlined, color: danger, size: iconSize)
                            : Text(rows[r][i], style: TextStyle(
                                color: rows[r][i] == 'C' ? danger
                                  : rows[r][i] == '=' ? Colors.white : foreground,
                                fontSize: rows[r][i] == '()' ? textSize * 0.8 : textSize,
                                fontWeight: FontWeight.w400,
                              )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
                if (r != rows.length - 1) const SizedBox(height: gap),
              ],
            ]),
          ),
        ),
      ),
    );
  }

}

// Help & feedback never reads financial records or API credentials.
// Both feedback sections deliberately use the very same ExpansionTile as FAQ:
// the native chevron, animation, theme colors and layout stay consistent.
class MafiHelpCenter extends StatefulWidget {
  const MafiHelpCenter({super.key, required this.language});
  final String language;

  @override
  State<MafiHelpCenter> createState() => _MafiHelpCenterState();
}

class _MafiHelpCenterState extends State<MafiHelpCenter> {
  // Independent controllers keep both drafts even when an ExpansionTile
  // disposes its collapsed children. Toggling either tile affects neither
  // the other tile nor the corresponding draft.
  final _bugDescription = TextEditingController();
  final _bugLocation = TextEditingController();
  final _ideaDescription = TextEditingController();

  String t(String key) =>
      helpLabels[widget.language]?[key] ?? helpLabels['en']![key] ?? key;

  @override
  void dispose() {
    _bugDescription.dispose();
    _bugLocation.dispose();
    _ideaDescription.dispose();
    super.dispose();
  }

  Future<void> _send(String kind) async {
    final isBug = kind == 'bug';
    final platform = Platform.isWindows
        ? 'Windows'
        : Platform.isAndroid
            ? 'Android'
            : 'Desktop';
    final message = isBug ? _bugDescription.text.trim() : _ideaDescription.text.trim();
    final subject = isBug
        ? 'MafiFlow ($platform) - Bug report'
        : 'MafiFlow ($platform) - Feature suggestion';
    final section = isBug ? _bugLocation.text.trim() : 'Feature suggestion';
    final body = 'MafiFlow ($platform)\n'
        'Language: ${widget.language}\n'
        'Section: $section\n\n'
        '$message\n\n'
        '(Screenshots can be attached in your email app.)';
    final uri = Uri(
      scheme: 'mailto',
      path: 'mafistudio.dev@gmail.com',
      query: Uri(queryParameters: {'subject': subject, 'body': body}).query,
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Email app unavailable');
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('emailConfirm'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('emailFailed'))));
      }
    }
  }

  // Contents live INSIDE the expansion tile, immediately below their title.
  // This is the same structure as each FAQ answer, not a shared card below
  // the two headings (which previously caused the misplaced form bug).
  Widget _feedbackFields({required bool isBug}) {
    final description = isBug ? _bugDescription : _ideaDescription;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBug) ...[
            TextField(
              key: const Key('help-bug-location'),
              controller: _bugLocation,
              decoration: InputDecoration(
                labelText: t('whereBug'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: Key(isBug ? 'help-bug-description' : 'help-idea-description'),
            controller: description,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: t(isBug ? 'describeBug' : 'describeIdea'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(t('emailPrivacy'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: Key(isBug ? 'help-send-bug' : 'help-send-idea'),
            onPressed: description.text.trim().isEmpty
                ? null
                : () => _send(isBug ? 'bug' : 'idea'),
            icon: const Icon(Icons.mail_outline),
            label: Text(t('sendEmail')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('helpCenter'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ExpansionTile(
              key: const PageStorageKey<String>('help-report-bug'),
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(t('reportBug')),
              children: [_feedbackFields(isBug: true)],
            ),
          ),
          Card(
            child: ExpansionTile(
              key: const PageStorageKey<String>('help-suggest-feature'),
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(t('suggestFeature')),
              children: [_feedbackFields(isBug: false)],
            ),
          ),
          const SizedBox(height: 12),
          Text(t('faq'), style: theme.textTheme.titleLarge),
          for (final q in [
            ['faqDataQ', 'faqDataA'],
            ['faqPaymentsQ', 'faqPaymentsA'],
            ['faqAiQ', 'faqAiA'],
            ['faqStatsQ', 'faqStatsA'],
          ])
            Card(
              child: ExpansionTile(
                title: Text(t(q[0])),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(t(q[1])),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
