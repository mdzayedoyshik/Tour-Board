# Setup guide — status and remaining steps

Firebase project: **tour-board-20bd4** · Android app
`1:230585437551:android:85946ccdd7d999284bac9a` (`com.techorbit.tour_board`)
· iOS app `1:230585437551:ios:0c9f6bc5bf0abd534bac9a` (`com.techorbit.tourBoard`).

| Step | Status |
|---|---|
| 1. Firebase project, Firestore (Standard, default DB), Google sign-in | ✅ done |
| 2. `flutterfire configure` (`firebase_options.dart`, `google-services.json`, Gradle plugin) | ✅ done and committed |
| 3a. Debug-key SHA-1/SHA-256 registered; `google-services.json` refreshed with OAuth clients | ✅ done |
| 3b. Upload-key SHA-1/SHA-256 | ⏳ run `scripts/setup_release_signing.sh` (§3) |
| 3c. Play App Signing SHA-1/SHA-256 | ⏳ after the first Play upload (§6) |
| 4. iOS Google Sign-In (`GIDClientID` + URL scheme in `Info.plist`) | ✅ done |
| 5. Firestore rules + indexes deployed | ✅ done (redeploy after rule changes) |
| 6. GitHub secrets | ⏳ §3 sets the signing ones; add `PLAY_STORE_JSON_KEY` (§5) |
| 7. First Play Console upload | ⏳ manual, §6 |
| 8. Invite domain / App Links | ➖ not needed: invites use join codes only |
| 9. Physical-device checks | ⏳ `docs/TEST_PLAN.md` |

---

## 1. Run it now (debug)

```bash
flutter run          # on a connected Android phone or emulator
```

Google sign-in works in debug builds because the debug key's fingerprints
are registered. If it says "isn't set up", check that Google is enabled under
*Authentication → Sign-in method*.

## 2. Env files

`env/dev.env` and `env/prod.env` exist locally (git-ignored); every key has a
default, so they are optional.

| Key | Value | How to get it |
|---|---|---|
| `MAP_TILE_URL` | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | Default OSM tiles; light use only. For heavy use, sign up with a tile provider and paste its URL template. |
| `MAP_TILE_ATTRIBUTION` / `MAP_ATTRIBUTION_URL` | OSM attribution | Use the attribution your tile provider requires. |
| `PLACE_SEARCH_PROVIDER` | `nominatim` or `none` | `none` = manual place name/coordinates only. |
| `NOMINATIM_URL` | `https://nominatim.openstreetmap.org` | Or a self-hosted instance. |
| `PLACE_SEARCH_CONTACT_EMAIL` | blank | Optional: an email OSM can contact about this app's traffic. |
| `USE_FIREBASE_EMULATOR` / `FIREBASE_EMULATOR_HOST` | `false` / `10.0.2.2` | Local emulators only; ignored in prod. |

No secrets belong in these files. CI recreates them from the optional
`ENV_DEV` / `ENV_PROD` secrets (the script in §3 can upload them).

## 3. Upload key, fingerprints and GitHub secrets (steps 3b and 6)

Run in your own terminal (in Claude Code: `! bash scripts/setup_release_signing.sh`):

```bash
bash scripts/setup_release_signing.sh
```

It:

1. creates `android/properties/upload.jks` (PKCS12, RSA 2048, 10 000 days)
   and `android/properties/key.properties` — both git-ignored;
2. prints the upload key's SHA-1 and SHA-256;
3. optionally registers them with Firebase and refreshes
   `android/app/google-services.json` (commit that file afterwards);
4. optionally sets the GitHub secrets `KEYSTORE_BASE64`,
   `KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `ENV_PROD`, `ENV_DEV`
   with `gh secret set`.

**Back up `upload.jks` and its password** (password manager / offline
drive). Losing them blocks updates until Google approves a key reset.

Local release builds now sign with the upload key:

```bash
flutter build appbundle --release --dart-define=ENV=prod
# -> build/app/outputs/bundle/release/app-release.aab
```

## 4. Before the first upload

- Bump `version:` in `pubspec.yaml` for every upload (`1.0.0+1`, `1.0.0+2` …).
- Play Console needs a privacy policy URL; the in-app text under
  *Settings → Privacy and data retention* is a starting point.

## 5. Play Console service account (`PLAY_STORE_JSON_KEY`)

1. Google Cloud Console → the project linked to Play (or any project) →
   *IAM & Admin → Service accounts → Create*. No roles needed.
2. *Keys → Add key → JSON* — downloads a JSON file. **This is a secret.**
3. Play Console → *Users and permissions → Invite new users* → the service
   account email → app permission for Tour Board with *Release to testing
   tracks* (and *Release apps to production* if wanted).
4. Store it: `gh secret set PLAY_STORE_JSON_KEY < path/to/key.json`, then
   delete the downloaded file.

Until this secret exists, the deploy workflow builds and tests but skips the
upload (with a notice), and until the signing secrets exist it also skips the
GitHub release.

## 6. First Play upload (step 7) and Play App Signing (step 3c)

The API cannot create a new app, so the first release is manual:

1. Play Console → *Create app* (name, language, free).
2. *Testing → Internal testing → Create release* → upload
   `app-release.aab` from §3 → accept **Play App Signing**.
3. Fill in the store listing, content rating, data safety (Google account
   name/email/photo; no location; no ads) and target audience.
4. *Setup → App signing* → copy the **App signing key** SHA-1 and SHA-256
   and register them so sign-in works for Play-installed builds:

   ```bash
   firebase apps:android:sha:create 1:230585437551:android:85946ccdd7d999284bac9a <SHA1> --project tour-board-20bd4
   firebase apps:android:sha:create 1:230585437551:android:85946ccdd7d999284bac9a <SHA256> --project tour-board-20bd4
   firebase apps:sdkconfig ANDROID 1:230585437551:android:85946ccdd7d999284bac9a --project tour-board-20bd4 > android/app/google-services.json
   ```

   Commit the updated file.

After that, every push to `main` builds, creates a GitHub release and
uploads to the internal track automatically.

## 7. Redeploying rules

```bash
cd rules_test && npm test && cd ..
firebase deploy --only firestore:rules,firestore:indexes
```

## 8. Joining tours

Hosts share the 12-character **join code** (More → Invite people, or Tour
settings → Join code). Friends open Tour Board → *Join* and type it; the host
approves. No website or domain is required. Links/App Links can be added
later if you get a domain.
