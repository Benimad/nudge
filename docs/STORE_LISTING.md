# Nudge — Play Store Listing Kit

Everything the Play Console asks for, pre-written in the product's shame-free
voice. Tune freely; keep the tone.

## App title (30 chars max)
`Nudge: ADHD Habit Tracker`

## Short description (80 chars max)
`Gentle habits for real brains. No red badges, no shame — just tiny wins.`

## Full description (4000 chars max)

Most habit apps are built for brains that don't need them. Nudge is built for
the rest of us — ADHD, autistic, anxious, or just overwhelmed.

**Gentle by design**
- No red badges. No guilt-trip streaks. Missing a day gets you "no shame," not
  a broken chain.
- Soft nudges or vibration-only reminders — you choose how loud your day is.
- A sensory-safe mode that calms the whole interface.

**Built for stuck brains**
- Paralysis mode notices when you freeze and breaks the task into 30-second
  micro-steps.
- Body doubling: focus alongside other real people, with a calm timer and
  encouragement that shows up exactly when motivation dips.
- An AI coach that speaks ADHD — it breaks tasks down instead of telling you
  to "just start."

**Celebrate every win**
- Dopamine points, confetti, and streaks that build you up instead of
  stressing you out.
- Stats that find your patterns ("Wednesdays are your superpower") instead of
  shaming your gaps.

**Private by default**
- Your habits live on your device. Offline mode keeps everything local.
- No ads, ever. We never sell your data. Analytics are anonymous, content-free,
  and can be switched off in Settings.
- Export everything, or share a progress report with your therapist — your call.

Start with one tiny habit. That's the whole method.

## Category
Health & Fitness (or Productivity)

## Tags
ADHD, habit tracker, focus timer, routines, neurodivergent, body doubling

## Content rating questionnaire notes
- No user-generated public content (AI chat is 1:1, not shared).
- Health-adjacent: mentions ADHD/anxiety but provides no medical advice —
  answer "no" to medical-device/diagnosis questions.

## Data safety form (matches PRIVACY_POLICY.md)
| Question | Answer |
|---|---|
| Collects data? | Yes |
| Data types | App activity (habit events), App info (crash logs), Personal identifiers (email, only with Google sign-in) |
| Encrypted in transit? | Yes |
| Deletable by user? | Yes (in-app deletion) |
| Shared with third parties? | Processors only: Firebase (sync/crash), Google Gemini (AI replies), RevenueCat (subscriptions), PostHog (anonymous analytics, if enabled) |
| Sold? | No |

## Release checklist (Play Console)
1. Privacy policy URL published and linked.
2. `flutter build appbundle --release` with all `--dart-define` keys
   (see lib/core/config/app_config.dart header for the full command).
3. Internal testing track → sandbox purchase test → production.
4. Screenshots: welcome, home with habits, celebration, stats, paralysis mode,
   settings (light + dark). The UI is showcase-grade — use real screens, not
   mockups.
