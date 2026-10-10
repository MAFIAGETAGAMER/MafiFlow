import tkinter as tk
from tkinter import ttk, messagebox, simpledialog, simpledialog
import json, os, sys, urllib.request, urllib.error, threading, queue, math
from datetime import datetime

# Windows HiDPI: evita que Windows escale MafiFlow como una imagen borrosa.
# Per-Monitor V2 cuando está disponible, con fallbacks para Windows anteriores.
if sys.platform == 'win32':
    try:
        import ctypes
        try:
            ctypes.windll.user32.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4))
        except Exception:
            try:
                ctypes.windll.shcore.SetProcessDpiAwareness(2)
            except Exception:
                ctypes.windll.user32.SetProcessDPIAware()
    except Exception:
        pass

APP_DIR=os.path.join(os.getenv('APPDATA') or os.path.expanduser('~'),'MafiFlow')
os.makedirs(APP_DIR,exist_ok=True)
DATA_FILE=os.path.join(APP_DIR,'datos.json')
DEFAULT={'monthly_income':0.0,'rent':0.0,'savings_goal':0.0,'transactions':[],'monthly_payments':[],'processed_months':[],'ai_provider':'OpenAI','ai_api_key':'','ai_model':'','ai_base_url':'','ai_history':[],'setup_completed':False,'language':'es','theme':'light','custom_categories':[]}

def resource(name):
    base=getattr(sys,'_MEIPASS',os.path.dirname(os.path.abspath(__file__)))
    candidates=[os.path.join(base,'assets',name),os.path.join(base,name)]
    for path in candidates:
        if os.path.exists(path): return path
    return candidates[0]

def load_data():
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE,'r',encoding='utf-8') as f:d=json.load(f)
            for k,v in DEFAULT.items():
                if k not in d:d[k]=v.copy() if isinstance(v,list) else v
            if not d.get('monthly_payments') and float(d.get('rent',0) or 0)>0:
                d['monthly_payments']=[{'name':'Renta','amount':float(d['rent']),'active':True}]
            return d
        except: pass
    d=DEFAULT.copy(); d['transactions']=[]; d['monthly_payments']=[]; d['processed_months']=[]; d['ai_history']=[]; return d

def save_data():
    with open(DATA_FILE,'w',encoding='utf-8') as f:json.dump(data,f,ensure_ascii=False,indent=2)
def money(x):return f'${x:,.2f}'
def month_key():return datetime.now().strftime('%Y-%m')
def process_month():
    m=month_key()
    if m in data.get('processed_months',[]):return
    stamp=datetime.now().strftime('%Y-%m-%d %H:%M')
    data['transactions'].append({'date':stamp,'type':'Ingreso mensual','category':'Ingreso mensual','amount':float(data['monthly_income']),'note':'Ingreso mensual automático','auto_month':m})
    for p in data.get('monthly_payments',[]):
        if p.get('active',True) and float(p.get('amount',0) or 0)>0:
            data['transactions'].append({'date':stamp,'type':'Pago mensual','category':'Pago mensual','amount':float(p['amount']),'note':p.get('name','Pago mensual'),'auto_month':m})
    data['processed_months'].append(m); save_data()

data=load_data()
root=tk.Tk()
root.title('MafiFlow 1.3.2')
root.geometry('1180x760')
root.minsize(980,650)
try:
    root.iconphoto(True, tk.PhotoImage(file=resource('MafiFlow.png')))
except Exception:
    pass
# Abrir maximizada para que toda la interfaz sea utilizable desde el primer instante.
try:
    root.state('zoomed')
except Exception:
    pass
THEMES={
'light':{'BG':'#F3F5EE','PANEL':'#FFFFFF','PANEL2':'#FAFBF7','TEXT':'#203128','MUTED':'#758078','GREEN':'#58A66C','ACCENT':'#255F3B','RED':'#D86666','LINE':'#DDE5DC','INPUT':'#FFFFFF','SIDEBAR':'#07533F','NAV_ACTIVE':'#CFF4C9','BUTTON':'#EDF3EC','HEAD':'#EAF1E9','SELECT':'#DCEEDF','TRACK':'#E6EBE5','PURPLE':'#6949A5','INCOME_BG':'#EAF7EC','EXPENSE_BG':'#FDEEEE','SAVING_BG':'#F1ECFA'},
'dark':{'BG':'#151A17','PANEL':'#202722','PANEL2':'#242C26','TEXT':'#EEF4EF','MUTED':'#9BA79E','GREEN':'#6CC982','ACCENT':'#8AD29B','RED':'#EF7777','LINE':'#344139','INPUT':'#29322C','SIDEBAR':'#063D31','NAV_ACTIVE':'#245C48','BUTTON':'#2B352E','HEAD':'#29352D','SELECT':'#35513D','TRACK':'#3A463E','PURPLE':'#B59AE6','INCOME_BG':'#20382A','EXPENSE_BG':'#3B2727','SAVING_BG':'#302A3D'} }
def set_theme_vars(name):
    global BG,PANEL,PANEL2,TEXT,MUTED,GREEN,ACCENT,RED,LINE,INPUT
    t=THEMES.get(name,THEMES['light']); BG=t['BG'];PANEL=t['PANEL'];PANEL2=t['PANEL2'];TEXT=t['TEXT'];MUTED=t['MUTED'];GREEN=t['GREEN'];ACCENT=t['ACCENT'];RED=t['RED'];LINE=t['LINE'];INPUT=t['INPUT']
set_theme_vars(data.get('theme','light'))

