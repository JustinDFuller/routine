#!/usr/bin/env python3

import argparse
import json
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path


BEGIN_MARKER = "<!-- BEGIN GENERATED SCREENSHOTS -->"
END_MARKER = "<!-- END GENERATED SCREENSHOTS -->"
EXPECTED_INDEXES = range(1, 18)
CANONICAL_NAME_PATTERN = re.compile(
    r"^(?P<index>\d{2})-(?P<slug>[a-z0-9]+(?:-[a-z0-9]+)*)-(?P<appearance>dark|light)\.png$"
)
SUGGESTED_NAME_PATTERN = re.compile(
    r"^(?P<canonical>\d{2}-[a-z0-9]+(?:-[a-z0-9]+)*-(?:dark|light))_\d+_[0-9A-F-]{36}\.png$"
)
VALIDATION_SECTION_PATTERN = re.compile(r"^## Validation\b.*$", re.MULTILINE)
NEXT_SECTION_PATTERN = re.compile(r"^## \S.*$", re.MULTILINE)


class ScreenshotAssetError(RuntimeError):
    pass


@dataclass(frozen=True)
class CanonicalScreenshot:
    index: int
    slug: str
    appearance: str
    file: str
    source_file: str
    source_suggested_name: str

    def manifest_record(self) -> dict[str, object]:
        return {
            "index": self.index,
            "slug": self.slug,
            "appearance": self.appearance,
            "file": self.file,
            "sourceFile": self.source_file,
            "sourceSuggestedName": self.source_suggested_name,
        }


def fail(message: str) -> None:
    raise ScreenshotAssetError(message)


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        fail(f"missing JSON file: {path}")


def flatten_attachments(payload: object) -> list[dict[str, object]]:
    if isinstance(payload, list):
        tests = payload
    elif isinstance(payload, dict):
        tests = [payload]
    else:
        fail("attachment manifest must be a JSON object or array")

    attachments: list[dict[str, object]] = []
    for test_entry in tests:
        if not isinstance(test_entry, dict):
            fail("attachment manifest entries must be objects")

        raw_attachments = test_entry.get("attachments")
        if not isinstance(raw_attachments, list):
            fail("attachment manifest entry is missing an attachments array")

        for attachment in raw_attachments:
            if not isinstance(attachment, dict):
                fail("attachment entries must be objects")
            attachments.append(attachment)

    return attachments


def canonical_name_from_suggested_name(suggested_name: str) -> str:
    if not suggested_name.endswith(".png"):
        fail(f"unexpected attachment extension for {suggested_name}")

    match = SUGGESTED_NAME_PATTERN.fullmatch(suggested_name)
    if match is None:
        fail(
            "malformed suggestedHumanReadableName "
            f"{suggested_name}; expected NN-slug-(dark|light)_N_UUID.png"
        )

    return f"{match.group('canonical')}.png"


def build_canonical_screenshot(
    attachment: dict[str, object],
    export_root: Path,
) -> CanonicalScreenshot:
    exported_file_name = attachment.get("exportedFileName")
    suggested_name = attachment.get("suggestedHumanReadableName")

    if not isinstance(exported_file_name, str) or not exported_file_name:
        fail("attachment is missing exportedFileName")
    if not isinstance(suggested_name, str) or not suggested_name:
        fail(f"attachment {exported_file_name} is missing suggestedHumanReadableName")

    source_path = export_root / exported_file_name
    if not source_path.is_file():
        fail(f"missing exported screenshot file: {source_path}")

    canonical_name = canonical_name_from_suggested_name(suggested_name)
    canonical_match = CANONICAL_NAME_PATTERN.fullmatch(canonical_name)
    if canonical_match is None:
        fail(f"canonical screenshot name is invalid: {canonical_name}")

    return CanonicalScreenshot(
        index=int(canonical_match.group("index")),
        slug=canonical_match.group("slug"),
        appearance=canonical_match.group("appearance"),
        file=canonical_name,
        source_file=exported_file_name,
        source_suggested_name=suggested_name,
    )


def sort_screenshots(screenshots: list[CanonicalScreenshot]) -> list[CanonicalScreenshot]:
    appearance_order = {"dark": 0, "light": 1}
    return sorted(
        screenshots,
        key=lambda screenshot: (
            screenshot.index,
            appearance_order[screenshot.appearance],
            screenshot.slug,
            screenshot.file,
        ),
    )


