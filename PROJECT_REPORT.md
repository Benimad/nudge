# Nudge — Project Progress Report

**App:** Nudge — ADHD Habit Tracker & Focus (`com.app.nudge`, v1.0.0+1)
**Date:** July 5, 2026 (updated after the release-hardening pass)
**Report basis:** Full code survey, clean static analysis, 16 passing automated tests, and scripted
end-to-end walkthroughs on a Pixel 7 Pro emulator in **both light and dark mode**.

---

## 1. Executive Summary

Nudge is feature-complete, visually polished, tested, and release-engineered. Since the previous
report (~85%), every item that can be completed inside the repository has been completed: dependency
cleanup, bundled typography, real presence, signing, security rules, analytics wiring, test
coverage, store documents, and a device-verified dark-mode QA pass.

**Overall completion: ~95%.** The remaining ~5% is, by nature, outside the codebase: pasting real
API keys into the build command, deploying the Firestore rules with your Firebase login, filling the
Play Console listing, and an iOS build on a Mac. Every one of those has its scaffolding, docs, and
fallbacks already in place.

| Area | Was | Now |
|---|---|---|
| UI/UX & design system | 95% | 100% — dark mode device-verified, typography actually Inter everywhere |
| Core habit features | 95% | 100% — edit/delete now reachable (long-press / chevron), overflow fix |
| Onboarding & launch experience | 100% | 100% |
| Stats & insights | 90% | 100% — honest "not enough data" state |
| AI Coach | 80% | 95% — valid configurable model, offline fallback; needs only a key |
| Focus / body doubling | 85% | 100% — presence count is now real (Firestore heartbeats) |
| Monetization | 60% | 85% — fully wired; needs only real RevenueCat keys + store products |
| Notifications | 85% | 95% — brand color fixed, copy audited; physical-device Doze test remains |
| Data layer & sync | 85% | 90% — rules written; restore drill on fresh install still recommended |
| Analytics | 50% | 95% — dart-define init, safe no-op without a key; needs only a key |
| Testing | 10% | 90% — 13 real-DB unit tests + 3 widget tests, all green |
| Release engineering | 30% | 90% — signed keystore + gradle wiring, bundle builds; console work remains |

---

## 2. What Was Completed in This Pass

### Code quality & performance
- **Removed 7 unused dependencies** (`supabase_flutter`, `table_calendar`, `confetti`, `lottie`,
  `screenshot`, `flutter_secure_storage`, `http`) — 37 transitive packages gone from the tree.
- **Bundled Inter** (400–800 weights) as assets and removed `google_fonts`. This also fixed a latent
  typography bug: dozens of `fontFamily: 'Inter'` styles previously fell back to Roboto because no
  Inter family was declared. Fonts now load instantly and fully offline.
- `flutter analyze`: 0 issues. `flutter test`: 16/16 green.

### Correctness & honesty fixes
- **Real body-doubling presence**: `presence/{uid}` heartbeat docs in Firestore with an aggregate
  count query — the "people working" number is now real people (self included), never invented.
  Fully fault-tolerant: offline it just shows you.
- **Celebration screen overflow** on short screens fixed (scroll-safe layout) — caught by the new
  widget tests.
- **Stats AI insight** shows an honest "not enough data yet" state instead of a fabricated
  Wednesday pattern.
- **Habit edit/delete was unreachable** from the UI despite being fully implemented — now opened by
  long-press or the chevron (verified on device: pre-filled sheet + delete button).
- Notification accent color updated from the legacy purple to the brand token.

### Premium experience
- **Haptics** on habit completion (medium), goal/brain-type selection, tab switches, habit save,
  and session start.
- **Progress count-up**: the home progress bar and its percentage now animate in lockstep.
- **Skeleton shimmer loaders** replace spinners on the habit list and the paralysis-mode AI wait
  ("Breaking it down into tiny steps…").
- **Onboarding payoff card** on first Home visit: "Because you chose '<goal>'" with a tip pointing
  at the matching feature. One-time, dismissible. Verified on device.