LANG_NAMES={'es':'Español','en':'English','fr':'Français','de':'Deutsch','bn':'বাংলা'}
T={
'es':{'edit_category_short':'✎ Editar','edit_category':'Editar categoría','edit_category_prompt':'Corrige el nombre de la categoría:','category_builtin_error':'Las categorías predeterminadas no se pueden editar.','category_exists_error':'Ya existe una categoría con ese nombre.','new_category_short':'+ Nueva categoría','create_category':'Crear categoría','category_prompt':'Escribe el nombre de la nueva categoría:','advanced_stats':'Vista avanzada','simple_stats':'Vista simplificada','expense_detail':'Detalle de gastos','impact':'Impacto','share_expenses':'del gasto mensual','monthly_impact':'Impacto sobre tus gastos del mes','category_analysis':'Análisis por categoría','transactions_count':'movimientos','when':'Cuándo','expense':'Gasto','expenses_nav':'◉  Gastos','expenses_title':'Gastos','expenses_sub':'Consulta tus gastos en general o analiza en detalle dónde se va tu dinero.','overview':'Vista general','advanced_view':'Vista avanzada','expenses_month':'Gastos del mes','expense_count':'Movimientos de gasto','average_expense':'Gasto promedio','manage_categories':'Administrar categorías','new_category':'Nueva categoría','add_category':'Agregar categoría','delete_category':'Eliminar categoría','category_name':'Nombre de categoría','custom_categories':'Tus categorías','no_expenses':'No hay gastos en este mes.','expense_history':'Historial de gastos','stats':'▥  Estadísticas','stats_title':'Estadísticas','stats_sub':'Compara tus ingresos, gastos y ahorro con meses anteriores.','month_compare':'Comparación de meses','monthly_summary':'Resumen mensual','difference_previous':'Diferencia vs. mes anterior','bars':'Barras','line':'Línea','pie':'Pastel','category_spending':'Gastos por categoría','no_history':'Todavía no hay suficientes datos para mostrar esta gráfica.','auto_income_note':'Se añadirá automáticamente {amount} al comenzar cada mes.','total':'Total','home':'⌂  Inicio','moves':'≡  Movimientos','monthly':'▣  Pagos mensuales','ai':'✦  Consejero IA','settings':'⚙  Configuración','local':'Los datos se guardan\nlocalmente en tu PC.','home_title':'Inicio','home_sub':'Un vistazo claro a tu mes, sin llenar la pantalla de cosas.','available':'Disponible','income':'Ingresos','spent':'Gastos','savings':'Ahorro objetivo','recent':'Últimos movimientos','monthly_title':'Pagos mensuales','moves_title':'Movimientos','moves_sub':'Agrega o corrige ingresos y gastos. El historial tiene su propio espacio.','new_move':'Nuevo movimiento','type':'Tipo','category':'Categoría','amount':'Cantidad','note':'Nota','add_move':'Agregar movimiento','date':'Fecha','delete':'Eliminar','edit_amount':'Editar cantidad','monthly_sub':'Tus obligaciones se descuentan automáticamente una sola vez al comenzar cada mes.','new_payment':'Nuevo pago','name':'Nombre','monthly_amount':'Cantidad mensual','add_payment':'Agregar pago mensual','payment':'Pago','status':'Estado','toggle':'Activar / pausar','edit':'Editar','ai_title':'Consejero IA','ai_sub':'Un chat amplio para hablar con tu consejero. Tus datos del mes se incluyen automáticamente como contexto.','write_ai':'Escríbele a tu consejero','send':'Enviar','settings_title':'Configuración','settings_sub':'Tus datos se guardan localmente. El Consejero IA es opcional y puede usar distintos proveedores.','auto_income':'Ingreso mensual automático','saving_goal':'Meta de ahorro','ai_provider':'Proveedor de IA','ai_key':'API Key de IA','model':'Modelo','base_url':'Base URL (solo proveedor personalizado)','language':'Idioma / Language','save':'Guardar cambios','active':'Activo','paused':'Pausado','no_moves':'Todavía no hay movimientos.','you':'Tú','advisor':'Consejero IA','welcome':'Bienvenido a MafiFlow','setup':'Configura tus finanzas en menos de un minuto.','privacy':'Nada se sube a MafiFlow. Tus datos quedan en tu PC.\nEl Consejero IA es opcional. Puedes conectar tu propio proveedor y API Key desde Configuración.','usual_income':'Ingreso mensual habitual','optional_saving':'Meta de ahorro mensual (opcional)','first_payment':'Primer pago mensual (opcional)','name_example':'Nombre — por ejemplo, Renta','start':'Empezar a usar MafiFlow','later':'Podrás cambiar todo esto después en Configuración y Pagos mensuales.','expense_type':'Gasto','extra_income_type':'Ingreso extra','monthly_income_type':'Ingreso mensual','monthly_payment_type':'Pago mensual','cat_food':'Comida','cat_transport':'Transporte','cat_phone':'Teléfono/Internet','cat_fun':'Entretenimiento','cat_shopping':'Compras','cat_health':'Salud','cat_studies':'Estudios','cat_project':'Juego/Proyecto','cat_other':'Otro','paused_suffix':'pausado','savings_progress':'Progreso de ahorro','savings_target':'Meta de ahorro','appearance':'Apariencia','theme':'Tema','light_mode':'Claro','dark_mode':'Oscuro','rent':'Renta','chat_hint':'Puedes preguntarme, por ejemplo: “¿Puedo gastar $70 esta semana?”'},
'en':{'edit_category_short':'✎ Edit','edit_category':'Edit category','edit_category_prompt':'Correct the category name:','category_builtin_error':'Default categories cannot be edited.','category_exists_error':'A category with that name already exists.','new_category_short':'+ New category','create_category':'Create category','category_prompt':'Enter the name of the new category:','advanced_stats':'Advanced view','simple_stats':'Simple view','expense_detail':'Expense detail','impact':'Impact','share_expenses':'of monthly spending','monthly_impact':'Impact on your monthly spending','category_analysis':'Category analysis','transactions_count':'transactions','when':'When','expense':'Expense','expenses_nav':'◉  Expenses','expenses_title':'Expenses','expenses_sub':'See your overall spending or analyze in detail where your money goes.','overview':'Overview','advanced_view':'Advanced view','expenses_month':'Expenses this month','expense_count':'Expense transactions','average_expense':'Average expense','manage_categories':'Manage categories','new_category':'New category','add_category':'Add category','delete_category':'Delete category','category_name':'Category name','custom_categories':'Your categories','no_expenses':'There are no expenses this month.','expense_history':'Expense history','stats':'▥  Statistics','stats_title':'Statistics','stats_sub':'Compare your income, expenses and savings with previous months.','month_compare':'Month comparison','monthly_summary':'Monthly summary','difference_previous':'Difference vs. previous month','bars':'Bars','line':'Line','pie':'Pie','category_spending':'Spending by category','no_history':'There is not enough data to display this chart yet.','auto_income_note':'{amount} will be added automatically at the start of each month.','total':'Total','home':'⌂  Home','moves':'≡  Transactions','monthly':'▣  Monthly payments','ai':'✦  AI Advisor','settings':'⚙  Settings','local':'Your data is stored\nlocally on your PC.','home_title':'Home','home_sub':'A clear look at your month, without cluttering the screen.','available':'Available','income':'Income','spent':'Expenses','savings':'Savings goal','recent':'Recent transactions','monthly_title':'Monthly payments','moves_title':'Transactions','moves_sub':'Add or correct income and expenses. Your history has its own space.','new_move':'New transaction','type':'Type','category':'Category','amount':'Amount','note':'Note','add_move':'Add transaction','date':'Date','delete':'Delete','edit_amount':'Edit amount','monthly_sub':'Your obligations are deducted automatically once at the start of each month.','new_payment':'New payment','name':'Name','monthly_amount':'Monthly amount','add_payment':'Add monthly payment','payment':'Payment','status':'Status','toggle':'Activate / pause','edit':'Edit','ai_title':'AI Advisor','ai_sub':'A spacious chat to talk with your advisor. Your monthly data is automatically included as context.','write_ai':'Write to your advisor','send':'Send','settings_title':'Settings','settings_sub':'Your data is stored locally. The AI Advisor is optional and can use different providers.','auto_income':'Automatic monthly income','saving_goal':'Savings goal','ai_provider':'AI provider','ai_key':'AI API Key','model':'Model','base_url':'Base URL (custom provider only)','language':'Language','save':'Save changes','active':'Active','paused':'Paused','no_moves':'No transactions yet.','you':'You','advisor':'AI Advisor','welcome':'Welcome to MafiFlow','setup':'Set up your finances in less than a minute.','privacy':'Nothing is uploaded to MafiFlow. Your data stays on your PC.\nThe AI Advisor is optional. You can connect your own provider and API Key in Settings.','usual_income':'Usual monthly income','optional_saving':'Monthly savings goal (optional)','first_payment':'First monthly payment (optional)','name_example':'Name — for example, Rent','start':'Start using MafiFlow','later':'You can change all of this later in Settings and Monthly payments.','expense_type':'Expense','extra_income_type':'Extra income','monthly_income_type':'Monthly income','monthly_payment_type':'Monthly payment','cat_food':'Food','cat_transport':'Transport','cat_phone':'Phone/Internet','cat_fun':'Entertainment','cat_shopping':'Shopping','cat_health':'Health','cat_studies':'Studies','cat_project':'Game/Project','cat_other':'Other','paused_suffix':'paused','savings_progress':'Savings progress','savings_target':'Savings goal','appearance':'Appearance','theme':'Theme','light_mode':'Light','dark_mode':'Dark','rent':'Rent','chat_hint':'You can ask me, for example: “Can I spend $70 this week?”'},
'fr':{'edit_category_short':'✎ Modifier','edit_category':'Modifier la catégorie','edit_category_prompt':'Corrigez le nom de la catégorie :','category_builtin_error':'Les catégories par défaut ne peuvent pas être modifiées.','category_exists_error':'Une catégorie portant ce nom existe déjà.','new_category_short':'+ Nouvelle catégorie','create_category':'Créer une catégorie','category_prompt':'Saisissez le nom de la nouvelle catégorie :','advanced_stats':'Vue avancée','simple_stats':'Vue simplifiée','expense_detail':'Détail des dépenses','impact':'Impact','share_expenses':'des dépenses mensuelles','monthly_impact':'Impact sur vos dépenses du mois','category_analysis':'Analyse par catégorie','transactions_count':'opérations','when':'Quand','expense':'Dépense','expenses_nav':'◉  Dépenses','expenses_title':'Dépenses','expenses_sub':'Consultez vos dépenses globales ou analysez en détail où va votre argent.','overview':'Vue générale','advanced_view':'Vue avancée','expenses_month':'Dépenses du mois','expense_count':'Opérations de dépense','average_expense':'Dépense moyenne','manage_categories':'Gérer les catégories','new_category':'Nouvelle catégorie','add_category':'Ajouter la catégorie','delete_category':'Supprimer la catégorie','category_name':'Nom de la catégorie','custom_categories':'Vos catégories','no_expenses':'Aucune dépense ce mois-ci.','expense_history':'Historique des dépenses','stats':'▥  Statistiques','stats_title':'Statistiques','stats_sub':'Comparez vos revenus, dépenses et épargne avec les mois précédents.','month_compare':'Comparaison des mois','monthly_summary':'Résumé mensuel','difference_previous':'Différence par rapport au mois précédent','bars':'Barres','line':'Ligne','pie':'Camembert','category_spending':'Dépenses par catégorie','no_history':'Il n’y a pas encore assez de données pour afficher ce graphique.','auto_income_note':'{amount} sera ajouté automatiquement au début de chaque mois.','total':'Total','home':'⌂  Accueil','moves':'≡  Mouvements','monthly':'▣  Paiements mensuels','ai':'✦  Conseiller IA','settings':'⚙  Paramètres','local':'Vos données sont stockées\nlocalement sur votre PC.','home_title':'Accueil','home_sub':'Un aperçu clair de votre mois, sans encombrer l’écran.','available':'Disponible','income':'Revenus','spent':'Dépenses','savings':'Objectif d’épargne','recent':'Derniers mouvements','monthly_title':'Paiements mensuels','moves_title':'Mouvements','moves_sub':'Ajoutez ou corrigez vos revenus et dépenses.','new_move':'Nouveau mouvement','type':'Type','category':'Catégorie','amount':'Montant','note':'Note','add_move':'Ajouter le mouvement','date':'Date','delete':'Supprimer','edit_amount':'Modifier le montant','monthly_sub':'Vos obligations sont déduites automatiquement une seule fois au début de chaque mois.','new_payment':'Nouveau paiement','name':'Nom','monthly_amount':'Montant mensuel','add_payment':'Ajouter le paiement mensuel','payment':'Paiement','status':'État','toggle':'Activer / suspendre','edit':'Modifier','ai_title':'Conseiller IA','ai_sub':'Discutez avec votre conseiller. Les données du mois sont ajoutées automatiquement au contexte.','write_ai':'Écrivez à votre conseiller','send':'Envoyer','settings_title':'Paramètres','settings_sub':'Vos données restent locales. Le Conseiller IA est facultatif et accepte différents fournisseurs.','auto_income':'Revenu mensuel automatique','saving_goal':'Objectif d’épargne','ai_provider':'Fournisseur IA','ai_key':'Clé API IA','model':'Modèle','base_url':'URL de base (fournisseur personnalisé uniquement)','language':'Langue / Language','save':'Enregistrer','active':'Actif','paused':'Suspendu','no_moves':'Aucun mouvement pour le moment.','you':'Vous','advisor':'Conseiller IA','welcome':'Bienvenue dans MafiFlow','setup':'Configurez vos finances en moins d’une minute.','privacy':'Rien n’est envoyé à MafiFlow. Vos données restent sur votre PC.\nLe Conseiller IA est facultatif. Configurez votre fournisseur et votre clé API dans Paramètres.','usual_income':'Revenu mensuel habituel','optional_saving':'Objectif d’épargne mensuel (facultatif)','first_payment':'Premier paiement mensuel (facultatif)','name_example':'Nom — par exemple, Loyer','start':'Commencer avec MafiFlow','later':'Vous pourrez tout modifier plus tard dans Paramètres et Paiements mensuels.','expense_type':'Dépense','extra_income_type':'Revenu supplémentaire','monthly_income_type':'Revenu mensuel','monthly_payment_type':'Paiement mensuel','cat_food':'Alimentation','cat_transport':'Transport','cat_phone':'Téléphone/Internet','cat_fun':'Divertissement','cat_shopping':'Achats','cat_health':'Santé','cat_studies':'Études','cat_project':'Jeu/Projet','cat_other':'Autre','paused_suffix':'suspendu','savings_progress':'Progression de l’épargne','savings_target':'Objectif d’épargne','appearance':'Apparence','theme':'Thème','light_mode':'Clair','dark_mode':'Sombre','rent':'Loyer','chat_hint':'Vous pouvez me demander, par exemple : « Puis-je dépenser 70 $ cette semaine ? »'},
'de':{'edit_category_short':'✎ Bearbeiten','edit_category':'Kategorie bearbeiten','edit_category_prompt':'Korrigiere den Kategorienamen:','category_builtin_error':'Standardkategorien können nicht bearbeitet werden.','category_exists_error':'Eine Kategorie mit diesem Namen existiert bereits.','new_category_short':'+ Neue Kategorie','create_category':'Kategorie erstellen','category_prompt':'Gib den Namen der neuen Kategorie ein:','advanced_stats':'Erweiterte Ansicht','simple_stats':'Einfache Ansicht','expense_detail':'Ausgabendetails','impact':'Auswirkung','share_expenses':'der monatlichen Ausgaben','monthly_impact':'Auswirkung auf deine Monatsausgaben','category_analysis':'Kategorieanalyse','transactions_count':'Transaktionen','when':'Wann','expense':'Ausgabe','expenses_nav':'◉  Ausgaben','expenses_title':'Ausgaben','expenses_sub':'Sieh deine gesamten Ausgaben oder analysiere detailliert, wohin dein Geld fließt.','overview':'Übersicht','advanced_view':'Erweiterte Ansicht','expenses_month':'Ausgaben diesen Monat','expense_count':'Ausgabentransaktionen','average_expense':'Durchschnittliche Ausgabe','manage_categories':'Kategorien verwalten','new_category':'Neue Kategorie','add_category':'Kategorie hinzufügen','delete_category':'Kategorie löschen','category_name':'Kategoriename','custom_categories':'Deine Kategorien','no_expenses':'Diesen Monat gibt es keine Ausgaben.','expense_history':'Ausgabenverlauf','stats':'▥  Statistiken','stats_title':'Statistiken','stats_sub':'Vergleiche Einnahmen, Ausgaben und Ersparnisse mit früheren Monaten.','month_compare':'Monatsvergleich','monthly_summary':'Monatsübersicht','difference_previous':'Unterschied zum Vormonat','bars':'Balken','line':'Linie','pie':'Kreis','category_spending':'Ausgaben nach Kategorie','no_history':'Es gibt noch nicht genügend Daten für dieses Diagramm.','auto_income_note':'{amount} wird zu Beginn jedes Monats automatisch hinzugefügt.','total':'Gesamt','home':'⌂  Start','moves':'≡  Transaktionen','monthly':'▣  Monatliche Zahlungen','ai':'✦  KI-Berater','settings':'⚙  Einstellungen','local':'Deine Daten werden lokal\nauf deinem PC gespeichert.','home_title':'Start','home_sub':'Ein klarer Überblick über deinen Monat, ohne unnötige Unordnung.','available':'Verfügbar','income':'Einnahmen','spent':'Ausgaben','savings':'Sparziel','recent':'Letzte Transaktionen','monthly_title':'Monatliche Zahlungen','moves_title':'Transaktionen','moves_sub':'Füge Einnahmen und Ausgaben hinzu oder korrigiere sie.','new_move':'Neue Transaktion','type':'Typ','category':'Kategorie','amount':'Betrag','note':'Notiz','add_move':'Transaktion hinzufügen','date':'Datum','delete':'Löschen','edit_amount':'Betrag bearbeiten','monthly_sub':'Deine Verpflichtungen werden einmal zu Beginn jedes Monats automatisch abgezogen.','new_payment':'Neue Zahlung','name':'Name','monthly_amount':'Monatlicher Betrag','add_payment':'Monatliche Zahlung hinzufügen','payment':'Zahlung','status':'Status','toggle':'Aktivieren / pausieren','edit':'Bearbeiten','ai_title':'KI-Berater','ai_sub':'Chatte mit deinem Berater. Deine Monatsdaten werden automatisch als Kontext hinzugefügt.','write_ai':'Schreibe deinem Berater','send':'Senden','settings_title':'Einstellungen','settings_sub':'Deine Daten bleiben lokal. Der KI-Berater ist optional und unterstützt verschiedene Anbieter.','auto_income':'Automatisches Monatseinkommen','saving_goal':'Sparziel','ai_provider':'KI-Anbieter','ai_key':'KI-API-Schlüssel','model':'Modell','base_url':'Basis-URL (nur benutzerdefinierter Anbieter)','language':'Sprache / Language','save':'Änderungen speichern','active':'Aktiv','paused':'Pausiert','no_moves':'Noch keine Transaktionen.','you':'Du','advisor':'KI-Berater','welcome':'Willkommen bei MafiFlow','setup':'Richte deine Finanzen in weniger als einer Minute ein.','privacy':'Nichts wird zu MafiFlow hochgeladen. Deine Daten bleiben auf deinem PC.\nDer KI-Berater ist optional. Anbieter und API-Schlüssel kannst du in Einstellungen verbinden.','usual_income':'Übliches Monatseinkommen','optional_saving':'Monatliches Sparziel (optional)','first_payment':'Erste monatliche Zahlung (optional)','name_example':'Name — zum Beispiel Miete','start':'MafiFlow starten','later':'Du kannst dies später in Einstellungen und Monatliche Zahlungen ändern.','expense_type':'Ausgabe','extra_income_type':'Zusätzliches Einkommen','monthly_income_type':'Monatliches Einkommen','monthly_payment_type':'Monatliche Zahlung','cat_food':'Lebensmittel','cat_transport':'Transport','cat_phone':'Telefon/Internet','cat_fun':'Unterhaltung','cat_shopping':'Einkäufe','cat_health':'Gesundheit','cat_studies':'Studium','cat_project':'Spiel/Projekt','cat_other':'Sonstiges','paused_suffix':'pausiert','savings_progress':'Sparfortschritt','savings_target':'Sparziel','appearance':'Darstellung','theme':'Design','light_mode':'Hell','dark_mode':'Dunkel','rent':'Miete','chat_hint':'Du kannst mich zum Beispiel fragen: „Kann ich diese Woche 70 $ ausgeben?“'},
'bn':{'edit_category_short':'✎ সম্পাদনা','edit_category':'বিভাগ সম্পাদনা','edit_category_prompt':'বিভাগের নাম ঠিক করুন:','category_builtin_error':'ডিফল্ট বিভাগ সম্পাদনা করা যায় না।','category_exists_error':'এই নামে একটি বিভাগ ইতিমধ্যে আছে।','new_category_short':'+ নতুন বিভাগ','create_category':'বিভাগ তৈরি করুন','category_prompt':'নতুন বিভাগের নাম লিখুন:','advanced_stats':'উন্নত দৃশ্য','simple_stats':'সহজ দৃশ্য','expense_detail':'খরচের বিস্তারিত','impact':'প্রভাব','share_expenses':'মাসিক খরচের','monthly_impact':'এই মাসের খরচে প্রভাব','category_analysis':'বিভাগ বিশ্লেষণ','transactions_count':'লেনদেন','when':'কখন','expense':'খরচ','expenses_nav':'◉  খরচ','expenses_title':'খরচ','expenses_sub':'সামগ্রিক খরচ দেখুন অথবা বিস্তারিতভাবে বিশ্লেষণ করুন টাকা কোথায় যাচ্ছে।','overview':'সাধারণ দৃশ্য','advanced_view':'উন্নত দৃশ্য','expenses_month':'এই মাসের খরচ','expense_count':'খরচের লেনদেন','average_expense':'গড় খরচ','manage_categories':'বিভাগ পরিচালনা','new_category':'নতুন বিভাগ','add_category':'বিভাগ যোগ করুন','delete_category':'বিভাগ মুছুন','category_name':'বিভাগের নাম','custom_categories':'আপনার বিভাগ','no_expenses':'এই মাসে কোনো খরচ নেই।','expense_history':'খরচের ইতিহাস','stats':'▥  পরিসংখ্যান','stats_title':'পরিসংখ্যান','stats_sub':'আগের মাসগুলোর সাথে আপনার আয়, খরচ ও সঞ্চয় তুলনা করুন।','month_compare':'মাসের তুলনা','monthly_summary':'মাসিক সারাংশ','difference_previous':'আগের মাসের তুলনায় পার্থক্য','bars':'বার','line':'লাইন','pie':'পাই','category_spending':'বিভাগ অনুযায়ী খরচ','no_history':'এই চার্ট দেখানোর জন্য এখনো যথেষ্ট তথ্য নেই।','auto_income_note':'প্রতি মাসের শুরুতে স্বয়ংক্রিয়ভাবে {amount} যোগ হবে।','total':'মোট','home':'⌂  হোম','moves':'≡  লেনদেন','monthly':'▣  মাসিক পেমেন্ট','ai':'✦  AI উপদেষ্টা','settings':'⚙  সেটিংস','local':'আপনার তথ্য আপনার পিসিতেই\nস্থানীয়ভাবে সংরক্ষিত থাকে।','home_title':'হোম','home_sub':'অপ্রয়োজনীয় ভিড় ছাড়াই আপনার মাসের পরিষ্কার চিত্র।','available':'উপলভ্য','income':'আয়','spent':'খরচ','savings':'সঞ্চয়ের লক্ষ্য','recent':'সাম্প্রতিক লেনদেন','monthly_title':'মাসিক পেমেন্ট','moves_title':'লেনদেন','moves_sub':'আয় ও খরচ যোগ করুন বা সংশোধন করুন।','new_move':'নতুন লেনদেন','type':'ধরন','category':'বিভাগ','amount':'পরিমাণ','note':'নোট','add_move':'লেনদেন যোগ করুন','date':'তারিখ','delete':'মুছুন','edit_amount':'পরিমাণ সম্পাদনা','monthly_sub':'প্রতি মাসের শুরুতে আপনার নিয়মিত পেমেন্ট একবার স্বয়ংক্রিয়ভাবে কাটা হয়।','new_payment':'নতুন পেমেন্ট','name':'নাম','monthly_amount':'মাসিক পরিমাণ','add_payment':'মাসিক পেমেন্ট যোগ করুন','payment':'পেমেন্ট','status':'অবস্থা','toggle':'সক্রিয় / বিরতি','edit':'সম্পাদনা','ai_title':'AI উপদেষ্টা','ai_sub':'আপনার উপদেষ্টার সাথে চ্যাট করুন। মাসের তথ্য স্বয়ংক্রিয়ভাবে প্রসঙ্গ হিসেবে যুক্ত হয়।','write_ai':'আপনার উপদেষ্টাকে লিখুন','send':'পাঠান','settings_title':'সেটিংস','settings_sub':'আপনার তথ্য স্থানীয়ভাবে থাকে। AI উপদেষ্টা ঐচ্ছিক এবং বিভিন্ন প্রদানকারী ব্যবহার করতে পারে।','auto_income':'স্বয়ংক্রিয় মাসিক আয়','saving_goal':'সঞ্চয়ের লক্ষ্য','ai_provider':'AI প্রদানকারী','ai_key':'AI API Key','model':'মডেল','base_url':'Base URL (শুধু কাস্টম প্রদানকারী)','language':'ভাষা / Language','save':'পরিবর্তন সংরক্ষণ','active':'সক্রিয়','paused':'বিরত','no_moves':'এখনও কোনো লেনদেন নেই।','you':'আপনি','advisor':'AI উপদেষ্টা','welcome':'MafiFlow-তে স্বাগতম','setup':'এক মিনিটেরও কম সময়ে আপনার অর্থব্যবস্থা সেট করুন।','privacy':'MafiFlow-এ কিছু আপলোড হয় না। আপনার তথ্য আপনার পিসিতেই থাকে।\nAI উপদেষ্টা ঐচ্ছিক। সেটিংস থেকে নিজের প্রদানকারী ও API Key যুক্ত করতে পারেন।','usual_income':'সাধারণ মাসিক আয়','optional_saving':'মাসিক সঞ্চয়ের লক্ষ্য (ঐচ্ছিক)','first_payment':'প্রথম মাসিক পেমেন্ট (ঐচ্ছিক)','name_example':'নাম — যেমন, ভাড়া','start':'MafiFlow ব্যবহার শুরু করুন','later':'পরে সেটিংস ও মাসিক পেমেন্ট থেকে সবকিছু পরিবর্তন করতে পারবেন।','expense_type':'খরচ','extra_income_type':'অতিরিক্ত আয়','monthly_income_type':'মাসিক আয়','monthly_payment_type':'মাসিক পেমেন্ট','cat_food':'খাবার','cat_transport':'যাতায়াত','cat_phone':'ফোন/ইন্টারনেট','cat_fun':'বিনোদন','cat_shopping':'কেনাকাটা','cat_health':'স্বাস্থ্য','cat_studies':'পড়াশোনা','cat_project':'গেম/প্রজেক্ট','cat_other':'অন্যান্য','paused_suffix':'বিরত','savings_progress':'সঞ্চয়ের অগ্রগতি','savings_target':'সঞ্চয়ের লক্ষ্য','appearance':'চেহারা','theme':'থিম','light_mode':'হালকা','dark_mode':'গাঢ়','rent':'ভাড়া','chat_hint':'আপনি আমাকে জিজ্ঞেস করতে পারেন, যেমন: “আমি কি এই সপ্তাহে $70 খরচ করতে পারি?”'}
}
# Extra live-UI strings added in BETA 11. Keeping these outside the large base
# dictionaries makes the migration safe for existing user data.
_EXTRA_I18N={
'es':{'delete_category_short':'✕ Eliminar','delete_category_confirm':'¿Eliminar la categoría “{name}”?\n\nLos movimientos existentes de esa categoría pasarán a “Otro”.','category_deleted':'Categoría eliminada.'},
'en':{'delete_category_short':'✕ Delete','delete_category_confirm':'Delete the category “{name}”?\n\nExisting transactions in that category will be moved to “Other”.','category_deleted':'Category deleted.'},
'fr':{'delete_category_short':'✕ Supprimer','delete_category_confirm':'Supprimer la catégorie « {name} » ?\n\nLes opérations existantes de cette catégorie seront déplacées vers « Autre ».','category_deleted':'Catégorie supprimée.'},
'de':{'delete_category_short':'✕ Löschen','delete_category_confirm':'Kategorie „{name}“ löschen?\n\nVorhandene Transaktionen dieser Kategorie werden nach „Sonstiges“ verschoben.','category_deleted':'Kategorie gelöscht.'},
'bn':{'delete_category_short':'✕ মুছুন','delete_category_confirm':'“{name}” বিভাগটি মুছবেন?\n\nএই বিভাগের বিদ্যমান লেনদেনগুলো “অন্যান্য”-তে সরানো হবে।','category_deleted':'বিভাগ মুছে ফেলা হয়েছে।'}
}
for _lang,_items in _EXTRA_I18N.items(): T[_lang].update(_items)