def validate_expected_set(
    screenshots: list[CanonicalScreenshot],
    expected_count: int,
) -> None:
    if len(screenshots) != expected_count:
        fail(f"expected {expected_count} screenshots, found {len(screenshots)}")

    seen_files: set[str] = set()
    grouped: dict[int, set[str]] = {}
    slugs_by_index: dict[int, set[str]] = {}
    for screenshot in screenshots:
        if screenshot.file in seen_files:
            fail(f"duplicate canonical screenshot name: {screenshot.file}")
        seen_files.add(screenshot.file)
        grouped.setdefault(screenshot.index, set()).add(screenshot.appearance)
        slugs_by_index.setdefault(screenshot.index, set()).add(screenshot.slug)

    missing_indexes = [index for index in EXPECTED_INDEXES if index not in grouped]
    unexpected_indexes = [index for index in grouped if index not in EXPECTED_INDEXES]

    if missing_indexes:
        fail(
            "missing screenshot indexes: "
            + ", ".join(f"{index:02d}" for index in missing_indexes)
        )
    if unexpected_indexes:
        fail(
            "unexpected screenshot indexes: "
            + ", ".join(f"{index:02d}" for index in sorted(unexpected_indexes))
        )

    for index in EXPECTED_INDEXES:
        appearances = grouped[index]
        if appearances != {"dark", "light"}:
            found = ", ".join(sorted(appearances)) or "none"
            fail(
                f"screenshot index {index:02d} must include exactly one dark and one light capture; "
                f"found {found}"
            )
        if len(slugs_by_index[index]) != 1:
            fail(
                f"screenshot index {index:02d} must map to exactly one state slug; found "
                + ", ".join(sorted(slugs_by_index[index]))
            )


def promote_command(args: argparse.Namespace) -> int:
    export_root = Path(args.export_root)
    canonical_root = Path(args.canonical_root)
    manifest_path = export_root / "manifest.json"

    attachments = flatten_attachments(load_json(manifest_path))
    screenshots = [
        build_canonical_screenshot(attachment, export_root)
        for attachment in attachments
    ]
    screenshots = sort_screenshots(screenshots)
    validate_expected_set(screenshots, args.expected_count)

    canonical_root.mkdir(parents=True, exist_ok=True)

    for stale_png in canonical_root.glob("*.png"):
        stale_png.unlink()

    for screenshot in screenshots:
        shutil.copy2(export_root / screenshot.source_file, canonical_root / screenshot.file)

    manifest_records = [screenshot.manifest_record() for screenshot in screenshots]
    manifest_output = json.dumps(manifest_records, indent=2)
    (canonical_root / "manifest.json").write_text(f"{manifest_output}\n")
    return 0


def load_canonical_manifest(manifest_path: Path) -> list[CanonicalScreenshot]:
    payload = load_json(manifest_path)
    if not isinstance(payload, list):
        fail("canonical manifest must be a JSON array")

    screenshots: list[CanonicalScreenshot] = []
    for entry in payload:
        if not isinstance(entry, dict):
            fail("canonical manifest entries must be objects")

        required_keys = [
            "index",
            "slug",
            "appearance",
            "file",
            "sourceFile",
            "sourceSuggestedName",
        ]
        missing_keys = [key for key in required_keys if key not in entry]
        if missing_keys:
            fail(
                "canonical manifest entry is missing fields: "
                + ", ".join(missing_keys)
            )

        file_name = entry["file"]
        slug = entry["slug"]
        appearance = entry["appearance"]
        source_file = entry["sourceFile"]
        source_suggested_name = entry["sourceSuggestedName"]
        index = entry["index"]

        if not isinstance(index, int):
            fail("canonical manifest index must be an integer")
        if not all(isinstance(value, str) for value in [
            file_name,
            slug,
            appearance,
            source_file,
            source_suggested_name,
        ]):
            fail("canonical manifest entry fields must be strings")

        canonical_match = CANONICAL_NAME_PATTERN.fullmatch(file_name)
        if canonical_match is None:
            fail(f"canonical manifest contains invalid file name: {file_name}")
        if int(canonical_match.group("index")) != index:
            fail(f"canonical manifest index mismatch for {file_name}")
        if canonical_match.group("slug") != slug:
            fail(f"canonical manifest slug mismatch for {file_name}")
        if canonical_match.group("appearance") != appearance:
            fail(f"canonical manifest appearance mismatch for {file_name}")

        screenshots.append(
            CanonicalScreenshot(
                index=index,
                slug=slug,
                appearance=appearance,
                file=file_name,
                source_file=source_file,
                source_suggested_name=source_suggested_name,
            )
        )

    screenshots = sort_screenshots(screenshots)
    validate_expected_set(screenshots, len(screenshots))
    return screenshots


def state_label(screenshot: CanonicalScreenshot) -> str:
    title = " ".join(segment.capitalize() for segment in screenshot.slug.split("-"))
    return f"{screenshot.index:02d} {title}"


def blob_image_url(
    repo_owner: str,
    repo_name: str,
    ref: str,
    canonical_root: str,
    file_name: str,
) -> str:
    canonical_root = canonical_root.strip("/")
    return (
        "https://github.com/"
        f"{repo_owner}/{repo_name}/blob/{ref}/{canonical_root}/{file_name}?raw=true"
    )