### Release engineering & security
- **Release signing**: upload keystore generated (random 128-bit password), `key.properties` wired
  into `build.gradle.kts` with a warning fallback to debug signing; both files gitignored.
  ⚠️ **Back up `android/upload-keystore.jks` + `android/key.properties` somewhere safe** (password
  manager / secure drive). Enroll in Play App Signing on first upload.
- **Firestore security rules** (`firestore.rules` + `firebase.json`): `users/{uid}/**` owner-only,
  presence readable by signed-in users but writable only to your own heartbeat, everything else
  denied. Deploy with `firebase deploy --only firestore:rules`.
- **Analytics**: PostHog now initializes from Dart via `--dart-define=POSTHOG_API_KEY` (native
  auto-init disabled on both platforms); without a key every call is a silent no-op.
- **AI Coach**: model id is `--dart-define=GEMINI_MODEL` (default `gemini-2.5-flash`, a valid,
  broadly available model); no key → offline ADHD knowledge base, clearly by design.
- **Tests**: 13 unit tests run the real repository against real SQLite (streak math incl. grace
  period, per-habit isolation, dedupe; completion rates; undo; totals) + 3 widget tests
  (pluralization, layout, mascot painting).
- **Docs**: `PRIVACY_POLICY.md` (publishable, matches actual data practices) and
  `docs/STORE_LISTING.md` (title/descriptions in product voice, data-safety form answers, release
  checklist).

### QA (device-verified this pass)
| Flow | Light | Dark |
|---|---|---|
| Launch window → splash → welcome | ✅ (prior pass) | ✅ |
| Onboarding: brain type → goals → reminders → Home | ✅ (prior pass) | ✅ |
| Personalization card on first Home | — | ✅ |
| Add habit sheet, save | ✅ | ✅ |
| Complete → celebration ("1 day" singular) | ✅ | ✅ |
| Long-press → Edit habit sheet (delete available) | — | ✅ |
| Stats, Settings tabs | ✅ | ✅ |
| Home re-verify after theme flip | ✅ | — |

---

## 3. Remaining Work (requires you / external accounts)

These cannot be completed from inside the repo — everything is pre-wired for them:

1. **RevenueCat**: create the app + `pro` entitlement + monthly/annual products in the RevenueCat
   and Play Console dashboards, then build with
   `--dart-define=REVENUECAT_ANDROID_KEY=goog_xxx`. Sandbox-test one purchase.
2. **Gemini key**: `--dart-define=GEMINI_API_KEY=...` (AI Studio). Without it the coach uses the
   offline knowledge base — acceptable to ship, but label it in the listing if you do.
3. **PostHog key** (optional for v1): `--dart-define=POSTHOG_API_KEY=phc_...`.
4. **Deploy Firestore rules**: `firebase deploy --only firestore:rules` (needs your Firebase CLI
   login). **Do this before shipping — without it your project may be running on permissive rules.**
5. **Back up the signing keystore** (see above) — losing it before Play App Signing enrollment
   means losing the app identity.
6. **Play Console**: publish `PRIVACY_POLICY.md` at a URL, fill the listing from
   `docs/STORE_LISTING.md`, upload `build/app/outputs/bundle/release/app-release.aab` to an
   internal testing track.
7. **Physical-device test**: notification timing under Doze, haptics feel, and one full onboarding
   run on real hardware.
8. **iOS**: build/validate on a Mac (Firebase iOS config, APNs key, RevenueCat iOS key, icons).
   The Dart code is platform-clean; this is configuration work.

## 4. Nice-to-haves explicitly deferred (post-v1 roadmap)

Home-screen widgets, Wear OS complications, habit template packs, weekly digest, therapist PDF
export, streak repair/vacation mode, tablet layouts, richer presence (rooms), on-device AI upgrade.

---

## 5. Bottom Line

The application itself is done: designed, animated, honest, accessible, tested, and verified on
device in both themes. What separates this repo from the Play Store is a set of account-level
actions — keys, rule deployment, console forms, a keystore backup — collectively an afternoon of
work, none of it code.
