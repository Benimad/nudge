# Nudge — Play Store Listing Kit

Everything the Play Console asks for, pre-written in the product's shame-free
voice. Tune freely; keep the tone.

## App title (30 chars max)
`Nudge: Habit Tracker & Focus`

(Personal developer accounts cannot publish health-category apps — see the
Category section. Keep "ADHD" out of the TITLE; the description may describe
the audience.)

## Short description (80 chars max)
`Gentle habits for real brains. No red badges, no shame — just tiny wins.`

## Full description (4000 chars max)

PASTE EXACTLY AS-IS — plain text only. Play Console renders no markdown, so
never paste `**bold**`, `#` headers, or comma-separated keyword lists (those
trigger the "unstructured keywords" listing rejection).

---

Nudge is a habit tracker and focus companion designed for people with ADHD, autism, or anxiety — and for anyone whose brain doesn't respond well to traditional productivity apps.

Most habit apps punish you for missing a day. Nudge never does. There are no red badges, no broken-chain guilt, and no streak pressure. Instead you get gentle reminders and honest encouragement that help you build routines one tiny step at a time.

WHAT NUDGE DOES

• Track daily habits with soft nudges or vibration-only reminders — you choose how loud your day is.
• When you freeze, Paralysis Mode notices and breaks the task into 30-second micro-steps, without judgment.
• Chat with an AI coach that understands ADHD. It knows your habits, streaks, goals, and patterns, so its advice fits your real life. No connection? It falls back to built-in coping strategies that work offline.
• Focus alongside other real people with body doubling: a calm timer, live presence, and encouragement that appears exactly when motivation usually dips.
• Check in with your mood in one tap and see how it connects to your habits over time.
• Understand your patterns with weekly stats: your strongest day of the week, your completion trend, and a short insight written about your week.

BUILT FOR NEURODIVERGENT BRAINS

• Sensory-safe mode calms the entire interface.
• Reduce-motion, high-contrast, and large-text accessibility settings throughout.
• Celebrations appear for meaningful moments — finishing your day, first wins, milestones — so they stay rewarding instead of overwhelming.

PRIVATE BY DEFAULT

• Your habits are stored on your device, with an optional private cloud backup so you never lose progress after reinstalling.
• Offline mode keeps everything local. No ads, ever. We never sell your data.
• Export your data anytime, or delete everything with one tap in Settings.

Nudge Pro is an optional subscription that unlocks unlimited habits, unlimited AI coaching, and unlimited focus sessions. The free version is fully functional with up to five habits.

Start with one tiny habit. That's the whole method.

---

## Category
Productivity — NOT Health & Fitness.

Google requires organization accounts for health-category apps (policy since
Aug 2024). Nudge is a habit tracker / focus tool, provides no medical advice,
diagnosis, or treatment, so it is honestly declared as:
- Category: Productivity
- App content → Health apps: "My app does not have any health features"
- Content rating: "No" to all medical/diagnostic questions

(Do NOT paste keyword lists anywhere in the listing — Play flags them.)

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

## Legal URLs (already live via GitHub Pages)
- Privacy policy: https://benimad.github.io/nudge/privacy-policy.html
- Terms of service: https://benimad.github.io/nudge/terms.html

## Release checklist (Play Console)
1. Privacy policy URL (above) pasted into the Play Console listing.
2. `flutter build appbundle --release --dart-define-from-file=dart_defines.json`
   (template: dart_defines.example.json; see lib/core/config/app_config.dart).
3. Internal testing track → sandbox purchase test → production.
4. Screenshots: welcome, home with habits, celebration, stats, paralysis mode,
   settings (light + dark). The UI is showcase-grade — use real screens, not
   mockups.
