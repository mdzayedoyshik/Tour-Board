# Tour Board — End-to-End Claude Code Development Brief

> **Purpose:** This is the source-of-truth implementation prompt for building Tour Board from an empty or existing repository into a polished, tested Flutter application.
>
> **Product promise:** Plan a trip together, record every shared expense, understand who owes what, and optionally share live locations — with an extremely simple interface.
>
> **Hard constraints:** Flutter app; Firebase-first; no custom backend; stay within Firebase Spark (free) plan; no paid services required for core functionality; premium minimal UI; security and financial correctness over shortcuts.

---

## 0. Instructions to Claude Code

Act as a senior Flutter engineer, Firebase architect, product designer, QA engineer, and security reviewer. Implement the product end to end, not merely a demo or a set of mock screens.

1. First inspect the repository, current Flutter/Firebase setup, package versions, existing conventions, and tests. Do not overwrite working code blindly.
2. If the repository is empty, scaffold a stable Flutter project and establish the architecture described below.
3. Before making large changes, create/update `README.md`, `docs/PRODUCT_SPEC.md`, `docs/ARCHITECTURE.md`, `docs/FIRESTORE_SCHEMA.md`, `docs/SECURITY_RULES.md`, `docs/TEST_PLAN.md`, and `docs/FREE_TIER_LIMITS.md`. This document remains the primary implementation brief.
4. Work in small, verifiable stages. After each stage, run formatting, static analysis, and relevant tests. Fix errors before continuing.
5. Do not leave core flows as TODOs, fake buttons, hardcoded success messages, or mock-only implementations. If an external credential is missing, build the complete integration boundary, document exact setup steps, and provide a clear development fallback.
6. Never put Firebase Admin credentials, service-account JSON, FCM server credentials, private API keys, or other secrets in the Flutter app.
7. Do not enable a paid Firebase plan, create billable cloud resources, or add a service that can incur charges. Ask for explicit approval before any such change. Default to Firebase Spark and services that can be used without a paid backend.
8. Do not claim that every third-party service is free forever. Verify current pricing and plan restrictions from official documentation before adding a dependency or service. Record any uncertainty in `docs/FREE_TIER_LIMITS.md`.
9. Keep code readable, modular, and straightforward. Prefer small functions and clear names over clever abstractions. Add comments where they explain non-obvious decisions, especially security, money arithmetic, offline conflict handling, and location lifecycle.
10. When a feature cannot be implemented securely under the no-backend/free-plan constraint, do not fake it or weaken security. Implement the safe fallback described in this spec and explain the limitation in the UI/docs.
11. Never run destructive commands, delete user files, overwrite existing unrelated files, or change Firebase project settings without inspecting first.
12. At completion, provide: features implemented, architecture summary, exact setup instructions, required Firebase Console steps, tests run and results, known limitations, and a prioritized remaining checklist.

### Mandatory implementation workflow

- Phase A: inspect repository and produce a concise plan.
- Phase B: scaffold architecture, theme, navigation, error handling, and tests.
- Phase C: Firebase Auth and onboarding.
- Phase D: tour creation, invitations, membership and security rules.
- Phase E: expenses, split calculations, balances, settlements, edit history.
- Phase F: itinerary, map integration, notes and packing checklist.
- Phase G: real-time updates, in-app notifications and local notifications.
- Phase H: opt-in location sharing with conservative update rates.
- Phase I: offline support, retention cleanup strategy, internationalization and accessibility.
- Phase J: security review, tests, performance review, documentation and release readiness.

Do not start Phase H before Phases C–G are stable.

---

## 1. Product overview

### Product name

**Tour Board**

### One-sentence description

A lightweight shared workspace for groups to plan trips, track shared spending, calculate balances, coordinate places and activities, and optionally share live locations.

### Target users

- Friends planning a weekend trip, initially such as Cox’s Bazar.
- Families, couples, student groups and small travel groups.
- Future international users with different currencies, languages, dates and time zones.

### Product principles

1. **Simple first:** a first-time user should understand the main screen without a tutorial.
2. **Financially correct:** split arithmetic, refunds, settlements and rounding must be reliable.
3. **Secure by default:** client UI is never the security boundary. Firestore Security Rules are.
4. **Free-first:** do not depend on paid Firebase services or an always-on server.
5. **Privacy-respecting:** location sharing is off until explicitly enabled, has a visible status, and can be stopped immediately.
6. **Real-time where useful:** update the active tour as changes arrive, but avoid wasteful listeners and reads.
7. **Graceful offline behavior:** show cached data and permit safe drafts; never pretend an unsynced write succeeded remotely.
8. **Minimal and premium:** mostly black, white and neutral grays with one restrained accent color.
9. **International-ready:** no hardcoded currency symbols, date formats, or user-facing strings.
10. **Honest limitations:** do not promise background location or push delivery that the platform and free-only architecture cannot guarantee.

### Explicit non-goals for the first release

- Payments or money transfers inside the app.
- Banking integrations or financial-account connections.
- Public social feed or public trip discovery.
- Chat/messaging system.
- AI-generated itineraries.
- Receipt OCR.
- File uploads or cloud receipt storage in MVP.
- Route navigation or turn-by-turn navigation.
- Continuous location history or location playback.
- Complex business/team subscriptions.
- Web admin dashboard.
- Guaranteed push notifications while the app is terminated without a trusted server-side sender.
- Guaranteed background tracking on every Android/iOS device.

---

## 2. Hard free-tier and no-backend policy

This is a core product constraint. Design around it, and do not quietly introduce paid dependencies.

### 2.1 Firebase services

Use only what is available on the Firebase Spark plan without creating billable dependencies:

- Firebase Authentication with Google provider, subject to current product/plan requirements.
- Cloud Firestore within its Spark quotas.
- Firebase Cloud Messaging as a delivery transport where supported, but **do not assume a secure client-only way to trigger arbitrary push messages to other users**.
- Firebase App Check only if it can be configured without adding paid dependencies; document its limitations.
- Firebase Storage is not required in MVP. Do not upload avatars, receipts or attachments to Storage. Use the Google profile photo URL where available.
- Do not use Cloud Functions, Cloud Run, App Engine, a custom server, scheduled functions, paid extensions, or a third-party paid backend.
- Do not enable Firebase Blaze or create a billing account as part of implementation.
- Do not use Firebase Dynamic Links; that product has been discontinued. Implement normal HTTPS invite links using Android App Links and iOS Universal Links, with a documented fallback.

**Important architectural consequence:** Cloud Firestore has no general-purpose trusted server logic on the Spark plan. Client-side Firestore writes must be constrained by Security Rules. Do not put secrets in the app. Do not allow a client to send FCM messages directly using a server key.

### 2.2 Notifications under this constraint

Implement these layers:

