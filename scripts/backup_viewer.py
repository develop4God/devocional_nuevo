#!/usr/bin/env python3
"""
backup_viewer.py — Devocional Cristiano backup inspector
Handles gzip-compressed and plain JSON backup files.

Usage:
  python3 backup_viewer.py <file>                  # inspect single file
  python3 backup_viewer.py <file_a> <file_b>       # compare two files
  python3 backup_viewer.py <file> --raw            # dump full JSON
  python3 backup_viewer.py <file> --ids            # list all readDevocionalIds
  python3 backup_viewer.py <file> --section stats  # show one section only
"""

import sys
import json
import gzip
import argparse
from pathlib import Path
from datetime import datetime


# ── ANSI colors ──────────────────────────────────────────────────────────────
R = "\033[91m"   # red
G = "\033[92m"   # green
Y = "\033[93m"   # yellow
B = "\033[94m"   # blue
C = "\033[96m"   # cyan
W = "\033[97m"   # white
DIM = "\033[2m"
BOLD = "\033[1m"
RESET = "\033[0m"

def bold(s):   return f"{BOLD}{s}{RESET}"
def green(s):  return f"{G}{s}{RESET}"
def red(s):    return f"{R}{s}{RESET}"
def yellow(s): return f"{Y}{s}{RESET}"
def cyan(s):   return f"{C}{s}{RESET}"
def dim(s):    return f"{DIM}{s}{RESET}"
def blue(s):   return f"{B}{s}{RESET}"


# ── Load ─────────────────────────────────────────────────────────────────────
def load_backup(path: Path) -> dict:
    raw = path.read_bytes()
    # detect gzip magic bytes
    if raw[:2] == b'\x1f\x8b':
        data = gzip.decompress(raw)
        compressed = True
    else:
        data = raw
        compressed = False
    return json.loads(data.decode('utf-8')), compressed, len(raw)


# ── Spiritual stats extraction ───────────────────────────────────────────────
def get_stats(payload: dict) -> dict:
    ss = payload.get('spiritual_stats', {})
    if isinstance(ss, str):
        ss = json.loads(ss)
    # handle old nested wrapper bug {'stats': {...}}
    if 'stats' in ss and isinstance(ss['stats'], dict):
        ss = ss['stats']
    return ss


# ── Answered prayers extraction ──────────────────────────────────────────────
def get_answered_prayers(payload: dict) -> list:
    """
    Returns answered prayers from either:
      1. Top-level 'answered_prayers' key (legacy format), or
      2. Items inside 'saved_prayers' with status == 'answered' (current format).
    """
    top_level = payload.get('answered_prayers')
    if isinstance(top_level, list) and top_level:
        return top_level
    # Current format: answered prayers live inside saved_prayers
    return [p for p in payload.get('saved_prayers', []) if isinstance(p, dict) and p.get('status') == 'answered']


# ── Section printers ─────────────────────────────────────────────────────────
def print_header(path: Path, compressed: bool, size_bytes: int):
    fmt = green("gzip compressed") if compressed else yellow("plain JSON")
    print(f"\n{bold('━━ ' + path.name + ' ━━')}  {dim(fmt)}  {dim(str(round(size_bytes/1024, 1)) + ' KB')}")


def print_stats_cards(payload: dict):
    ss = get_stats(payload)
    read_ids = ss.get('readDevocionalIds', [])
    total    = ss.get('totalDevocionalesRead', 0)
    streak   = ss.get('currentStreak', 0)
    longest  = ss.get('longestStreak', 0)

    count_color = green if len(read_ids) > 0 else red
    print(f"\n{bold('📊 Spiritual stats')}")
    print(f"  {'Read devocionales (IDs):':<30} {count_color(bold(str(len(read_ids))))}")
    print(f"  {'Total read (counter):':<30} {total}")
    print(f"  {'Current streak:':<30} {streak}")
    print(f"  {'Longest streak:':<30} {longest}")

    # warn if counter != ids length
    if total != len(read_ids):
        print(f"  {yellow('⚠  counter vs IDs mismatch:')} counter={total}, ids={len(read_ids)}")


