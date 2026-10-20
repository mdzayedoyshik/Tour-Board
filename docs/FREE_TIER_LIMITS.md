# Free-tier limits and cost safety

**Verified: 2026-10-20** against the official pages linked below. Free tiers
and provider policies change; re-check before each release. Nothing here is
promised to stay free forever.

## Services

| Service | Plan | Free allowance used |
|---|---|---|
| Firebase Authentication (Google) | Spark | 50K MAUs |
| Cloud Firestore (Standard) | Spark | 1 GiB stored, 50K reads/day, 20K writes/day, 20K deletes/day, 10 GiB/month egress |
| Firebase Cloud Messaging | Spark | No charge |
| Render web service (backend) | Free | Sleeps after ~15 min idle; cold start up to ~1 min |
| GitHub Actions (daily cleanup, CI, deploy) | Free tier | A few minutes per day |
| Google Maps SDK for Android/iOS | Google Maps Platform | Unlimited (no per-load charge) |
| Places API (New) Autocomplete | Essentials | 10,000 requests/month; **free when the session ends in Place Details** |
| Place Details (address + location only) | Essentials | 10,000/month |
| Geocoding (dropped pins) | Essentials | 10,000/month |

Sources: [Firebase pricing](https://firebase.google.com/pricing),
[Google Maps Platform pricing](https://developers.google.com/maps/billing-and-pricing/pricing),
[Place data fields / SKUs](https://developers.google.com/maps/documentation/places/web-service/data-fields),
[Render free instances](https://render.com/docs/free).

Google Maps Platform requires a billing account even within the free usage.
Set a budget alert (e.g. $1/month) in Google Cloud Billing.

## How the app stays inside the free tiers

**Google Maps / Places**
- The map itself uses the mobile SDK (no usage charge).
- All Places/Geocoding calls go through the backend with the server key; the
  key never ships in the app.
- Place Details requests only Essentials fields (`id`, `formattedAddress`,
  `shortFormattedAddress`, `location`). `displayName` would bill as Pro
  (5,000/month), so the name comes from the autocomplete suggestion instead.
- Autocomplete uses session tokens that end with a Place Details call.
- The backend counts every Google call in Firestore and **stops at 9,000 per
  SKU per month** (`serverMeta/mapsUsage-YYYY-MM`), returning
  `quota-exceeded`; the app then asks the user to drop a pin.
- Per-user limits: 30 place requests/minute, 300/day. Results are cached
  (suggestions 10 min, places 24 h, reverse geocode on an ~11 m grid).
- Search waits for 3+ characters and a 450 ms pause in typing.

**Firestore**
- Listeners are scoped to visible screens and cancelled on dispose; older
  notes/feed are paginated (30); nothing polls.
- Each server event costs roughly: 2 reads for the tour + members, 1–2 for
  the referenced document, 1 write for de-duplication, 1 write per
  recipient's inbox item, 1 read per recipient profile and device list.
  A 10-member tour adding 40 expenses/day ≈ 40 × (≈25 reads + ≈11 writes)
  ≈ 1,000 reads and 440 writes per day.
- The daily cleanup is bounded to 2,000 documents per run.

**Render**
- The app sends events in the background and retries once, so a cold start
  never blocks the user; pushes may arrive up to a minute late after idle.
- The daily GitHub Action wakes the server before running the cleanup job.

## Retention (server job, daily 03:30 Dhaka)

| Data | Deleted |
|---|---|
| Join codes | when expired (14 days) or revoked |
| Inbox notifications | 30 days after creation |
| Finished join requests (approved/rejected/cancelled) | 7 days after their last update |
| Whole tours (all expenses, plans, notes, payments, members, index entries) | 30 days after the tour's end date; members get a push + inbox warning 7 days before, and the app shows the deletion date once the trip ends |
| Push device tokens | when FCM reports them invalid, or not refreshed for 60 days |
| Server de-dup records | 30 days |

If the server is down, nothing is lost: the app hides expired items by
timestamp and the next run catches up.

## Deliberately not used

Cloud Functions / Blaze, Firebase Storage, Dynamic Links (discontinued),
live location sharing, Places "Pro"/"Enterprise" fields, Street View,
Directions/Routes APIs (directions open the Google Maps app via a URL),
third-party analytics or crash reporting.