1. **Real-time in-app updates:** Firestore listeners for only the currently visible tour screens and small notification/inbox records. This is the primary collaboration mechanism.
2. **In-app notification center:** store compact notification documents in Firestore when an authorized client action creates an event, where rules can validate the event and recipients.
3. **Local notifications:** the device may schedule reminders for itinerary events or local deadlines the current user opted into. Local notifications are not remote push.
4. **FCM readiness, not an insecure sender:** it is acceptable to configure Firebase Messaging token handling and foreground message display if a trusted sender is later introduced, but do not claim that client-only code can securely trigger cross-user FCM pushes.
5. If cross-user push notifications cannot be delivered without trusted server logic, label them as **not available in strict free/no-backend mode** in the documentation. Keep the app useful with in-app updates and optional local reminders. Do not silently use a third-party relay or leaked server key.

Never make notifications the main UI. Use restrained badges, a small inbox, and user-controlled preferences. Avoid sending one notification per tiny edit or location update.

### 2.3 Google Maps and “everything free”

Google Maps SDKs and Google Places/geocoding services can have billing requirements and usage-based charges. A usage allowance is not a guarantee that every configuration remains free.

To preserve a strict no-cost default:

- Implement a `MapProvider` abstraction.
- Default implementation: `flutter_map` with OpenStreetMap-compatible tiles and attribution, subject to the selected tile provider’s usage policy. Do not scrape tiles or violate provider terms.
- Provide a clean map view with markers, saved places, member avatars, distance calculations and itinerary pins.
- For place search, use a provider abstraction. The free MVP can let users search using an explicitly documented no-cost provider with its rate limits, or manually add a place name and coordinates. Respect the provider’s usage policy and avoid high-volume geocoding.
- Do not make Google Places API a required dependency.
- If the owner later chooses Google Maps SDK, it must be an explicit configuration choice with official pricing verification, API-key restrictions, budget monitoring and a clear warning that hard zero-cost cannot be guaranteed. Do not configure it automatically.
- The map must work in a limited/manual mode if place-search service is unavailable.

Do not assert that OpenStreetMap tile hosting is unlimited or universally free. Keep the tile URL/provider configurable and document attribution and usage limits.

### 2.4 Quota-aware Firestore usage

Use small, scoped queries and listeners. Never subscribe to an entire tour’s complete history when only recent items are needed.

- Keep only one active listener per visible data stream; cancel it when the screen is disposed or the user changes tours.
- Use `limit()` and pagination for expense, activity and edit history.
- Do not poll Firestore.
- Do not write location coordinates more often than necessary.
- Do not write presence heartbeats every few seconds.
- Do not write a document on every map camera movement.
- Avoid storing denormalized copies of large data. Duplicate only tiny summaries when it demonstrably saves reads.
- Do not maintain a globally updated tour document counter for every expense.
- Avoid a listener that re-reads all members whenever a single expense changes.
- Cache small documents and paginate old records.
- Avoid unnecessary read-after-write calls; use the result of the write or local state where safe.
- Add loading, empty, error, stale-data and offline states.
- Include a developer-only diagnostics page that shows approximate listener count, pending local writes, and whether data is cached, without exposing private data.

Firestore free quotas and policies may change. Before implementation, check current official Firebase pricing and Spark plan limitations and record the verified date and sources in `docs/FREE_TIER_LIMITS.md`. Do not assume quotas can be increased while staying on Spark.

### 2.5 Data retention without paid scheduled jobs

Do not rely on Firestore TTL or Cloud Functions for automated cleanup on the free plan.

- Do not automatically delete a closed tour after one month.
- Retain essential expense and settlement history so members can refer to past contributions.
- Use a `retentionPolicy` field and expiry timestamps for disposable records.
- Old join requests and expired invite tokens may be lazily cleaned when an authorized user opens the relevant screen, provided rules permit the deletion and it is safe.
- Expired location records should be treated as invisible immediately based on timestamps, even if the physical document remains until a client cleanup pass.
- On opening a tour, an authorized client can delete expired temporary location documents and old ephemeral inbox records in a bounded batch. Do not attempt unlimited collection scans.
- Clean up only documents the signed-in user is allowed to delete. Never weaken Security Rules to make cleanup convenient.
- Explain that lazy cleanup is not guaranteed to run if nobody opens the app. The UI must ignore expired data regardless.
- If the user explicitly deletes a tour, use a safe, bounded deletion workflow and explain that large recursive deletes may be impractical without a trusted backend. For MVP, support archive/close first; implement deletion carefully and test it.

---

## 3. Technology stack

Use stable, mutually compatible package versions available at implementation time. Do not blindly pin old versions. Record selected versions in `pubspec.yaml` and document any compatibility decisions.

### App

- Flutter stable and Dart stable compatible with it.
- Feature-first architecture with clear domain/data/presentation separation.
- State management: **Riverpod** (use `flutter_riverpod`) unless the repository already has a coherent BLoC implementation. Do not mix state-management frameworks.
- Navigation: `go_router`.
- Models: immutable typed models; use a code generator only if it materially improves maintainability. Keep generated files checked in when standard for the selected package.
- Forms and validation: reusable components and centralized validators.
- Local preferences: `shared_preferences` for small settings only.
- Offline/local drafts: use Firestore’s supported offline persistence plus a small local database if necessary. Prefer Drift/SQLite for structured draft queue only if required; do not add a local database just for fashion.
- Map: `flutter_map` with a provider abstraction for a strict free-first default.
- Location: `geolocator` or another maintained plugin after verifying current Android/iOS permissions and behavior.
- Local notifications: a maintained local-notification plugin only for user-opted-in reminders.
- Connectivity: use connectivity information as a hint, never as proof that the internet or Firestore is reachable.
- Localization: Flutter `gen_l10n` / ARB files.
- Testing: `flutter_test`, unit tests, widget tests, integration tests, Firebase Emulator Suite where possible.
- Linting: Flutter lints plus a consistent project lint policy.

### Firebase

- Firebase Authentication.
- Cloud Firestore.
- Firebase Messaging only within the safe constraints in this brief.
- Firebase App Check only if feasible under the no-cost constraint and documented.
- Firebase Emulator Suite for local development and rules tests.
- No custom backend.
- No Cloud Functions.
- No Firebase Storage in MVP.
- No external analytics service in MVP. Crash reporting/analytics must not introduce a paid-plan requirement or privacy burden; document options instead of enabling them automatically.

### FlutterFire setup

Use official FlutterFire CLI workflow when available:

1. Create a Firebase project manually in the Firebase Console.
2. Keep the project on Spark.
3. Register Android and iOS apps.
4. Enable Google sign-in in Firebase Authentication.
5. Configure platform files with FlutterFire CLI.
6. Generate `firebase_options.dart`.
7. Never commit service-account credentials.
8. Add a clear `.gitignore` and `.env.example` only for non-secret configurable values.
9. Provide a setup guide for SHA-1/SHA-256 fingerprints, Android package name, iOS bundle ID, OAuth consent configuration, and redirect configuration as needed.
10. App must show a helpful configuration error if Firebase is not configured; it must not crash on startup.

---

