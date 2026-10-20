# Security Rules

`firestore.rules` is the security boundary. The UI's permission helper
(`lib/features/membership/domain/permissions.dart`) mirrors it for display
only. Tests: `rules_test/rules.test.mjs` (46 cases, Firestore emulator).

```bash
cd rules_test && npm ci && npm test     # needs Java 17+ and firebase-tools
firebase deploy --only firestore:rules  # only with explicit intent
```

## Roles and permission matrix

| Capability | Host | Admin | Member |
|---|:-:|:-:|:-:|
| Read tour content (while active) | ✓ | ✓ | ✓ |
| Add own expense / plan / note | ✓ | ✓ | ✓ |
| Edit/delete own expense, plan, note (open tour) | ✓ | ✓ | ✓ |
| Edit/delete others' expense, plan, note | ✓ | ✓ | ✗ |
| Record an expense paid by someone else | ✓ | ✓ | setting |
| Packing: add / tick | ✓ | ✓ | setting (default on) |
| Packing: delete others' items | ✓ | ✓ | ✗ |
| Approve/reject join requests, manage invites | ✓ | ✓ | ✗ |
| Remove members | anyone but host | members only | ✗ |
| Change roles, transfer host, change settings | ✓ | ✗ | ✗ |
| Edit details, close/reopen/archive | ✓ | setting (default on) | ✗ |
| Delete archived tour | ✓ | ✗ | ✗ |
| Submit settlement | as payer or payee | same | same |
| Confirm settlement | counterparty | counterparty, or uninvolved admin if counterparty inactive | counterparty |

## Data access model

- **Membership** is `tours/{t}/members/{me}.status == 'active'`. The Home
  index is never used for authorisation.
- **Profiles** are owner-only; members see name/photo snapshots only.
- **Invites**: `get` by code for signed-in users, `list` denied. A code grants
  only the ability to *request* access, and only if the invite is unrevoked,
  unexpired, matches the tour's current `inviteCode`, and the tour is open.
- **Join requests**: created only by the requester for themselves; at most 3
  attempts; requesters cannot delete (which would reset attempts). Approval
  requires the member record to become active in the same batch.
- **Members**: no self-assignment of roles or status. Host transfer needs the
  tour's `hostUid`, the new host's role and the old host's demotion in one
  batch. The host cannot leave without transferring.
- **Expenses**: fields whitelisted; amount is an int in (0, 999,999,999,999];
  currency from a fixed list; payer and every share UID must be in
  `allMemberUids` (current or former members); shares map size 1–30 and sum
  exactly to the amount; `createdBy`/`createdAt` immutable; every update must
  bump `revisionCount` and write the matching revision document atomically;
  soft delete is terminal (no resurrection); hard delete only during tour
  deletion. Closed/archived tours reject all expense writes.
- **Revisions**: create-only, by the same editor in the same commit as the
  parent edit; never updated.
- **Settlements**: only payer or payee may create, always as
  `pending_confirmation`; amounts/parties immutable; confirm/dispute by the
  counterparty; cancel by the creator; `confirmed` is terminal so it cannot
  apply twice. Allowed in closed tours (post-trip settling).
- **Inbox**: clients cannot create items at all; the backend writes them
  (Admin SDK) after verifying the event against Firestore. Owner-only reads;
  the owner may only flip `read` or delete.
- **Devices** (`users/{uid}/devices`): owner-only FCM tokens with a strict
  shape; read by the backend.
- **Profile `notificationPrefs`**: booleans `important`/`expenses`/`plans`.
- **`serverEvents`, `serverMeta`**: no client access.
- **Backend**: every `/v1` call requires a valid Firebase ID token (revoked
  tokens rejected); events are accepted only if Firestore shows the caller
  really performed them; recipients are chosen by the server; place search
  and events are rate-limited per user; the cleanup endpoint needs a secret.

## Threat assumptions

- Clients are untrusted and may send any write the SDK allows.
- Tour members are semi-trusted friends: they can create tour-scoped
  notifications of allowed types to fellow members (possible nuisance, not
  data exposure).
- Join codes may be forwarded; host/admin approval is the gate.

## Known limitations (client-only invariants)

- **Balances are not stored**; they are recomputed from canonical records,
  so there is no aggregate to forge.
- Rules cannot loop, so share sums are validated by padding the share list
  to 30 entries and summing in fixed steps (sum is an int, equals the
  amount, and the sum of absolute values equals the sum ⇒ no negatives).
  This stays under the 1000-expression limit.
- Revision `before`/`after` contents are bounded in size but not
  cross-checked against the parent document.
- `memberCount` caps: rules cap `allMemberUids` at 60; the 30 *active*
  member cap is enforced by the client (rules cannot count documents).
- Feed and inbox writes are best-effort follow-ups, not atomic with the
  action.
- A member can see payment references of other members' settlements in the
  same tour (needed for confirmation and transparency).
