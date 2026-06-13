#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

gh_bin="${GH_BIN:-gh}"
pr_number="${1:-26}"
canonical_root="${ROUTINE_SCREENSHOT_CANONICAL_ROOT:-Docs/Screenshots}"
manifest_path="${canonical_root}/manifest.json"
screenshot_asset_script="${ROUTINE_SCREENSHOT_ASSET_SCRIPT:-./Scripts/screenshot-assets.py}"

pr_json="$("$gh_bin" pr view "$pr_number" --json body,headRefName,headRefOid,headRepositoryOwner,headRepository,url)"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

metadata_file="$workdir/metadata.json"
body_file="$workdir/body.md"
updated_body_file="$workdir/body-updated.md"

PR_JSON="$pr_json" python3 - "$metadata_file" "$body_file" <<'PY'
import json
import os
import pathlib
import sys

metadata_path = pathlib.Path(sys.argv[1])
body_path = pathlib.Path(sys.argv[2])
payload = json.loads(os.environ["PR_JSON"])

repository = payload.get("headRepository") or {}
owner = (payload.get("headRepositoryOwner") or {}).get("login") or ""
name = repository.get("name") or ""
name_with_owner = repository.get("nameWithOwner") or ""

if name_with_owner:
    split_owner, split_name = name_with_owner.split("/", 1)
    owner = owner or split_owner
    name = name or split_name

if not owner or not name:
    owner = "JustinDFuller"
    name = "routine"

metadata = {
    "owner": owner,
    "name": name,
    "ref": payload.get("headRefOid") or payload.get("headRefName") or "screenshots",
    "url": payload.get("url") or "",
}

metadata_path.write_text(json.dumps(metadata))
body_path.write_text(payload.get("body") or "")
PY

repo_owner="$(python3 - "$metadata_file" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
print(payload["owner"])
PY
)"

repo_name="$(python3 - "$metadata_file" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
print(payload["name"])
PY
)"

ref_name="$(python3 - "$metadata_file" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
print(payload["ref"])
PY
)"

pr_url="$(python3 - "$metadata_file" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
print(payload["url"])
PY
)"

python3 "$screenshot_asset_script" replace-pr-body \
    --manifest "$manifest_path" \
    --canonical-root "$canonical_root" \
    --repo-owner "$repo_owner" \
    --repo-name "$repo_name" \
    --ref "$ref_name" \
    --input "$body_file" \
    --output "$updated_body_file"

"$gh_bin" pr edit "$pr_number" --body-file "$updated_body_file"

echo "Updated PR #${pr_number}: ${pr_url}"