def tr(key): return T.get(data.get('language','es'),T['es']).get(key,T['es'].get(key,key))

# Valores internos estables para movimientos. Se guardan en español/canónico para no
# romper datos existentes; la interfaz muestra la traducción del idioma activo.
TYPE_KEYS={
    'Gasto':'expense_type','Ingreso extra':'extra_income_type',
    'Ingreso mensual':'monthly_income_type','Pago mensual':'monthly_payment_type'
}
CATEGORY_KEYS={
    'Comida':'cat_food','Transporte':'cat_transport','Teléfono/Internet':'cat_phone',
    'Entretenimiento':'cat_fun','Compras':'cat_shopping','Salud':'cat_health',
    'Estudios':'cat_studies','Juego/Proyecto':'cat_project','Otro':'cat_other',
    'Ingreso mensual':'monthly_income_type','Pago mensual':'monthly_payment_type'
}
NOTE_KEYS={'Ingreso mensual automático':'auto_income','Renta':'rent'}


def semantic_label(value, mapping):
    return tr(mapping.get(value,'')) if value in mapping else value


def ui_semantic(value, mapping=None):
    """Translate canonical OR previously translated built-in values to current UI language."""
    if value is None: return ''
    raw=str(value)
    mp=mapping or {}
    lang=data.get('language','es')
    # Direct canonical lookup.
    key=mp.get(raw)
    if key:
        return tr(key)
    # If the stored value is a translation from any supported language, recover its key.
    for canonical,k in mp.items():
        if raw == canonical:
            return tr(k)
        for source_lang in T:
            if T[source_lang].get(k) == raw:
                return tr(k)
    # Legacy semantic values/notes.
    legacy_keys={
        'Ingreso mensual automático':'auto_income','Automatic monthly income':'auto_income',
        'Revenu mensuel automatique':'auto_income','Automatisches Monatseinkommen':'auto_income',
        'স্বয়ংক্রিয় মাসিক আয়':'auto_income',
        'Renta':'rent','Rent':'rent','Loyer':'rent','Miete':'rent','ভাড়া':'rent'
    }
    if raw in legacy_keys:
        return tr(legacy_keys[raw])
    return raw

def canonical_type(value):
    v=str(value)
    aliases={
      'Gasto':['Gasto','Expense','Dépense','Ausgabe','খরচ'],
      'Ingreso extra':['Ingreso extra','Extra income','Revenu supplémentaire','Zusätzliches Einkommen','অতিরিক্ত আয়']
    }
    for canonical, vals in aliases.items():
        if v in vals: return canonical
    return v

def canonical_from_display(value, mapping):
    # Acepta etiquetas de cualquiera de los idiomas para que cambiar de idioma en vivo
    # nunca cambie el significado de los datos guardados.
    for canonical,key in mapping.items():
        for lang in T:
            if T[lang].get(key)==value:
                return canonical
    return value

def normalize_saved_semantics():
    """Repair legacy rows that older betas accidentally saved in the display language."""
    changed=False
    for tx in data.get('transactions',[]):
        old=tx.get('type',''); new=canonical_from_display(old,TYPE_KEYS)
        if new!=old: tx['type']=new; changed=True
        old=tx.get('category',''); new=canonical_from_display(old,CATEGORY_KEYS)
        if new!=old: tx['category']=new; changed=True
        note=tx.get('note','')
        # Only normalize system-generated notes; user notes remain exactly as written.
        for canonical,key in NOTE_KEYS.items():
            if any(note==T[lang].get(key) for lang in T):
                if note!=canonical: tx['note']=canonical; changed=True
                break
    if changed: save_data()

normalize_saved_semantics()

def type_choices(): return [ui_semantic('Gasto',TYPE_KEYS), ui_semantic('Ingreso extra',TYPE_KEYS)]
def category_choices():
    canonical_builtins=['Comida','Transporte','Teléfono/Internet','Entretenimiento','Compras','Salud','Estudios','Juego/Proyecto']
    builtins=[ui_semantic(x,CATEGORY_KEYS) for x in canonical_builtins]
    other=ui_semantic('Otro',CATEGORY_KEYS)
    # Las categorías personales conservan exactamente el nombre escrito por el usuario.
    # Filtramos cualquier traducción accidental de una categoría del sistema y dejamos "Otro" siempre al final.
    reserved=set()
    for canonical,key in CATEGORY_KEYS.items():
        reserved.add(canonical.casefold())
        for lang in T:
            val=T[lang].get(key)
            if val: reserved.add(str(val).casefold())
    custom=[x for x in data.get('custom_categories',[]) if str(x).casefold() not in reserved]
    return builtins+custom+[other]
root.configure(bg=BG)
style=ttk.Style();
try:style.theme_use('clam')
except:pass
style.configure('Treeview',background=PANEL2,fieldbackground=PANEL2,foreground=TEXT,rowheight=32,borderwidth=0,font=('Segoe UI',10))
style.configure('Treeview.Heading',background='#EAF1E9',foreground=TEXT,borderwidth=0,font=('Segoe UI',10,'bold'))
style.map('Treeview',background=[('selected','#DCEEDF')],foreground=[('selected',TEXT)])
style.configure('TCombobox',fieldbackground='#ffffff',background='#ffffff',foreground='#111111',arrowcolor='#111111')
style.map('TCombobox',fieldbackground=[('readonly','#ffffff')],foreground=[('readonly','#111111')],selectbackground=[('readonly','#ffffff')],selectforeground=[('readonly','#111111')])
root.option_add('*TCombobox*Listbox.background','#ffffff')
root.option_add('*TCombobox*Listbox.foreground','#111111')
root.option_add('*TCombobox*Listbox.selectBackground','#d9e6dc')
root.option_add('*TCombobox*Listbox.selectForeground','#111111')

# Clean background for UI 1.2
bg_img=None

shell=tk.Frame(root,bg=BG,highlightthickness=1,highlightbackground=LINE); shell.place(relx=.018,rely=.025,relwidth=.964,relheight=.95)
sidebar=tk.Frame(shell,bg=THEMES[data.get('theme','light')]['SIDEBAR'],width=270); sidebar.pack(side='left',fill='y'); sidebar.pack_propagate(False)
content=tk.Frame(shell,bg=BG); content.pack(side='left',fill='both',expand=True)

logo_wrap=tk.Frame(sidebar,bg=THEMES[data.get('theme','light')]['SIDEBAR'])
logo_wrap.pack(fill='x',padx=10,pady=(10,12))
wordmark_img=None
try:
    brand_source=Image.open(resource('MafiFlow_Wordmark.png')).convert('RGBA')
    brand_source.thumbnail((205,53),Image.Resampling.LANCZOS)
    wordmark_img=ImageTk.PhotoImage(brand_source)
    wordmark_label=tk.Label(logo_wrap,image=wordmark_img,bg=logo_wrap.cget('bg'),bd=0,highlightthickness=0)
    wordmark_label.pack(anchor='w',padx=0)
except Exception:
    wordmark_label=tk.Label(logo_wrap,text='MafiFlow',bg=logo_wrap.cget('bg'),fg='#FFFFFF',font=('Segoe UI',22,'bold'))
    wordmark_label.pack(anchor='center')

pages={}; nav_buttons={}
def page(name):
    f=tk.Frame(content,bg=BG); pages[name]=f; return f
def show_page(name):
    for f in pages.values():f.pack_forget()
    pages[name].pack(fill='both',expand=True)
    for n,b in nav_buttons.items():b.configure(bg=THEMES[data.get('theme','light')]['NAV_ACTIVE'] if n==name else THEMES[data.get('theme','light')]['SIDEBAR'],fg='#173D28' if n==name and data.get('theme','light')=='light' else '#FFFFFF')
    refresh_all()

def nav(name,label):
    b=tk.Button(sidebar,text=label,anchor='w',relief='flat',bd=0,bg=THEMES[data.get('theme','light')]['SIDEBAR'],fg='#F5FFF8',activebackground=THEMES[data.get('theme','light')]['NAV_ACTIVE'],activeforeground=ACCENT,font=('Segoe UI',11),padx=20,pady=12,command=lambda:show_page(name))
    b.pack(fill='x',padx=10,pady=2); nav_buttons[name]=b