def print_meta(payload: dict):
    META_KEYS = [
        'timestamp', 'backup_timestamp', 'language',
        'preferred_bible_version', 'merge_source',
        'version', 'app_version', 'compression_enabled',
    ]
    print(f"\n{bold('🗂  Metadata')}")
    for k in META_KEYS:
        v = payload.get(k)
        if v is None:
            continue
        label = f"  {k + ':':<32}"
        if isinstance(v, bool):
            print(f"{label} {green(str(v)) if v else yellow(str(v))}")
        else:
            print(f"{label} {v}")


LIST_SECTIONS = [
    ('favorite_devotionals',  '⭐', 'Favorite devotionals'),
    ('saved_prayers',         '🙏', 'Saved prayers'),
    ('answered_prayers',      '✔️ ', 'Answered prayers'),
    ('saved_thanksgivings',   '☀️ ', 'Saved thanksgivings'),
    ('testimonies',           '💬', 'Testimonies'),
    ('completed_encounters',  '✨', 'Completed encounters'),
    ('marked_bible_verses',   '📖', 'Marked bible verses'),
    ('read_dates',            '📅', 'Read dates (calendar — not restored)'),
]

OBJ_SECTIONS = [
    ('discovery_progress',   '🧭', 'Discovery progress'),
    ('discovery_favorites',  '🔖', 'Discovery favorites'),
]

def _section_items(key: str, payload: dict) -> list:
    """Return the effective item list for a section key, handling derived sections."""
    if key == 'answered_prayers':
        return get_answered_prayers(payload)
    v = payload.get(key, [])
    return v if isinstance(v, list) else []


def print_sections(payload: dict, verbose: bool = False):
    print(f"\n{bold('📦 Content counts')}")
    for key, icon, label in LIST_SECTIONS:
        v = _section_items(key, payload)
        count = len(v)
        bar = green(f"{count:>4} items") if count > 0 else dim(f"{count:>4} items")
        print(f"  {icon}  {label:<38} {bar}")
        if verbose and count > 0:
            for i, item in enumerate(v[:5]):
                if isinstance(item, dict):
                    preview = item.get('id') or item.get('title') or item.get('text', '')[:60]
                else:
                    preview = str(item)
                print(f"       {dim('[' + str(i) + ']')} {preview}")
            if count > 5:
                print(f"       {dim('... +' + str(count - 5) + ' more')}")

    for key, icon, label in OBJ_SECTIONS:
        v = payload.get(key, {})
        count = len(v) if isinstance(v, dict) else 0
        bar = green(f"{count:>4} entries") if count > 0 else dim(f"{count:>4} entries")
        print(f"  {icon}  {label:<38} {bar}")

    # read devocional IDs from stats
    ss = get_stats(payload)
    ids = ss.get('readDevocionalIds', [])
    bar = green(f"{len(ids):>4} IDs") if ids else red(f"{len(ids):>4} IDs  ← EMPTY")
    print(f"  🔖  {'Read devocionales (IDs in stats):':<38} {bar}")


def print_read_ids(payload: dict):
    ss = get_stats(payload)
    ids = ss.get('readDevocionalIds', [])
    if not ids:
        print(red("  No readDevocionalIds found — possible bug"))
        return
    print(f"\n{bold(f'🔖 readDevocionalIds ({len(ids)} total)')}")
    cols = 4
    for i in range(0, len(ids), cols):
        row = ids[i:i+cols]
        print("  " + "  ".join(f"{dim('['+str(i+j)+']')}{id_}" for j, id_ in enumerate(row)))


