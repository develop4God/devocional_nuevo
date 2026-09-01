#!/usr/bin/env python3
"""scripts/coverage_report.py

Single source of truth for coverage reporting — used both locally and by
.github/workflows/🚀Flutter CI.yml (merge-coverage job). Parses raw lcov
DA:/LF:/LH: records directly instead of using `lcov --list`, whose per-file
Rate column misreports 0.0% for some files under lcov 2.0-1 even though the
underlying LF:/LH: data is correct.

Usage:
  flutter test --coverage <test paths...>
  scripts/coverage_report.py [--filter SUBSTRING] [--github-summary] [--out FILE]

Example:
  scripts/coverage_report.py --filter onboarding
"""
import argparse
import os
import sys

# Files/dirs with no meaningful executable logic to protect with tests:
# abstract interfaces, thin Firebase SDK pass-through wrappers, debug-only
# screens (kDebugMode), the app composition root, and features not
# confirmed for production. Update this single list to change exclusions
# for both local runs and CI.
EXCLUDE_SUBSTRINGS = [
    "/blocs/onboarding/",
    "/pages/onboarding/",
    "/services/backup/",
    "/debug/",
    "/pages/debug_page.dart",
    "/repositories/devocional_repository.dart",
    "/services/auth_service.dart",
    "/services/push_messaging.dart",
    "/main.dart",
    "/services/user_profile_store.dart",
    "/repositories/prayer_wall_repository.dart",
    "/splash_screen.dart",
    "/utils/constants/devocional_years.dart",
]


def as_lcov_remove_patterns():
    """EXCLUDE_SUBSTRINGS rendered as `lcov --remove` glob patterns, so CI's
    HTML report (genhtml) is filtered from this same single list."""
    return [f"*{sub}*" if not sub.endswith(".dart") else f"*{sub}" for sub in EXCLUDE_SUBSTRINGS]


def parse_lcov(lcov_path, filt):
    with open(lcov_path) as f:
        content = f.read()

    records = content.split("SF:")[1:]
    results = []
    for rec in records:
        lines = rec.splitlines()
        filename = lines[0].strip()
        if filt and filt not in filename:
            continue
        if any(sub in filename for sub in EXCLUDE_SUBSTRINGS):
            continue
        hit = total = 0
        for line in lines[1:]:
            if line.startswith("DA:"):
                total += 1
                if int(line[3:].split(",")[1]) > 0:
                    hit += 1
        results.append((filename, hit, total))

    results.sort(key=lambda r: (r[1] / r[2] if r[2] else 1.0))
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lcov-file", default=os.environ.get("LCOV_FILE", "coverage/lcov.info"))
    parser.add_argument("--filter", default="")
    parser.add_argument("--github-summary", action="store_true",
                         help="Append the summary to $GITHUB_STEP_SUMMARY (CI only)")
    parser.add_argument("--out", default=None,
                         help="Write the summary text to this file (e.g. coverage/summary.txt)")
    parser.add_argument("--print-lcov-remove-patterns", action="store_true",
                         help="Print EXCLUDE_SUBSTRINGS as `lcov --remove` glob patterns "
                              "(one per line) and exit, for CI to filter lcov.info before genhtml.")
    args = parser.parse_args()

    if args.print_lcov_remove_patterns:
        for pattern in as_lcov_remove_patterns():
            print(pattern)
        return

    if not os.path.isfile(args.lcov_file):
        print(f"error: {args.lcov_file} not found. Run 'flutter test --coverage <paths>' first.",
              file=sys.stderr)
        sys.exit(1)

    results = parse_lcov(args.lcov_file, args.filter)

    for filename, hit, total in results:
        pct = (hit / total * 100) if total else 100.0
        print(f"{pct:6.1f}%  {hit:4d}/{total:<4d}  {filename}")

    th = sum(h for _, h, _ in results)
    tt = sum(t for _, _, t in results)
    if not tt:
        return

    pct = th / tt * 100
    print(f"\nTOTAL: {th}/{tt} = {pct:.1f}%")

    icon = "🟢" if pct >= 70 else "🟡" if pct >= 50 else "🔴"
    summary_line = f"{icon} Coverage: {pct:.1f}% ({th}/{tt} lines)"

    low = [(f, (h / t * 100), t) for f, h, t in results if t and (h / t * 100) < 50]
    low.sort(key=lambda x: x[1])
    top3 = "\n".join(f"  🔴 {d}: {p:.1f}%   {n}" for d, p, n in low[:3])
    pain = f"Top gaps:\n{top3}" if top3 else "No critical gaps below 50%"

    output = f"{summary_line}\n{pain}"

    if args.out:
        with open(args.out, "w") as f:
            f.write(output)

    if args.github_summary:
        step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if step_summary:
            with open(step_summary, "a") as f:
                f.write(f"## 📊 Coverage\n```\n{output}\n```\n")


if __name__ == "__main__":
    main()