## 4. User journey and onboarding

### 4.1 Welcome screen

Create a single, polished onboarding screen:

- Tour Board wordmark/text logo; do not require an external logo asset.
- Short line: “Plan together. Spend clearly. Travel better.”
- One primary button: “Continue with Google”.
- Small privacy note: “Your tours are shared only with people who are members.”
- Minimal light/dark styling; no long carousel or forced tutorial.
- Show progress while signing in and a clear recoverable error on failure.
- Prevent duplicate sign-in attempts while one is in progress.

### 4.2 Google sign-in

- Google Sign-In is required to create or join a tour.
- Use Firebase Authentication’s Google provider.
- Do not collect passwords.
- On first sign-in, create a minimal user profile document if it does not exist.
- Use provider-returned display name, email and photo URL when available.
- A Google account does not reliably provide a phone number. Do not invent or scrape a phone number. Phone number is optional and can be added later if there is a clear product need; do not require phone auth in MVP.
- Do not copy more Google account data than needed.
- Handle user cancellation, offline errors, account selection, expired sessions, deleted accounts and missing profile fields.
- On subsequent launches, route authenticated users directly to Home.
- Add a clear sign-out action under settings.
- Provide a documented account/data deletion process that does not leave private tour data accessible to a deleted account. Because no backend is available, clearly handle ownership transfer and user-owned data deletion within the limits of client rules.

### 4.3 Profile

Fields:
- `uid` (Firebase Auth UID; canonical identity)
- `displayName`
- `email`
- `photoUrl` (provider URL; optional)
- `phoneNumber` (optional; normally null)
- `locale`
- `createdAt`
- `updatedAt`
- `lastSeenAt` only if useful; do not heartbeat frequently

Allow editing display name and locale. Do not allow changing `uid` or writing a different user’s profile. Email should come from authenticated provider data and not be user-editable in Firestore.

---

## 5. Main app information architecture

Use a small, predictable navigation structure.

### Home

- “Your tours” list sorted by active/upcoming first.
- Compact tour cards with name, date range, member count and current status.
- Primary actions: “Create tour” and “Join with link/code”.
- Empty state: concise explanation and two actions.
- Recently closed tours are available in a separate section.
- Avoid expensive queries across all tours. Store the current user’s membership index under `users/{uid}/tourMemberships/{tourId}` to fetch their tours efficiently, but ensure writes to that index cannot grant membership or bypass the canonical membership record.
- The index is a convenience, not an authorization source. Validate actual membership in `tours/{tourId}/members/{uid}`.

### Tour workspace

Four main destinations, with a compact top bar showing tour name and member avatars:

1. **Expenses**
2. **Plan**
3. **Map**
4. **More**

“More” contains members, notes, packing checklist, activity/inbox, tour settings, permissions and close-tour action.

On small screens, use a bottom navigation bar with labels and clear selected states. On larger screens, adapt gracefully without making a different app.

### Tour overview

At the top of Expenses or the tour workspace, show:
- Total recorded spending.
- Current user’s net balance.
- Number of members.
- Trip dates/status.
- A clear “Add expense” action.
- Do not show a confusing accounting dashboard with too many charts.

### Visual design system

Default direction:
- Light background: `#FFFFFF` / very light neutral.
- Dark background: approximately `#111214`.
- Surface gray: restrained neutral tones.
- Accent: `#5685F7` or a similarly accessible blue, used sparingly.
- Text: high contrast; secondary text still readable.
- Semantic colors only for clear status (success, warning, error), not decorative cards.
- Rounded corners approximately 12–16 px; consistent spacing scale.
- Typography: native platform-friendly sans-serif; use clear weight/size hierarchy.
- Use subtle transitions, skeletons, and restrained haptics where useful.
- No excessive gradients, glassmorphism, rainbow colors, giant hero graphics, or dense cards.
- Respect system light/dark preference and provide explicit Light/Dark/System settings.
- Maintain accessible contrast, dynamic text sizes, screen-reader labels, tap targets and focus order.
- Avoid emoji as the only icon or status indicator.

Build a reusable design system:
- `AppColors`, `AppTheme`, `AppTypography`, spacing constants, radii, elevation, icon sizes.
- Buttons: primary, secondary, text, destructive.
- Reusable form fields, amount input, avatar, member chip, status pill, empty state, error state, loading skeleton, confirmation sheet, snackbar.
- Consistent confirmation for destructive or financially meaningful actions.

---

## 6. Tour creation and lifecycle

### Create tour form

Required:
- Tour name.
- Start date and end date.
- Home/display currency (ISO 4217 code).
Optional:
- Description.
- Cover image is out of scope for MVP.
- Approximate budget.
- Default timezone (derive sensibly from device, allow correction).

Validate:
- End date cannot be before start date.
- Tour name must be non-empty and bounded in length.
- Currency must be a valid supported code.
- Amounts must be positive and within safe integer bounds.
- Store timestamps consistently in UTC and preserve the tour’s intended IANA timezone where scheduling needs local time.

When creating a tour:
- The creator becomes host/admin.
- Create canonical tour document, member document and user membership index.
- Avoid partially created tours. Since Firestore client batches/transactions have limits and no server-side rollback, use a transaction/batch where possible, and make creation idempotent with a stable generated tour ID.
- Handle failure with a retry-safe UI and do not show success until the required writes have been acknowledged.
- Generate a high-entropy invite token or code, never a sequential predictable ID. Store only what is needed, and do not treat knowledge of a tour ID as authorization.

### Tour lifecycle

Statuses:
- `upcoming`
- `active`
- `closed`
- `archived`

Rules:
- Tour status is controlled by host/admin.
- Closing a tour prevents new ordinary expenses/plans/notes and makes the historical record read-only, while allowing the designated settlement workflow.
- Archiving hides it from the main upcoming list but keeps it accessible.
- Reopening a closed tour should require an explicit confirmation and be recorded in the tour’s edit history.
- Do not delete a tour automatically after one month.
- Display the current status clearly.

---

## 7. Invite links, join requests and membership

### Join flow

1. Host shares a link through Android/iOS share sheet, messaging apps, email, etc.
2. Link opens the installed app where possible; otherwise it opens a simple HTTPS landing/fallback page if configured, or displays instructions to install/open the app and paste the code.
3. User signs in with Google.
4. App shows tour name, dates, host display name and a clear “Request to join” action. Do not expose member email addresses or private data before approval.
5. Create a join request with `pending` status.
6. Host sees a small pending-request badge and can approve or reject.
7. On approval, create the canonical membership record and membership index atomically where possible.
8. Notify the requester via in-app status and show the tour on their Home.
9. Rejected users cannot read tour details or submit repeated requests indefinitely; allow a reasonable retry policy.
10. Invite links can be revoked/rotated by host.

### Membership policy

Keep it easy for ordinary groups:

