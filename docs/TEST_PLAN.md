# Test plan

## Automated

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test                          # unit + widget
cd rules_test && npm test             # Security Rules (emulator)
```

CI runs all of these on pull requests (`ci.yml`); `deploy.yml` runs analyze
and tests before every Play upload.

### Unit (`test/unit`)

| Area | Covered |
|---|---|
| Money | parsing to minor units, locale separators, currency exponents (0/2/3), zero/negative/huge input, round-trip, display formatting |
| Splits | equal with remainders, order independence, tiny totals, weights with largest remainder, custom sum validation, 2000 randomised cases (sum always exact) |
| Balances | sign convention, payer not participating, nets sum to zero, partial/full settlements, pending/disputed/cancelled ignored, duplicate settlement counted once, soft-deleted excluded, currencies separate, host as debtor, transfer suggestions settle all debts |
| Permissions | full matrix incl. closed tours, settings toggles, settlement confirm/dispute/cancel and admin fallback |
| Invites | generation, parsing (raw/dashed/links/custom scheme), Crockford normalisation, expiry/revocation |
| Geo | coordinate bounds |
| Dates | range validation, inclusive day keys, IANA local→UTC (DST), offset labels, effective status by tour zone |
| Plans / search / push | sparse sort keys, ordering, day grouping, reminder selection, place search via backend (auth header, session tokens, quota/outage errors), notification tap routing |

### Widget (`test/widget`)

Welcome (copy, loading, duplicate-tap guard, network error, cancel), Home
(empty, sections, member count, inbox badge), expense form (Save disabled
until valid, live split preview, custom mismatch), expense detail ("View
edits" only with revisions, deleted marker, owner controls), balances
(pending/confirmed/disputed states, plain-language balance, confirm action),
join (invalid code without network call, expired invite), tour form
validation, plan (empty itinerary days, manual place entry when search is
off, invalid coordinates), design system (text on status pills, dark theme
token, WCAG AA contrast for primary/secondary text).

### Security Rules (`rules_test`, 46 cases)

Profiles (owner-only, email/uid immutable), tour creation (host batch,
no impersonation), read access (unauthenticated, non-member, removed member),
invites (get not list), join requests (self only, expired/revoked/rotated
invites, no self-approval, host approval batch, re-admission), roles (no
escalation, host transfer batch, removal limits, host cannot leave),
expenses (valid/invalid amounts, unknown fields, malformed/oversized/
non-member shares, historical members, forged `createdBy`, edits need
revisions, cross-user edits, immutable revisions, terminal soft delete,
closed tours), settlements (party-only creation, no self-confirmation, no
forged confirmer, single confirmation, dispute reason, admin fallback,
closed tours), inbox (type whitelist, no free text, no forged approvals,
owner-only reads), content ownership, feed actor, leave batch, note
revisions, packing edits.

### Backend (`Tour-Board-Backend`)

`npm test` (13 unit: config, Places proxy mapping/caching/Essentials-only
fields/caps, push text, auth, validation, cron secret, rate limits) and
`npm run test:emulator` (11 integration: event verification incl. forged and
non-member events, delivery idempotency, preferences, invalid-token pruning,
retention policy, deletion warnings, monthly usage caps).

## Manual / physical device (before release)

- [ ] Google sign-in and sign-out on a physical Android device; fresh install
      and existing session; cancel the account picker.
- [ ] Create a tour; share the join code to a messaging app; join on a
      second device by typing the code (also with lowercase/dashes).
- [ ] Request, approve, reject, cancel and retry joining (attempt limit).
- [ ] Two devices: expenses, plans and notes update live on both.
- [ ] Airplane mode: add an expense (shows "Pending sync", not in balances),
      restart the app, reconnect and confirm it syncs once.
- [ ] Two devices edit the same expense → second save reports a conflict.
- [ ] Host as debtor and creditor; partial settlement; dispute; admin
      fallback after the counterparty leaves.
- [ ] Close the tour: expenses/plans read-only, settling still works; reopen.
- [ ] Map: numbered day-coloured pins, day filter, carousel syncs with the
      map, dark style in dark mode, Directions opens Google Maps.
- [ ] Place picker: search suggestions, tap/long-press/drag pin, rename,
      offline and quota messages.
- [ ] Push: second device receives join request, payment and expense pushes
      with the app closed; taps open the right screen; toggles in Settings
      stop expense/plan pushes; sign-out stops pushes on that device.
- [ ] Ended tour shows its deletion date; run the cleanup workflow manually
      against a test tour.
- [ ] Poor network and repeated taps on Save/Approve/Confirm.
- [ ] Dark/light/system themes, 200 % text size, TalkBack labels.
- [ ] Local reminders: enable, edit a plan time, delete it, deny OS permission.
- [ ] Account deletion as host (blocked) and as member.
- [ ] `strings` the release APK/AAB for keys: only public Firebase client
      config is present; no service-account or FCM server credentials.
