# MafiFlow Windows 1.5.11 — Perfiles

## Added
- Multiple private, independent financial profiles on one Windows PC.
- Select, create, rename and delete profiles (cannot delete the last one).
- Compatible multi-profile JSON import/export, with desktop file chooser and clipboard.
- Offline deterministic balance report as an alternative to online AI providers.

## Fixed / improved
- Existing desktop data migrated without deleting legacy `mafiflow_data` storage.
- Financial advisor includes starting balance, all income/expenses and reserved savings when calculating available funds.
- Period overview and automatic recurrent calculations refreshed on resume and new days.
- Date parsing works with the original desktop transaction timestamps.
- User-friendly localized HTTP 401, 403 and 429 messages; no workaround for provider geo-restrictions.
- Currency changes only affect formatting, and **never automatically exchange existing amounts**.
- Existing desktop feedback accordion forms, official MafiFlow EXE and Store logos preserved.

## Distribution
- Flutter source: `1.5.11+27`.
- Microsoft Store package: `1.5.11.0`, x64, same Store identity and publisher.
- GitHub Actions workflow now includes finance/archive/Windows Help Center tests before building MSIX.
- **Status:** source update provided; Flutter build/tests and certification need to be run on Windows CI.
