#!/usr/bin/env python3
"""Markdown table gate for the B70 notes and port docs (LESSONS 45).

A table row with the wrong number of columns renders as mangled text and, worse, silently changes which column a
claim lives in - the defect class that this check has already caught once by hand (a README row missing its third
column). It is therefore a gate, not a printer: it exits nonzero on the first bad row so `git add` can be blocked.

Scope: pipes inside backticks/code spans are ignored (measurement rows often quote `a|b` style argv), and a line is
only treated as a table row if it starts with '|' - continuation lines of wrapped prose are not rows.

Usage:  python3 notes/b70/check_tables.py [path ...]      (defaults to notes/b70/*.md + doc/port/b70*.md)
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT = sorted(glob.glob(os.path.join(ROOT, "notes/b70/*.md"))) + \
    sorted(glob.glob(os.path.join(ROOT, "doc/port/b70*.md")))


def cells(line):
    """Split a '|'-prefixed row into cells, ignoring pipes inside `code spans`."""
    stripped = re.sub(r"`[^`]*`", lambda m: m.group(0).replace("|", "\0"), line)
    parts = stripped.split("|")
    if parts and parts[0].strip() == "":
        parts = parts[1:]
    if parts and parts[-1].strip() == "":
        parts = parts[:-1]
    return [p.replace("\0", "|").strip() for p in parts]


def check(path):
    bad, n = [], 0
    width, start = None, 0
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    for i, line in enumerate(lines, 1):
        if line.lstrip().startswith("|"):
            if width is None:
                width, start = len(cells(line)), i
                continue
            w = len(cells(line))
            n += 1
            if w != width:
                bad.append(f"{path}:{i}: row has {w} columns, header ({start}) has {width}: {line[:70]}")
        else:
            width = None
    return bad


def main(argv):
    paths = argv[1:] or DEFAULT
    bad = []
    for p in paths:
        bad += check(p)
    for b in bad:
        print(b)
    print(f"{len(paths)} files checked: {'OK' if not bad else str(len(bad)) + ' bad row(s)'}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))