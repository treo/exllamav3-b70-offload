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
OPTIONAL_SECTIONS: list[str] = []
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
    if any(sections.count(s) > 1 for s in sections):
        errs.append(f"{path.name}: a section appears twice")
    want = [s for s in REQUIRED_SECTIONS + OPTIONAL_SECTIONS if s in sections]
    if sections != want:
        errs.append(f"{path.name}: section order is {sections}, expected {want}")

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
    if re.search(r"—", text):
        errs.append(f"{path.name}: em-dash between statements: name the relation")
    if re.search(r"(?<=\w)--(?=\w)", text):
        errs.append(f"{path.name}: double hyphen between words: name the relation")
    for line in prose_lines(text):
        plain = CODE_SPAN_RE.sub(" ", line)
        plain = LINK_RE.sub(r"\1", plain)
        if re.search(r"(?<=[\w.\"')])\s+[-\u2013]\s+(?=[a-z])", plain):
            errs.append(f"{path.name}: spaced hyphen between statements: {line[:70]}")
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


def check_index(files: list[pathlib.Path], errs: list[str], here: pathlib.Path | None = None) -> None:
    """The index in README.md must agree with the records it lists."""
    here = here or HERE
    readme = here / "README.md"
    if not readme.exists():
        errs.append("README.md: missing index")
        return
    text = readme.read_text()
    rows = re.findall(r"^\| (ADR-\d{4}) \| \[([^\]]+)\]\(([^)]+)\) \| ([^|]+) \|$", text, flags=re.M)
    listed = {r[0] for r in rows}
    for f in files:
        fid = "ADR-" + f.name[4:8]
        if fid not in listed:
            errs.append(f"README.md: index omits {fid}")
    for fid, title, href, status in rows:
        path = (here / href).resolve()
        if not path.exists():
            errs.append(f"README.md: {fid} links to a missing file {href}")
            continue
        head = path.read_text().splitlines()[0]
        if head != f"# {fid}: {title}":
            errs.append(f"README.md: {fid} index title differs from the record title")
        if head[6:10] != fid[4:]:
            errs.append(f"README.md: {fid} links to a record with a different id ({href})")
        actual = re.search(r"^- Status: (.+)$", path.read_text(), flags=re.M)
        if actual and actual.group(1).strip() != status.strip():
            errs.append(f"README.md: {fid} index status {status.strip()!r} != record {actual.group(1).strip()!r}")
    for label, target in LINK_RE.findall(text):
        if target.startswith(("http://", "https://", "#")):
            continue
        target = target.split("#")[0]
        if target and not (here / target).resolve().exists():
            errs.append(f"README.md: broken link {target} (label {label!r})")

    # traceability: every record must be mapped back to a source, so that an unmapped
    # decision cannot enter the set unnoticed
    if "## Traceability" not in text:
        errs.append("README.md: no Traceability section, so records cannot be mapped back to a source")
    else:
        mapped = set(re.findall(r"ADR-\d{4}", text.split("## Traceability", 1)[1]))
        for f in files:
            fid = "ADR-" + f.name[4:8]
            if fid not in mapped:
                errs.append(f"README.md: {fid} has no source mapping in the traceability tables")