- **Host:** creator; can manage members, roles, permissions, invite links, tour settings, and close/reopen the tour.
- **Admin:** optional trusted co-host; can manage content and members except actions reserved to host, such as transfer ownership or delete/close if configured.
- **Member:** can view tour data and perform actions allowed by permissions.
- The host can appoint an admin and can remove a member.
- Do not let the last host disappear without transferring ownership.
- The host can transfer hosting to an existing member with explicit confirmation.
- A removed member loses future access immediately according to rules. Keep their historical name/UID references in expense records for accounting, but do not expose data to the removed account.
- Never erase a member’s past expense contribution just because they left.
- If a member leaves, preserve their balance and allow the host to settle it.
- A user can cancel their own pending join request.
- Do not allow arbitrary self-approval or client-side role escalation.

### Permissions

Keep a simple default permission matrix, configurable by host/admin:

| Capability | Host/Admin | Member default |
|---|---:|---:|
| View tour while a member | Yes | Yes |
| Add own expense | Yes | Yes |
| Edit/delete own expense | Yes | Yes, with restrictions after closure |
| Edit/delete another member’s expense | Yes | No |
| Add/edit own itinerary item | Yes | Yes |
| Edit/delete another member’s itinerary item | Yes | No |
| Add/edit own note | Yes | Yes |
| Edit/delete another member’s note | Yes | No |
| Manage packing checklist | Yes | Yes by default |
| Approve/reject join requests | Yes | No |
| Remove/role-change members | Yes | No |
| Change tour settings / close tour | Host; Admin only if granted | No |
| View live location of opted-in members | Tour members only | Tour members only |
| Start/stop own location sharing | Own device only | Own device only |
| Confirm a settlement | Eligible payer/payee; admin fallback | Eligible payer/payee |

Implement the permission matrix consistently in UI and Firestore Security Rules. UI hiding is not authorization.

---

## 8. Expense tracking and split engine

This is the most important feature. Implement it with thorough unit tests before styling every edge case.

### 8.1 Add expense

Fields:
- Description/title (required, length-limited).
- Amount (required, positive).
- Currency (default tour currency; allow another currency only if conversion behavior is clearly implemented).
- Payer (default current user; only choose another payer if authorized and the payer is a member).
- Date/time (default now).
- Category (Food, Transport, Stay, Tickets/Activities, Shopping, Other; extensible).
- Split method.
- Included members.
- Optional note.
- Receipt/photo uploads are out of scope in MVP to avoid Storage dependency.
- Created/updated metadata.

Use a custom numeric keypad/amount field that handles decimal separators and currency formatting safely. Parse into integer minor units. Never use `double` for financial arithmetic.

### 8.2 Split methods

Support:
1. **Equal split:** split between selected members.
2. **Custom amount:** each member’s share is entered explicitly and the sum must equal the expense total.
3. **Shares/weights:** split by units, e.g. 2 shares versus 1 share.
4. **Selected members:** any subset can participate.
5. Optional future feature: percentage split, only after the above are reliable.

A payer may or may not be included as a participant; make this explicit. If the payer is not a participant, they paid on behalf of participants and should be credited accordingly.

### 8.3 Correct balance model

Represent every expense as:
- One payment made by a payer.
- A list of member shares that sum exactly to the expense amount.
- A currency code.
- An immutable record of the original creation data plus current editable fields and revision history.

For each currency, a member’s net position is:

`net = amount_paid_by_member - member_share_of_expenses - confirmed_outgoing_settlements + confirmed_incoming_settlements`

Be careful with sign conventions and document them. A positive net means the group owes the member; a negative net means the member owes the group/others. In the UI, prefer plain language: “You should receive” or “You owe”.

Do not merge different currencies into a single balance unless the app stores an explicit exchange rate, conversion date and source/entered-by metadata. For MVP, display separate balances per currency when multiple currencies exist.

### 8.4 Rounding

- Store money in integer minor units (e.g. BDT uses poisha; currencies vary in exponent).
- Use currency metadata for decimal digits where available.
- For equal splits with a remainder, distribute the remaining minor units deterministically across participants in a stable order so the sum exactly matches the total.
- For custom splits, reject unless all shares add up exactly to the total.
- For shares/weights, use deterministic largest-remainder allocation.
- Add property-based or table-driven tests for random amounts, participant counts, zero/negative inputs, very small values, and large valid amounts.
- Do not use `toStringAsFixed` as a financial calculation.

### 8.5 Editing and deletion

- Users can edit/delete only their own expense by default; admin can edit/delete any expense.
- Every edit creates a compact revision entry on the expense itself or in a tightly scoped subcollection, not a separate audit-trail screen.
- In the expense details screen, show a subtle **“View edits”** text action only when revisions exist.
- Revision data: editor UID, timestamp, changed field names, previous/new values for relevant non-sensitive fields, and optional reason. Never store authentication secrets or location coordinates in edit history.
- Do not allow ordinary users to edit a closed tour’s expense. Admin can reopen the tour or use the explicitly allowed correction process.
- Deletion should be a soft delete/tombstone so historical balances and audit records remain explainable. Recalculate balances excluding the deleted expense, but retain its tombstone and revision history for authorized members.
- Avoid storing an unbounded duplicate copy of the entire expense for each revision. Store only changed fields and compact before/after values.
- Make edits transactional when updating an expense and its revision entry. If this cannot be guaranteed with the chosen Firestore transaction pattern, design a safe write order and idempotent revision IDs.

### 8.6 Balance calculation and settlements

- Compute balances from paginated expense/settlement records or from carefully maintained summaries.
- Do not make a single giant Firestore read on every screen opening.
- For MVP-sized tours, load current expenses with pagination and compute client-side; maintain a compact per-member/currency summary only if it can be updated safely without server logic.
- Never let a member write another user’s balance summary.
- Since there is no trusted backend, do not treat client-written aggregate summaries as authoritative unless the Security Rules and transaction model can validate them. Prefer recomputation from canonical records when needed.
- Settlement optimization may suggest a minimal set of transfers between debtors and creditors. Show it as a suggestion, not as a payment instruction.
- The group pays offline. The app never moves money.

### 8.7 Expense UI

Main screen:
- Total expenses in tour currency.
- “Your balance” card in plain language.
- Optional compact budget progress if a budget exists.
- Expense list with category icon, title, payer, date, amount, and subtle edited marker.
- Filter by date/category/member.
- Search by title.
- Floating or prominent “Add expense” action.
- Empty state with one clear CTA.

Add/edit screen:
- Amount first, then description, payer, split method and participants.
- Show a live split preview: total, participants, and each share.
- Disable Save until valid.
- Clearly show the effect on shares before confirmation.
- Avoid a long multi-page wizard for a simple expense.
- Confirmation sheet only when editing changes other members’ balances materially.

Expense detail:
- Full split breakdown and payer.
- “View edits” when revisions exist.
- Edit/delete controls according to permissions.
- Accessible, non-color-only indication for deleted/corrected records.

---

## 9. Settlements and post-trip accounting

Settlements represent offline payments; Tour Board does not transfer money.

### Settlement workflow

