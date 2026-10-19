# Free-tier limits and cost safety

**Verified: 2026-10-19** against the official pages linked below. Free tiers,
quotas and provider policies change; re-check them before each release. No
service here is promised to be free forever.

## Services used

| Service | Plan | Notes |
|---|---|---|
| Firebase Authentication (Google provider) | Spark | Pricing page lists 50K MAUs (with Identity Platform) on Spark. |
| Cloud Firestore (Standard) | Spark | 1 GiB stored, 50K reads/day, 20K writes/day, 20K deletes/day, 10 GiB/month egress. |
| OpenStreetMap tiles | Public OSMF tile server | Best effort, no SLA; may block heavy use. Configurable via `MAP_TILE_URL`. |
| Nominatim geocoding | Public OSMF instance | Optional (`PLACE_SEARCH_PROVIDER=nominatim`); manual entry always works. |

Sources: [Firebase pricing](https://firebase.google.com/pricing),
[OSM tile policy](https://operations.osmfoundation.org/policies/tiles/),
[Nominatim policy](https://operations.osmfoundation.org/policies/nominatim/).

## Deliberately not used

Cloud Functions, Cloud Run, scheduled jobs, Firestore TTL, Firebase Storage,
Dynamic Links (discontinued), location APIs, Google Maps / Places SDKs, paid extensions,
third-party analytics or crash reporting, and any FCM server key in the app.
The Blaze plan is never required.

Spark has no trusted server logic, so:

- **Push notifications to other users are not available in strict free mode.**
  A client cannot securely trigger cross-user FCM messages. The app uses live
  listeners while open, an in-app inbox (rules-validated, no free text), and
  device-local reminders. Adding push later needs a trusted sender (e.g. Cloud
  Functions on Blaze) and is an explicit owner decision.
- App Check is not enabled. Its attestation providers have their own quotas;
  it can be added later without changing the data model.

## Expected Firestore usage

Approximate document operations for common actions (N = items returned):

| Action | Reads | Writes |
|---|---|---|
| Sign in (first time / later) | 1 | 1 / 0–1 |
| Open Home | index N + 1 get + 1 count() per tour | 0 |
| Open a tour (first listen) | 1 tour + members (≤60) + expenses (≤1000) + settlements (≤500) | 0 |
| Re-render / tab switch | 0 (listeners stay attached; cache) | 0 |
| Add expense | 0 (+1 per active listener on other devices) | 2 (expense + feed event) |
| Edit / delete expense | 1 (transaction) | 2–3 (expense, revision, feed) |
| Approve join request | 3 (transaction) | 4 + 2 best-effort (inbox, feed) |
| Record + confirm settlement | 1 | 2 + feed/inbox |
| Mark inbox item read | 0 | 1 |

Listeners are scoped to visible screens and cancelled on dispose. Older
notes and feed entries are fetched page by page (30). Nothing polls.

A tour with 10 members adding 40 expenses a day uses roughly 40 × 2 = 80
writes and 40 × 10 = 400 listener reads per day — far below the limits. The
main cost is the first open of a large tour (one read per expense); tours are
bounded to the latest 1000 expenses.

## Map tiles and search

- Tiles: the OSM policy requires visible attribution (shown on the map), an
  identifying User-Agent (`flutter_map (com.techorbit.tour_board)`), honouring
  cache headers, viewport-only fetching, and **no offline/bulk download**. The
  public server is best effort and may block heavy use; for growth, switch
  `MAP_TILE_URL` to a commercial or self-hosted provider (check its pricing).
- Nominatim: max **1 request/second** (enforced client-side), identifying
  User-Agent and contact email, results cached, **no autocomplete** — search
  runs only when the user submits. If search is rate-limited or offline, the
  form falls back to manual name/coordinates.

## Retention without scheduled jobs

There is no TTL or cron on Spark. Disposable records carry expiry timestamps
and are hidden immediately by the UI; authorised clients delete a bounded
batch when they open the relevant screen (inbox ≤50). If
nobody opens the app, cleanup does not run. Closed tours are never deleted
automatically. Tour deletion is a host-run, bounded client workflow for
archived tours.
