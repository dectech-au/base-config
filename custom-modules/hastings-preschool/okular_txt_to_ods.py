#!/usr/bin/env python3
# okular_txt_to_ods.py
# Okular "Export as Plain Text" -> output.ods, one sheet per room.
# Deps: python3 + odfpy (torch-free).

import sys, re
from pathlib import Path
from typing import List, Dict, Any

from odf.opendocument import OpenDocumentSpreadsheet
from odf.table import Table, TableRow, TableCell, CoveredTableCell
from odf.text import P
from odf import style

DAYS = ["Mon","Tue","Wed","Thu","Fri"]  # weekend dropped

ROOM_RE = re.compile(r"([A-Za-z/\- ]+ Room),")
DATE_RE = re.compile(r"\d{2}/\d{2}/\d{4}")

def is_room_line(line: str):
    m = ROOM_RE.search(line)
    return m.group(1).strip() if m else None

def date_positions(line: str) -> List[int]:
    # absolute positions of all dd/mm/yyyy tokens on the date row
    return [m.start() for m in DATE_RE.finditer(line)]

def is_age_or_contact(line: str) -> bool:
    s = line.strip()
    return bool(re.search(r"\b\d+\s+yrs", s)) or bool(re.search(r"\b[MPHW]\s*:\s*\S", s)) or s == ""

def parse_age(line: str):
    m = re.search(r"(\d+)\s*yrs(?:\s+(\d+)\s*mths)?", line)
    if not m: return None
    yy = int(m.group(1)); mm = m.group(2)
    return f"{yy}y{int(mm)}m" if mm else f"{yy}y"

def parse_okular_text(lines: List[str]) -> Dict[str, Dict[str, Any]]:
    """
    Returns: {
      room_key: {
        "title": full title with date range,
        "rows":  [ ["Name (age)", Mon..Fri] or ["Totals", Mon..Fri] ],
        "headers": ["Name", "Mon dd/mm/yyyy", ...],
      }
    }
    """
    rooms: Dict[str, Dict[str, Any]] = {}
    current = None
    days_start: int | None = None
    date_pos_all: List[int] | None = None
    guardian_start: int | None = None

    i, n = 0, len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        # New room title?
        rt = is_room_line(line)
        if rt:
            key = rt.replace(" Room","").split(",")[0].strip()
            rooms[key] = {"title": rt, "rows": [], "headers": None}
            current = key
            days_start = None
            date_pos_all = None
            guardian_start = None
            i += 1
            continue

        if current:
            # Capture date row and build weekday header labels
            pos_all = date_positions(line)
            if pos_all and len(pos_all) >= 5:
                date_pos_all = pos_all
                days_start = pos_all[0]
                # For header labels, cap each slice at the next date start (so Fri stops at Sat)
                header_ends = pos_all[1:6]  # next starts for Mon..Fri
                ends = header_ends + ([len(line)] if len(header_ends) < 5 else [])
                # Build weekday header strings
                headers = ["Name"]
                for day, s, e in zip(DAYS, [pos_all[0]]+pos_all[1:5], ends):
                    headers.append(f"{day} {line[s:e].strip()}")
                rooms[current]["headers"] = headers
                i += 1
                continue

        # Grab guardian column start from the "Name  Guardian" header row
        if current and (days_start is not None) and ("Name" in line and "Guardian" in line):
            guardian_start = line.find("Guardian")
            i += 1
            continue

        if not (current and days_start is not None and date_pos_all is not None):
            i += 1
            continue

        # Totals: take first five n/d pairs only, ignore Closed
        if line.strip().lower().startswith("totals"):
            pairs = re.findall(r"(\d+)\s*/\s*(\d+)", line)
            vals = [f"{a}/{b}" for (a,b) in pairs[:5]]
            while len(vals) < 5: vals.append("")
            rooms[current]["rows"].append(["Totals"] + vals)
            i += 1
            continue

        # Skip orphaned detail lines
        if is_age_or_contact(line):
            i += 1
            continue

        # Data row
        seg = line[:days_start]
        if guardian_start is not None and guardian_start < days_start:
            name = seg[:guardian_start].rstrip()
            guardian = seg[guardian_start:days_start].strip()
        else:
            # Fallback: split at the last run of 2+ spaces before day columns
            m = list(re.finditer(r"\s{2,}", seg))
            if m:
                cut = m[-1].start()
                name = seg[:cut].rstrip()
                guardian = seg[cut:].strip()
            else:
                # Heuristic fallback: first two tokens are name
                toks = seg.split()
                name = " ".join(toks[:2]) if len(toks) >= 2 else seg.strip()
                guardian = " ".join(toks[2:]) if len(toks) > 2 else ""

        if not name:
            i += 1
            continue

        # Age from next line (if present)
        age = parse_age(lines[i+1]) if i + 1 < n else None
        name_age = f"{name} ({age})" if age else name

        # Build weekday flags using next date start as the cap for Fri
        look = [line]
        if i + 1 < n: look.append(lines[i+1])
        if i + 2 < n: look.append(lines[i+2])
        maxlen = max(len(L) for L in look)
        fri_end = date_pos_all[5] if len(date_pos_all) > 5 else maxlen
        ends_for_days = [date_pos_all[1], date_pos_all[2], date_pos_all[3], date_pos_all[4], fri_end]
        starts_for_days = date_pos_all[:5]

        day_vals = []
        for s, e in zip(starts_for_days, ends_for_days):
            has_fixed = any("Fixed" in L[s:e] for L in look)
            day_vals.append("Fixed" if has_fixed else "")

        rooms[current]["rows"].append([name_age] + day_vals)

        # advance past age/contact lines
        i += 1
        while i < n and is_age_or_contact(lines[i]):
            i += 1
        continue

        i += 1

    return rooms

