#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

security_bin="${SECURITY_BIN:-security}"
service="routine.app-store-connect"

if (( $# != 3 )); then
    echo "usage: ./Scripts/store-app-store-connect-credentials.sh <key-id> <issuer-id> <path-to-AuthKey.p8>" >&2
    exit 1
fi

key_id="$1"
issuer_id="$2"
key_path="$3"

if [[ ! -r "$key_path" ]]; then
    echo "error: App Store Connect auth key is not readable at $key_path." >&2
    exit 1
fi

if ! grep -q "PRIVATE KEY" "$key_path"; then
    echo "error: $key_path is not a PEM private key." >&2
    exit 1
fi

encoded_key="$(base64 <"$key_path" | tr -d '\n')"

"$security_bin" delete-generic-password -s "$service" -a release >/dev/null 2>&1 || true

print -r -- "add-generic-password -U -s $service -a release -T \"\" -w ${key_id}:${issuer_id}:${encoded_key}" | "$security_bin" -i >/dev/null

echo "Stored App Store Connect credentials in the login Keychain item '$service'."
echo "Every use will ask for approval. Click Allow, never Always Allow, so agents cannot read the key silently."
echo "Keep a backup of $key_path in a password manager before deleting the loose file."
