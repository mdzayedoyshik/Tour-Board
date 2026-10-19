# Product spec — Tour Board

The full brief is [`IMPLEMENTATION_BRIEF.md`](IMPLEMENTATION_BRIEF.md). This
page summarises what the app does today.

**Promise:** plan a trip together, record every shared expense, understand
who owes what, and optionally share live locations — with an extremely
simple interface. Free-first (Firebase Spark, no backend), secure by default,
honest about limits.

## Users and principles

Friends, families, couples and student groups (first target: a Cox's Bazar
weekend). Simple first, financially correct, rules as the security boundary,
privacy-respecting location, real-time where useful, graceful offline,
minimal premium UI, international-ready.

## Features

- **Onboarding**: one screen, "Continue with Google", privacy note.
- **Home**: active/upcoming, recently closed and archived tours; create or
  join; inbox badge.
- **Tours**: name, dates, currency, time zone, optional budget and
  description; statuses upcoming/active (by date), closed, archived; host
  can reopen, archive and delete archived tours.
- **Invites and membership**: 12-character codes / links, request → approve
  or decline, attempt limit, revoke/rotate links, roles host/admin/member,
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
- **Map**: OSM map with place pins and member avatars, attribution, people
  sheet with sharing status, tile-failure fallback.
- **Location sharing**: off by default; 30 min / 2 h / until trip ends;
  visible indicator and Stop; foreground only; stale/paused/not sharing.
- **More**: members, notes (with edit history), packing checklist, activity
  feed, tour settings and permissions.
- **Notifications**: in-app inbox, unseen-activity badge by preference,
  opt-in device-local plan reminders. No remote push in strict free mode.
- **Settings**: name, read-only email, theme, language, notification
  preferences, location help, privacy/retention explanation, sign out,
  account deletion (blocked while hosting), developer diagnostics (long-press
  the version line).

## Non-goals (MVP)

Payments, banking, public discovery, chat, AI itineraries, receipt OCR, file
uploads, turn-by-turn navigation, location history, subscriptions, web
admin, guaranteed push or background tracking.

## Localization

English via ARB (`lib/l10n/app_en.arb`, 460+ strings); add a language by
adding `app_<code>.arb`. Locale-aware dates and money; ISO currency codes;
UTC storage with IANA tour zones.