1. Balance screen shows who owes whom.
2. A debtor chooses a suggested creditor and taps “Mark as paid”.
3. Enter amount (full or partial), payment method optional, transaction/reference ID optional, and note optional.
4. Create a settlement record with `pending_confirmation` status.
5. The payee can confirm or dispute it. An admin can confirm as a fallback only under documented rules.
6. Only confirmed settlements affect final net balances.
7. Both parties can see settlement status and metadata.
8. If disputed, record a reason and keep the record visible; do not silently delete it.
9. A payment can be split into multiple partial settlements.
10. The admin can owe a member just like any other member. Never special-case the host as financially exempt.
11. Admin should not approve their own settlement as the only approver when the other party can confirm. If the admin is the payer/payee, require the counterparty to confirm whenever possible.
12. Closed tours preserve balances and allow settlement confirmation/correction. Ordinary expenses and itinerary edits are frozen unless the tour is explicitly reopened.
13. Keep payment references private to the tour members who need them; do not expose them publicly.

Settlement fields:
- `id`
- `tourId`
- `fromUid`
- `toUid`
- `amountMinor`
- `currencyCode`
- `status`: `pending_confirmation`, `confirmed`, `disputed`, `cancelled`
- `paymentMethod` optional
- `transactionReference` optional
- `note` optional
- `createdBy`
- `createdAt`
- `updatedAt`
- `confirmedBy` optional
- `confirmedAt` optional
- revision metadata if edited

Validate that both parties are tour members (including retained historical members only through a specific settlement exception), amount is positive, and currency is consistent with the selected balance. Prevent the same settlement from being confirmed twice or being applied more than once.

---

## 10. Tour planning, places and map

### Itinerary model

Support day-wise plans:
- Day/date.
- Activity/place title.
- Start time and optional end time.
- Place name.
- Latitude/longitude if known.
- Short note/description.
- Estimated cost and currency (optional).
- Created by, updated by, created/updated timestamps.
- Status: planned, completed, skipped/cancelled.
- Sort order.

Features:
- Add, edit, delete own items; admins can manage all.
- Reorder activities within a day.
- Show day timeline and map pins.
- Tap a place to see its details and open external map/navigation apps using a normal URL scheme when available.
- Add a place manually when search is unavailable.
- Add “free-form plan” items that do not need coordinates.
- Avoid requiring location permission to browse or create itinerary items.
- Show time zone/local time clearly for tours crossing time zones.
- Allow a place to be marked as a favorite/pinned stop.
- Support a simple shared packing checklist under More.

### Map screen

- Use the `MapProvider` abstraction and default free-first map described above.
- Show saved itinerary locations and opted-in live member locations with visually distinct marker styles.
- Tapping a place marker opens a compact bottom sheet with name, time, notes and estimated cost.
- Tapping a member marker opens a compact sheet with avatar, name, “Last updated …”, approximate distance from the current user, and a sharing status.
- Do not show the user’s location to others unless they explicitly enabled sharing.
- Do not show exact location to non-members.
- Do not display a stale marker as live; use a clear stale/last-seen state.
- Cluster markers if necessary; do not redraw the whole map on every unrelated Firestore update.
- Do not store map camera movements in Firestore.
- Handle map permission denial gracefully; saved places still work.
- Add attribution required by the selected tile provider.

### Place search

- Use a provider interface so the app can change search/geocoding provider later.
- The strict free MVP must not depend on a billing-required Google Places API.
- Use a policy-compliant provider with request throttling/caching or manual place entry.
- Cache recent search results locally only when allowed by the provider’s terms.
- Debounce typing, enforce a minimum query length, and do not make a request per keystroke.
- Handle zero results, provider outage, rate limiting and invalid coordinates.
- If a user specifically wants Google Maps later, document the separate API-key and billing setup; do not claim the Google Maps/Places combination is guaranteed free.

---

## 11. Optional live location sharing

This feature must be opt-in and must never be represented as guaranteed background tracking.

### User experience

- Location sharing is **off by default**.
- The user starts sharing from the Map screen with a clear explanation of who can see it.
- Show a persistent “Sharing location” indicator while active and an immediate Stop button.
- Offer a duration: 30 minutes, 2 hours, until trip ends, or stop manually. Choose a conservative default such as 2 hours.
- Show each member’s last update timestamp and status: Live/recent, Stale, Sharing paused, or Not sharing.
- Members who do not share remain visible in the member list but have no location marker.
- Do not nag users to enable sharing.
- End sharing when the selected duration expires, the tour closes, or the user stops it.
- Because client-only expiry cannot be trusted to delete data automatically while a device is offline, the UI must immediately hide expired coordinates by timestamp; the next authorized client cleanup may remove the record.

### Location updates and battery

- Request foreground permission only when the user enables sharing.
- Request background permission only if a supported implementation actually needs it and the user has explicitly chosen that mode. Do not request “always” permission during onboarding.
- Start with foreground-only sharing in MVP. Background sharing is a later opt-in enhancement requiring physical-device testing and platform policy review.
- Use distance and time thresholds; do not continuously write GPS updates.
- Initial tuning target while the map is actively being used: update after meaningful movement (for example, around 50–100 m) or a conservative minimum interval (for example, 30–60 seconds). These are starting values, not guarantees; profile battery and Firestore write usage and tune.
- When stationary, reduce updates substantially.
- Never write a location for every GPS callback.
- Write only the latest location document per user per tour. Do not persist a location-history collection in MVP.
- Include `updatedAt`, `sharingUntil`, and coarse status fields.
- Use device-side distance calculation for member-to-viewer distance.
- Respect OS location settings and permission revocation immediately.
- Stop streams and timers when sharing stops, the tour ends, the user signs out, or the screen/lifecycle policy requires it.
- Avoid continuous background service unless explicitly designed, documented and tested. Do not promise that Android/iOS will keep the app alive.
- Use a low-accuracy/balanced setting by default, not navigation-grade high accuracy.

### Location privacy and access

Although the app is intended for friends, privacy controls are not optional engineering overhead:
- Only current approved members can read a tour’s location documents.
- A user can write only their own location document.
- Users can stop sharing and clear their own location document.
- Rules must prevent writes for non-members and prevent reading after membership removal.
- Expired location records must not be displayed, even if physically present.
- Do not include coordinates in notification text or edit history.
- Do not expose precise coordinates before the user opts in.
- Document that live location can consume battery and may stop when the OS suspends the app.

### Free-tier location cost protection

- Latest-location document is overwritten rather than appending a new document each time.
- Keep update rates conservative.
- Only members currently viewing the map should listen to the locations collection; cancel listeners when leaving the map.
- Avoid a separate presence heartbeat system.
- Cap tour membership or document a practical group-size limit for the MVP (e.g. 20–30 members) and test it.
- Do not use location as a security or emergency guarantee.

---

## 12. Notes, packing list and activity feed

### Shared notes