def render_pr_section(
    screenshots: list[CanonicalScreenshot],
    repo_owner: str,
    repo_name: str,
    ref: str,
    canonical_root: str,
) -> str:
    rows_by_index: dict[int, dict[str, CanonicalScreenshot]] = {}
    for screenshot in screenshots:
        rows_by_index.setdefault(screenshot.index, {})[screenshot.appearance] = screenshot

    lines = [
        BEGIN_MARKER,
        "## Screenshots",
        "",
        f"Canonical assets: {canonical_root}",
        "",
        "| State | Dark | Light |",
        "| --- | --- | --- |",
    ]

    for index in EXPECTED_INDEXES:
        row = rows_by_index[index]
        dark = row["dark"]
        light = row["light"]
        dark_url = blob_image_url(repo_owner, repo_name, ref, canonical_root, dark.file)
        light_url = blob_image_url(repo_owner, repo_name, ref, canonical_root, light.file)
        lines.append(
            f"| {state_label(dark)} | "
            f'<img src="{dark_url}" width="240"> | '
            f'<img src="{light_url}" width="240"> |'
        )

    lines.append(END_MARKER)
    return "\n".join(lines)


def render_pr_section_command(args: argparse.Namespace) -> int:
    screenshots = load_canonical_manifest(Path(args.manifest))
    section = render_pr_section(
        screenshots=screenshots,
        repo_owner=args.repo_owner,
        repo_name=args.repo_name,
        ref=args.ref,
        canonical_root=args.canonical_root,
    )
    sys.stdout.write(f"{section}\n")
    return 0


def replace_or_append_generated_block(body: str, generated_block: str) -> str:
    marker_pattern = re.compile(
        rf"{re.escape(BEGIN_MARKER)}.*?{re.escape(END_MARKER)}",
        re.DOTALL,
    )

    if BEGIN_MARKER in body and END_MARKER in body:
        replaced = marker_pattern.sub(generated_block, body, count=1)
        return ensure_trailing_newline(replaced)

    validation_match = VALIDATION_SECTION_PATTERN.search(body)
    if validation_match is not None:
        next_section_match = NEXT_SECTION_PATTERN.search(body, validation_match.end())
        insert_at = next_section_match.start() if next_section_match is not None else len(body)
        prefix = body[:insert_at].rstrip()
        suffix = body[insert_at:].lstrip("\n")
        pieces = [prefix, generated_block]
        if suffix:
            pieces.append(suffix)
        return ensure_trailing_newline("\n\n".join(piece for piece in pieces if piece))

    prefix = body.rstrip()
    if prefix:
        return ensure_trailing_newline(f"{prefix}\n\n{generated_block}")
    return ensure_trailing_newline(generated_block)


def ensure_trailing_newline(text: str) -> str:
    return text if text.endswith("\n") else f"{text}\n"


def replace_pr_body_command(args: argparse.Namespace) -> int:
    screenshots = load_canonical_manifest(Path(args.manifest))
    generated_block = render_pr_section(
        screenshots=screenshots,
        repo_owner=args.repo_owner,
        repo_name=args.repo_name,
        ref=args.ref,
        canonical_root=args.canonical_root,
    )
    body = Path(args.input).read_text()
    updated_body = replace_or_append_generated_block(body, generated_block)
    Path(args.output).write_text(updated_body)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    promote_parser = subparsers.add_parser("promote")
    promote_parser.add_argument("--export-root", required=True)
    promote_parser.add_argument("--canonical-root", required=True)
    promote_parser.add_argument("--expected-count", required=True, type=int)
    promote_parser.set_defaults(func=promote_command)

    render_parser = subparsers.add_parser("render-pr-section")
    render_parser.add_argument("--manifest", required=True)
    render_parser.add_argument("--canonical-root", required=True)
    render_parser.add_argument("--repo-owner", required=True)
    render_parser.add_argument("--repo-name", required=True)
    render_parser.add_argument("--ref", "--branch", dest="ref", required=True)
    render_parser.set_defaults(func=render_pr_section_command)

    replace_parser = subparsers.add_parser("replace-pr-body")
    replace_parser.add_argument("--manifest", required=True)
    replace_parser.add_argument("--canonical-root", required=True)
    replace_parser.add_argument("--repo-owner", required=True)
    replace_parser.add_argument("--repo-name", required=True)
    replace_parser.add_argument("--ref", "--branch", dest="ref", required=True)
    replace_parser.add_argument("--input", required=True)
    replace_parser.add_argument("--output", required=True)
    replace_parser.set_defaults(func=replace_pr_body_command)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.func(args)
    except ScreenshotAssetError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
