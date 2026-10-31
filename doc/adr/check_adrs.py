#!/usr/bin/env python3
"""Structure and plain-English checks for the ADR set in this directory.

Every check exits nonzero on failure, because a check that prints a complaint and returns
success is decoration rather than protection. See notes/b70/LESSONS.md item 45.

    python3 doc/adr/check_adrs.py            # check every ADR
    python3 doc/adr/check_adrs.py --verbose  # also print the longest sentences kept
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent

FILENAME_RE = re.compile(r"^ADR-(\d{4})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")
REQUIRED_SECTIONS = ["Context", "Decision", "Consequences", "Alternatives considered", "Links"]
OPTIONAL_SECTIONS = ["Amendment"]
ALLOWED_STATUS = {"Proposed", "Accepted", "Rejected", "Deprecated"}
META_BULLETS = ["Status", "Date", "Deciders", "Tags"]

# Banned words: the modal ladder and the recurring errors in ASD-STE100 Issue 9, as
# references/strict-vocabulary.md lists them. Word-boundary match, prose only.
BANNED_WORDS = {
    r"\bshould\b": "use must, or state it as a fact",
    r"\bwould\b": "restructure: if X occurs, Y occurs",
    r"\bmay\b": "use can",
    r"\bmight\b": "use can",
    r"\bcould\b": "use can",
    r"\bhowever\b": "use but",
    r"\btherefore\b": "use thus, or as a result",
    r"\bsince\b": "use because",
    r"\bensure\b": "use make sure that",
    r"\bverify\b": "use make sure that, or examine",
    r"\bperform\b": "use do",
    r"\bavoid\b": "use prevent",
    r"\bacceptable\b": "use permitted, or give the limit",
    r"\robviously\b": "delete it, it carries no fact",
    r"\bsimply\b": "delete it",
    r"\bcrucial\b": "state the fact instead",
    r"\bimportant to note\b": "delete it",
    r"\bin order to\b": "use to",
}

# Sentence budget. Rule 6.3 of ASD-STE100 gives 25 words for descriptive text and rule 5.1
# gives 20 for procedural text. The limit below is the descriptive budget plus a tolerance for
# identifiers and units, which the standard counts as one word each.
SENTENCE_LIMIT = 30

CODE_SPAN_RE = re.compile(r"`[^`]*`")
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
ADR_REF_RE = re.compile(r"ADR-\d{4}")
SENT_SPLIT_RE = re.compile(r"(?<=[.!?])\s+")

# A comma followed by a present participle is the pattern rule 3.5 forbids. The stop list drops
# ordinary words that merely end in the same three letters.
ING_RE = re.compile(r",\s+([a-z]{4,}ing)\b")
ING_STOP = {"bring", "thing", "string", "spring", "swing", "cling", "fling", "sling", "sting",
            "during", "among", "being", "having", "offer", "ceiling", "floor"}


def prose_lines(text: str) -> list[str]:
    """Metadata bullets, headings, tables and blank lines are not prose."""
    out: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            continue
        if stripped.startswith("|"):
            continue
        if re.match(r"^-\s+(Status|Date|Deciders|Tags):", stripped):
            continue
        out.append(stripped)
    return out


def words(sentence: str) -> int:
    s = CODE_SPAN_RE.sub(" X ", sentence)
    s = LINK_RE.sub(r"\1", s)
    return len([t for t in re.split(r"\s+", s) if t.strip("-–—\"'.:,()")])


def check_structure(path: pathlib.Path, text: str, errs: list[str]) -> None:
    m = FILENAME_RE.match(path.name)
    if not m:
        errs.append(f"{path.name}: file name must match ADR-NNNN-short-title.md")
        return
    fid = m.group(1)

    lines = text.splitlines()
    if not lines or not lines[0].startswith(f"# ADR-{fid}: "):
        errs.append(f"{path.name}: first line must be '# ADR-{fid}: <title>'")

    sections = re.findall(r"^## (.+?)\s*$", text, flags=re.M)
    missing = [s for s in REQUIRED_SECTIONS if s not in sections]
    if missing:
        errs.append(f"{path.name}: missing sections {missing}")
    extra = [s for s in sections if s not in REQUIRED_SECTIONS + OPTIONAL_SECTIONS]
    if extra:
        errs.append(f"{path.name}: sections outside the template {extra}")
    if sections != sorted(set(sections), key=sections.index) or len(sections) != len(set(sections)):
        errs.append(f"{path.name}: sections duplicated or out of template order")

    for bullet in META_BULLETS:
        if not re.search(rf"^- {bullet}: \S", text, flags=re.M):
            errs.append(f"{path.name}: missing '- {bullet}:' line")

    st = re.search(r"^- Status: (.+)$", text, flags=re.M)
    if st:
        value = st.group(1).strip()
        base = value.split(",")[0].strip()
        if base not in ALLOWED_STATUS and not value.startswith("Superseded by ADR-"):
            errs.append(f"{path.name}: status {value!r} is not one of {sorted(ALLOWED_STATUS)}")
    dt = re.search(r"^- Date: (\d{4}-\d{2}-\d{2})$", text, flags=re.M)
    if not dt:
        errs.append(f"{path.name}: date must be YYYY-MM-DD")

    if "\t" in text:
        errs.append(f"{path.name}: tabs, use spaces")
    if re.search(r"—|--(?=\w)", text):
        errs.append(f"{path.name}: em-dash or double-hyphen between statements: name the relation")
    if ";" in re.sub(CODE_SPAN_RE, "", text):
        errs.append(f"{path.name}: semicolon, write two sentences")


def check_references(path: pathlib.Path, text: str, ids: set[str], errs: list[str]) -> None:
    for ref in set(ADR_REF_RE.findall(text)):
        if ref == f"ADR-{path.name[4:8]}":
            continue
        if ref not in ids:
            errs.append(f"{path.name}: refers to {ref}, which does not exist")
    for label, target in LINK_RE.findall(text):
        if target.startswith(("http://", "https://", "#")):
            continue
        target = target.split("#")[0]
        if not target:
            errs.append(f"{path.name}: empty link target for {label!r}")
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.exists():
            errs.append(f"{path.name}: broken link {target} (label {label!r})")
        elif resolved.is_dir() and not target.endswith("/"):
            errs.append(f"{path.name}: directory link {target} should end with a slash")


def check_style(path: pathlib.Path, text: str, errs: list[str], warns: list[str], verbose: bool) -> None:
    body = text.split("## Context", 1)[-1]
    for line in prose_lines(body):
        plain = CODE_SPAN_RE.sub(" ", line)
        for pattern, why in BANNED_WORDS.items():
            if re.search(pattern, plain, flags=re.I):
                errs.append(f"{path.name}: banned word {pattern!r} ({why}) in: {line[:70]}")
        contraction = re.search(
            r"\b(?:don't|doesn't|didn't|won't|wouldn't|couldn't|shouldn't|isn't|aren't|wasn't|"
            r"weren't|hasn't|haven't|hadn't|can't|it's|that's|there's|here's|let's|I'm|we're|"
            r"you're|they're|we'll|you'll|they'll|he's|she's|it'll|would've|could've|should've|"
            r"must've|might've)\b",
            plain,
        )
        if contraction:
            errs.append(f"{path.name}: contraction {contraction.group(0)!r} in: {line[:70]}")
        sentences = [s for s in SENT_SPLIT_RE.split(plain) if words(s) > 0]
        longest = max((words(s) for s in sentences), default=0)
        if longest > SENTENCE_LIMIT:
            worst = max(sentences, key=words)
            errs.append(f"{path.name}: sentence of {longest} words (limit {SENTENCE_LIMIT}): {worst[:80]}...")
        elif verbose:
            warns.append(f"{path.name}: longest sentence {longest} words")
        if re.search(r"\bis to be\b|\bhas been\b|\bhave been\b", plain):
            errs.append(f"{path.name}: present perfect or complex passive in: {line[:70]}")
        hit = ING_RE.search(plain)
        if hit and hit.group(1) not in ING_STOP:
            errs.append(f"{path.name}: '-ing' clause after a comma ({hit.group(1)}), start a new sentence: {line[:70]}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    files = sorted(HERE.glob("ADR-*.md"))
    if not files:
        print("no ADR files found", file=sys.stderr)
        return 1

    ids = {f"ADR-{FILENAME_RE.match(f.name).group(1)}" for f in files if FILENAME_RE.match(f.name)}
    if len(ids) != len(files):
        print(f"FAIL: {len(files)} files, {len(ids)} unique ids", file=sys.stderr)
        return 1

    errs: list[str] = []
    warns: list[str] = []
    for f in files:
        text = f.read_text()
        check_structure(f, text, errs)
        check_references(f, text, ids, errs)
        check_style(f, text, errs, warns, args.verbose)

    if args.verbose:
        for w in warns:
            print(f"note: {w}")
    for e in errs:
        print(f"FAIL: {e}", file=sys.stderr)
    print(f"{len(files)} ADRs checked, {len(errs)} failures")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())