- Create short text notes, title optional, creator and timestamps.
- Members can edit/delete their own notes; admin can manage all.
- Show an edited indicator and “View edits” in note details when revisions exist.
- Paginate if notes grow.
- Do not implement rich text or file attachments in MVP.

### Packing checklist

- Shared checklist items with label, checked state, optional assigned member, creator and timestamps.
- Members can add/check items by default; admin can remove any item.
- Use a compact list and quick add.
- Avoid a write for every animation; persist only actual state changes.

### Activity feed

Show only useful events:
- Member requested to join / approved / rejected.
- Expense added/edited/deleted.
- Plan item added/edited.
- Settlement submitted/confirmed/disputed.
- Tour closed/reopened.
- Role/permission changes.

Do not generate activity records for every location update, map movement, typing event or checkbox animation. Activity records should be compact and paginated.

---

## 13. Firestore schema

Use a consistent, documented naming convention. IDs should be stable, non-sensitive and generated safely.

Suggested structure:

```text
users/{uid}
users/{uid}/tourMemberships/{tourId}

tours/{tourId}
tours/{tourId}/members/{uid}
tours/{tourId}/joinRequests/{requestId}
tours/{tourId}/inviteTokens/{tokenId}
tours/{tourId}/expenses/{expenseId}
tours/{tourId}/expenses/{expenseId}/revisions/{revisionId}
tours/{tourId}/settlements/{settlementId}
tours/{tourId}/days/{dayId}/activities/{activityId}
tours/{tourId}/notes/{noteId}
tours/{tourId}/notes/{noteId}/revisions/{revisionId}
tours/{tourId}/packingItems/{itemId}
tours/{tourId}/activityFeed/{activityId}
tours/{tourId}/inbox/{notificationId}
tours/{tourId}/locations/{uid}
```

Do not create all optional collections until needed. Avoid empty documents.

### Key model guidance

**User**
- `uid`, `displayName`, `email`, `photoUrl`, `phoneNumber?`, `locale`, `createdAt`, `updatedAt`.

**Tour**
- `name`, `description?`, `hostUid`, `status`, `startAt`, `endAt`, `timeZone`, `currencyCode`, `budgetMinor?`, `createdAt`, `updatedAt`, `schemaVersion`.

**Member**
- `uid`, `displayNameSnapshot`, `photoUrlSnapshot?`, `role`, `status`, `permissions`, `joinedAt`, `removedAt?`.
- Do not store email in every member document unless the product proves it is necessary. Avoid exposing member emails unnecessarily.

**Join request**
- `uid`, `displayNameSnapshot`, `photoUrlSnapshot?`, `status`, `createdAt`, `updatedAt`, `reviewedBy?`, `reviewedAt?`.
- Only the requester and authorized admins can access the request details.

**Expense**
- `title`, `amountMinor`, `currencyCode`, `payerUid`, `participantShares` or a subcollection only if size requires it, `category`, `occurredAt`, `note?`, `createdBy`, `createdAt`, `updatedAt`, `revisionCount`, `deletedAt?`, `deletedBy?`, `schemaVersion`.
- For small tours, keep a bounded array of participant shares in the expense document. Validate its size. If the chosen rules cannot validate the array adequately, redesign before shipping rather than assuming it is safe.
- A share includes `uid` and `amountMinor`. Its sum must equal the expense total.
- Do not store balances as the sole source of truth.

**Settlement**
- Fields listed in Section 9.
- Include an idempotency identifier or deterministic operation ID to avoid duplicate application.

**Activity**
- `title`, `placeName?`, `latitude?`, `longitude?`, `startAt?`, `endAt?`, `estimatedCostMinor?`, `currencyCode?`, `note?`, `sortOrder`, `status`, `createdBy`, `createdAt`, `updatedAt`, `revisionCount`, `deletedAt?`.

**Revision**
- `editorUid`, `editedAt`, `changedFields`, compact `before`, compact `after`, `reason?`.
- Bound the number and size of revisions or implement safe archival/deletion policy. Do not copy large documents repeatedly.

**Location**
- `uid`, `latitude`, `longitude`, `accuracyMeters?`, `updatedAt`, `sharingUntil`, `sourceStatus`.
- No history collection in MVP. No coordinates in activity feed.
- Validate latitude/longitude bounds and timestamp fields in rules as far as practical.

### Query and index plan

Create composite indexes only for actual query patterns. Document each index in `docs/FIRESTORE_SCHEMA.md`. Typical patterns:
- Current user’s membership index ordered by `lastOpenedAt` or `joinedAt`.
- Join requests by `status` and `createdAt`.
- Expenses ordered by `occurredAt` descending.
- Expenses filtered by category/member only if needed and supported.
- Activities by day and `sortOrder`.
- Activity feed by `createdAt` descending.
- Settlements by status and created date.
- Do not create indexes for speculative filters.

### Consistency and transactions

- Use Firestore transactions or batched writes where appropriate.
- Transactions can retry; keep callbacks free of side effects.
- Generate IDs outside transaction callbacks when deterministic retry behavior matters.
- Do not send notifications or show success from inside a transaction callback.
- Use idempotent operations for membership approval, settlement confirmation and tour creation.
- Remember Security Rules have limits on document access calls in multi-document operations. Test batch/transaction rules in the Emulator Suite.
- The client is untrusted. Validate allowed fields, types, value ranges, immutable fields, membership and ownership in rules.

---

## 14. Firestore Security Rules

Security Rules are a release blocker. Never deploy permissive rules such as `allow read, write: if request.auth != null`.

Implement and test rules for:
- User can read/update only their own profile; immutable UID and email-provider consistency.
- Only approved members can read tour content.
- Only host/admin can approve join requests, change roles, manage invites, and close/reopen a tour.
- A user can create only their own join request.
- Membership status and role cannot be self-assigned or escalated by an ordinary member.
- A user can create/edit/delete their own expense; admin can manage all; payer and participant UIDs must be valid tour members or valid historical references under a defined exception.
- Expense amount must be a positive integer in a safe range.
- Currency code must be a bounded string and preferably from a supported list.
- Split shares must have valid UIDs and non-negative/positive integer amounts, with sum equal to total where rules can safely validate it. If rule limitations prevent robust validation, constrain supported split behavior or design a safer schema.
- Members cannot edit another person’s content by changing `createdBy`.
- Revision records can be created only by the same authorized editor in the same operation context; they are not client-editable after creation.
- Soft-deleted documents cannot be silently resurrected by unauthorized clients.
- Settlement can be created only by a relevant party and confirmed by the counterparty or permitted admin; a party cannot forge the other party’s confirmation.
- User can write only their own location document; only current members can read it.
- Expired invite tokens cannot be used to bypass approval.
- All fields are validated and unexpected fields are rejected where practical.
- Closed tour rules block ordinary changes but allow the explicit settlement workflow.
- No user can read a removed member’s private account profile through tour membership.
- Notification inbox documents are readable only by their intended recipient and cannot be forged to notify arbitrary users without authorization.

