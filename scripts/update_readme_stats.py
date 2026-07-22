#!/usr/bin/env python3
"""Regenerates README.md stats (test counts, coverage, file counts) from the
real codebase, in both English and Spanish sections, so they never silently
drift out of sync again.

Usage:
    python3 scripts/update_readme_stats.py --coverage-info coverage/lcov_filtered.info --test-count 3157

Run from the repo root. Coverage/test-count args are optional; when omitted,
only file/directory counts are refreshed.
"""

import argparse
import re
import subprocess
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
README_PATH = REPO_ROOT / "README.md"
PUBSPEC_PATH = REPO_ROOT / "pubspec.yaml"


def count_dart_files_recursive(path: Path) -> int:
    return len(list(path.rglob("*.dart")))


def count_test_files_recursive(path: Path) -> int:
    return len(list(path.rglob("*_test.dart")))


def get_flutter_version() -> str | None:
    """Reads the pinned Flutter version from the CI workflow, so the README
    badge/mentions always reflect the toolchain CI actually uses."""
    ci_workflow = REPO_ROOT / ".github" / "workflows" / "🚀Flutter CI.yml"
    if not ci_workflow.exists():
        return None
    match = re.search(r"flutter-version:\s*'([\d.]+)'", ci_workflow.read_text())
    return match.group(1) if match else None


def build_lib_tree_block() -> str:
    lib = REPO_ROOT / "lib"
    dirs = sorted(d for d in lib.iterdir() if d.is_dir())
    lines = ["lib/"]
    for i, d in enumerate(dirs):
        connector = "└──" if i == len(dirs) - 1 else "├──"
        count = len(list(d.rglob("*.dart")))
        lines.append(f"{connector} {d.name}/  ({count} files)")
    return "\n".join(lines)


def build_test_tree_block() -> str:
    test = REPO_ROOT / "test"
    dirs = sorted(d for d in test.iterdir() if d.is_dir())
    lines = ["test/"]
    for i, d in enumerate(dirs):
        connector = "└──" if i == len(dirs) - 1 else "├──"
        count = len(list(d.rglob("*_test.dart")))
        lines.append(f"{connector} {d.name}/  ({count} tests)")
    return "\n".join(lines)


def replace_marked_block(content: str, marker: str, new_inner: str) -> str:
    start = f"<!-- README-STATS:{marker} -->"
    end = f"<!-- /README-STATS:{marker} -->"
    pattern = re.compile(re.escape(start) + r".*?" + re.escape(end), re.DOTALL)
    if not pattern.search(content):
        raise RuntimeError(f"Marker not found: {marker}")
    replacement = f"{start}\n```\n{new_inner}\n```\n{end}"
    return pattern.sub(lambda _: replacement, content)


def get_app_version() -> str | None:
    if not PUBSPEC_PATH.exists():
        return None
    match = re.search(r"^version:\s*(\S+)", PUBSPEC_PATH.read_text(), re.MULTILINE)
    return match.group(1) if match else None


def get_language_codes() -> list[str]:
    i18n_dir = REPO_ROOT / "i18n"
    if not i18n_dir.exists():
        return []
    return sorted(p.stem for p in i18n_dir.glob("*.json"))


def build_language_list(existing_list: str, actual_codes: list[str]) -> str:
    """Preserves the existing README ordering; appends any codes present in
    i18n/ but missing from the README list, so new languages get surfaced
    without reordering ones already there."""
    existing_codes = [c.strip() for c in existing_list.split(",")]
    missing = [c for c in actual_codes if c not in existing_codes]
    return ", ".join(existing_codes + missing)


def run_lcov_summary(info_path: Path) -> tuple[str, str, str]:
    result = subprocess.run(
        ["lcov", "--ignore-errors", "unused", "--summary", str(info_path)],
        capture_output=True, text=True,
    )
    raw = result.stdout + result.stderr
    cov = re.search(r"lines\.*: ([\d.]+)%", raw)
    hit = re.search(r"lines\.*: [\d.]+% \((\d+)", raw)
    tot = re.search(r"of (\d+)", raw)
    if not (cov and hit and tot):
        raise RuntimeError(f"Could not parse lcov summary:\n{raw}")
    return cov.group(1), hit.group(1), tot.group(1)


def fmt(n: str | int) -> str:
    return f"{int(n):,}"


