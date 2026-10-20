# Product spec — Tour Board

The full brief is [`IMPLEMENTATION_BRIEF.md`](IMPLEMENTATION_BRIEF.md). This
page summarises what the app does today.

**Promise:** plan a trip together, record every shared expense, understand
who owes what, and map the itinerary — with an extremely simple interface.
Free-first (Firebase Spark + a small free-tier backend), secure by default,
honest about limits.

## Users and principles

Friends, families, couples and student groups (first target: a Cox's Bazar
weekend). Simple first, financially correct, rules as the security boundary,
privacy-respecting, real-time where useful, graceful offline,
minimal premium UI, international-ready.

## Features

- **Onboarding**: one screen, "Continue with Google", privacy note.
- **Home**: active/upcoming, recently closed and archived tours; create or
  join; inbox badge.
- **Tours**: name, dates, currency, time zone, optional budget and
  description; statuses upcoming/active (by date), closed, archived; host
  can reopen, archive and delete archived tours.
- **Invites and membership**: 12-character join codes (no links), request →
  approve or decline, attempt limit, revoke/rotate codes, roles host/admin/member,
  remove, leave, transfer host, 30-member cap.
- **Expenses**: amount first, description, category, payer, date, equal /
  exact-amount / shares splits with any subset of members, live preview,
  search and filters, budget progress, soft delete, "View edits" history.
- **Balances and settlements**: per-currency nets in plain language,
  suggested transfers, record a payment (full or partial, method,
  reference, note), counterparty confirms or disputes, admin fallback.
- **Plan**: day-wise itinerary in the tour's time zone, times, place search
  or manual coordinates, estimated cost, pinned stops, done/skipped,
  reorder, open in external maps.
- **Map**: Google Maps with numbered, day-coloured stops, a day filter and a
  swipeable stop carousel; places are chosen on a full-screen map (search or
  drop a pin). Directions open Google Maps. (No live location sharing.)
- **More**: members, notes (with edit history), packing checklist, activity
  feed, tour settings and permissions.
- **Notifications**: push notifications and an in-app inbox for join
  requests, payments, roles, tour status and (optionally) expense/plan
  updates; opt-in device-local plan reminders.
- **Retention**: tours are deleted 30 days after they end (with warnings);
  old notifications and join requests are cleaned up daily.
- **Settings**: name, read-only email, theme, language, notification
  preferences, privacy/retention explanation, sign out,
  account deletion (blocked while hosting), developer diagnostics (long-press
  the version line).

## Non-goals (MVP)

Payments, banking, public discovery, chat, AI itineraries, receipt OCR, file
uploads, turn-by-turn navigation, live location sharing, subscriptions, web
admin, guaranteed push or background tracking.

## Localization

English via ARB (`lib/l10n/app_en.arb`, 460+ strings); add a language by
adding `app_<code>.arb`. Locale-aware dates and money; ISO currency codes;
UTC storage with IANA tour zones.
