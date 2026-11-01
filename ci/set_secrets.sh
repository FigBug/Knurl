#!/bin/bash -e
# One-time setup of the GitHub Actions secrets used by ci/build.sh.
# Run locally on a Mac that has the Developer ID Application certificate in
# its login keychain and APPLE_USER / APPLE_PASS exported in the shell.
#
#   P12_PASSWORD=<password> ./ci/set_secrets.sh
#
# Exports the certificate and private key to a temporary .p12 protected by
# P12_PASSWORD, uploads it base64-encoded as APPLICATION, and sets the
# remaining secrets. Nothing is written to the repository.
cd "$(dirname "$0")/.."

REPO="${REPO:-FigBug/Knurl}"
TEAM_ID="${TEAM_ID:-3FS7DJDG38}"
DEV_APP_ID="${DEV_APP_ID:-Developer ID Application: Roland Rabien (${TEAM_ID})}"

for var in P12_PASSWORD APPLE_USER APPLE_PASS; do
  if [ -z "${!var:-}" ]; then echo "$var is not set"; exit 1; fi
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The keychain will prompt for permission to export the private key.
security export -t identities -f pkcs12 -k login.keychain-db \
  -P "$P12_PASSWORD" -o "$TMP/Application.p12" "$DEV_APP_ID"

base64 -i "$TMP/Application.p12" | gh secret set APPLICATION -R "$REPO"
gh secret set P12_PASSWORD -R "$REPO" --body "$P12_PASSWORD"
gh secret set APPLE_USER   -R "$REPO" --body "$APPLE_USER"
gh secret set APPLE_PASS   -R "$REPO" --body "$APPLE_PASS"

echo
gh secret list -R "$REPO"