for n,k in [('home','home'),('moves','moves'),('monthly','monthly'),('stats','stats'),('ai','ai'),('settings','settings')]:nav(n,tr(k))
sidebar_local=tk.Label(sidebar,text=tr('local'),bg=THEMES[data.get('theme','light')]['SIDEBAR'],fg='#BFD9CB',justify='left',font=('Segoe UI',8)); sidebar_local.pack(side='bottom',anchor='w',padx=22,pady=20)

# helpers
def header(parent,title,sub=''):
    h=tk.Frame(parent,bg=BG); h.pack(fill='x',padx=32,pady=(28,20)); tk.Label(h,text=title,bg=BG,fg=TEXT,font=('Segoe UI',22,'bold')).pack(anchor='w')
    if sub:tk.Label(h,text=sub,bg=BG,fg=MUTED,font=('Segoe UI',10)).pack(anchor='w',pady=(3,0))
def card(parent):return tk.Frame(parent,bg=PANEL,highlightthickness=1,highlightbackground=LINE)
def button(parent,text,cmd,accent=False):return tk.Button(parent,text=text,command=cmd,relief='flat',bd=0,bg=GREEN if accent else '#EDF3EC',fg='#FFFFFF' if accent else TEXT,activebackground='#69B77B',activeforeground='#FFFFFF' if accent else TEXT,font=('Segoe UI',10,'bold'),padx=14,pady=8)
def entry(parent,var,show=None):return tk.Entry(parent,textvariable=var,show=show,bg=INPUT,fg=TEXT,insertbackground=TEXT,relief='flat',highlightthickness=1,highlightbackground=LINE,highlightcolor=GREEN,font=('Segoe UI',10))
def label(parent,text,muted=False):return tk.Label(parent,text=text,bg=parent.cget('bg'),fg=MUTED if muted else TEXT,font=('Segoe UI',10))

# HOME — redesigned dashboard
home=page('home'); header(home,tr('home_title'),tr('home_sub'))
home_body=tk.Frame(home,bg=BG); home_body.pack(fill='both',expand=True,padx=32,pady=(0,30))
summary=tk.Frame(home_body,bg=BG); summary.pack(fill='x')
summary_labels={}; summary_cards={}; summary_title_labels={}
summary_specs=[('income',tr('income'),'$',THEMES[data.get('theme','light')]['INCOME_BG'],GREEN),('spent',tr('spent'),'−',THEMES[data.get('theme','light')]['EXPENSE_BG'],RED),('savings',tr('savings'),'◎',THEMES[data.get('theme','light')]['SAVING_BG'],THEMES[data.get('theme','light')]['PURPLE'])]
for i,(k,t,ico,bgc,fgc) in enumerate(summary_specs):
    c=tk.Frame(summary,bg=bgc,highlightthickness=1,highlightbackground=LINE)
    c.grid(row=0,column=i,sticky='nsew',padx=(0 if i==0 else 10,0)); summary.columnconfigure(i,weight=1)
    top=tk.Frame(c,bg=bgc); top.pack(fill='x',padx=18,pady=(15,2))
    tk.Label(top,text=ico,bg=bgc,fg=fgc,font=('Segoe UI',18,'bold')).pack(side='left',padx=(0,8))
    summary_title_labels[k]=tk.Label(top,text=t,bg=bgc,fg=fgc,font=('Segoe UI',10,'bold')); summary_title_labels[k].pack(side='left'); summary_cards[k]=(c,top)
    summary_labels[k]=tk.Label(c,text='$0.00',bg=bgc,fg=fgc,font=('Segoe UI',20,'bold')); summary_labels[k].pack(anchor='w',padx=18,pady=(4,15))

avail=card(home_body); avail.pack(fill='x',pady=(14,0))
available_title=tk.Label(avail,text='✓  '+tr('available'),bg=PANEL,fg=MUTED,font=('Segoe UI',10,'bold')); available_title.pack(side='left',padx=18,pady=12)
summary_labels['available']=tk.Label(avail,text='$0.00',bg=PANEL,fg=GREEN,font=('Segoe UI',12,'bold')); summary_labels['available'].pack(side='right',padx=18)

auto_income_card=card(home_body); auto_income_card.pack(fill='x',pady=(12,0))
auto_income_title=tk.Label(auto_income_card,text='▣  '+tr('auto_income'),bg=PANEL,fg=TEXT,font=('Segoe UI',11,'bold')); auto_income_title.pack(side='left',padx=18,pady=12)
auto_income_note=tk.Label(auto_income_card,text='',bg=PANEL,fg=MUTED,font=('Segoe UI',9)); auto_income_note.pack(side='right',padx=18,pady=12)

progressrow=tk.Frame(home_body,bg=BG); progressrow.pack(fill='x',pady=(14,0))
progress_card=card(progressrow); progress_card.pack(side='left',fill='both',expand=True,padx=(0,8))
goal_card=card(progressrow); goal_card.pack(side='left',fill='both',expand=True,padx=(8,0))
progress_title=tk.Label(progress_card,text='↗  '+tr('savings_progress'),bg=PANEL,fg=TEXT,font=('Segoe UI',12,'bold')); progress_title.pack(anchor='w',padx=18,pady=(15,5))
saving_progress_text=tk.Label(progress_card,text='0%',bg=PANEL,fg=ACCENT,font=('Segoe UI',20,'bold')); saving_progress_text.pack(anchor='w',padx=18)
saving_canvas=tk.Canvas(progress_card,height=18,bg=PANEL,highlightthickness=0); saving_canvas.pack(fill='x',padx=18,pady=(7,15))
saving_track=saving_canvas.create_rectangle(0,5,500,13,fill=THEMES[data.get('theme','light')]['TRACK'],outline=''); saving_fill=saving_canvas.create_rectangle(0,5,0,13,fill=GREEN,outline='')
goal_title=tk.Label(goal_card,text='◎  '+tr('savings_target'),bg=PANEL,fg=TEXT,font=('Segoe UI',12,'bold')); goal_title.pack(anchor='w',padx=18,pady=(15,5))
saving_goal_text=tk.Label(goal_card,text='$0.00',bg=PANEL,fg=THEMES[data.get('theme','light')]['PURPLE'],font=('Segoe UI',20,'bold')); saving_goal_text.pack(anchor='w',padx=18)
saving_goal_sub=tk.Label(goal_card,text='',bg=PANEL,fg=MUTED,font=('Segoe UI',9)); saving_goal_sub.pack(anchor='w',padx=18,pady=(6,15))

