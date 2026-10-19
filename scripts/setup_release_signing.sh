#!/usr/bin/env bash
# Creates the Android upload keystore and wires it into local builds,
# Firebase (SHA fingerprints) and GitHub Actions secrets.
#
#   bash scripts/setup_release_signing.sh
#
# Writes (git-ignored):
#   android/properties/upload.jks
#   android/properties/key.properties
#
# BACK UP upload.jks AND THE PASSWORDS. Without them you cannot publish
# updates until Google approves an upload-key reset.
set -euo pipefail

if [[ ! -t 0 ]]; then
  echo "This script asks for passwords, so it needs an interactive terminal."
  echo "Open a normal terminal (outside Claude Code) and run:"
  echo "  cd $(pwd) && bash scripts/setup_release_signing.sh"
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROPS_DIR="$ROOT/android/properties"
JKS="$PROPS_DIR/upload.jks"
PROPS="$PROPS_DIR/key.properties"
FIREBASE_PROJECT="tour-board-20bd4"
ANDROID_APP_ID="1:230585437551:android:85946ccdd7d999284bac9a"

# Find keytool: JAVA_HOME, Android Studio's bundled JDK, or PATH.
KEYTOOL=""
for candidate in "${JAVA_HOME:-}/bin/keytool" /opt/android-studio/jbr/bin/keytool \
  "$HOME/android-studio/jbr/bin/keytool" "$(command -v keytool || true)"; do
  if [[ -n "$candidate" && -x "$candidate" ]]; then KEYTOOL="$candidate"; break; fi
done
[[ -n "$KEYTOOL" ]] || { echo "keytool not found. Install a JDK or set JAVA_HOME."; exit 1; }

ask_yes() { read -r -p "$1 [y/N] " reply; [[ "$reply" =~ ^[Yy]$ ]]; }

mkdir -p "$PROPS_DIR"

if [[ -f "$JKS" ]]; then
  echo "Keystore already exists at $JKS — reusing it."
  read -r -p "Key alias [upload]: " ALIAS; ALIAS="${ALIAS:-upload}"
  read -r -s -p "Keystore password: " STORE_PASS; echo
  read -r -s -p "Key password (Enter = same): " KEY_PASS; echo
  KEY_PASS="${KEY_PASS:-$STORE_PASS}"
else
  read -r -p "Key alias [upload]: " ALIAS; ALIAS="${ALIAS:-upload}"
  while true; do
    read -r -s -p "Choose a keystore password (min 6 chars): " STORE_PASS; echo
    read -r -s -p "Repeat password: " STORE_PASS2; echo
    [[ "$STORE_PASS" == "$STORE_PASS2" && ${#STORE_PASS} -ge 6 ]] && break
    echo "Passwords differ or are too short; try again."
  done
  # PKCS12 keystores use one password for store and key.
  KEY_PASS="$STORE_PASS"
  read -r -p "Your name or organisation for the certificate [Tour Board]: " CN
  CN="${CN:-Tour Board}"
  "$KEYTOOL" -genkeypair -v -keystore "$JKS" -storetype PKCS12 \
    -keyalg RSA -keysize 2048 -validity 10000 -alias "$ALIAS" \
    -storepass "$STORE_PASS" -keypass "$KEY_PASS" -dname "CN=$CN"
fi

printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=%s\nstoreFile=../properties/upload.jks\n' \
  "$STORE_PASS" "$KEY_PASS" "$ALIAS" > "$PROPS"
chmod 600 "$PROPS" "$JKS"
echo "Wrote $PROPS"

FINGERPRINTS="$("$KEYTOOL" -list -v -keystore "$JKS" -alias "$ALIAS" -storepass "$STORE_PASS")"
SHA1="$(grep -m1 'SHA1:' <<<"$FINGERPRINTS" | awk '{print $2}')"
SHA256="$(grep -m1 'SHA256:' <<<"$FINGERPRINTS" | awk '{print $2}')"
echo
echo "Upload key SHA-1:   $SHA1"
echo "Upload key SHA-256: $SHA256"
echo

if command -v firebase >/dev/null && ask_yes "Register these fingerprints with Firebase and refresh google-services.json?"; then
  firebase apps:android:sha:create "$ANDROID_APP_ID" "$SHA1" --project "$FIREBASE_PROJECT"
  firebase apps:android:sha:create "$ANDROID_APP_ID" "$SHA256" --project "$FIREBASE_PROJECT"
  firebase apps:sdkconfig ANDROID "$ANDROID_APP_ID" --project "$FIREBASE_PROJECT" \
    > "$ROOT/android/app/google-services.json"
  echo "Updated android/app/google-services.json — commit it."
fi

if command -v gh >/dev/null && ask_yes "Store signing secrets in the GitHub repo (gh secret set)?"; then
  cd "$ROOT"
  base64 -w0 "$JKS" | gh secret set KEYSTORE_BASE64
  printf '%s' "$STORE_PASS" | gh secret set KEY_STORE_PASSWORD
  printf '%s' "$KEY_PASS" | gh secret set KEY_PASSWORD
  printf '%s' "$ALIAS" | gh secret set KEY_ALIAS
  [[ -f env/prod.env ]] && gh secret set ENV_PROD < env/prod.env
  [[ -f env/dev.env ]] && gh secret set ENV_DEV < env/dev.env
  echo "GitHub secrets set. PLAY_STORE_JSON_KEY must be added separately (see docs/SETUP_GUIDE.md)."
fi

echo
echo "Done. Back up $JKS and your password somewhere safe (not in git)."
