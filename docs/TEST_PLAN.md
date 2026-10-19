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
| Location | live/stale/paused/expired, sharing windows and caps, write throttling, coordinate bounds |
| Dates | range validation, inclusive day keys, IANA local→UTC (DST), offset labels, effective status by tour zone |
| Plans / search / reminders | sparse sort keys, ordering, day grouping, reminder selection, Nominatim parsing, no request for short queries |

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

### Security Rules (`rules_test`, 47 cases)

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
closed tours), locations (owner-only, bounds, window, member-only reads,
cleanup), inbox (type whitelist, no free text, no forged approvals,
owner-only reads), content ownership, feed actor, leave batch, note
revisions, packing edits.

## Manual / physical device (before release)

- [ ] Google sign-in and sign-out on a physical Android device; fresh install
      and existing session; cancel the account picker.
- [ ] Create a tour; share the invite to a messaging app; open the link with
      the app installed and not installed; paste the code manually.
- [ ] Request, approve, reject, cancel and retry joining (attempt limit).
- [ ] Two devices: expenses, plans and notes update live on both.
- [ ] Airplane mode: add an expense (shows "Pending sync", not in balances),
      restart the app, reconnect and confirm it syncs once.
- [ ] Two devices edit the same expense → second save reports a conflict.
- [ ] Host as debtor and creditor; partial settlement; dispute; admin
      fallback after the counterparty leaves.
- [ ] Close the tour: expenses/plans read-only, settling still works; reopen.
- [ ] Location: deny permission, grant, revoke while sharing, background the
      app (shows paused), let the window expire, stop; stale label after 5 min.
- [ ] Battery and Firestore usage during 30 min of sharing while walking.
- [ ] Poor network and repeated taps on Save/Approve/Confirm.
- [ ] Dark/light/system themes, 200 % text size, TalkBack labels.
- [ ] Local reminders: enable, edit a plan time, delete it, deny OS permission.
- [ ] Account deletion as host (blocked) and as member.
- [ ] `strings` the release APK/AAB for keys: only public Firebase client
      config is present; no service-account or FCM server credentials.