mid=tk.Frame(home_body,bg=BG); mid.pack(fill='both',expand=True,pady=(14,0))
recent=card(mid); recent.pack(side='left',fill='both',expand=True,padx=(0,9)); monthly_preview=card(mid); monthly_preview.pack(side='left',fill='both',expand=True,padx=(9,0))
recent_title=tk.Label(recent,text='≡  '+tr('recent'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); recent_title.pack(anchor='w',padx=18,pady=(16,10))
recent_box=tk.Frame(recent,bg=PANEL); recent_box.pack(fill='both',expand=True,padx=18,pady=(0,16))
monthly_preview_title=tk.Label(monthly_preview,text='▣  '+tr('monthly_title'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); monthly_preview_title.pack(anchor='w',padx=18,pady=(16,10))
monthly_box=tk.Frame(monthly_preview,bg=PANEL); monthly_box.pack(fill='both',expand=True,padx=18,pady=(0,16))

# MOVEMENTS
moves=page('moves'); header(moves,tr('moves_title'),tr('moves_sub'))
mb=tk.Frame(moves,bg=BG); mb.pack(fill='both',expand=True,padx=32,pady=(0,28))
form=card(mb); form.pack(side='left',fill='y',padx=(0,16)); tablecard=card(mb); tablecard.pack(side='left',fill='both',expand=True)
type_var=tk.StringVar(value=semantic_label('Gasto',TYPE_KEYS)); category_var=tk.StringVar(value=semantic_label('Comida',CATEGORY_KEYS)); amount_var=tk.StringVar(); note_var=tk.StringVar()
for txt in [tr('new_move')]:
    tk.Label(form,text=txt,bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')).pack(anchor='w',padx=18,pady=(18,12))
def field(lbl,w):
    label(form,lbl,True).pack(anchor='w',padx=18,pady=(8,4)); w.pack(fill='x',padx=18,ipady=6)
type_cb=ttk.Combobox(form,textvariable=type_var,values=type_choices(),state='readonly'); field(tr('type'),type_cb)
label(form,tr('category'),True).pack(anchor='w',padx=18,pady=(8,4))
cat_line=tk.Frame(form,bg=PANEL); cat_line.pack(fill='x',padx=18)
cat_line.columnconfigure(0,weight=1)
cat_cb=ttk.Combobox(cat_line,textvariable=category_var,values=category_choices(),state='readonly')
cat_cb.grid(row=0,column=0,sticky='ew',ipady=3)
def create_category_from_moves():
    name=simpledialog.askstring(tr('create_category'),tr('category_prompt'),parent=root)
    if not name:return
    name=name.strip()
    if not name:return
    existing=[x.casefold() for x in data.get('custom_categories',[])]
    builtin=[x.casefold() for x in ['Comida','Transporte','Teléfono/Internet','Entretenimiento','Compras','Salud','Estudios','Juego/Proyecto','Otro']]
    if name.casefold() not in existing and name.casefold() not in builtin:
        data.setdefault('custom_categories',[]).append(name); save_data()
    cat_cb.configure(values=category_choices()); category_var.set(name)
new_category_btn=tk.Button(cat_line,text=tr('new_category_short'),command=create_category_from_moves,relief='flat',bd=0,bg=PANEL2,fg=TEXT,font=('Segoe UI',8,'bold'),cursor='hand2',padx=7,pady=5)
new_category_btn.grid(row=0,column=1,padx=(7,0))

def edit_category_from_moves():
    # Sirve como pequeño "borrador": permite corregir una categoría personal mal escrita.
    current=canonical_from_display(category_var.get(),CATEGORY_KEYS)
    custom=data.get('custom_categories',[])
    match=next((x for x in custom if x==current or x==category_var.get()),None)
    if not match:
        messagebox.showinfo(tr('edit_category'),tr('category_builtin_error'),parent=root); return
    name=simpledialog.askstring(tr('edit_category'),tr('edit_category_prompt'),initialvalue=match,parent=root)
    if name is None: return
    name=name.strip()
    if not name or name==match: return
    reserved=[]
    for canonical,key in CATEGORY_KEYS.items():
        reserved.append(canonical.casefold())
        for lang in T:
            if T[lang].get(key): reserved.append(T[lang][key].casefold())
    existing=[str(x).casefold() for x in custom if x!=match]
    if name.casefold() in existing or name.casefold() in reserved:
        messagebox.showerror(tr('edit_category'),tr('category_exists_error'),parent=root); return
    data['custom_categories']=[name if x==match else x for x in custom]
    # Renombrar también el historial para no partir las estadísticas en dos categorías.
    for tx in data.get('transactions',[]):
        if tx.get('category')==match: tx['category']=name
    save_data(); category_var.set(name); cat_cb.configure(values=category_choices()); refresh_all()

edit_category_btn=tk.Button(cat_line,text=tr('edit_category_short'),command=edit_category_from_moves,relief='flat',bd=0,bg=PANEL2,fg=TEXT,font=('Segoe UI',8,'bold'),cursor='hand2',padx=7,pady=5)
edit_category_btn.grid(row=0,column=2,padx=(5,0))

def delete_category_from_moves():
    current=canonical_from_display(category_var.get(),CATEGORY_KEYS)
    custom=data.get('custom_categories',[])
    match=next((x for x in custom if x==current or x==category_var.get()),None)
    if not match:
        messagebox.showinfo(tr('delete_category'),tr('category_builtin_error'),parent=root); return
    if not messagebox.askyesno(tr('delete_category'),tr('delete_category_confirm').format(name=match),parent=root):
        return
    data['custom_categories']=[x for x in custom if x!=match]
    # Preserve history: a deleted personal category becomes the canonical built-in "Otro".
    for tx in data.get('transactions',[]):
        if tx.get('category')==match:
            tx['category']='Otro'
    category_var.set(ui_semantic('Otro',CATEGORY_KEYS))
    save_data(); refresh_all()

delete_category_btn=tk.Button(cat_line,text=tr('delete_category_short'),command=delete_category_from_moves,relief='flat',bd=0,bg=PANEL2,fg=TEXT,font=('Segoe UI',8,'bold'),cursor='hand2',padx=7,pady=5)
delete_category_btn.grid(row=0,column=3,padx=(5,0))
field(tr('amount'),entry(form,amount_var)); field(tr('note'),entry(form,note_var))
def add_tx():
    try:a=float(amount_var.get())
    except:return messagebox.showerror('Cantidad inválida','Escribe una cantidad válida.')
    if a<=0:return
    data['transactions'].append({'date':datetime.now().strftime('%Y-%m-%d %H:%M'),'type':canonical_from_display(type_var.get(),TYPE_KEYS),'category':canonical_from_display(category_var.get(),CATEGORY_KEYS),'amount':a,'note':note_var.get().strip()}); amount_var.set('');note_var.set('');save_data();refresh_all()
button(form,tr('add_move'),add_tx,True).pack(fill='x',padx=18,pady=20)
tree=ttk.Treeview(tablecard,columns=('date','type','cat','amount','note'),show='headings')
for c,t,w in [('date',tr('date'),120),('type',tr('type'),105),('cat',tr('category'),125),('amount',tr('amount'),90),('note',tr('note'),180)]:tree.heading(c,text=t);tree.column(c,width=w,anchor='w')
tree.pack(fill='both',expand=True,padx=14,pady=(14,8))
def edit_tx():
    s=tree.selection()
    if not s:return
    t=data['transactions'][int(s[0])];v=simpledialog.askfloat('Editar','Nueva cantidad:',initialvalue=t['amount'],minvalue=.01,parent=root)
    if v is not None:t['amount']=v;save_data();refresh_all()
def del_tx():
    s=tree.selection()
    if s and messagebox.askyesno('Eliminar','¿Eliminar este movimiento?'):data['transactions'].pop(int(s[0]));save_data();refresh_all()
tb=tk.Frame(tablecard,bg=PANEL);tb.pack(fill='x',padx=14,pady=(0,14));button(tb,tr('delete'),del_tx).pack(side='right',padx=(8,0));button(tb,tr('edit_amount'),edit_tx).pack(side='right')

# MONTHLY
monthly=page('monthly'); header(monthly,tr('monthly_title'),tr('monthly_sub'))
rb=tk.Frame(monthly,bg=BG);rb.pack(fill='both',expand=True,padx=32,pady=(0,28)); rf=card(rb);rf.pack(side='left',fill='y',padx=(0,16)); rt=card(rb);rt.pack(side='left',fill='both',expand=True)
rp_name=tk.StringVar();rp_amount=tk.StringVar();tk.Label(rf,text=tr('new_payment'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')).pack(anchor='w',padx=18,pady=(18,12));field_parent=rf
label(rf,tr('name'),True).pack(anchor='w',padx=18,pady=(8,4));entry(rf,rp_name).pack(fill='x',padx=18,ipady=6);label(rf,tr('monthly_amount'),True).pack(anchor='w',padx=18,pady=(12,4));entry(rf,rp_amount).pack(fill='x',padx=18,ipady=6)
def add_payment():
    n=rp_name.get().strip()
    try:a=float(rp_amount.get())
    except:return messagebox.showerror('Cantidad inválida','Escribe una cantidad válida.')
    if n and a>0:data['monthly_payments'].append({'name':n,'amount':a,'active':True});rp_name.set('');rp_amount.set('');save_data();refresh_all()
button(rf,tr('add_payment'),add_payment,True).pack(fill='x',padx=18,pady=20)
ptree=ttk.Treeview(rt,columns=('name','amount','active'),show='headings');
for c,t,w in [('name',tr('payment'),300),('amount',tr('amount'),170),('active',tr('status'),160)]:
    ptree.heading(c,text=t,anchor='center')
    ptree.column(c,width=w,anchor='center',stretch=True)
style.configure('Monthly.Treeview',background=PANEL2,fieldbackground=PANEL2,foreground=TEXT,
    rowheight=34,borderwidth=1,relief='solid')
style.configure('Monthly.Treeview.Heading',background=THEMES[data.get('theme','light')]['HEAD'],
    foreground=TEXT,borderwidth=1,relief='solid',font=('Segoe UI',10,'bold'))
ptree.configure(style='Monthly.Treeview')
ptree.pack(fill='both',expand=True,padx=14,pady=(14,8))
def edit_payment():
    s=ptree.selection()
    if not s:return
    p=data['monthly_payments'][int(s[0])];n=simpledialog.askstring('Editar pago','Nombre:',initialvalue=p['name'],parent=root)
    if n is None:return
    a=simpledialog.askfloat('Editar pago','Cantidad mensual:',initialvalue=p['amount'],minvalue=.01,parent=root)
    if a is not None:p['name']=n.strip() or p['name'];p['amount']=a;save_data();refresh_all()
def toggle_payment():
    s=ptree.selection()
    if s:p=data['monthly_payments'][int(s[0])];p['active']=not p.get('active',True);save_data();refresh_all()
def del_payment():
    s=ptree.selection()
    if s and messagebox.askyesno('Eliminar','¿Eliminar este pago mensual?'):data['monthly_payments'].pop(int(s[0]));save_data();refresh_all()
pb=tk.Frame(rt,bg=PANEL);pb.pack(fill='x',padx=14,pady=(0,14));button(pb,tr('delete'),del_payment).pack(side='right',padx=(8,0));button(pb,tr('toggle'),toggle_payment).pack(side='right',padx=(8,0));button(pb,tr('edit'),edit_payment).pack(side='right')

# STATISTICS
stats=page('stats'); header(stats,tr('stats_title'),tr('stats_sub'))
stats_body=tk.Frame(stats,bg=BG); stats_body.pack(fill='both',expand=True,padx=32,pady=(0,28))
stats_tabs=tk.Frame(stats_body,bg=BG); stats_tabs.pack(fill='x',pady=(0,12))
stats_simple_btn=button(stats_tabs,tr('simple_stats'),lambda:show_stats_mode('simple'),True); stats_simple_btn.pack(side='left',padx=(0,8))
stats_advanced_btn=button(stats_tabs,tr('advanced_stats'),lambda:show_stats_mode('advanced')); stats_advanced_btn.pack(side='left')
stats_views=tk.Frame(stats_body,bg=BG); stats_views.pack(fill='both',expand=True)
stats_simple_view=tk.Frame(stats_views,bg=BG); stats_advanced_view=tk.Frame(stats_views,bg=BG)
stats_simple_view.place(relx=0,rely=0,relwidth=1,relheight=1)

stats_top=tk.Frame(stats_simple_view,bg=BG); stats_top.pack(fill='both',expand=True)
stats_chart_card=card(stats_top); stats_chart_card.pack(side='left',fill='both',expand=True,padx=(0,9))
stats_summary_card=card(stats_top); stats_summary_card.pack(side='left',fill='both',expand=True,padx=(9,0))
stats_head=tk.Frame(stats_chart_card,bg=PANEL); stats_head.pack(fill='x',padx=18,pady=(15,8))
stats_chart_title=tk.Label(stats_head,text=tr('month_compare'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); stats_chart_title.pack(side='left')
chart_type_var=tk.StringVar(value=tr('bars'))
chart_type_box=ttk.Combobox(stats_head,textvariable=chart_type_var,values=[tr('bars'),tr('line'),tr('pie')],state='readonly',width=14); chart_type_box.pack(side='right')
stats_canvas=tk.Canvas(stats_chart_card,height=300,bg=PANEL,highlightthickness=0); stats_canvas.pack(fill='both',expand=True,padx=18,pady=(0,16))
stats_summary_title=tk.Label(stats_summary_card,text=tr('monthly_summary'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); stats_summary_title.pack(anchor='w',padx=18,pady=(15,8))
stats_summary_box=tk.Frame(stats_summary_card,bg=PANEL); stats_summary_box.pack(fill='both',expand=True,padx=18,pady=(0,16))

stats_bottom=tk.Frame(stats_simple_view,bg=BG); stats_bottom.pack(fill='both',expand=True,pady=(14,0))
stats_category_card=card(stats_bottom); stats_category_card.pack(side='left',fill='both',expand=True,padx=(0,9))
stats_compare_card=card(stats_bottom); stats_compare_card.pack(side='left',fill='both',expand=True,padx=(9,0))
stats_category_title=tk.Label(stats_category_card,text=tr('category_spending'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); stats_category_title.pack(anchor='w',padx=18,pady=(15,8))
stats_category_canvas=tk.Canvas(stats_category_card,height=205,bg=PANEL,highlightthickness=0); stats_category_canvas.pack(fill='both',expand=True,padx=18,pady=(0,16))
stats_compare_title=tk.Label(stats_compare_card,text=tr('difference_previous'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); stats_compare_title.pack(anchor='w',padx=18,pady=(15,8))
stats_compare_box=tk.Frame(stats_compare_card,bg=PANEL); stats_compare_box.pack(fill='both',expand=True,padx=18,pady=(0,16))

# Advanced spending analysis
adv_top=tk.Frame(stats_advanced_view,bg=BG); adv_top.pack(fill='x')
adv_cat_card=card(adv_top); adv_cat_card.pack(side='left',fill='both',expand=True,padx=(0,9))
adv_impact_card=card(adv_top); adv_impact_card.pack(side='left',fill='both',expand=True,padx=(9,0))
adv_category_title=tk.Label(adv_cat_card,text=tr('category_analysis'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); adv_category_title.pack(anchor='w',padx=18,pady=(15,8))
adv_canvas=tk.Canvas(adv_cat_card,height=220,bg=PANEL,highlightthickness=0); adv_canvas.pack(fill='both',expand=True,padx=18,pady=(0,16))
adv_impact_title=tk.Label(adv_impact_card,text=tr('monthly_impact'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); adv_impact_title.pack(anchor='w',padx=18,pady=(15,8))
adv_impact_box=tk.Frame(adv_impact_card,bg=PANEL); adv_impact_box.pack(fill='both',expand=True,padx=18,pady=(0,16))
adv_detail_card=card(stats_advanced_view); adv_detail_card.pack(fill='both',expand=True,pady=(14,0))
adv_detail_title=tk.Label(adv_detail_card,text=tr('expense_detail'),bg=PANEL,fg=TEXT,font=('Segoe UI',13,'bold')); adv_detail_title.pack(anchor='w',padx=18,pady=(15,8))
adv_tree=ttk.Treeview(adv_detail_card,columns=('date','cat','amount','impact','note'),show='headings')
for c,key,w in [('date','when',135),('cat','category',170),('amount','expense',115),('impact','impact',145),('note','note',270)]:
    adv_tree.heading(c,text=tr(key)); adv_tree.column(c,width=w,anchor='w')
adv_tree.pack(fill='both',expand=True,padx=16,pady=(0,16))

stats_mode=tk.StringVar(value='simple')
def style_stats_tabs(which):
    active_bg=GREEN; active_fg='#FFFFFF'
    idle_bg=PANEL2; idle_fg=TEXT
    stats_simple_btn.configure(bg=active_bg if which=='simple' else idle_bg,fg=active_fg if which=='simple' else idle_fg,
                               activebackground=active_bg if which=='simple' else idle_bg,activeforeground=active_fg if which=='simple' else idle_fg)
    stats_advanced_btn.configure(bg=active_bg if which=='advanced' else idle_bg,fg=active_fg if which=='advanced' else idle_fg,
                                 activebackground=active_bg if which=='advanced' else idle_bg,activeforeground=active_fg if which=='advanced' else idle_fg)
def show_stats_mode(which):
    stats_mode.set(which); style_stats_tabs(which)
    if which=='advanced':
        stats_advanced_view.place(relx=0,rely=0,relwidth=1,relheight=1); stats_advanced_view.lift(); draw_advanced_statistics()
    else:
        stats_simple_view.place(relx=0,rely=0,relwidth=1,relheight=1); stats_simple_view.lift(); draw_statistics()

def draw_advanced_statistics():
    adv_canvas.delete('all')
    tx=[t for t in data.get('transactions',[]) if t.get('date','').startswith(month_key()) and t.get('type') in ('Gasto','Pago mensual')]
    total=sum(float(t.get('amount',0)) for t in tx); cats={}
    for t in tx: cats.setdefault(t.get('category','Otro'),[]).append(t)
    palette=['#55C878','#F07C82','#8D75D8','#F2C14E','#58A6D6','#E88FC2','#73C9B5','#E69A55','#9BBF65','#8E9AAF']
    ordered=sorted(cats.items(),key=lambda kv:sum(float(x.get('amount',0)) for x in kv[1]),reverse=True)
    adv_canvas.update_idletasks(); W=max(480,adv_canvas.winfo_width()); H=max(220,adv_canvas.winfo_height())
    if not ordered:
        adv_canvas.create_text(W/2,H/2,text=tr('no_history'),fill=MUTED,font=('Segoe UI',9))
    else:
        size=min(170,H-36); x0=22; y0=(H-size)/2; x1=x0+size; y1=y0+size; angle=0
        for i,(cat,arr) in enumerate(ordered):
            val=sum(float(x.get('amount',0)) for x in arr); extent=(val/total*360) if total else 0
            adv_canvas.create_arc(x0,y0,x1,y1,start=angle,extent=extent,fill=palette[i%len(palette)],outline=PANEL,width=2); angle+=extent
        lx=x1+28
        for i,(cat,arr) in enumerate(ordered[:8]):
            val=sum(float(x.get('amount',0)) for x in arr); pct=(val/total*100) if total else 0; y=22+i*27
            adv_canvas.create_rectangle(lx,y,lx+13,y+13,fill=palette[i%len(palette)],outline='')
            adv_canvas.create_text(lx+21,y+7,text=ui_semantic(cat,CATEGORY_KEYS),anchor='w',fill=TEXT,font=('Segoe UI',8,'bold'))
            adv_canvas.create_text(W-6,y+7,text=f'{money(val)} · {pct:.1f}%',anchor='e',fill=TEXT,font=('Segoe UI',8))
    for w in adv_impact_box.winfo_children():w.destroy()
    for i,(cat,arr) in enumerate(ordered[:7]):
        val=sum(float(x.get('amount',0)) for x in arr); pct=val/total*100 if total else 0
        row=tk.Frame(adv_impact_box,bg=PANEL); row.pack(fill='x',pady=4)
        tk.Label(row,text='●',bg=PANEL,fg=palette[i%len(palette)],font=('Segoe UI',10,'bold')).pack(side='left',padx=(0,6))
        tk.Label(row,text=ui_semantic(cat,CATEGORY_KEYS),bg=PANEL,fg=TEXT,font=('Segoe UI',9,'bold')).pack(side='left')
        tk.Label(row,text=f"{len(arr)} {tr('transactions_count')} · {pct:.1f}%",bg=PANEL,fg=MUTED,font=('Segoe UI',8)).pack(side='right')
    for iid in adv_tree.get_children():adv_tree.delete(iid)
    for t in sorted(tx,key=lambda x:x.get('date',''),reverse=True):
        amount=float(t.get('amount',0)); pct=amount/total*100 if total else 0
        adv_tree.insert('','end',values=(t.get('date',''),ui_semantic(t.get('category',''),CATEGORY_KEYS),money(amount),f'{pct:.1f}% {tr("share_expenses")}',ui_semantic(t.get('note',''),NOTE_KEYS)))

adv_canvas.bind('<Configure>',lambda e:root.after(60,draw_advanced_statistics))

def month_shift(key,delta):
    y,m=map(int,key.split('-')); m+=delta
    while m<1:y-=1;m+=12
    while m>12:y+=1;m-=12
    return f'{y:04d}-{m:02d}'

def month_label(key):
    m=int(key[-2:])
    names={'es':['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'],
    'en':['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
    'fr':['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Aoû','Sep','Oct','Nov','Déc'],
    'de':['Jan','Feb','Mär','Apr','Mai','Jun','Jul','Aug','Sep','Okt','Nov','Dez'],
    'bn':['জানু','ফেব','মার্চ','এপ্রি','মে','জুন','জুল','আগ','সেপ','অক্টো','নভে','ডিসে']}
    return names.get(data.get('language','es'),names['es'])[m-1]

def month_totals(key):
    tx=[t for t in data.get('transactions',[]) if t.get('date','').startswith(key)]
    inc=sum(float(t.get('amount',0)) for t in tx if t.get('type') in ('Ingreso mensual','Ingreso extra'))
    exp=sum(float(t.get('amount',0)) for t in tx if t.get('type') in ('Gasto','Pago mensual'))
    return inc,exp,max(0,inc-exp)

def pct_change(cur,prev):
    if prev==0:return None if cur else 0
    return (cur-prev)/abs(prev)*100

def draw_statistics(event=None):
    stats_canvas.delete('all'); stats_category_canvas.delete('all')
    months=[month_shift(month_key(),i) for i in range(-5,1)]
    vals=[month_totals(m) for m in months]
    stats_canvas.update_idletasks(); W=max(520,stats_canvas.winfo_width()); H=max(260,stats_canvas.winfo_height())
    pad=48; maxv=max([x for row in vals for x in row[:2]]+[1])
    chart=chart_type_var.get()
    # Grid
    for i in range(5):
        y=pad+(H-2*pad)*i/4
        stats_canvas.create_line(pad,y,W-pad,y,fill=LINE)
        stats_canvas.create_text(pad-7,y,text=money(maxv*(1-i/4)),anchor='e',fill=MUTED,font=('Segoe UI',8))
    if chart==tr('line'):
        for si,color in [(0,GREEN),(1,RED)]:
            pts=[]
            for i,row in enumerate(vals):
                x=pad+(W-2*pad)*i/5; y=H-pad-row[si]/maxv*(H-2*pad)
                pts += [x,y]; stats_canvas.create_oval(x-3,y-3,x+3,y+3,fill=color,outline='')
            stats_canvas.create_line(*pts,fill=color,width=3,smooth=True)
    elif chart==tr('pie'):
        inc,exp,_=vals[-1]; inc=max(0.0,inc); exp=max(0.0,exp); total=inc+exp; extent=360*inc/total if total>0 else 0
        cx=W/2;cy=H/2;r=min(90,H/2-35)
        if total>0:
            if inc>0:stats_canvas.create_arc(cx-r,cy-r,cx+r,cy+r,start=90,extent=-extent if exp>0 else -359.9,fill=GREEN,outline=PANEL)
            if exp>0:stats_canvas.create_arc(cx-r,cy-r,cx+r,cy+r,start=90-extent,extent=-(360-extent) if inc>0 else -359.9,fill=RED,outline=PANEL)
        else:
            stats_canvas.create_oval(cx-r,cy-r,cx+r,cy+r,outline=LINE,width=12)
        stats_canvas.create_oval(cx-42,cy-42,cx+42,cy+42,fill=PANEL,outline=PANEL)
        stats_canvas.create_text(cx,cy,text=money(inc-exp),fill=TEXT,font=('Segoe UI',11,'bold'))
    else:
        gw=(W-2*pad)/6
        for i,(inc,exp,_) in enumerate(vals):
            bw=gw*.24; x=pad+gw*i+gw*.22
            for j,(val,color) in enumerate([(inc,GREEN),(exp,RED)]):
                y=H-pad-val/maxv*(H-2*pad)
                stats_canvas.create_rectangle(x+j*(bw+5),y,x+j*(bw+5)+bw,H-pad,fill=color,outline='')
    if chart!=tr('pie'):
        for i,m in enumerate(months):
            x=pad+(W-2*pad)*(i/5) if chart==tr('line') else pad+(W-2*pad)/6*(i+.5)
            stats_canvas.create_text(x,H-18,text=month_label(m),fill=MUTED,font=('Segoe UI',9))
    # Legend
    stats_canvas.create_rectangle(W-170,12,W-158,24,fill=GREEN,outline='')
    stats_canvas.create_text(W-152,18,text=tr('income'),anchor='w',fill=TEXT,font=('Segoe UI',8))
    stats_canvas.create_rectangle(W-82,12,W-70,24,fill=RED,outline='')
    stats_canvas.create_text(W-64,18,text=tr('spent'),anchor='w',fill=TEXT,font=('Segoe UI',8))

    cur=vals[-1]; prev=vals[-2]
    for box in (stats_summary_box,stats_compare_box):
        for w in box.winfo_children():w.destroy()
    purple=THEMES[data.get('theme','light')]['PURPLE']
    for title,val,color in [(tr('income'),cur[0],GREEN),(tr('spent'),cur[1],RED),(tr('savings'),cur[2],purple)]:
        r=tk.Frame(stats_summary_box,bg=PANEL);r.pack(fill='x',pady=6)
        tk.Label(r,text=title,bg=PANEL,fg=TEXT).pack(side='left')
        tk.Label(r,text=money(val),bg=PANEL,fg=color,font=('Segoe UI',10,'bold')).pack(side='right')
    for title,c,p,color in [(tr('income'),cur[0],prev[0],GREEN),(tr('spent'),cur[1],prev[1],RED),(tr('savings'),cur[2],prev[2],purple)]:
        ch=pct_change(c,p); txt='—' if ch is None else f'{ch:+.0f}%'
        r=tk.Frame(stats_compare_box,bg=PANEL);r.pack(fill='x',pady=7)
        tk.Label(r,text=title,bg=PANEL,fg=TEXT).pack(side='left')
        tk.Label(r,text=txt,bg=PANEL,fg=color,font=('Segoe UI',11,'bold')).pack(side='right')

    # Category donut
    stats_category_canvas.update_idletasks(); CW=max(480,stats_category_canvas.winfo_width())
    tx=[t for t in data.get('transactions',[]) if t.get('date','').startswith(month_key()) and t.get('type')=='Gasto']
    cats={}
    for t in tx: cats[t.get('category','Otro')]=cats.get(t.get('category','Otro'),0)+max(0.0,float(t.get('amount',0)))
    cats={k:v for k,v in cats.items() if math.isfinite(v) and v>0}
    if not cats:
        stats_category_canvas.create_text(CW/2,95,text=tr('no_history'),fill=MUTED,font=('Segoe UI',9))
    else:
        colors=[GREEN,RED,purple,'#F0AE4F','#77A8D8','#A6AAA7']; total=sum(cats.values()); start=90;cx=100;cy=95;r=70
        for i,(cat,val) in enumerate(sorted(cats.items(),key=lambda x:x[1],reverse=True)[:6]):
            ext=-360*val/total; color=colors[i%len(colors)]
            stats_category_canvas.create_arc(cx-r,cy-r,cx+r,cy+r,start=start,extent=ext,fill=color,outline=PANEL);start+=ext
            yy=20+i*27
            stats_category_canvas.create_oval(205,yy,217,yy+12,fill=color,outline='')
            stats_category_canvas.create_text(228,yy+6,text=ui_semantic(cat,CATEGORY_KEYS),anchor='w',fill=TEXT,font=('Segoe UI',9))
            stats_category_canvas.create_text(CW-12,yy+6,text=f'{val/total*100:.0f}%  {money(val)}',anchor='e',fill=TEXT,font=('Segoe UI',9))
        stats_category_canvas.create_oval(cx-38,cy-38,cx+38,cy+38,fill=PANEL,outline=PANEL)
        stats_category_canvas.create_text(cx,cy-4,text=money(total),fill=TEXT,font=('Segoe UI',9,'bold'))
        stats_category_canvas.create_text(cx,cy+14,text=tr('total'),fill=MUTED,font=('Segoe UI',8))

chart_type_box.bind('<<ComboboxSelected>>',draw_statistics)
stats_canvas.bind('<Configure>',lambda e:root.after(60,draw_statistics))
stats_category_canvas.bind('<Configure>',lambda e:root.after(60,draw_statistics))

# AI CHAT
ai=page('ai'); header(ai,tr('ai_title'),tr('ai_sub'))
aic=card(ai);aic.pack(fill='both',expand=True,padx=32,pady=(0,28))
# El compositor se empaqueta PRIMERO en la parte inferior para reservar siempre su altura.
# Después el historial ocupa únicamente el espacio restante. Así nunca queda fuera de la ventana.
composer=tk.Frame(aic,bg=PANEL,height=105);composer.pack(side='bottom',fill='x',padx=14,pady=(8,14));composer.pack_propagate(False)
tk.Label(composer,text=tr('write_ai'),bg=PANEL,fg=MUTED,font=('Segoe UI',9)).pack(anchor='w',pady=(2,6))
askrow=tk.Frame(composer,bg=PANEL);askrow.pack(fill='both',expand=True)
askentry=tk.Text(askrow,height=3,bg=INPUT,fg=TEXT,insertbackground=TEXT,relief='flat',wrap='word',highlightthickness=1,highlightbackground=LINE,highlightcolor=GREEN,font=('Segoe UI',10),padx=10,pady=8)
askentry.pack(side='left',fill='both',expand=True,padx=(0,8))

chatwrap=tk.Frame(aic,bg=PANEL);chatwrap.pack(side='top',fill='both',expand=True,padx=14,pady=(14,0))
scroll=tk.Scrollbar(chatwrap);scroll.pack(side='right',fill='y')
chat=tk.Text(chatwrap,bg=PANEL2,fg=TEXT,insertbackground=TEXT,relief='flat',wrap='word',font=('Segoe UI',10),padx=20,pady=18,state='disabled',yscrollcommand=scroll.set,spacing1=2,spacing3=8)
chat.pack(side='left',fill='both',expand=True);scroll.config(command=chat.yview)
chat.tag_config('you',foreground='#9FCFA9',font=('Segoe UI',10,'bold'))
chat.tag_config('bot',foreground=TEXT)
chat.tag_config('meta',foreground=MUTED)
ai_busy=False

def financial_context():
    m=month_key();tx=[t for t in data['transactions'] if t.get('date','').startswith(m)]
    inc=sum(float(t['amount']) for t in tx if t['type'] in ('Ingreso mensual','Ingreso extra')); bills=sum(float(t['amount']) for t in tx if t['type']=='Pago mensual'); spent=sum(float(t['amount']) for t in tx if t['type']=='Gasto')
    lines='\n'.join(f"{t['type']} | {t['category']} | {float(t['amount']):.2f} | {ui_semantic(t.get('note',''),NOTE_KEYS)}" for t in tx[-30:])
    return f"Mes {m}. Ingresos {inc:.2f}. Pagos mensuales {bills:.2f}. Otros gastos {spent:.2f}. Meta de ahorro {float(data['savings_goal']):.2f}. Movimientos:\n{lines or 'Sin movimientos'}"

AI_PROVIDERS={
    'OpenAI': {'base_url':'https://api.openai.com/v1','default_model':'gpt-5.6'},
    'NVIDIA': {'base_url':'https://integrate.api.nvidia.com/v1','default_model':'z-ai/glm-5.3'},
    'Otro compatible': {'base_url':'','default_model':''},
}
def ai_config():
    provider=(data.get('ai_provider') or 'OpenAI').strip()
    cfg=AI_PROVIDERS.get(provider,AI_PROVIDERS['OpenAI'])
    base=(data.get('ai_base_url') or '').strip() if provider=='Otro compatible' else cfg['base_url']
    return provider,(data.get('ai_api_key') or '').strip(),base.rstrip('/'),(data.get('ai_model') or cfg['default_model']).strip()

def draw_chat():
    chat.config(state='normal');chat.delete('1.0','end')
    if not data.get('ai_history'):chat.insert('end',tr('chat_hint')+'\n\n','meta')
    for h in data.get('ai_history',[])[-30:]:
        content=h.get('content') or ''
        if h.get('role')=='user':chat.insert('end',tr('you')+'\n','you');chat.insert('end',content+'\n\n','bot')
        else:chat.insert('end',tr('advisor')+'\n','you');chat.insert('end',content+'\n\n','bot')
    chat.config(state='disabled');chat.see('end')

# Los hilos de red nunca modifican Tkinter directamente.
ai_events=queue.Queue()
AI_STATUS={
 'es':('La IA está preparando tu respuesta','Esperando respuesta del proveedor','El proveedor no devolvió texto.'),
 'en':('AI is preparing your response','Waiting for the provider','The provider returned no text.'),
 'fr':('L’IA prépare votre réponse','En attente du fournisseur','Le fournisseur n’a renvoyé aucun texte.'),
 'de':('Die KI bereitet deine Antwort vor','Warten auf den Anbieter','Der Anbieter hat keinen Text zurückgegeben.'),
 'bn':('AI আপনার উত্তর প্রস্তুত করছে','প্রদানকারীর উত্তরের অপেক্ষায়','প্রদানকারী কোনো লেখা ফেরত দেয়নি।')}
status_var=tk.StringVar(value='')
# El indicador va DENTRO del historial: el compositor tiene altura fija
# y antes ocultaba el Label de estado fuera del área visible.
chat.tag_config('ai_wait',foreground=MUTED,font=('Segoe UI',10,'italic'))
def show_ai_wait(text):
    chat.config(state='normal')
    try:
        chat.delete('ai_wait_start','ai_wait_end')
    except tk.TclError:
        pass
    if text:
        chat.mark_set('ai_wait_start','end-1c')
        chat.insert('end',text+'\n','ai_wait')
        chat.mark_set('ai_wait_end','end-1c')
        chat.mark_gravity('ai_wait_start','left')
        chat.mark_gravity('ai_wait_end','right')
    chat.config(state='disabled')
    chat.see('end')

ai_phase='idle'
ai_frame=0
ai_received=False

def animate_ai_status():
    global ai_frame
    if ai_busy and not ai_received:
        lang=data.get('language','es')
        messages=AI_STATUS.get(lang,AI_STATUS['es'])
        base=messages[1] if ai_phase=='connected' else messages[0]
        dots='.'*((ai_frame%3)+1)
        status_var.set(base+dots)
        show_ai_wait(base+dots)
        ai_frame+=1
    try:root.after(420,animate_ai_status)
    except tk.TclError:pass

def append_stream_piece(piece):
    global ai_received
    if not piece:return
    if not ai_received:
        ai_received=True
        status_var.set('')
        show_ai_wait('')
    chat.config(state='normal');chat.insert('end',piece,'bot');chat.config(state='disabled');chat.see('end')

def finish_ai(ans, failed=False):
    global ai_busy,ai_phase,ai_received
    ans=(ans or '').strip() or AI_STATUS.get(data.get('language','es'),AI_STATUS['es'])[2]
    data.setdefault('ai_history',[]).append({'role':'assistant','content':ans});data['ai_history']=data['ai_history'][-40:];save_data()
    ai_busy=False;ai_phase='idle';ai_received=False
    status_var.set('');show_ai_wait('');send_btn.config(state='normal');askentry.config(state='normal');draw_chat();askentry.focus_set()

def poll_ai_events():
    global ai_phase
    try:
        for _ in range(100):
            kind,payload=ai_events.get_nowait()
            if kind=='connected':ai_phase='connected'
            elif kind=='piece':append_stream_piece(payload)
            elif kind=='finish':finish_ai(payload)
            elif kind=='error':finish_ai(payload,True)
    except queue.Empty:pass
    try:root.after(45,poll_ai_events)
    except tk.TclError:pass

root.after(45,poll_ai_events)
root.after(420,animate_ai_status)

def stream_worker(payload,key,base_url,provider):
    full=[]
    try:
        req=urllib.request.Request(base_url+'/chat/completions',data=payload,headers={'Authorization':'Bearer '+key,'Content-Type':'application/json','Accept':'text/event-stream'})
        with urllib.request.urlopen(req,timeout=120) as r:
            ai_events.put(('connected',None))
            # Los servidores SSE pueden entregar datos: en múltiples líneas.
            for raw in r:
                line=raw.decode('utf-8','replace').strip()
                if not line.startswith('data:'):continue
                body=line[5:].strip()
                if body=='[DONE]':break
                try:o=json.loads(body)
                except (ValueError,TypeError):continue
                choices=o.get('choices') or []
                if not choices:continue
                ch=choices[0].get('delta') or {}
                piece=ch.get('content') or ''
                if isinstance(piece,list):piece=''.join(item.get('text','') for item in piece if isinstance(item,dict))
                if isinstance(piece,str) and piece:
                    full.append(piece);ai_events.put(('piece',piece))
        ai_events.put(('finish',''.join(full)))
    except urllib.error.HTTPError as e:
        ai_events.put(('error',f'{provider}: HTTP {e.code} — {e.reason}'))
    except Exception as e:
        ai_events.put(('error',f'{provider}: {type(e).__name__}: {e}'))

def ask_ai(event=None):
    global ai_busy,ai_phase,ai_received,ai_frame
    q=askentry.get('1.0','end-1c').strip();provider,key,base_url,model=ai_config()
    if not q or ai_busy:return
    if not key:return messagebox.showwarning('Falta API Key','Guarda tu API Key de IA en Configuración.')
    if not base_url:return messagebox.showwarning('Falta Base URL','Configura la Base URL para tu proveedor personalizado.')
    if not model:return messagebox.showwarning('Falta modelo','Escribe el nombre del modelo que quieres utilizar.')
    askentry.delete('1.0','end');data.setdefault('ai_history',[]).append({'role':'user','content':q});save_data();draw_chat()
    sysmsg='Eres el consejero financiero dentro de MafiFlow. Responde siempre en el idioma seleccionado por el usuario ('+LANG_NAMES.get(data.get('language','es'),'Español')+'), de forma clara, práctica y fácil de entender. Usa los datos proporcionados. No inventes cifras. No des asesoría de inversión. Si una compra pondría en riesgo pagos obligatorios o la meta de ahorro, dilo claramente. Puedes dar respuestas detalladas cuando ayuden, pero evita relleno.\nDATOS ACTUALES:\n'+financial_context()
    msgs=[{'role':'system','content':sysmsg}]+data['ai_history'][-12:]
    payload=json.dumps({'model':model,'messages':msgs,'temperature':0.35,'max_tokens':1200,'stream':True}).encode()
    ai_busy=True;ai_phase='waiting';ai_received=False;ai_frame=0
    status_var.set(AI_STATUS.get(data.get('language','es'),AI_STATUS['es'])[0]+'...')
    send_btn.config(state='disabled');askentry.config(state='disabled')
    chat.config(state='normal');chat.insert('end',tr('advisor')+'\n','you');chat.config(state='disabled');chat.see('end')
    show_ai_wait(status_var.get())
    threading.Thread(target=stream_worker,args=(payload,key,base_url,provider),daemon=True).start()

send_btn=button(askrow,tr('send'),ask_ai,True);send_btn.pack(side='right',fill='y')
def send_on_enter(event):
    # Enter envía; Shift+Enter crea una nueva línea.
    if event.state & 0x0001:
        return None
    ask_ai(); return 'break'
askentry.bind('<Return>',send_on_enter)

# SETTINGS
settings=page('settings');header(settings,tr('settings_title'),tr('settings_sub'))
sc=card(settings);sc.pack(fill='x',padx=32,pady=(0,20))
income_var=tk.StringVar(value=str(data['monthly_income']));save_var=tk.StringVar(value=str(data['savings_goal']))
provider_var=tk.StringVar(value=data.get('ai_provider') or 'OpenAI');api_var=tk.StringVar(value=data.get('ai_api_key') or '')
model_var=tk.StringVar(value=data.get('ai_model') or AI_PROVIDERS.get(provider_var.get(),{}).get('default_model',''))
base_var=tk.StringVar(value=data.get('ai_base_url') or '')
grid=tk.Frame(sc,bg=PANEL);grid.pack(fill='x',padx=20,pady=20);grid.columnconfigure(1,weight=1)
def setting_label(text,row):
    tk.Label(grid,text=text,bg=PANEL,fg=MUTED,font=('Segoe UI',10)).grid(row=row,column=0,sticky='w',pady=9,padx=(0,18))
setting_label(tr('auto_income'),0);entry(grid,income_var).grid(row=0,column=1,sticky='ew',ipady=7)
setting_label(tr('saving_goal'),1);entry(grid,save_var).grid(row=1,column=1,sticky='ew',ipady=7)
setting_label(tr('ai_provider'),2)
provider_box=ttk.Combobox(grid,textvariable=provider_var,values=['OpenAI','NVIDIA','Otro compatible'],state='readonly')
provider_box.grid(row=2,column=1,sticky='ew',ipady=5)
setting_label(tr('ai_key'),3);entry(grid,api_var,'•').grid(row=3,column=1,sticky='ew',ipady=7)
setting_label(tr('model'),4);entry(grid,model_var).grid(row=4,column=1,sticky='ew',ipady=7)
advanced=tk.Frame(sc,bg=PANEL)
tk.Label(advanced,text=tr('base_url'),bg=PANEL,fg=MUTED,font=('Segoe UI',10)).pack(anchor='w')
entry(advanced,base_var).pack(fill='x',pady=(5,0),ipady=7)
def update_provider_ui(event=None):
    provider=provider_var.get()
    default=AI_PROVIDERS.get(provider,{}).get('default_model','')
    if provider!='Otro compatible':
        advanced.pack_forget()
        if not model_var.get().strip() or model_var.get().strip() in [v['default_model'] for v in AI_PROVIDERS.values() if v['default_model']]:
            model_var.set(default)
    else:
        advanced.pack(fill='x',padx=20,pady=(0,14))
provider_box.bind('<<ComboboxSelected>>',update_provider_ui);update_provider_ui()
def apply_theme(name=None):
    if name is None: name=data.get('theme','light')
    if name not in THEMES: name='light'
    old_colors=set(sum(([v for v in x.values()] for x in THEMES.values()),[]))
    data['theme']=name; set_theme_vars(name); t=THEMES[name]
    root.configure(bg=BG); shell.configure(bg=BG,highlightbackground=LINE); content.configure(bg=BG); sidebar.configure(bg=t['SIDEBAR'])
    logo_wrap.configure(bg=t['SIDEBAR']); wordmark_label.configure(bg=t['SIDEBAR']); sidebar_local.configure(bg=t['SIDEBAR'],fg='#BFD9CB')
    def walk(w):
        cls=w.winfo_class()
        try:
            bg=w.cget('bg')
            if bg in (THEMES['light']['BG'],THEMES['dark']['BG']): w.configure(bg=BG)
            elif bg in (THEMES['light']['PANEL'],THEMES['dark']['PANEL']): w.configure(bg=PANEL)
            elif bg in (THEMES['light']['PANEL2'],THEMES['dark']['PANEL2']): w.configure(bg=PANEL2)
            elif bg in (THEMES['light']['SIDEBAR'],THEMES['dark']['SIDEBAR']): w.configure(bg=t['SIDEBAR'])
            elif bg in (THEMES['light']['BUTTON'],THEMES['dark']['BUTTON']): w.configure(bg=t['BUTTON'])
        except Exception: pass
        try:
            fg=w.cget('fg')
            if fg in (THEMES['light']['TEXT'],THEMES['dark']['TEXT']): w.configure(fg=TEXT)
            elif fg in (THEMES['light']['MUTED'],THEMES['dark']['MUTED']): w.configure(fg=MUTED)
            elif fg in (THEMES['light']['GREEN'],THEMES['dark']['GREEN']): w.configure(fg=GREEN)
            elif fg in (THEMES['light']['RED'],THEMES['dark']['RED']): w.configure(fg=RED)
            elif fg in (THEMES['light']['ACCENT'],THEMES['dark']['ACCENT']): w.configure(fg=ACCENT)
            elif fg in (THEMES['light']['PURPLE'],THEMES['dark']['PURPLE']): w.configure(fg=t['PURPLE'])
        except Exception: pass
        try:
            if cls=='Entry': w.configure(bg=INPUT,fg=TEXT,insertbackground=TEXT,highlightbackground=LINE,highlightcolor=GREEN)
            elif cls in ('Label','Button','Checkbutton','Radiobutton'):
                # Legibilidad consistente: oscuro en tema claro, claro en tema oscuro.
                try:
                    current_fg=w.cget('fg')
                    semantic=(GREEN,RED,t['PURPLE'],'#8DE39A','#BFD9CB')
                    # No tocar textos de la sidebar ni colores semánticos.
                    parent_bg=str(w.master.cget('bg')) if hasattr(w,'master') else ''
                    if parent_bg != str(t['SIDEBAR']) and current_fg not in semantic:
                        w.configure(fg=('#13251D' if name=='light' else '#F2F7F4'))
                except Exception: pass
        except Exception: pass
        for ch in w.winfo_children(): walk(ch)
    walk(root)
    # dashboard accent cards retain their semantic colors.
    semantic=[('income','INCOME_BG',GREEN),('spent','EXPENSE_BG',RED),('savings','SAVING_BG',t['PURPLE'])]
    for k,bgkey,fg in semantic:
        c,top=summary_cards[k]; c.configure(bg=t[bgkey],highlightbackground=LINE); top.configure(bg=t[bgkey])
        for ch in top.winfo_children(): ch.configure(bg=t[bgkey],fg=fg)
        summary_labels[k].configure(bg=t[bgkey],fg=fg); summary_title_labels[k].configure(bg=t[bgkey],fg=fg)
    saving_canvas.configure(bg=PANEL); saving_canvas.itemconfig(saving_track,fill=t['TRACK']); saving_canvas.itemconfig(saving_fill,fill=GREEN)
    saving_goal_text.configure(fg=t['PURPLE'])
    style.configure('Treeview',background=PANEL2,fieldbackground=PANEL2,foreground=TEXT)
    style.configure('Treeview.Heading',background=t['HEAD'],foreground=TEXT)
    style.configure('Monthly.Treeview',background=PANEL2,fieldbackground=PANEL2,foreground=TEXT,borderwidth=1,relief='solid')
    style.configure('Monthly.Treeview.Heading',background=t['HEAD'],foreground=TEXT,borderwidth=1,relief='solid')
    style.map('Treeview',background=[('selected',t['SELECT'])],foreground=[('selected',TEXT)])
    style.configure('TCombobox',fieldbackground=INPUT,background=INPUT,foreground=TEXT,arrowcolor=TEXT)
    style.map('TCombobox',fieldbackground=[('readonly',INPUT)],foreground=[('readonly',TEXT)],selectbackground=[('readonly',INPUT)],selectforeground=[('readonly',TEXT)])
    root.option_add('*TCombobox*Listbox.background',INPUT); root.option_add('*TCombobox*Listbox.foreground',TEXT)
    for n,b in nav_buttons.items(): b.configure(bg=t['NAV_ACTIVE'] if pages.get(n) and pages[n].winfo_ismapped() else t['SIDEBAR'],fg='#173D28' if pages.get(n) and pages[n].winfo_ismapped() and name=='light' else ('#FFFFFF' if not pages.get(n) or not pages[n].winfo_ismapped() else '#FFFFFF'),activebackground=t['NAV_ACTIVE'])
    try:
        chat.configure(bg=PANEL2,fg=TEXT,insertbackground=TEXT)
        askentry.configure(bg=INPUT,fg=TEXT,insertbackground=TEXT)
        stats_canvas.configure(bg=PANEL); stats_category_canvas.configure(bg=PANEL); adv_canvas.configure(bg=PANEL); cat_line.configure(bg=PANEL); new_category_btn.configure(bg=PANEL2,fg=TEXT); edit_category_btn.configure(bg=PANEL2,fg=TEXT)
    except Exception: pass

    try:
        chat.configure(bg=PANEL,fg=TEXT,insertbackground=TEXT)
        chat.tag_configure('you',foreground=('#74C98A' if name=='dark' else '#4FA966'))
        chat.tag_configure('bot',foreground=('#F2F7F4' if name=='dark' else '#13251D'))
        chat.tag_configure('meta',foreground=('#D5E2DB' if name=='dark' else '#65756D'))
    except Exception: pass
    refresh_all()
    try: style_stats_tabs(stats_mode.get())
    except Exception: pass
    try: draw_statistics()
    except Exception: pass

def apply_language():
    # Cambia todos los textos ya creados sin reiniciar la aplicación.
    reverse={}
    for lang,items in T.items():
        for key,value in items.items():
            reverse[value]=key
    def walk(widget):
        try:
            current=widget.cget('text')
            if current in reverse:
                widget.config(text=tr(reverse[current]))
        except Exception:
            pass
        for child in widget.winfo_children():
            walk(child)
    walk(root)
    # Force the main labels/tables to the currently selected language so no previous
    # language remains embedded after live switching.
    try:
        nav_keys={'home':'home','moves':'moves','monthly':'monthly','stats':'stats','ai':'ai','settings':'settings'}
        for n,k in nav_keys.items(): nav_buttons[n].configure(text=tr(k))
        sidebar_local.configure(text=tr('local'))
        summary_title_labels['income'].configure(text=tr('income'))
        summary_title_labels['spent'].configure(text=tr('spent'))
        summary_title_labels['savings'].configure(text=tr('savings'))
        ptree.heading('name',text=tr('payment'),anchor='center')
        ptree.heading('amount',text=tr('amount'),anchor='center')
        ptree.heading('active',text=tr('status'),anchor='center')
        tree.heading('date',text=tr('date')); tree.heading('type',text=tr('type'))
        tree.heading('category',text=tr('category')); tree.heading('amount',text=tr('amount')); tree.heading('note',text=tr('note'))
        adv_tree.heading('date',text=tr('when')); adv_tree.heading('cat',text=tr('category'))
        adv_tree.heading('amount',text=tr('expense')); adv_tree.heading('impact',text=tr('impact')); adv_tree.heading('note',text=tr('note'))
        quick_language_var.set(LANGUAGE_NAMES.get(data.get('language','es'),'🌐  Español')) if 'quick_language_var' in globals() else None
    except Exception:
        pass
    # Encabezados de tablas y listas con valores semánticos.
    for c,key in [('date','date'),('type','type'),('cat','category'),('amount','amount'),('note','note')]: tree.heading(c,text=tr(key))
    for c,key in [('name','payment'),('amount','amount'),('active','status')]: ptree.heading(c,text=tr(key))
    old_type=canonical_from_display(type_var.get(),TYPE_KEYS); old_cat=canonical_from_display(category_var.get(),CATEGORY_KEYS)
    type_cb.configure(values=type_choices()); cat_cb.configure(values=category_choices())
    type_var.set(semantic_label(old_type,TYPE_KEYS)); category_var.set(semantic_label(old_cat,CATEGORY_KEYS))
    available_title.config(text='✓  '+tr('available')); progress_title.config(text='↗  '+tr('savings_progress')); goal_title.config(text='◎  '+tr('savings_target')); recent_title.config(text='≡  '+tr('recent')); monthly_preview_title.config(text='▣  '+tr('monthly_title'))
    summary_title_labels['income'].config(text=tr('income')); summary_title_labels['spent'].config(text=tr('spent')); summary_title_labels['savings'].config(text=tr('savings'))
    new_category_btn.config(text=tr('new_category_short')); edit_category_btn.config(text=tr('edit_category_short')); delete_category_btn.config(text=tr('delete_category_short')); stats_simple_btn.config(text=tr('simple_stats')); stats_advanced_btn.config(text=tr('advanced_stats')); adv_category_title.config(text=tr('category_analysis')); adv_impact_title.config(text=tr('monthly_impact')); adv_detail_title.config(text=tr('expense_detail'))
    for c,key in [('date','when'),('cat','category'),('amount','expense'),('impact','impact'),('note','note')]: adv_tree.heading(c,text=tr(key))
    auto_income_title.config(text='▣  '+tr('auto_income')); stats_chart_title.config(text=tr('month_compare')); stats_summary_title.config(text=tr('monthly_summary')); stats_category_title.config(text=tr('category_spending')); stats_compare_title.config(text=tr('difference_previous')); chart_type_var.set(tr('bars')); chart_type_box.configure(values=[tr('bars'),tr('line'),tr('pie')])
    draw_chat(); refresh_all()

def save_settings():
    try:data['monthly_income']=max(0,float(income_var.get()));data['savings_goal']=max(0,float(save_var.get()))
    except:return messagebox.showerror('Dato inválido','Ingreso y ahorro deben ser números.')
    data['ai_provider']=provider_var.get();data['ai_api_key']=api_var.get().strip();data['ai_model']=model_var.get().strip();data['ai_base_url']=base_var.get().strip()
    save_data();apply_language();apply_theme(data.get('theme','light'));messagebox.showinfo(tr('save'),tr('save'))
button(sc,tr('save'),save_settings,True).pack(anchor='e',padx=20,pady=(0,20))

# FIRST RUN — configuración limpia para la edición pública
def first_run_setup():
    if data.get('setup_completed'):
        return True
    win=tk.Toplevel(root); win.title(tr('welcome')); win.configure(bg=BG)
    win.geometry('560x590'); win.resizable(False,False); win.transient(root); win.grab_set()
    win.protocol('WM_DELETE_WINDOW', lambda: None)
    tk.Label(win,text='MafiFlow',bg=BG,fg=ACCENT,font=('Segoe UI',26,'bold')).pack(anchor='w',padx=34,pady=(30,2))
    tk.Label(win,text=tr('setup'),bg=BG,fg=TEXT,font=('Segoe UI',13,'bold')).pack(anchor='w',padx=34,pady=(0,5))
    tk.Label(win,text=tr('privacy'),bg=BG,fg=MUTED,justify='left',font=('Segoe UI',9)).pack(anchor='w',padx=34,pady=(0,22))
    box=tk.Frame(win,bg=PANEL,highlightthickness=1,highlightbackground=LINE); box.pack(fill='x',padx=34)
    iv=tk.StringVar(); sv=tk.StringVar(); pn=tk.StringVar(value='Renta'); pa=tk.StringVar()
    def wf(txt,var):
        tk.Label(box,text=txt,bg=PANEL,fg=MUTED,font=('Segoe UI',9)).pack(anchor='w',padx=18,pady=(13,4))
        e=entry(box,var); e.pack(fill='x',padx=18,ipady=7); return e
    first=wf(tr('usual_income'),iv); wf(tr('optional_saving'),sv)
    tk.Label(box,text=tr('first_payment'),bg=PANEL,fg=TEXT,font=('Segoe UI',10,'bold')).pack(anchor='w',padx=18,pady=(18,0))
    wf(tr('name_example'),pn); wf('Cantidad',pa)
    done={'ok':False}
    def finish():
        try: income=float(iv.get().strip() or 0); saving=float(sv.get().strip() or 0); amount=float(pa.get().strip() or 0)
        except ValueError:
            messagebox.showerror('Revisa los datos','Las cantidades deben ser números.',parent=win); return
        if income < 0 or saving < 0 or amount < 0:
            messagebox.showerror('Revisa los datos','Las cantidades no pueden ser negativas.',parent=win); return
        data['monthly_income']=income; data['savings_goal']=saving; data['monthly_payments']=[]
        if pn.get().strip() and amount>0: data['monthly_payments'].append({'name':pn.get().strip(),'amount':amount,'active':True})
        data['setup_completed']=True; save_data(); done['ok']=True; win.destroy()
    button(win,tr('start'),finish,True).pack(fill='x',padx=34,pady=24)
    tk.Label(win,text=tr('later'),bg=BG,fg=MUTED,font=('Segoe UI',8)).pack()
    first.focus_set(); root.wait_window(win); return done['ok']

# refresh
def refresh_all():
    m=month_key();tx=[t for t in data['transactions'] if t.get('date','').startswith(m)]
    inc=sum(float(t['amount']) for t in tx if t['type'] in ('Ingreso mensual','Ingreso extra')); bills=sum(float(t['amount']) for t in tx if t['type']=='Pago mensual'); spent=sum(float(t['amount']) for t in tx if t['type']=='Gasto'); available=inc-bills-spent-float(data['savings_goal'])
    summary_labels['income'].config(text=money(inc));summary_labels['spent'].config(text=money(bills+spent));summary_labels['savings'].config(text=money(float(data['savings_goal'])));summary_labels['available'].config(text=money(available),fg=GREEN if available>=0 else RED)
    goal=float(data.get('savings_goal',0) or 0); current=max(0.0,inc-bills-spent); pct=0 if goal<=0 else max(0,min(100,int(current/goal*100)))
    saving_progress_text.config(text=f'{pct}%'); saving_goal_text.config(text=money(goal)); saving_goal_sub.config(text=f'{money(current)} / {money(goal)}')
    saving_canvas.update_idletasks(); w=max(1,saving_canvas.winfo_width()); saving_canvas.coords(saving_track,0,5,w,13); saving_canvas.coords(saving_fill,0,5,w*(pct/100),13)
    auto_income_note.config(text=tr('auto_income_note').format(amount=money(float(data.get('monthly_income',0) or 0))))
    for w in recent_box.winfo_children():w.destroy()
    for t in list(reversed(data['transactions']))[:6]:
        row=tk.Frame(recent_box,bg=PANEL);row.pack(fill='x',pady=5);note=t.get('note') or ui_semantic(t.get('category',''),CATEGORY_KEYS)
        note=ui_semantic(note,NOTE_KEYS); tk.Label(row,text=note,bg=PANEL,fg=TEXT,font=('Segoe UI',10)).pack(side='left');sign='+' if t['type'] in ('Ingreso mensual','Ingreso extra') else '-';tk.Label(row,text=sign+money(float(t['amount'])),bg=PANEL,fg=GREEN if sign=='+' else RED,font=('Segoe UI',10,'bold')).pack(side='right')
    if not data['transactions']:tk.Label(recent_box,text=tr('no_moves'),bg=PANEL,fg=MUTED).pack(anchor='w')
    for w in monthly_box.winfo_children():w.destroy()
    for p in data.get('monthly_payments',[])[:7]:
        row=tk.Frame(monthly_box,bg=PANEL);row.pack(fill='x',pady=5);tk.Label(row,text=p['name'],bg=PANEL,fg=TEXT).pack(side='left');tk.Label(row,text=money(float(p['amount']))+('' if p.get('active',True) else '  · '+tr('paused_suffix')),bg=PANEL,fg=MUTED).pack(side='right')
    for x in tree.get_children():tree.delete(x)
    for i,t in enumerate(data['transactions']):tree.insert('','end',iid=str(i),values=(t['date'],ui_semantic(t['type'],TYPE_KEYS),ui_semantic(t['category'],CATEGORY_KEYS),money(float(t['amount'])),ui_semantic(t.get('note',''),NOTE_KEYS)))
    for x in ptree.get_children():ptree.delete(x)
    for i,p in enumerate(data['monthly_payments']):ptree.insert('','end',iid=str(i),values=(p['name'],money(float(p['amount'])),tr('active') if p.get('active',True) else tr('paused')))
    # Rebuild dynamic ComboBoxes AND their selected display value. This is important:
    # ttk updates the drop-down list separately from the text currently shown.
    _type_canonical=canonical_from_display(type_var.get(),TYPE_KEYS)
    _cat_canonical=canonical_from_display(category_var.get(),CATEGORY_KEYS)
    type_cb.configure(values=type_choices())
    cat_cb.configure(values=category_choices())
    type_var.set(ui_semantic(_type_canonical,TYPE_KEYS))
    category_var.set(ui_semantic(_cat_canonical,CATEGORY_KEYS))
    draw_chat()
    try: draw_statistics(); draw_advanced_statistics()
    except Exception: pass

# Arranque público: la ventana principal debe existir y estar visible antes de abrir
# el asistente modal. Si el root está withdrawn, Windows puede ocultar también el
# Toplevel y la aplicación parece no abrir mientras wait_window espera para siempre.
root.update_idletasks()
root.deiconify()
root.lift()
if first_run_setup():
    process_month()
    apply_theme(data.get('theme','light'))
    show_page('home')

# ===== BETA 7: quick sidebar controls =====
LANGUAGE_OPTIONS=[
    ('🌐  Español','es'),('🌐  English','en'),('🌐  Français','fr'),
    ('🌐  Deutsch','de'),('🌐  বাংলা','bn')
]
LANGUAGE_NAMES={code:label for label,code in LANGUAGE_OPTIONS}

def quick_change_language(event=None):
    selected=quick_language_var.get()
    code=next((code for label,code in LANGUAGE_OPTIONS if label==selected),'es')
    # Capturar el significado ANTES de cambiar idioma. Así ningún Combobox conserva francés/español/etc.
    old_type=canonical_from_display(type_var.get(),TYPE_KEYS)
    old_cat=canonical_from_display(category_var.get(),CATEGORY_KEYS)
    data['language']=code
    save_data()
    try:
        apply_language()
        type_cb.configure(values=type_choices()); type_var.set(ui_semantic(old_type,TYPE_KEYS))
        cat_cb.configure(values=category_choices()); category_var.set(ui_semantic(old_cat,CATEGORY_KEYS))
        chart_type_box.configure(values=[tr('bars'),tr('line'),tr('pie')])
        # Redibujar tablas/listas con traducción semántica en el mismo instante.
        refresh_all()
    except Exception:
        refresh_all()

def quick_change_theme(name):
    data['theme']=name
    save_data()
    apply_theme(name)
    try:
        quick_sun.configure(bg='#CFF5B7' if name=='light' else THEMES[name]['SIDEBAR'],fg='#173D28' if name=='light' else '#FFFFFF')
        quick_moon.configure(bg='#CFF5B7' if name=='dark' else THEMES[name]['SIDEBAR'],fg='#173D28' if name=='dark' else '#FFFFFF')
    except Exception:
        pass

# Bottom dock: always accessible, no need to open Settings.
quick_dock=tk.Frame(sidebar,bg=THEMES[data.get('theme','light')]['SIDEBAR'])
quick_dock.pack(side='bottom',fill='x',padx=10,pady=(6,14))

quick_language_var=tk.StringVar(value=LANGUAGE_NAMES.get(data.get('language','es'),'🌐  Español'))
quick_language=ttk.Combobox(quick_dock,textvariable=quick_language_var,state='readonly',
    values=[label for label,code in LANGUAGE_OPTIONS],font=('Segoe UI',9))
quick_language.pack(fill='x',ipady=4,pady=(0,8))
quick_language.bind('<<ComboboxSelected>>',quick_change_language)

quick_theme=tk.Frame(quick_dock,bg=THEMES[data.get('theme','light')]['SIDEBAR'],
    highlightthickness=1,highlightbackground='#2B7862')
quick_theme.pack(fill='x')
quick_sun=tk.Button(quick_theme,text='☀',bd=0,relief='flat',font=('Segoe UI Symbol',14),
    command=lambda:quick_change_theme('light'),cursor='hand2')
quick_sun.pack(side='left',fill='x',expand=True,padx=2,pady=2)
quick_moon=tk.Button(quick_theme,text='☾',bd=0,relief='flat',font=('Segoe UI Symbol',15),
    command=lambda:quick_change_theme('dark'),cursor='hand2')
quick_moon.pack(side='left',fill='x',expand=True,padx=2,pady=2)

quick_footer=tk.Label(quick_dock,text='MafiFlow v1.3.2\nGestiona hoy, vive mejor',
    bg=THEMES[data.get('theme','light')]['SIDEBAR'],fg='#8FB8A8',
    justify='left',anchor='w',font=('Segoe UI',7))
quick_footer.pack(fill='x',pady=(9,0))
quick_change_theme(data.get('theme','light'))

root.mainloop()