def write_ods(rooms: Dict[str, Dict[str, Any]], out_path: Path):
    doc = OpenDocumentSpreadsheet()

    # Row style for 30px (~0.794cm) height
    tall = style.Style(name="Row30px", family="table-row")
    tall.addElement(style.TableRowProperties(rowheight="0.794cm"))
    doc.styles.addElement(tall)

    order = ["Barrang","Bilin","Naatiyn"]
    for key in [k for k in order if k in rooms] + [k for k in rooms if k not in order]:
        data = rooms[key]
        table = Table(name=key)

        # Title row merged A..I with full title
        tr = TableRow()
        tc = TableCell(valuetype="string", numbercolumnsspanned=9)
        tc.addElement(P(text=data["title"]))
        tr.addElement(tc)
        for _ in range(8):
            tr.addElement(CoveredTableCell())
        table.addElement(tr)

        # Header row
        headers = data.get("headers") or (["Name"] + DAYS)
        tr = TableRow()
        for h in headers:
            tc = TableCell(valuetype="string"); tc.addElement(P(text=h)); tr.addElement(tc)
        table.addElement(tr)

        # Data rows (child rows get tall style)
        for row in data["rows"]:
            is_totals = row and row[0] == "Totals"
            tr = TableRow(stylename=None if is_totals else tall)
            for val in row:
                tc = TableCell(valuetype="string"); tc.addElement(P(text=str(val))); tr.addElement(tc)
            table.addElement(tr)

        doc.spreadsheet.addElement(table)

    doc.save(str(out_path), True)

def main():
    if len(sys.argv) not in (2,3):
        print("Usage: okular_txt_to_ods.py input.txt [output.ods]", file=sys.stderr); sys.exit(1)
    inp = Path(sys.argv[1]).expanduser()
    if not inp.exists():
        print(f"No such file: {inp}", file=sys.stderr); sys.exit(1)
    out = Path(sys.argv[2]).expanduser() if len(sys.argv)==3 else inp.with_name("output.ods")

    lines = inp.read_text(encoding="utf-8", errors="replace").splitlines()
    rooms = parse_okular_text(lines)
    if not rooms:
        print("No rooms parsed. Is this an Okular plain-text export?", file=sys.stderr); sys.exit(2)

    write_ods(rooms, out)
    print(f"OK: wrote {out}")

if __name__ == "__main__":
    main()