**Critical limitation:** without a trusted backend, some cross-document financial invariants and aggregate updates may be difficult to enforce perfectly in Firestore Security Rules. Do not pretend otherwise. Use a schema/rule design that keeps canonical writes small and independently verifiable. If a required invariant cannot be securely enforced client-side, simplify the feature rather than ship an exploitable implementation.

Deliver:
- `firestore.rules`
- `firestore.indexes.json`
- `firebase.json` for Emulator Suite/rules testing as appropriate
- Rules tests covering unauthorized reads, privilege escalation, cross-user edits, closed tours, settlements and location privacy.
- A documented deployment command, but do not deploy without explicit user permission.

---

## 15. Offline mode and conflict handling

### Expected behavior

- Firestore persistence should provide cached reads and queued writes where supported.
- Clearly indicate when the screen is showing cached data or pending writes.
- Draft expense/plan/note forms can be saved locally and retried.
- Do not claim a join request or membership approval succeeded until the relevant remote write is acknowledged.
- A pending expense must not be counted as a confirmed shared expense until synchronized. It may be shown as “Pending sync” to the author.
- Handle duplicate submission by disabling the submit action while in progress and using a stable client operation ID where appropriate.
- Do not assume connectivity status means Firestore is reachable.
- Provide retry controls and a non-alarming error state.

### Conflict rules

- Financial records: never silently overwrite a newer remote version. Compare `updatedAt`/revision metadata and show a conflict resolution screen when both local and remote edits changed the same record.
- Notes: use a simple last-write-wins policy only if the UI clearly warns on conflict; otherwise preserve both versions or prompt the user.
- Itinerary sort order: re-read and reconcile on reconnect; avoid rewriting the whole day list on every reorder.
- Checklist: independent item-level documents allow smaller conflict scope.
- Membership/permissions: require server-confirmed online writes; no offline role changes or join approvals.
- Location: never queue stale location updates for later delivery. Drop old queued location writes; location should reflect current time, not a previous trip moment.
- Settlement confirmation: do not apply offline confirmation as final until server synchronization is acknowledged.

Test offline, reconnect, duplicate submit, app restart, and two devices editing the same record.

---

## 16. Internationalization, dates and money

- Use `flutter gen-l10n` with ARB files.
- English is the initial language.
- Keep all user-facing strings in localization resources; no UI text literals scattered across widgets.
- Format dates/times with locale-aware APIs.
- Store timestamps in UTC; store the tour’s IANA timezone for planned local events.
- Use ISO 4217 currency codes, not hardcoded `$` or `৳` in logic.
- Store integer minor units and use a currency metadata utility for decimal digits.
- Do not automatically convert currency. Multiple currencies display separately until conversion is deliberately implemented.
- Avoid storing formatted amount strings in Firestore.
- Ensure pluralization and date-range labels localize correctly.
- Avoid culturally specific assumptions in default categories and onboarding.

---

## 17. Accessibility, UX and performance

### Accessibility

- Meet reasonable WCAG contrast standards.
- All controls have semantic labels.
- Tap targets are comfortably large.
- Respect text scaling.
- Avoid color-only meaning.
- Support keyboard navigation on larger screens where practical.
- Provide clear validation and focus the first invalid field.
- Support reduced motion where practical.

### Performance

- Use lazy lists and pagination.
- Avoid unnecessary rebuilds; scope Riverpod providers to feature/data streams.
- Dispose listeners and location streams.
- Avoid large images and unnecessary assets.
- Use profile URLs as remote avatars with fallback initials; cache images carefully.
- Do not run expensive full-history balance recalculations on every widget rebuild.
- Do not use a global Firestore listener for all app data.
- Keep startup fast and show a useful loading shell.
- Add error boundaries/guarded async calls so a failed stream does not crash the app.
- Profile on a physical Android device, not only an emulator.

### UX states every screen must implement

- Loading.
- Empty.
- Error with retry.
- Offline/cached.
- Pending sync.
- Permission denied.
- Access revoked.
- Stale data.
- Success confirmation.
- Destructive action confirmation.
- Partial/unavailable external provider.

---

## 18. Notifications and reminders

### In-app inbox

Create compact notification documents for relevant events:
- Join request received (for host/admin).
- Join approved/rejected (for requester).
- Expense added/edited if the user opted in to such updates.
- Settlement submitted/confirmed/disputed.
- Itinerary changed if opted in.
- Tour closed/reopened.
- Role/permission change.

Rules:
- Never create notifications for every location update.
- Avoid notifying the actor about their own action unless useful.
- Keep notifications small and paginated.
- Mark as read with a minimal write.
- Preferences: important updates, expense updates, plan updates, local reminders.
- If notification records are generated by clients, design rules to prevent spoofing, arbitrary recipients and unauthorized access. If safe validation is not possible, rely on listeners to canonical data and local UI indicators rather than trusting arbitrary notification writes.

### Push notifications

Strict Spark/no-backend mode:
- Do not promise reliable remote push for every collaborative event.
- Do not send FCM HTTP requests from the app using server credentials.
- Document that trusted server-side push delivery requires a trusted sender and may require leaving the strict no-backend constraint.
- Do not introduce Cloud Functions or paid services without explicit user approval.
- The app must still be fully usable with live Firestore listeners while open and local reminders.

### Local reminders

- User-controlled and off by default until opted in.
- Itinerary reminder can be scheduled locally on the device.
- Reschedule/cancel local reminders when an activity changes or is removed.
- Handle OS notification permission denial.
- Explain that reminders are device-local and do not notify other tour members.

---

## 19. Account, data and privacy settings

Settings:
- Profile name/photo preview, email read-only, optional phone field only if implemented.
- Theme: System / Light / Dark.
- Language.
- Notification preferences.
- Location-sharing status and permission help.
- Privacy and data retention explanation.
- Sign out.
- Account deletion/help flow.

Account deletion must not accidentally orphan a tour:
- If the user is the only host, require ownership transfer or explicit closure before deletion.
- If they are a member, remove active membership but retain required historical UID/name snapshots for accounting where permitted.
- Delete the user’s profile and membership indexes only after safe steps are completed.
- Explain which group financial records remain and why.
- Do not claim full erasure from all other members’ historical financial records if those records must remain consistent.
- Because no backend is allowed, document any deletion limitations honestly.

---

## 20. Recommended Flutter folder structure

Adapt to the existing repo if it already has a coherent equivalent. Otherwise use:

