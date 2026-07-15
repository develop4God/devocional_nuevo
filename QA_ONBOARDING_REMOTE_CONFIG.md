# QA Script — Remote Config Cleanup + Onboarding Wiring

**Branch:** `chore/add-toogle-discovery-debug`
**Scope:** commits `c86b712c`, `ad075681`, `85b4d101`, `80e22208`

This branch does three things:
1. Removes three dead remote-config flags (`feature_legacy`, `feature_bloc`, `show_backup_section`) that were hardcoded to their production values for months.
2. Wires up the existing (previously dark) onboarding flow behind DI + a single remote-config flag (`enable_onboarding_flow`).
3. Deletes orphaned debug widgets (`DebugSettingsSection`, `TestBadgesPage`) that were never constructed anywhere.

**Testing-only change:** `lib/services/remote_config_service.dart` has `enable_onboarding_flow` local default hardcoded to `true` (marked with a `// TODO: revert to false before merging to main`). This is intentional for this QA pass — **do not merge to `main` without reverting it to `false`** unless Firebase Console's `enable_onboarding_flow` is also confirmed off.

---

## 0. Pre-flight

```bash
git status                      # confirm clean tree on this branch
flutter clean && flutter pub get
```

Run automated gates first — if these fail, stop and report before doing manual QA:

```bash
dart format --output=none --set-exit-if-changed lib/ test/
dart analyze --fatal-infos
flutter test test/unit/services/remote_config_service_test.dart \
              test/unit/services/onboarding_service_test.dart \
              test/unit/blocs/backup_bloc_working_test.dart \
              test/unit/blocs/onboarding_bloc_user_flows_test.dart \
              test/behavioral/onboarding_behavior_test.dart \
              test/migration/no_singleton_antipatterns_test.dart \
              test/unit/services/service_locator_test.dart \
              test/unit/providers/devocional_provider_working_test.dart \
              test/unit/providers/devocional_provider_test.dart \
              --reporter compact
```

Expected: all green, 0 analyzer issues.

---

## 1. Onboarding flow (new — this is the main manual QA target)

**Setup:** fresh install or clear app data (Settings → Apps → [app] → Storage → Clear Data), so no `onboarding_complete` SharedPreferences key exists.

| # | Step | Expected |
|---|---|---|
| 1.1 | Launch app fresh (first-ever install / cleared data) | Onboarding flow appears (Welcome → Theme Selection → Backup Configuration → Complete) instead of going straight to the devotionals home screen |
| 1.2 | Complete the onboarding flow end to end | Lands on the normal app home (`AppNavigationShell`) after the Complete page |
| 1.3 | Kill and relaunch the app | Onboarding does **not** show again (goes straight to home) — confirms `isOnboardingComplete()` persists |
| 1.4 | Clear app data again, but this time kill the app mid-onboarding (after Welcome, before Complete) | On relaunch, onboarding resumes/restarts rather than silently skipping — verifies the `onboarding_in_progress` flag path still works |
| 1.5 | With onboarding data cleared, force close app during splash before `_initializeApp()` resolves, then reopen | No crash, app recovers to either splash or onboarding, never stuck |

**Regression checks:**

| # | Step | Expected |
|---|---|---|
| 1.6 | On the Theme Selection onboarding page, pick a theme | Theme applies immediately and persists into the main app after onboarding completes |
| 1.7 | On the Backup Configuration onboarding page, connect/skip Google Drive backup | Choice is respected — check Settings → Backup section afterward reflects it |

---

## 2. Remote config kill-switch behavior

Since `enable_onboarding_flow` defaults to `true` locally on this branch for testing:

| # | Step | Expected |
|---|---|---|
| 2.1 | With no network / airplane mode on first launch (fresh install) | `fetchAndActivate()` fails, service falls back to the local default (`true` on this branch) — onboarding still shows. No crash, no infinite spinner. |
| 2.2 | Temporarily edit the local default in `remote_config_service.dart` to `false`, rebuild, fresh install | Onboarding does **not** show, app goes straight to home — confirms the flag genuinely gates it end-to-end, not just cosmetically |

*(Revert any temporary edit from 2.2 before continuing — don't leave `false` committed either, unless that's your intended final state.)*

---

## 3. Settings page — Backup section (flag removed, should always show)

| # | Step | Expected |
|---|---|---|
| 3.1 | Open Settings | "Google Drive Backup" tile is visible (previously gated by `show_backup_section`, now unconditional) |
| 3.2 | Tap the Backup tile | Navigates to `BackupSettingsPage` normally, no regression |

---

## 4. Devotional read tracking (feature_bloc/feature_legacy removed)

| # | Step | Expected |
|---|---|---|
| 4.1 | Open a devotional, read it fully (scroll to bottom, let it finalize / navigate away) | No crash. In Firebase DebugView or logcat (`developer.log` with name `DevocionalProvider`), confirm `devotional_bloc_success` analytics event fires (not `devotional_legacy_success` or `devotional_tracking_mode` — those no longer exist) |
| 4.2 | Check spiritual stats update after reading (e.g. Stats page / streak counter) | Stats still update correctly — confirms `_statsService.recordDevocionalRead(...)` (which runs unconditionally, unrelated to the removed flag branching) is unaffected |

---

## 5. Debug menu (orphaned widgets removed)

| # | Step | Expected |
|---|---|---|
| 5.1 | Open the app's Debug section/menu (if reachable in this build) | No "Badges" test page or the old `DebugSettingsSection` panel appears — they're deleted. Confirm nothing in the debug menu references them (should already be absent since they were never wired in) |
| 5.2 | grep sanity check: `grep -rn "DebugSettingsSection\|TestBadgesPage" lib/` | No matches |

---

## 6. Regression sweep (things that touched shared files)

| # | Step | Expected |
|---|---|---|
| 6.1 | App cold start, general navigation through main tabs (Devotionals, Discovery, Encounters, Settings) | No crashes, no missing services (`getService<T>()` errors would show as red screen / exception) |
| 6.2 | Force-kill and relaunch a few times in a row | `RemoteConfigService.initialize()` and `OnboardingService` registration don't throw or double-initialize (check logs for `RemoteConfigService: Already initialized, skipping...` on subsequent calls, not errors) |

---

## Sign-off checklist

- [ ] All automated gates green (Section 0)
- [ ] Onboarding shows on fresh install, persists as complete after finishing (1.1–1.5)
- [ ] Remote flag genuinely gates onboarding on/off (2.1–2.2)
- [ ] Backup section always visible in Settings (3.1–3.2)
- [ ] Devotional read analytics fire without crash, stats still update (4.1–4.2)
- [ ] No orphaned debug widgets reachable (5.1–5.2)
- [ ] No regressions in general navigation (6.1–6.2)
- [ ] **Before merging to `main`:** confirm `enable_onboarding_flow` local default is reverted to `false` (or Firebase Console value is verified `false`) — see TODO in `remote_config_service.dart`
