# Nudge — Privacy Policy

**Effective date:** July 5, 2026
**App:** Nudge — ADHD Habit Tracker & Focus (`com.app.nudge`)
**Contact:** adamlaalami72@gmail.com

> Publish this document at a public URL (e.g. a GitHub Page) and link it in the
> Play Console listing before release. Review it with counsel if you expand
> into regulated health data territory.

## The short version

Your habits live on your device. We sync an encrypted-in-transit copy to your
own private cloud space so you don't lose it, we never sell data, and we show
no ads. Turn on Offline mode and nothing leaves your phone at all.

## What Nudge stores

- **Habit data** — habit names, completion history, streaks, focus-session
  durations, and optional notes you write. Stored in a local database on your
  device (the source of truth) and mirrored to your private Firebase Firestore
  space, scoped to your account, so you can restore it after reinstalling.
- **Preferences** — your selected brain type, goals, reminder times, and
  accessibility settings. Stored locally; goals and profile settings may be
  mirrored to your private cloud space.
- **Account identity** — by default an anonymous Firebase account is created
  so sync has somewhere to write. If you choose "Sign in with Google," we
  receive your Google account email and display name for authentication only.
- **AI Coach conversations** — messages you send to the AI coach are processed
  by Google's Gemini API to generate a reply. With Offline mode on (or no
  network), coaching uses an on-device knowledge base and nothing is sent.
- **Focus presence** — during a body-doubling session, an anonymous heartbeat
  (a timestamp keyed to your user id) is shared so the "people working" count
  is real. It contains no habit or task content and is deleted when the
  session ends.
- **Purchase status** — subscriptions are processed by Google Play / Apple and
  RevenueCat. We never see your payment details, only an entitlement flag.
- **Crash reports & analytics** — Firebase Crashlytics receives crash traces.
  If product analytics are enabled in a build, PostHog receives anonymous
  usage events (e.g. "habit_completed") — never habit names' content beyond
  the title you gave the habit, and never AI coach message content.

## What Nudge does NOT do

- No ads, no ad SDKs, no selling or renting data to anyone.
- No access to your contacts, location, camera, photos, or files.
- Microphone access is used only while you actively use voice input in the AI
  coach, and audio is processed for transcription only.

## Data retention & deletion

- **Delete in-app:** Settings → Privacy & data → "Export my data" /
  "Delete all data" removes the local database and your cloud mirror.
- Uninstalling the app removes all local data immediately.
- To delete your cloud data and account entirely, use the in-app deletion or
  email us at the contact above.

## Children

Nudge is not directed at children under 13 and does not knowingly collect data
from them.

## Your rights (GDPR/CCPA)

You may request access, correction, export, or deletion of your data at any
time via the in-app tools or by email. We respond within 30 days.

## Changes

We'll update this policy in-app and at its published URL when practices change,
with the effective date above.
