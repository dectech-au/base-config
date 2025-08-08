#!/usr/bin/env python3
# okular_txt_to_ods.py
# Okular "Export as Plain Text" -> output.ods (one sheet per room)
# Deps: python3 + odfpy

import sys, re
from pathlib import Path
from typing import List, Dict, Any

from odf.opendocument import OpenDocumentSpreadsheet
from odf.table import Table, TableRow, TableCell, CoveredTableCell
from odf.text import P
from odf import style

DAYS = ["Mon","Tue","Wed","Thu","Fri"]  # weekend removed
ROOM_LINE = re.compile(r"(.+ Room, .+ - .+)$")  # whole title line
DATE_RE   = re.compile(r"\d{2}/\d{2}/\d{4}")

def find_room_line(line: str):
    m = ROOM_LINE.search(line)
    return m.group(1).strip() if m else None

def date_positions(line: str) -> List[int]:
    return [m.start() for m in DATE_RE.finditer(line)]

def is_age_or_contact(line: str) -> bool:
    s = line.strip()
    return bool(re.search(r"\b\d+\s+yrs", s)) or bool(re.search(r"\b[MPHW]\s*:\s*\S", s)) or s == ""

def parse_age(line: str):
    m = re.search(r"(\d+)\s*yrs(?:\s+(\d+)\s*mths)?", line)
    if not m: return None
    yy = int(m.group(1)); mm = m.group(2)
    return f"{yy}y{int(mm)}m" if mm else f"{yy}y"

def two_token_name(seg: str) -> str:
    toks = seg.strip().split()
    if not toks: return ""
    return " ".join(toks[:2])  # strictly first + last

def room_key_from_title(title_line: str) -> str:
    # "Barrang Room, Monday, ..." -> "Barrang"
    base = title_line.split(" Room,", 1)[0].strip()
    return base

def parse_okular_text(lines: List[str]) -> Dict[str, Dict[str, Any]]:
    rooms: Dict[str, Dict[str, Any]] = {}
    current = None
    current_title = None
    pos_all: List[int] | None = None
    days_start: int | None = None
    child_row_flags: Dict[str, List[bool]] = {}  # per-room: True where row is a child (to style height)

    i, n = 0, len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        title = find_room_line(line)
        if title:
            key = room_key_from_title(title)
            rooms[key] = {"title": title, "rows": [], "headers": None}
            child_row_flags[key] = []
            current = key
            current_title = title
            pos_all = None
            days_start = None
            i += 1
            continue

        if current and pos_all is None:
            positions = date_positions(line)
            if positions and len(positions) >= 5:
                pos_all = positions  # all seven typically, we’ll only use first five
                days_start = positions[0]
                # header labels: "Mon dd/mm/yyyy" … stop each at next date start
                headers = ["Name"]
                for idx, day in enumerate(DAYS):
                    s = positions[idx]
                    e = positions[idx + 1] if idx + 1 < len(positions) else len(line)
                    headers.append(f"{day} {line[s:e].strip()}")
                rooms[current]["headers"] = headers
                i += 1
                continue

        if not (current and pos_all and days_start is not None):
            i += 1
            continue

        if "Name" in line and "Guardian" in line:
            i += 1
            continue

        if line.strip().lower().startswith("totals"):
            pairs = re.findall(r"(\d+)\s*/\s*(\d+)", line)
            vals = [f"{a}/{b}" for (a,b) in pairs[:5]]
            while len(vals) < 5: vals.append("")
            rooms[current]["rows"].append(["Totals"] + vals)
            child_row_flags[current].append(False)  # totals row, not a child row
            i += 1
            continue

        if is_age_or_contact(line):
            i += 1
            continue

        # Child row
        name = two_token_name(line[:days_start])
        if not name:
            i += 1
            continue

        # age from next line (if present)
        age = parse_age(lines[i+1]) if i + 1 < n else None
        name_age = f"{name} ({age})" if age else name

        # weekday flags using next date as slice cap for Fri
        look = [line]
        if i + 1 < n: look.append(lines[i+1])
        if i + 2 < n: look.append(lines[i+2])
        maxlen = max(len(L) for L in look)
        ends = [
            pos_all[1],
            pos_all[2],
            pos_all[3],
            pos_all[4],
            (pos_all[5] if len(pos_all) > 5 else maxlen),  # Fri ends at Sat start
        ]
        starts = pos_all[:5]

        day_vals = []
        for s, e in zip(starts, ends):
            has_fixed = any("Fixed" in L[s:e] for L in look)
            day_vals.append("Fixed" if has_fixed else "")

        rooms[current]["rows"].append([name_age] + day_vals)
        child_row_flags[current].append(True)  # mark this output row as a child for height styling

        # advance past age/contact lines
        i += 1
        while i < n and is_age_or_contact(lines[i]):
            i += 1
        continue

        i += 1

    # stash the child flags alongside rows for styling
    for k in rooms:
        rooms[k]["child_flags"] = child_row_flags[k]
    return rooms

def write_ods(rooms: Dict[str, Dict[str, Any]], out_path: Path):
    doc = OpenDocumentSpreadsheet()

    # 15pt row height for child rows
    tall = style.Style(name="Row15pt", family="table-row")
    tall.addElement(style.TableRowProperties(rowheight="15pt"))
    doc.styles.addElement(tall)

    order = ["Barrang","Bilin","Naatiyn"]
    sheet_keys = [k for k in order if k in rooms] + [k for k in rooms if k not in order]

    for key in sheet_keys:
        data = rooms[key]
        table = Table(name=key)

        # Row 1: merge A..I with the full title line
        tr = TableRow()
        tc = TableCell(valuetype="string", numbercolumnsspanned=9)
        tc.addElement(P(text=data["title"]))
        tr.addElement(tc)
        for _ in range(8):
            tr.addElement(CoveredTableCell())
        table.addElement(tr)

        # Row 2: headers ("Name", "Mon dd/mm/yyyy", ..., "Fri dd/mm/yyyy")
        headers = data.get("headers") or (["Name"] + DAYS)
        tr = TableRow()
        for h in headers:
            tc = TableCell(valuetype="string"); tc.addElement(P(text=h)); tr.addElement(tc)
        table.addElement(tr)

        # Rows 3..: child rows (15pt) and totals rows (default height)
        for row, is_child in zip(data["rows"], data["child_flags"]):
            tr = TableRow(stylename=(tall if is_child else None))
            for val in row:
                tc = TableCell(valuetype="string"); tc.addElement(P(text=str(val))); tr.addElement(tc)
            table.addElement(tr)

        doc.spreadsheet.addElement(table)

    # Do NOT auto-append suffix; we pass the exact filename
    doc.save(str(out_path), addsuffix=False)

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
        print("No rooms parsed. Is this an Okular plain-text export?", file=sys.stderr)
        sys.exit(2)

    write_ods(rooms, out)
    print(f"OK: wrote {out}")

if __name__ == "__main__":
    main()