def selftest() -> int:
    """Prove that each check can fail, on purpose, in a temporary directory.

    A check that has never been seen to fail is decoration (notes/b70/LESSONS.md item 45, and
    notes/adr_LESSONS.md W17). Each fixture below violates exactly one rule and must produce a
    failure that names it.
    """
    import shutil
    import tempfile

    head = "# ADR-9001: Fixture\n\n- Status: Accepted\n- Date: 2026-01-01\n- Deciders: t\n- Tags: `x`\n\n"
    good_sections = "## Context\n\nOk.\n\n## Decision\n\nOk.\n\n## Consequences\n\nOk.\n\n## Alternatives considered\n\nOk.\n\n## Links\n\nOk.\n"
    cases = {
        "order": head + "## Context\n\nOk.\n\n## Decision\n\nOk.\n\n## Consequences\n\nOk.\n\n## Links\n\nOk.\n\n## Alternatives considered\n\nOk.\n",
        "missing-section": head + "## Context\n\nOk.\n\n## Consequences\n\nOk.\n\n## Alternatives considered\n\nOk.\n\n## Links\n\nOk.\n",
        "unknown-section": head + good_sections + "\n## Notes\n\nOk.\n",
        "bad-status": head.replace("- Status: Accepted", "- Status: Shipped") + good_sections,
        "broken-date": head.replace("- Date: 2026-01-01", "- Date: 01/01/2026") + good_sections,
        "bad-reference": head + good_sections.replace("## Links\n\nOk.\n", "## Links\n\nSee ADR-9999 and [`nope`](nope.md).\n"),
        "banned-word": head + good_sections.replace("## Context\n\nOk.\n", "## Context\n\nYou should fix it.\n"),
        "contraction": head + good_sections.replace("## Context\n\nOk.\n", "## Context\n\nIt don't work.\n"),
        "semicolon": head + good_sections.replace("## Context\n\nOk.\n", "## Context\n\nOne thing; another thing.\n"),
        "long-sentence": head + good_sections.replace(
            "## Context\n\nOk.\n",
            "## Context\n\n" + " ".join([f"word{i}" for i in range(40)]) + ".\n",
        ),
        "dash": head + good_sections.replace("## Context\n\nOk.\n", "## Context\n\nThis one - not that one.\n"),
    }
    tmp = tempfile.mkdtemp(prefix="adr-selftest-")
    failures = 0
    try:
        for name, text in cases.items():
            p = pathlib.Path(tmp) / "ADR-9001-fixture.md"
            p.write_text(text)
            errs: list[str] = []
            check_structure(p, text, errs)
            check_references(p, text, {"ADR-9001"}, errs)
            check_style(p, text, errs, [], False)
            if not errs:
                print(f"SELFTEST FAIL: the {name} fixture passed, so the rule behind it cannot fail", file=sys.stderr)
                failures += 1
            else:
                print(f"selftest ok: {name} -> {errs[0][:96]}")
        # index completeness: a record missing from the index must fail
        d = pathlib.Path(tmp)
        (d / "ADR-9001-fixture.md").write_text(head + good_sections)
        (d / "README.md").write_text("# index\n")
        errs = []
        check_index(sorted(d.glob("ADR-*.md")), errs, here=d)
        if not errs:
            print("SELFTEST FAIL: an index that omits a record was accepted", file=sys.stderr)
            failures += 1
        else:
            print(f"selftest ok: index-omission -> {errs[0][:96]}")

        # traceability: a record that the index lists but no source table maps must fail
        (d / "README.md").write_text(
            "# index\n\n| ID | Record | Status |\n|---|---|---|\n"
            "| ADR-9001 | [Fixture](ADR-9001-fixture.md) | Accepted |\n\n"
            "## Traceability\n\n| ledger row | record |\n|---|---|\n| D1 | nothing |\n"
        )
        errs = []
        check_index(sorted(d.glob("ADR-*.md")), errs, here=d)
        if not any("source mapping" in e for e in errs):
            print("SELFTEST FAIL: a record with no source mapping was accepted", file=sys.stderr)
            failures += 1
        else:
            print("selftest ok: unmapped-record -> a record without a source mapping fails the index")
        # positive control: a clean fixture must produce no failure at all, or the
        # negative results above prove nothing
        clean = head + good_sections
        (d / "ADR-9001-fixture.md").write_text(clean)
        (d / "README.md").write_text(
            "# index\n\n| ID | Record | Status |\n|---|---|---|\n"
            "| ADR-9001 | [Fixture](ADR-9001-fixture.md) | Accepted |\n"
            "\n## Traceability\n\n| ledger row | record |\n|---|---|\n| D1 | ADR-9001 |\n"
        )
        errs = []
        check_structure(d / "ADR-9001-fixture.md", clean, errs)
        check_references(d / "ADR-9001-fixture.md", clean, {"ADR-9001"}, errs)
        check_style(d / "ADR-9001-fixture.md", clean, errs, [], False)
        check_index(sorted(d.glob("ADR-*.md")), errs, here=d)
        if errs:
            print(f"SELFTEST FAIL: the clean fixture was rejected: {errs[0][:96]}", file=sys.stderr)
            failures += 1
        else:
            print("selftest ok: clean fixture passes every check")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return 1 if failures else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--selftest", action="store_true", help="run the negative fixtures and exit")
    args = ap.parse_args()

    if args.selftest:
        return selftest()

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

    check_index(files, errs)

    if args.verbose:
        for w in warns:
            print(f"note: {w}")
    for e in errs:
        print(f"FAIL: {e}", file=sys.stderr)
    print(f"{len(files)} ADRs checked, {len(errs)} failures")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())