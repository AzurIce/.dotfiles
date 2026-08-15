#!/usr/bin/env python3
"""Report design state from the current tree and Notist module attributes."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Design:
    logical_path: str
    source_path: Path
    relative_path: str
    implementation: str
    location: str  # "active" or "archive"


def run(args: list[str]) -> str:
    result = subprocess.run(
        args,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "command failed"
        raise RuntimeError(message)
    return result.stdout


def git(repo: Path, *args: str) -> str:
    return run(["git", "-C", str(repo), *args])


def repository_root(repo: Path) -> Path:
    return Path(git(repo, "rev-parse", "--show-toplevel").strip())


def vault_root(repo: Path) -> Path:
    """Return the Vault root: docs/Notist.toml when present, else the repository root."""
    candidate = repo / "docs" / "Notist.toml"
    if candidate.is_file():
        return candidate.parent
    if (repo / "Notist.toml").is_file():
        return repo
    raise RuntimeError("no Notist.toml found at the repository root or docs/Notist.toml")


def property_values(attributes: list[dict]) -> dict[str, str]:
    values: dict[str, str] = {}
    for attribute in attributes:
        for key, raw in attribute.get("properties", []):
            value = raw.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
                value = value[1:-1]
            values[key] = value
    return values


def resolve_notist(repo: Path, override: str | None) -> str:
    if override:
        return override
    local = repo / "target" / "debug" / "notist"
    if local.is_file() and local.exists():
        return str(local)
    executable = shutil.which("notist")
    if executable is None:
        raise RuntimeError("notist executable not found on PATH")
    return executable


def load_designs(vault: Path, repo: Path, executable: str) -> list[Design]:

    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as snapshot_file:
        snapshot_path = Path(snapshot_file.name)

    try:
        run(
            [
                executable,
                "export",
                "snapshot",
                str(vault),
                "--output",
                str(snapshot_path),
                "--format",
                "json",
            ]
        )
        designs: list[Design] = []
        with snapshot_path.open(encoding="utf-8") as stream:
            for line in stream:
                record = json.loads(line)
                if record.get("kind") != "snapshot":
                    continue
                value = record.get("result", {}).get("value", {})
                for module in value.get("modules", []):
                    source_path = module.get("source_path")
                    if not source_path:
                        continue
                    source = Path(source_path)
                    try:
                        relative = source.relative_to(repo)
                    except ValueError:
                        continue
                    relative_text = relative.as_posix()
                    if not relative_text.startswith("docs/designs/"):
                        continue
                    if relative_text in {
                        "docs/designs/README.not",
                        "docs/designs/overview.not",
                        "docs/designs/archive/README.not",
                    }:
                        continue
                    if relative_text.startswith("docs/designs/archive/"):
                        location = "archive"
                    elif any(
                        relative_text.startswith(f"docs/designs/{directory}/")
                        for directory in ("language", "world", "host")
                    ) or relative_text == "docs/designs/overview.not":
                        location = "active"
                    else:
                        continue

                    values = property_values(module.get("attributes", []))
                    implementation = values.get("implementation", "unmarked")
                    designs.append(
                        Design(
                            logical_path=module["logical_path"],
                            source_path=source,
                            relative_path=relative_text,
                            implementation=implementation,
                            location=location,
                        )
                    )
        return designs
    finally:
        snapshot_path.unlink(missing_ok=True)


def uncommitted_design_changes(repo: Path) -> list[str]:
    output = git(
        repo,
        "status",
        "--porcelain=v1",
        "--untracked-files=all",
        "--",
        "docs/designs",
    )
    return [line.rstrip() for line in output.splitlines() if line.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Report design alignment from the current tree and Notist module attributes."
    )
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--all", action="store_true", help="show every known design state")
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit nonzero when implementation gaps or uncommitted design changes exist",
    )
    parser.add_argument(
        "--notist",
        help="path to the notist executable to use (default: repo target/debug/notist, then PATH)",
    )
    args = parser.parse_args()

    try:
        repo = repository_root(args.repo)
        vault = vault_root(repo)
        executable = resolve_notist(repo, args.notist)
        designs = load_designs(vault, repo, executable)
        changes = uncommitted_design_changes(repo)
    except RuntimeError as error:
        print(f"design-status: {error}", file=sys.stderr)
        return 2

    active = [design for design in designs if design.location == "active"]
    archived = [design for design in designs if design.location == "archive"]

    counts: dict[str, int] = {}
    for design in active:
        counts[design.implementation] = counts.get(design.implementation, 0) + 1

    open_gaps = [design for design in active if design.implementation != "aligned"]

    if args.all:
        print("Active designs:")
        for design in sorted(active, key=lambda item: item.relative_path):
            print(f"  {design.relative_path}  {design.implementation}")
        if archived:
            print("Archived designs:")
            for design in sorted(archived, key=lambda item: item.relative_path):
                print(f"  {design.relative_path}")
        print()

    print(f"Active designs: {len(active)}")
    print(
        "  " + ", ".join(
            f"{state}: {counts.get(state, 0)}"
            for state in ("aligned", "partial", "missing", "unmarked")
        )
    )

    print()
    print(f"Open implementation gaps: {len(open_gaps)}")
    if open_gaps:
        for design in sorted(open_gaps, key=lambda item: item.relative_path):
            print(f"- {design.relative_path}: {design.implementation}")
    else:
        print("(none)")

    print()
    print(f"Uncommitted design changes: {len(changes)}")
    if changes:
        for change in changes:
            print(change)
    else:
        print("(none)")

    if args.check and (open_gaps or changes):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
