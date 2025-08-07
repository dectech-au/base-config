#!/usr/bin/env python3
"""
text2xlsx – Okular text export → single-sheet spreadsheet
=========================================================
Take the **plain-text** export from Okular (or `pdftotext -layout`) and build a
single Excel sheet with columns: Room, Name, Guardian, Mon..Sun. It:

* Keeps **room headings** (Barrang/Bilin/Naatiyn) via a "Room" column.
* Keeps exactly **one** table header per room (skips continuation headers).
* Detects day columns by **character positions** from the Mon/Tue/… header,
  so wrapped lines and contact lines don’t break alignment.
* Treats any cell containing "Fixed" as **Fixed**; copies **Totals** rows as-is.

Usage
-----
```bash
python3 text2xlsx.py input.txt     # writes input.xlsx next to input.txt
# Optional: convert to ODS afterwards
#   ssconvert input.xlsx output.ods
```

Dependency: `openpyxl` (Nix: `python311Packages.openpyxl`).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List, Tuple

from openpyxl import Workbook

DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def find_day_slices(day_line: str) -> List[Tuple[int, int]]:
    """Return [(start,end)] slices for Mon..Sun based on their positions in *day_line*."""
    idx = []
    for d in DAYS:
        p = day_line.find(d)
        if p == -1:
            return []
        idx.append(p)
    idx.sort()
    bounds = []
    for i, start in enumerate(idx):
        end = idx[i + 1] if i + 1 < len(idx) else len(day_line)
        bounds.append((start, end))
    return bounds


def is_room_line(line: str) -> str | None:
    m = re.search(r"([A-Za-z/\- ]+ Room),", line)
    return m.group(1).strip() if m else None


def is_age_or_contact(line: str) -> bool:
    s = line.strip()
    return (
        " yrs" in s or
        re.search(r"\b[MPHW]\s*:\s*\S", s) is not None or
        s == ""
    )


def parse_text(txt_path: Path):
    lines = [l.rstrip("\n") for l in txt_path.read_text(encoding="utf-8").splitlines()]

    records = []  # [room, name, guardian, Mon..Sun]
    room = None

    guardian_start = None  # column index of Guardian (from header line)
    days_slices: List[Tuple[int, int]] = []
    days_start = None

    i = 0
    while i < len(lines):
        line = lines[i]

        # New room?
        maybe_room = is_room_line(line)
        if maybe_room:
            room = maybe_room
            guardian_start = None
            days_slices = []
            days_start = None
            i += 1
            continue

        # Capture days header and compute slices
        if not days_slices and any(d in line for d in DAYS):
            slices = find_day_slices(line)
            if slices:
                days_slices = slices
                days_start = slices[0][0]
                i += 1
                continue

        # Capture the "Name  Guardian" header to locate the Guardian column
        if days_slices and guardian_start is None and ("Name" in line and "Guardian" in line):
            guardian_start = line.find("Guardian")
            i += 1
            continue

        # Skip the date row under the day names
        if days_slices and re.search(r"\d{2}/\d{2}/\d{4}", line):
            i += 1
            continue

        # If we don't have a room or the table geometry yet, move on
        if not room or not days_slices or guardian_start is None:
            i += 1
            continue

        # Totals row
        if line.strip().startswith("Totals"):
            row_text = line
            vals = []
            for start, end in days_slices:
                vals.append(row_text[start:end].strip())
            records.append([room, "Totals", ""] + vals)
            i += 1
            continue

        # Candidate child row: take this line and peek ahead up to 2 lines to harvest day cells
        name = line[:guardian_start].strip()
        guardian = line[guardian_start:days_start].strip()

        # A real row should have both name and guardian, and not be the header itself
        if name and guardian and name != "Name" and guardian != "Guardian":
            lookahead = [line]
            # pull next two lines only for day cells; don't advance i yet
            for k in (1, 2):
                if i + k < len(lines):
                    lookahead.append(lines[i + k])
            # Build day values: if any lookahead slice contains "Fixed", mark Fixed, else empty
            day_vals = []
            for start, end in days_slices:
                cell_has_fixed = any("Fixed" in L[start:end] for L in lookahead)
                day_vals.append("Fixed" if cell_has_fixed else "")
            records.append([room, name, guardian] + day_vals)

            # Skip over following age/contact lines so we don't treat them as rows
            i += 1
            while i < len(lines) and is_age_or_contact(lines[i]):
                i += 1
            continue

        # Otherwise, just move on
        i += 1

    headers = ["Room", "Name", "Guardian"] + DAYS
    return headers, records


def write_xlsx(headers: List[str], records: List[List[str]], out_path: Path) -> None:
    wb = Workbook()
    ws = wb.active
    ws.title = "Roster"

    ws.append(headers)
    for rec in records:
        ws.append(rec)

    wb.save(out_path)


def main():
    if len(sys.argv) != 2:
        print("Usage: text2xlsx.py input.txt", file=sys.stderr)
        sys.exit(1)

    txt = Path(sys.argv[1]).expanduser()
    if not txt.exists():
        print(f"Error: file not found: {txt}", file=sys.stderr)
        sys.exit(1)

    headers, records = parse_text(txt)
    out = txt.with_suffix(".xlsx")
    write_xlsx(headers, records, out)
    print(f"✓ Wrote {out}")


if __name__ == "__main__":
    main()
