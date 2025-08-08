#/etc/nixos/custom-modules/hastings-preschool/okular_txt_to_ods.nix
{ config, pkgs, ... }:
{
  home.file.".local/bin/okular_txt_to_ods.py" = {
    executable = true;
    text = ''
#!/usr/bin/env python3
# okular_txt_to_ods.py
# Parse Okular "Export as Plain Text" and produce output.ods with one sheet per room.
# Deps: python3 + odfpy (Nix: python311Packages.odfpy). No CSV/ssconvert needed.

import sys, re
from pathlib import Path
from typing import List, Dict, Any

from odf.opendocument import OpenDocumentSpreadsheet
from odf.table import Table, TableRow, TableCell
from odf.text import P

DAYS = ["Mon","Tue","Wed","Thu","Fri"]  # Sat/Sun dropped

ROOM_RE = re.compile(r"([A-Za-z/\- ]+ Room),")
DATE_RE = re.compile(r"\d{2}/\d{2}/\d{4}")

def is_room_line(line: str):
    m = ROOM_RE.search(line)
    return m.group(1).strip() if m else None

def date_positions(line: str):
    return [m.start() for m in DATE_RE.finditer(line)]

def is_age_or_contact(line: str):
    s = line.strip()
    return bool(re.search(r"\b\d+\s+yrs", s)) or bool(re.search(r"\b[MPHW]\s*:\s*\S", s)) or s == ""

def parse_age(line: str):
    m = re.search(r"(\d+)\s*yrs(?:\s+(\d+)\s*mths)?", line)
    if not m: return None
    yy = int(m.group(1))
    mm = m.group(2)
    return f"{yy}y{int(mm)}m" if mm else f"{yy}y"

def split_name_guardian(seg: str):
    # Prefer double-space; fallback to first two tokens heuristic
    for m in re.finditer(r"\s{2,}", seg):
        left = seg[:m.start()].rstrip()
        right = seg[m.end():].strip()
        if left and right and not right.lower().startswith("guardian"):
            return left, right
    toks = seg.split()
    if len(toks) >= 3:
        return " ".join(toks[:2]), " ".join(toks[2:])
    return None, None

def parse_okular_text(lines: List[str]) -> Dict[str, Dict[str, Any]]:
    rooms: Dict[str, Dict[str, Any]] = {}
    current = None
    days_pos: List[int] | None = None
    days_start: int | None = None
    day_dates: List[str] = []

    i, n = 0, len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        rt = is_room_line(line)
        if rt:
            key = rt.replace(" Room","").split(",")[0].strip()
            rooms[key] = {"title": rt, "rows": [], "headers": None}
            current = key
            days_pos = None
            days_start = None
            day_dates = []
            i += 1
            continue

        if current:
            pos = date_positions(line)
            if pos and len(pos) >= 5:
                days_pos = pos[:5]
                days_start = days_pos[0]
                # capture the actual date strings for header labels
                ends = days_pos[1:] + [len(line)]
                day_dates = [line[s:e].strip() for s, e in zip(days_pos, ends)]
                # save header labels once: "Mon 11/08/2025" etc
                rooms[current]["headers"] = ["Name"] + [
                    f"{day} {dt}" for day, dt in zip(DAYS, day_dates)
                ]
                i += 1
                continue

        if not (current and days_pos and days_start is not None):
            i += 1
            continue

        if "Name" in line and "Guardian" in line:
            i += 1
            continue

        # Totals row: take first five n/d pairs only (ignore any "Closed")
        if line.strip().lower().startswith("totals"):
            pairs = re.findall(r"(\d+)\s*/\s*(\d+)", line)
            vals = [f"{a}/{b}" for (a,b) in pairs[:5]]
            while len(vals) < 5: vals.append("")
            rooms[current]["rows"].append(["Totals"] + vals)
            i += 1
            continue

        if is_age_or_contact(line):
            i += 1
            continue

        # Child row
        seg = line[:days_start]
        name, guardian = split_name_guardian(seg)
        if not (name and guardian):
            i += 1
            continue

        # age from next line
        age = parse_age(lines[i+1]) if i + 1 < n else None
        name_age = f"{name} ({age})" if age else name

        # day flags from this + next two lines
        look = [line]
        if i + 1 < n: look.append(lines[i+1])
        if i + 2 < n: look.append(lines[i+2])
        maxlen = max(len(L) for L in look)
        ends = days_pos[1:] + [maxlen]
        day_vals = [("Fixed" if any("Fixed" in L[s:e] for L in look) else "")
                    for s, e in zip(days_pos, ends)]

        rooms[current]["rows"].append([name_age] + day_vals)

        # advance, skipping age/contact lines
        i += 1
        while i < n and is_age_or_contact(lines[i]):
            i += 1
        continue

        i += 1

    return rooms

def write_ods(rooms: Dict[str, Dict[str, Any]], out_path: Path):
    doc = OpenDocumentSpreadsheet()
    order = ["Barrang","Bilin","Naatiyn"]
    for key in [k for k in order if k in rooms] + [k for k in rooms if k not in order]:
        data = rooms[key]
        table = Table(name=key)
        # Title row
        tr = TableRow(); tc = TableCell(valuetype="string"); tc.addElement(P(text=data["title"])); tr.addElement(tc)
        table.addElement(tr)
        # Header row
        headers = data.get("headers") or (["Name"] + DAYS)
        tr = TableRow()
        for h in headers:
            tc = TableCell(valuetype="string"); tc.addElement(P(text=h)); tr.addElement(tc)
        table.addElement(tr)
        # Data rows
        for row in data["rows"]:
            tr = TableRow()
            for val in row:
                # force text so 7/15 never becomes a date
                tc = TableCell(valuetype="string"); tc.addElement(P(text=str(val)))
                tr.addElement(tc)
            table.addElement(tr)
        doc.spreadsheet.addElement(table)
    doc.save(str(out_path), True)

def main():
    if len(sys.argv) not in (2,3):
        print("Usage: okular_txt_to_ods.py input.txt [output.ods]", file=sys.stderr)
        sys.exit(1)
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


    '';
  };
}
