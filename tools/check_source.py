"""Static release checks only. Does not execute Dart, build or inspect an MSIX."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parents[1]
main = (root / 'lib/main.dart').read_text(encoding='utf-8')
pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
assert re.search(r'^name: mafiflow$', pubspec, re.M)
assert re.search(r'^version: 1\.5\.12\+28$', pubspec, re.M)
assert '  msix: 3.18.0' in pubspec
for marker in ['onTap:widget.onCorrectAvailable', 'onTap:widget.onCorrectSavings',
               'onTap:widget.onEraseProfile', 'correctAvailableBalance(data,n)',
               'correctSavingsBalance(data,n)', 'archive.resetActive(defaults)',
               'controller:initialSavings', 'performSavingsAction(data,',
               'recentAdvisorMessages(history)', 'financeContext(widget.data)',
               'return otherLast(', 'compareCategoryEntries(a,b)',
               'await openFile(acceptedTypeGroups:', 'await getSaveLocation(',
               'archive.encode(omitSecrets:true)', "mafiflow_profiles_v1"]:
    assert marker in main, marker
home = main.split('  Widget home(){',1)[1].split('  Widget tile(',1)[0]
assert 'showCorrectAvailable' not in home and 'showCorrectSavings' not in home
assert 'savingsDialog(' not in home
assert home.count('showNewSavingsGoal') == 1
assert home.index('if(savingsGoalAchieved(data))') < home.index('showNewSavingsGoal')
settings = main.split('class _SettingsPanelState',1)[1].split('class Advisor',1)[0]
assert settings.index('onTap:widget.onCorrectAvailable') < settings.index('onTap:widget.onCorrectSavings') < settings.index('await widget.onNewGoal()') < settings.index('TextField(controller:income')
assert 'controller:opening' not in settings
for key in ['goalReached', 'initialSavings', 'clearProfile', 'spendSavings',
            'correctAvailable', 'availableTotal', 'correctAvailableHint']:
    assert main.count(f"'{key}':") == 5, key
for path in (root / 'test').glob('*_test.dart'):
    assert 'package:mafiflow_mobile/' not in path.read_text(encoding='utf-8')
assert len(list((root / 'test').glob('*_test.dart'))) == 7
workflow = (root / '.github/workflows/microsoft-store.yml').read_text(encoding='utf-8')
assert workflow.index('flutter test') < workflow.index('flutter build windows --release') < workflow.index("'run', 'msix:create'")
for marker in ["'--build-windows', 'false'", "'--version', '1.5.12.0'",
               "'--identity-name', 'Mafistudio.MafiFlow'",
               "'--publisher', 'CN=728E4776-BB76-436A-88FF-F627802F7887'",
               "'--logo-path', 'assets/MafiFlow-official.png'",
               'if-no-files-found: error', "flutter-version: '3.35.7'"]:
    assert marker in workflow, marker
for name, expected in json.loads((root / 'tools/official_asset_hashes.json').read_text()).items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == expected, name
print('PASS: source wiring, Windows file pickers, Home/Settings layout, translations, version/Store identity, workflow order and official assets.')
print('NOT EXECUTED: Flutter analyze/test/build, actual EXE/MSIX inspection, install/upgrade, Partner Center certification.')
