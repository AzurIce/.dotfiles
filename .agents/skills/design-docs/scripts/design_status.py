#!/usr/bin/env python3
"""Report the latest committed Design trailer state for a Git repository."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


TRAILER_RE = re.compile(r"^Design:\s*(?P<operations>.+?)\s*$", re.MULTILINE)
OPERATION_RE = re.compile(r"(?P<operation>[*=-])D(?P<design_id>\d{4})")
RECORD_SEPARATOR = "\x1e"
FIELD_SEPARATOR = "\x1f"


@dataclass(frozen=True)
class DesignState:
    design_id: str
    operation: str
    commit: str
    short_commit: str
    subject: str


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "git command failed"
        raise RuntimeError(message)
    return result.stdout


def repository_root(repo: Path) -> Path:
    root = git(repo, "rev-parse", "--show-toplevel").strip()
    return Path(root)


def latest_states(repo: Path) -> tuple[dict[str, DesignState], list[str]]:
    output = git(
        repo,
        "log",
        f"--format=%H{FIELD_SEPARATOR}%h{FIELD_SEPARATOR}%s{FIELD_SEPARATOR}%B{RECORD_SEPARATOR}",
    )
    states: dict[str, DesignState] = {}
    warnings: list[str] = []

    for record in output.split(RECORD_SEPARATOR):
        record = record.strip("\r\n")
        if not record:
            continue
        fields = record.split(FIELD_SEPARATOR, 3)
        if len(fields) != 4:
            warnings.append("could not parse one git log record")
            continue
        commit, short_commit, subject, message = fields
        for trailer in TRAILER_RE.finditer(message):
            operations = list(OPERATION_RE.finditer(trailer.group("operations")))
            if not operations:
                warnings.append(f"{short_commit} has an invalid Design trailer")
                continue
            for operation in operations:
                design_id = operation.group("design_id")
                if design_id in states:
                    continue
                states[design_id] = DesignState(
                    design_id=design_id,
                    operation=operation.group("operation"),
                    commit=commit,
                    short_commit=short_commit,
                    subject=subject,
                )

    return states, warnings


def design_path(repo: Path, design_id: str) -> str | None:
    active = sorted((repo / "docs" / "designs").glob(f"D{design_id}-*"))
    if active:
        return active[0].relative_to(repo).as_posix()
    archived = sorted((repo / "docs" / "designs" / "archive").glob(f"D{design_id}-*"))
    if archived:
        return archived[0].relative_to(repo).as_posix()
    return None


def design_files(repo: Path) -> tuple[dict[str, list[Path]], dict[str, list[Path]]]:
    designs = repo / "docs" / "designs"
    active: dict[str, list[Path]] = {}
    archived: dict[str, list[Path]] = {}
    name_re = re.compile(r"^D(?P<design_id>\d{4})-")

    if designs.is_dir():
        for path in designs.iterdir():
            match = name_re.match(path.name)
            if path.is_file() and match:
                active.setdefault(match.group("design_id"), []).append(path)
        archive = designs / "archive"
        if archive.is_dir():
            for path in archive.iterdir():
                match = name_re.match(path.name)
                if path.is_file() and match:
                    archived.setdefault(match.group("design_id"), []).append(path)

    return active, archived


def state_inconsistencies(
    repo: Path, states: dict[str, DesignState]
) -> list[str]:
    active, archived = design_files(repo)
    issues: list[str] = []

    for design_id, state in sorted(states.items()):
        active_files = active.get(design_id, [])
        archived_files = archived.get(design_id, [])
        if len(active_files) > 1:
            issues.append(f"D{design_id} has multiple active design files")
        if len(archived_files) > 1:
            issues.append(f"D{design_id} has multiple archived design files")
        if active_files and archived_files:
            issues.append(f"D{design_id} exists in both active and archive directories")
        if state.operation in {"=", "*"} and not active_files:
            issues.append(
                f"{state.operation}D{design_id} has no active design file "
                f"(latest state {state.short_commit})"
            )
        if state.operation == "-" and not archived_files:
            issues.append(
                f"-D{design_id} has no archived design file "
                f"(latest state {state.short_commit})"
            )
        if state.operation == "-" and active_files:
            issues.append(f"-D{design_id} still has an active design file")

    if states:
        known_ids = set(states)
        for design_id in sorted((set(active) | set(archived)) - known_ids):
            issues.append(f"D{design_id} has a design file but no committed Design state")

    return issues


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


def print_state(repo: Path, state: DesignState) -> None:
    location = design_path(repo, state.design_id)
    suffix = f" - {location}" if location else ""
    print(
        f"{state.operation}D{state.design_id}  "
        f"{state.short_commit} {state.subject}{suffix}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Report active designs that are not fully aligned with a Git repository."
    )
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument(
        "--all", action="store_true", help="show the latest state of every known design"
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit nonzero when designs are not fully aligned or uncommitted design changes exist",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        repo = repository_root(args.repo)
        states, warnings = latest_states(repo)
        inconsistencies = state_inconsistencies(repo, states)
        changes = uncommitted_design_changes(repo)
    except RuntimeError as error:
        print(f"design-status: {error}", file=sys.stderr)
        return 2

    open_mismatches = sorted(
        (state for state in states.values() if state.operation == "*"),
        key=lambda state: state.design_id,
    )

    if args.all:
        print("Latest design states:")
        if states:
            for state in sorted(states.values(), key=lambda item: item.design_id):
                print_state(repo, state)
        else:
            print("(no committed Design trailers)")
        print()

    print(f"Active designs not fully aligned: {len(open_mismatches)}")
    if open_mismatches:
        for state in open_mismatches:
            print_state(repo, state)
    else:
        print("(none)")

    print()
    print(f"Design state inconsistencies: {len(inconsistencies)}")
    if inconsistencies:
        for issue in inconsistencies:
            print(f"- {issue}")
    else:
        print("(none)")

    print()
    print(f"Uncommitted design changes: {len(changes)}")
    if changes:
        for change in changes:
            print(change)
    else:
        print("(none)")

    if warnings:
        print()
        print("Warnings:")
        for warning in warnings:
            print(f"- {warning}")

    if args.check and (open_mismatches or inconsistencies or changes or warnings):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