def coverage_color(pct: float) -> str:
    if pct >= 70:
        return "brightgreen"
    if pct >= 50:
        return "yellow"
    return "red"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--coverage-info", type=Path, default=None)
    parser.add_argument("--test-count", type=int, default=None)
    args = parser.parse_args()

    lib_files = count_dart_files_recursive(REPO_ROOT / "lib")
    test_files = count_test_files_recursive(REPO_ROOT / "test")
    language_codes = get_language_codes()
    languages = len(language_codes)
    flutter_version = get_flutter_version()
    app_version = get_app_version()
    current_year = date.today().year

    content = README_PATH.read_text()

    content = replace_marked_block(content, "lib-tree-en", build_lib_tree_block())
    content = replace_marked_block(content, "test-tree-en", build_test_tree_block())

    if app_version:
        content = re.sub(
            r"App Version: \S+", f"App Version: {app_version}", content
        )

    content = re.sub(r"© \d{4} develop4God", f"© {current_year} develop4God", content)

    if flutter_version:
        content = re.sub(
            r"Flutter-[\d.]+-blue\.svg",
            f"Flutter-{flutter_version}-blue.svg",
            content,
        )
        content = re.sub(
            r"Flutter [\d.]+(?=\*\*: )", f"Flutter {flutter_version}", content
        )
        content = re.sub(
            r"Flutter [\d.]+ or higher", f"Flutter {flutter_version} or higher", content
        )
        content = re.sub(
            r"Flutter [\d.]+ o superior", f"Flutter {flutter_version} o superior", content
        )

    if args.coverage_info and args.coverage_info.exists():
        coverage_pct, hit, total = run_lcov_summary(args.coverage_info)
        coverage_pct_f = float(coverage_pct)
        color = coverage_color(coverage_pct_f)
        hit_fmt, total_fmt = fmt(hit), fmt(total)

        content = re.sub(
            r"Coverage-[^-]*%25-[a-z]*\.svg",
            f"Coverage-{coverage_pct}%25-{color}.svg",
            content,
        )
        content = re.sub(
            r"[0-9.]+% code coverage\*\* \([0-9,]+ of [0-9,]+ lines\)",
            f"{coverage_pct}% code coverage** ({hit_fmt} of {total_fmt} lines)",
            content,
        )
        content = re.sub(
            r"\| Test Coverage(\s*)\| [0-9.]+% \([0-9,]+/[0-9,]+ lines\) \|",
            lambda m: f"| Test Coverage{m.group(1)}| {coverage_pct}% ({hit_fmt}/{total_fmt} lines) |",
            content,
        )
        content = re.sub(
            r"\| Cobertura de Tests(\s*)\| [0-9.]+% \([0-9,]+/[0-9,]+ líneas\)(\s*)\|",
            lambda m: f"| Cobertura de Tests{m.group(1)}| {coverage_pct}% ({hit_fmt}/{total_fmt} líneas){m.group(2)}|",
            content,
        )

    if args.test_count:
        test_count_fmt = fmt(args.test_count)
        content = re.sub(
            r"Tests-[0-9]*\+-[a-z]*\.svg",
            f"Tests-{args.test_count}+-brightgreen.svg",
            content,
        )
        content = re.sub(
            r"\*\*[0-9,]+ tests\*\* with full pass rate",
            f"**{test_count_fmt} tests** with full pass rate",
            content,
        )
        content = re.sub(
            r"\| Total Tests(\s*)\| [0-9,]+ tests \(100% passing ✅\) \|",
            lambda m: f"| Total Tests{m.group(1)}| {test_count_fmt} tests (100% passing ✅) |",
            content,
        )
        content = re.sub(
            r"\| Total de Tests(\s*)\| [0-9,]+ tests \(100% aprobados ✅\)(\s*)\|",
            lambda m: f"| Total de Tests{m.group(1)}| {test_count_fmt} tests (100% aprobados ✅){m.group(2)}|",
            content,
        )

    content = re.sub(
        r"\*\*[0-9,]+ test files\*\*",
        f"**{test_files} test files**",
        content,
    )
    content = re.sub(
        r"\| Source Files \(lib/\)(\s*)\| [0-9,]+ Dart files(\s*)\|",
        lambda m: f"| Source Files (lib/){m.group(1)}| {lib_files} Dart files{m.group(2)}|",
        content,
    )
    content = re.sub(
        r"\| Archivos Fuente \(lib/\)(\s*)\| [0-9,]+ archivos Dart(\s*)\|",
        lambda m: f"| Archivos Fuente (lib/){m.group(1)}| {lib_files} archivos Dart{m.group(2)}|",
        content,
    )
    content = re.sub(
        r"\| Test Files(\s*)\| [0-9,]+ test files(\s*)\|",
        lambda m: f"| Test Files{m.group(1)}| {test_files} test files{m.group(2)}|",
        content,
    )
    content = re.sub(
        r"\| Archivos de Test(\s*)\| [0-9,]+ archivos(\s*)\|",
        lambda m: f"| Archivos de Test{m.group(1)}| {test_files} archivos{m.group(2)}|",
        content,
    )
    def replace_supported_languages(match: re.Match) -> str:
        label, spacing, existing_list, trailing = match.groups()
        new_list = build_language_list(existing_list, language_codes)
        return f"| {label}{spacing}| {languages} ({new_list}){trailing}|"

    content = re.sub(
        r"\| (Supported Languages)(\s*)\| [0-9]+ \(([^)]*)\)(\s*)\|",
        replace_supported_languages,
        content,
    )
    content = re.sub(
        r"\| (Idiomas Soportados)(\s*)\| [0-9]+ \(([^)]*)\)(\s*)\|",
        replace_supported_languages,
        content,
    )

    README_PATH.write_text(content)
    print(f"lib files: {lib_files}, test files: {test_files}, languages: {languages}")
    print("README.md stats updated.")


if __name__ == "__main__":
    main()