# ── Diff ──────────────────────────────────────────────────────────────────────
def flatten_for_diff(payload: dict) -> dict:
    ss = get_stats(payload)
    flat = {}
    for k, _, _ in LIST_SECTIONS:
        flat[k] = len(_section_items(k, payload))
    for k, _, _ in OBJ_SECTIONS:
        v = payload.get(k, {})
        flat[k] = len(v) if isinstance(v, dict) else 0
    flat['stats.readDevocionalIds'] = len(ss.get('readDevocionalIds', []))
    flat['stats.totalDevocionalesRead'] = ss.get('totalDevocionalesRead', 0)
    flat['stats.currentStreak'] = ss.get('currentStreak', 0)
    flat['stats.longestStreak'] = ss.get('longestStreak', 0)
    for k in ['timestamp', 'backup_timestamp', 'language', 'preferred_bible_version',
              'merge_source', 'version', 'app_version']:
        flat[k] = payload.get(k, '—')
    return flat


def print_diff(payload_a: dict, name_a: str, payload_b: dict, name_b: str):
    fa = flatten_for_diff(payload_a)
    fb = flatten_for_diff(payload_b)
    all_keys = sorted(set(list(fa.keys()) + list(fb.keys())))

    diffs = [(k, fa.get(k, '—'), fb.get(k, '—')) for k in all_keys if str(fa.get(k)) != str(fb.get(k))]

    print(f"\n{bold('🔀 Diff')}")
    print(f"  {red('A = ' + name_a)}   {green('B = ' + name_b)}\n")

    if not diffs:
        print(f"  {green('✅ No differences found')}")
        return

    w = max(len(k) for k, _, _ in diffs) + 2
    for k, va, vb in diffs:
        print(f"  {k + ':':<{w}}  {red(str(va)):>20}  →  {green(str(vb))}")

    # IDs only in A / only in B
    ids_a = set(get_stats(payload_a).get('readDevocionalIds', []))
    ids_b = set(get_stats(payload_b).get('readDevocionalIds', []))
    only_a = ids_a - ids_b
    only_b = ids_b - ids_a

    if only_a or only_b:
        print(f"\n  {bold('readDevocionalIds delta:')}")
        if only_a:
            print(f"  {red('Only in A (' + str(len(only_a)) + '):')} {', '.join(sorted(only_a)[:10])}{'...' if len(only_a)>10 else ''}")
        if only_b:
            print(f"  {green('Only in B (' + str(len(only_b)) + '):')} {', '.join(sorted(only_b)[:10])}{'...' if len(only_b)>10 else ''}")
        merged = ids_a | ids_b
        print(f"  {cyan('Union (expected after merge): ' + str(len(merged)) + ' IDs')}")


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description='Devocional backup inspector')
    parser.add_argument('files', nargs='+', help='1 or 2 backup .json files')
    parser.add_argument('--raw', action='store_true', help='Dump full JSON')
    parser.add_argument('--ids', action='store_true', help='List all readDevocionalIds')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show item previews')
    parser.add_argument('--section', help='Show only one section (stats|meta|content|diff)')
    args = parser.parse_args()

    paths = [Path(f) for f in args.files]
    for p in paths:
        if not p.exists():
            print(red(f"File not found: {p}"))
            sys.exit(1)

    payload_a, compressed_a, size_a = load_backup(paths[0])

    if args.raw:
        print(json.dumps(payload_a, indent=2, ensure_ascii=False))
        return

    if args.ids:
        print_header(paths[0], compressed_a, size_a)
        print_read_ids(payload_a)
        return

    # Single file inspection
    print_header(paths[0], compressed_a, size_a)

    section = args.section
    if not section or section == 'stats':
        print_stats_cards(payload_a)
    if not section or section == 'meta':
        print_meta(payload_a)
    if not section or section == 'content':
        print_sections(payload_a, verbose=args.verbose)

    # Two-file comparison
    if len(paths) == 2:
        payload_b, compressed_b, size_b = load_backup(paths[1])
        print_header(paths[1], compressed_b, size_b)
        if not section or section == 'stats':
            print_stats_cards(payload_b)
        if not section or section == 'meta':
            print_meta(payload_b)
        if not section or section == 'content':
            print_sections(payload_b, verbose=args.verbose)
        if not section or section == 'diff':
            print_diff(payload_a, paths[0].name, payload_b, paths[1].name)

    print()


if __name__ == '__main__':
    main()
