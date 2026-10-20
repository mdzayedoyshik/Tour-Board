# Setup guide

Firebase project **tour-board-20bd4** · Android `com.techorbit.tour_board`
(app `1:230585437551:android:85946ccdd7d999284bac9a`) · iOS
`com.techorbit.tourBoard` · Backend: `https://tour-board-backend.onrender.com`
([Tour-Board-Backend](https://github.com/xX0ZAK0Xx/Tour-Board-Backend)).

## Status

| Item | Status |
|---|---|
| Firebase project, Firestore, Google sign-in, `flutterfire configure` | ✅ |
| SHA-1/SHA-256 for debug, upload and Play App Signing keys | ✅ |
| Upload keystore + GitHub signing secrets, `PLAY_STORE_JSON_KEY` | ✅ |
| Firestore rules + indexes (incl. collection-group overrides for cleanup) | deploy with each release (§6) |
| Render backend + its env vars | ⏳ §1 |
| Google Maps app key (`MAPS_API_KEY`) | ⏳ §2 |
| iOS push (APNs) | ⏳ §4, only when shipping iOS |

## 1. Backend on Render

Follow the backend repo's README. In short:

1. Firebase Console → Project settings → **Service accounts → Generate new
   private key** (JSON; keep it private).
2. Google Cloud → APIs & Services → **Credentials → Create API key** for the
   server: restrict to **Places API (New)** and **Geocoding API**; enable
   both APIs. This key lives only on Render.
3. `openssl rand -hex 32` → cron secret.
4. Render → New → Blueprint (repo `Tour-Board-Backend`, uses `render.yaml`).
   Environment: `FIREBASE_SERVICE_ACCOUNT` (paste JSON),
   `GOOGLE_MAPS_SERVER_KEY`, `CRON_SECRET`.
5. Backend repo → Settings → Secrets → Actions → `CRON_SECRET` (same value).
   The *Daily cleanup* workflow runs 03:30 Dhaka; run it once by hand from the
   Actions tab to check.
6. Check `https://tour-board-backend.onrender.com/health` returns `{"ok":true}`.

## 2. Google Maps app key

Google Maps needs a **billing account** linked to the Google Cloud project,
even on the free tier. The mobile Maps SDK has no usage charge; place search
goes through the backend, which caps usage below the free monthly allowance
(see `docs/FREE_TIER_LIMITS.md`). Add a budget alert (Billing → Budgets, e.g.
$1) as a safety net.

1. Enable **Maps SDK for Android** (and **Maps SDK for iOS**).
2. Create an API key, restricted to:
   - Android apps: package `com.techorbit.tour_board` with SHA-1s of the
     debug, upload and Play App Signing keys;
   - API restriction: Maps SDK for Android/iOS only.
   (For iOS create a second key restricted to bundle `com.techorbit.tourBoard`.)
3. Provide it to builds:
   - local Android: `android/properties/secrets.properties` →
     `MAPS_API_KEY=...` (git-ignored);
   - local iOS: copy `ios/Flutter/Secrets.xcconfig.example` to
     `Secrets.xcconfig` and set `MAPS_API_KEY`;
   - CI: `gh secret set MAPS_API_KEY` in the app repo.

Without a key the app works, but the map area stays blank.

## 3. Env files

`env/dev.env` / `env/prod.env` (git-ignored, optional; defaults built in):

```
API_BASE_URL=https://tour-board-backend.onrender.com
USE_FIREBASE_EMULATOR=false
FIREBASE_EMULATOR_HOST=10.0.2.2
```

CI writes them from the `ENV_DEV` / `ENV_PROD` secrets:
`gh secret set ENV_PROD < env/prod.env` (same for dev).

## 4. Push notifications

- **Android**: works out of the box (FCM is part of Firebase; no extra key).
  Users are asked for notification permission on first sign-in.
- **iOS** (when you ship iOS): Apple Developer → Keys → create an **APNs
  key**; Firebase Console → Project settings → Cloud Messaging → upload it.
  In Xcode enable *Push Notifications* and *Background Modes → Remote
  notifications* for the Runner target.

## 5. Releasing

Bump `version:` in `pubspec.yaml` (the number after `+` must always
increase) and push to `main`. `deploy.yml` analyzes, tests, builds the signed
APK/AAB, creates a GitHub release and uploads to the Play **internal** track.

## 6. Firestore rules and indexes

```bash
cd rules_test && npm ci && npm test && cd ..
firebase deploy --only firestore:rules,firestore:indexes --project tour-board-20bd4
```

Deploy before (or together with) an app release that depends on the change.
Collection-group indexes can take a few minutes to build.

## 7. Joining tours

Hosts share the 12-character join code (More → Invite people); friends open
Tour Board → *Join* and type it; the host approves.
