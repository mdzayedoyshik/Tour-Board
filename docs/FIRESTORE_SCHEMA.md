# Firestore schema

Paths are defined once in `lib/data/firebase/firestore_paths.dart`. All
timestamps are UTC (`serverTimestamp()` for audit fields). Money is integer
minor units with an ISO 4217 code; no formatted strings are stored.

```text
users/{uid}                                  private profile
users/{uid}/tourMemberships/{tourId}         Home index (convenience only)
users/{uid}/inbox/{id}                       in-app notifications
invites/{code}                               public preview for a 12-char code
tours/{tourId}
tours/{tourId}/members/{uid}
tours/{tourId}/joinRequests/{uid}            one per requester
tours/{tourId}/expenses/{id}
tours/{tourId}/expenses/{id}/revisions/{n}   n = 1, 2, 3 …
tours/{tourId}/settlements/{operationId}
tours/{tourId}/activities/{id}               itinerary items
tours/{tourId}/notes/{id}
tours/{tourId}/notes/{id}/revisions/{n}
tours/{tourId}/packingItems/{id}
tours/{tourId}/activityFeed/{id}
```

## Deviations from the brief's suggested layout

| Brief | Implemented | Why |
|---|---|---|
| `tours/{t}/inviteTokens/{token}` | `invites/{code}` | Hosts share the code itself (no links); `get` is allowed, `list` is not, so 60-bit codes cannot be enumerated. |
| `tours/{t}/inbox/{id}` | `users/{uid}/inbox/{id}` | Single-collection query per user; no collection-group index; owner-only reads. |
| `tours/{t}/days/{d}/activities/{id}` | `tours/{t}/activities/{id}` + `dayKey` | Avoids empty day documents and per-day queries. |
| join request auto-ID | `joinRequests/{uid}` | Idempotent; attempt limit cannot be reset. |

## Documents

**users/{uid}** — `uid`, `displayName` (≤60), `email` (= auth token email),
`photoUrl?`, `phoneNumber?`, `locale`, `createdAt`, `updatedAt`.

**tourMemberships/{tourId}** — `tourId`, `joinedAt`.

**invites/{code}** — `tourId`, `tourName`, `hostUid`, `hostName`, `startAt`,
`endAt`, `expiresAt` (≤30 days), `revoked`, `createdBy`, `createdAt`.

**tours/{t}** — `name`, `description?`, `hostUid`, `status`
(`upcoming|active|closed|archived`), `startAt`, `endAt` (UTC midnight of the
calendar date), `timeZone` (IANA), `currencyCode`, `budgetMinor?`,
`inviteCode?`, `allMemberUids` (everyone ever approved, append-only, ≤60),
`settings {adminsCanManageTour, membersCanEditPacking,
membersCanRecordForOthers}`, `createdAt`, `updatedAt`, `schemaVersion: 1`.

**members/{uid}** — `uid`, `displayNameSnapshot`, `photoUrlSnapshot?`, `role`
(`host|admin|member`), `status` (`active|removed|left`), `joinedAt`,
`removedAt?`, `updatedAt`. Former members keep their record so historical
names resolve. No emails.

**joinRequests/{uid}** — `uid`, `displayNameSnapshot`, `photoUrlSnapshot?`,
`status` (`pending|approved|rejected|cancelled`), `attemptCount` (≤3),
`inviteCode`, `createdAt`, `updatedAt`, `reviewedBy?`, `reviewedAt?`.

**expenses/{id}** — `title`, `amountMinor`, `currencyCode`, `payerUid`,
`shares {uid: amountMinor}` (1–30 entries, sum = amount), `splitMethod`
(`equal|custom|shares`), `splitWeights? {uid: int}`, `category`, `occurredAt`,
`note?`, `createdBy`, `createdAt`, `updatedAt`, `updatedBy?`,
`revisionCount`, `deletedAt?`, `deletedBy?`, `schemaVersion`. `shares` is the
only authoritative split; weights are kept to reopen the form.

**revisions/{n}** — `editorUid`, `editedAt`, `changedFields`, `before`,
`after` (changed fields only), `reason?`. Max 50 per record. Never contains
coordinates.

**settlements/{operationId}** — `fromUid` (payer), `toUid` (payee),
`amountMinor`, `currencyCode`, `status`
(`pending_confirmation|confirmed|disputed|cancelled`), `paymentMethod?`,
`transactionReference?`, `note?`, `createdBy`, `createdAt`, `updatedAt`,
`confirmedBy?`, `confirmedAt?`, `disputeReason?`. The document ID is the
client-generated operation ID (idempotent submission).

**activities/{id}** — `title`, `dayKey` (`YYYY-MM-DD` in the tour zone),
`startTime?`/`endTime?` (`HH:mm` local), `startAt?` (derived UTC),
`placeName?`, `latitude?`/`longitude?` (both or neither), `note?`,
`estimatedCostMinor?` + `currencyCode`, `sortOrder` (sparse ints, gap 1024),
`status` (`planned|completed|skipped`), `favorite`, `createdBy`, `updatedBy`,
`createdAt`, `updatedAt`.

**notes/{id}** — `title?`, `body` (≤2000), `createdBy`, `updatedBy`,
`createdAt`, `updatedAt`, `revisionCount`.

**packingItems/{id}** — `label`, `checked`, `assigneeUid?`, `checkedBy?`,
`createdBy`, `createdAt`, `updatedAt`.

**activityFeed/{id}** — `type`, `actorUid`, `subjectUid?`, `refId?`,
`label?` (≤80), `createdAt`. Append-only.

**users/{uid}/inbox/{id}** — `type`, `tourId`, `tourName`, `senderUid`,
`senderName`, `refId?`, `createdAt`, `expiresAt` (30 days), `read`.


## Queries and indexes

| Query | Index |
|---|---|
| `tourMemberships` order by `joinedAt` desc, limit 100 | single-field (auto) |
| `members` (all), limit 60; `count()` where `status == active` | auto |
| `joinRequests` where `status == pending` order by `createdAt` | **composite** (in `firestore.indexes.json`) |
| `expenses` order by `occurredAt` desc, limit 1000 | auto |
| `settlements` order by `createdAt` desc, limit 500 | auto |
| `activities` order by `dayKey`, limit 300 (sorted client-side) | auto |
| `notes` order by `updatedAt` desc, pages of 30 | auto |
| `packingItems` order by `createdAt`, limit 200 | auto |
| `activityFeed` order by `createdAt` desc, pages of 30 | auto |
| `inbox` order by `createdAt` desc, limit 30; cleanup where `expiresAt <` now | auto |

## Consistency

- Tour creation: one batch (tour, host member, index, invite) with a
  pre-generated tour ID.
- Approval: a transaction updates the request, creates or re-activates the
  member, appends to `allMemberUids` (first-time members) and writes the
  requester's index. Rules require these to be atomic.
- Expense / note edits: transaction reads the record, rejects if
  `revisionCount` changed (conflict), writes the record with
  `revisionCount + 1` and revision `n` in the same commit.
- Settlement transitions: transaction; `confirmed` is terminal.
- Feed events and inbox items are best-effort follow-ups; they never block
  the action.
