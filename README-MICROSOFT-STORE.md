# MafiFlow for Microsoft Store — 1.5.11.0

This project is the **Windows source release**, ported from the Android 1.0.10 multi-profile beta, not a prebuilt or signed MSIX. The Windows-specific icon, Help Center and native `.json` file pickers are preserved.

## Changes

- Independent local profiles with separate transactions, recurring payments, initial balance, reserved savings, currency, locale, theme and advisor context/history.
- One-time migration of previous `SharedPreferences` key `mafiflow_data` into `mafiflow_profiles_v1`. The old key is NOT removed; corrupted archives are not silently overwritten.
- Period totals and available-balance calculation improvements, date parsing, backward/forward period navigation and periodic/resume schedule refresh.
- Opening balance and accumulated transactions included in the generative AI context; helpful localized provider errors instead of HTML error pages.
- Optional **Offline** summary; deterministic local calculations, **not** a generative AI. No network or API key needed.
- Backup of ALL profiles to JSON (copied to clipboard and optionally saved as a Windows `.json` file); secret API keys are omitted. Import supports both legacy single-account JSON and version-1 multi-profile archives. The import confirmation replaces all profiles in the PC installation.
- Multilingual changes in ES/EN/FR/DE/BN.
- Windows Help Center forms and the official EXE + Store icon are kept intact.

## Microsoft Store packaging

The CI workflow `.github/workflows/microsoft-store.yml` builds on `windows-latest` when launched manually (**Actions → MafiFlow - Microsoft Store MSIX CORREGIDO → Run workflow**).

1. Generates native Windows Flutter project (`flutter create --platforms=windows --project-name mafiflow --org com.mafistudio .`).
2. Installs dependencies, runs `flutter analyze` and `flutter test` (finance, profiles and the Windows Help Center regressions).
3. Runs `tools/Branding-Windows.ps1` so the EXE uses the official MafiFlow icon, and builds a Release executable.
4. Packages/validates `dist/MafiFlow_Store_x64_1.5.11.0.msix` and uploads it with the icon verification report as a GitHub Actions artifact.

### IMPORTANT: Preserve existing Microsoft Store identity

- Name: `Mafistudio.MafiFlow`
- Publisher: `CN=728E4776-BB76-436A-88FF-F627802F7887`
- Publisher display name: `Mafistudio`
- Application Id: `mafiflow`
- x64 version: `1.5.11.0` (Flutter `1.5.11+27`)

The Microsoft Store MSIX is prepared for Store signing and submission, **not** a locally signed standalone installer. Microsoft Store's Partner Center must confirm that this version is greater than the published one and all package identity fields match the existing listing. The original desktop installer/app must be updated **in place**, not uninstalled and reinstalled, to retain local finances.

## Release smoke test BEFORE publishing

1. Keep a copy of the existing Store installation data and create a JSON backup if the old UI offers it. Upgrade over the same installed Store app; verify transactions, initial balance and payments still exist in **Profile 1**.
2. Create a second profile with currency CUP. Enter its own starting balance and transactions, switch back and confirm absolutely no cross-account mixing.
3. Change language/theme, restart Windows/app, check profile selection and data persistence.
4. Compare 'Disponible' with `opening balance + all recorded income - all recorded expenses - reserved savings` for both profiles; test period navigation and dated recurring payments.
5. Test offline advisor; test an authorized online provider including a 403 response in a supported environment. The offline feature does not evade geo-restrictions.
6. Export multi-profile JSON to a file and import it into a *test installation only*; check amounts, currencies and that API keys were excluded.
7. Verify icon on executable, Start menu and Store listing, and repeat Help Center accordion/form tests.

**Build verification limitation:** This archive has been inspected and checked structurally, but Flutter and Windows Store packaging tools are not installed in the authoring environment. No claim is made of successful `flutter analyze`, `flutter test`, real device validation, MSIX signing or Store acceptance until GitHub Actions and manual checks complete.