```text
lib/
  main.dart
  bootstrap.dart
  app/
    app.dart
    router.dart
    providers.dart
  core/
    config/
    errors/
    extensions/
    localization/
    logging/
    money/
    network/
    theme/
    utils/
    widgets/
  data/
    firebase/
      firebase_bootstrap.dart
      firestore_paths.dart
      firestore_helpers.dart
  features/
    auth/
      data/
      domain/
      presentation/
    home/
      data/
      domain/
      presentation/
    tours/
      data/
      domain/
      presentation/
    membership/
      data/
      domain/
      presentation/
    expenses/
      data/
      domain/
      presentation/
    settlements/
      data/
      domain/
      presentation/
    itinerary/
      data/
      domain/
      presentation/
    map/
      data/
      domain/
      presentation/
    location_sharing/
      data/
      domain/
      presentation/
    notes/
      data/
      domain/
      presentation/
    packing_list/
      data/
      domain/
      presentation/
    activity_feed/
      data/
      domain/
      presentation/
    notifications/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
test/
  unit/
  widget/
  integration/
docs/
  PRODUCT_SPEC.md
  ARCHITECTURE.md
  FIRESTORE_SCHEMA.md
  SECURITY_RULES.md
  FREE_TIER_LIMITS.md
  TEST_PLAN.md
```

Keep repository and domain models separate if the project complexity justifies it. Do not create empty layers or dozens of interfaces with no value. Avoid one giant repository/service file.

---

## 21. Testing requirements

### Unit tests

- Equal split for divisible and non-divisible amounts.
- Custom split sum validation.
- Weighted split and deterministic remainder distribution.
- Currency decimal handling.
- Net balance sign convention.
- Partial and full settlement effects.
- Disputed/cancelled settlement does not affect confirmed balance.
- Duplicate settlement operation does not double-count.
- Soft-deleted expense excluded from current balance but retained in history.
- Multi-currency balances remain separate.
- Date range validation and timezone display.
- Location expiry/stale thresholds.
- Invite token parsing/expiry.
- Permission evaluation helper tests.

### Widget tests

- Welcome screen and Google sign-in loading/error states.
- Home empty and populated states.
- Create tour validation.
- Join request states.
- Expense form split preview and invalid state.
- Expense detail “View edits”.
- Settlement pending/confirmed/disputed states.
- Itinerary empty, map unavailable and manual place entry.
- Location sharing off/on/stale/stopped states.
- Theme changes and accessibility labels.

### Firebase Emulator tests

- Unauthenticated users cannot read private tour data.
- Non-members cannot read tours, expenses, notes, settlements, or locations.
- Member cannot self-approve or assign admin role.
- Member cannot modify another member’s expense.
- Member cannot forge another user’s settlement confirmation.
- Removed member loses access.
- Expired invite cannot grant membership.
- Closed tour blocks ordinary writes but allows permitted settlement actions.
- Location writes are restricted to the owner and approved members.
- Profile writes cannot change immutable identity fields.
- Invalid amounts, unknown fields and malformed split arrays are rejected.
- User cannot forge arbitrary inbox notifications to other members.

### Integration/manual tests

- Sign in and sign out on physical Android device.
- Fresh install and existing session.
- Create tour and share link to another messaging app.
- Open invite link with app installed and not installed.
- Request, approve, reject, cancel and retry join.
- Two devices see expense/itinerary changes in real time.
- Test offline write, app restart, reconnect and conflict.
- Test host as debtor and creditor.
- Test partial settlement and disputed payment.
- Test location permission denied, revoked, paused, expired, stale and stopped.
- Test app background/foreground behavior and battery use.
- Test poor network and repeated taps.
- Test dark/light/system themes and large text.
- Confirm no secret is included in the app bundle or repository.

---

## 22. Release readiness and documentation

Before calling the app complete:

- `flutter analyze` passes with no unresolved errors.
- `dart format` has been run.
- All unit/widget/rules tests pass, or known failures are explicitly documented.
- Firestore rules are restrictive and tested in Emulator Suite.
- Indexes are documented and checked in.
- No API secrets or service-account files are committed.
- All external providers have documented pricing, attribution and usage constraints.
- Firebase project remains on Spark; no billing account or paid services were enabled.
- Android package ID and iOS bundle ID are documented.
- Android location permissions are minimal and accurate.
- iOS usage descriptions are present only for features actually implemented.
- Google Sign-In setup instructions are complete.
- Invite links have a valid fallback.
- Offline/pending-sync states are clear.
- No screen claims remote push or background tracking is guaranteed.
- Data retention and deletion behavior is documented.
- App supports system/light/dark themes and localization infrastructure.
- README explains setup, running, testing, emulator use, Firebase configuration, limitations and release build commands.

### Required docs

**`docs/FREE_TIER_LIMITS.md`**
- Verified date and official links.
- Spark quotas and current plan restrictions.
- Which services are used.
- Which services are deliberately not used.
- Expected Firestore reads/writes for common user actions.
- Location write budget estimate.
- Map tile/place provider limits and attribution.
- Notification limitations in no-backend mode.
- Explicit statement that free tiers and provider policies can change.

**`docs/SECURITY_RULES.md`**
- Roles and permission matrix.
- Data access model.
- Threat assumptions.
- How to run rule tests.
- Known limitations of client-only financial invariants.

**`docs/ARCHITECTURE.md`**
- Feature structure, state management, repository patterns, transactions, offline behavior and provider abstractions.

**`docs/TEST_PLAN.md`**
- Unit, widget, rules, integration and physical-device checks.

---

## 23. Definition of done

Tour Board is not done merely because screens render. The MVP is done only when:

1. A user can Google-sign-in and reach Home.
2. A host can create a tour and share an invite link.
3. Another user can request to join and the host can approve/reject.
4. Unapproved/non-members cannot read private tour data, verified by rules tests.
5. Members can add expenses with equal, custom and weighted splits.
6. Splits always sum exactly to the expense amount.
7. Each member can understand whether they owe or should receive money.
8. Members can submit offline settlements and the eligible counterparty/admin workflow is enforced.
9. Admins can also owe money.
10. Expense edits show a subtle “View edits” control and retain revisions.
11. Members can collaboratively build a day-wise itinerary with place coordinates or manual place entries.
12. Map UI works using the free-first provider, with proper attribution and graceful search failure.
13. Location sharing is opt-in, stoppable, time-limited in the UI, rate-limited, and clearly shows stale data.
14. The app never exposes location to non-members or permits another user to write someone else’s location.
15. The app behaves honestly offline and does not falsely confirm unsynced writes.
16. Notifications work to the extent possible without a trusted backend; no insecure FCM sender is included.
17. Data access is scoped and paginated; no broad unbounded listeners exist.
18. The app supports light/dark/system themes and localization infrastructure.
19. Core flows have unit, widget and security rules tests.
20. Firebase remains on Spark, no paid service was enabled, and limitations are documented.

---

## 24. Start now

Begin by inspecting the repository and reporting:
- What already exists.
- What is missing.
- Any configuration or dependency conflicts.
- A staged implementation plan.

Then implement the app in the phase order above. Keep the app runnable after each phase. Do not stop after generating plans or placeholder screens; continue through implementation, tests and documentation. If a required Firebase credential or project setting is missing, finish the code path and give precise manual setup steps.

**Highest priorities:** secure rules, correct expense math, clean join flow, excellent minimal UI, quota-conscious Firestore use, and honest free-tier limitations. Do not sacrifice these to add more features.
