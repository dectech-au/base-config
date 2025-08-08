#!/usr/bin/env python3
# okular_txt_to_ods.py
# Okular "Export as Plain Text" -> output.ods (one sheet per room)
# Deps: python3 + odfpy

import sys, re
from pathlib import Path
from typing import List, Dict, Any

from odf.opendocument import OpenDocumentSpreadsheet
from odf.table import Table, TableRow, TableCell, CoveredTableCell, TableColumn
from odf.text import P
from odf import style

DAYS = ["Mon","Tue","Wed","Thu","Fri"]  # weekend removed
ROOM_LINE = re.compile(r"(.+ Room, .+ - .+)$")
DATE_RE   = re.compile(r"\d{2}/\d{2}/\d{4}")

# column widths (cm), derived from your px targets at 96 DPI
COL_A_CM   = "8.467cm"   # 320 px
COL_W_CM   = "2.939cm"   # 111 px (weekday)
COL_GAP_CM = "0.714cm"   # 27 px   (gap)

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
    return title_line.split(" Room,", 1)[0].strip()

def parse_okular_text(lines: List[str]) -> Dict[str, Dict[str, Any]]:
    rooms: Dict[str, Dict[str, Any]] = {}
    current = None
    pos_all: List[int] | None = None
    days_start: int | None = None
    child_row_flags: Dict[str, List[bool]] = {}

    i, n = 0, len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        title = find_room_line(line)
        if title:
            key = room_key_from_title(title)
            rooms[key] = {"title": title, "rows": [], "headers": None}
            child_row_flags[key] = []
            current = key
            pos_all = None
            days_start = None
            i += 1
            continue

        if current and pos_all is None:
            positions = date_positions(line)
            if positions and len(positions) >= 5:
                pos_all = positions
                days_start = positions[0]
                # headers: Name, then 5 merged day labels (Mon..Fri)
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
            child_row_flags[current].append(False)  # totals not a child row
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
        age = parse_age(lines[i+1]) if i + 1 < n else None
        name_age = f"{name} ({age})" if age else name

        look = [line]
        if i + 1 < n: look.append(lines[i+1])
        if i + 2 < n: look.append(lines[i+2])
        maxlen = max(len(L) for L in look)
        fri_end = pos_all[5] if len(pos_all) > 5 else maxlen
        ends = [pos_all[1], pos_all[2], pos_all[3], pos_all[4], fri_end]
        starts = pos_all[:5]

        day_vals = []
        for s, e in zip(starts, ends):
            has_fixed = any("Fixed" in L[s:e] for L in look)
            day_vals.append("Fixed" if has_fixed else "")

        rooms[current]["rows"].append([name_age] + day_vals)
        child_row_flags[current].append(True)

        i += 1
        while i < n and is_age_or_contact(lines[i]):
            i += 1
        continue

        i += 1

    for k in rooms:
        rooms[k]["child_flags"] = child_row_flags[k]
    return rooms

def write_ods(rooms: Dict[str, Dict[str, Any]], out_path: Path):
    doc = OpenDocumentSpreadsheet()

    # Font faces (declare for portability)
    doc.fontfacedecls.addElement(style.FontFace(name="Verdana"))
    doc.fontfacedecls.addElement(style.FontFace(name="Calibri"))

    # Cell styles
    title_cell = style.Style(name="CellTitle", family="table-cell")
    title_cell.addElement(style.TextProperties(fontname="Verdana", fontsize="17pt"))
    body_cell = style.Style(name="CellBody", family="table-cell")
    body_cell.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))
    doc.automaticstyles.addElement(title_cell)
    doc.automaticstyles.addElement(body_cell)

    # Row height style for child rows (15pt ~ 30px)
    row15 = style.Style(name="Row15pt", family="table-row")
    row15.addElement(style.TableRowProperties(rowheight="15pt"))
    doc.automaticstyles.addElement(row15)

    # Column styles
    colA = style.Style(name="ColA", family="table-column")
    colA.addElement(style.TableColumnProperties(columnwidth=COL_A_CM))
    colW = style.Style(name="ColW", family="table-column")
    colW.addElement(style.TableColumnProperties(columnwidth=COL_W_CM))
    colG = style.Style(name="ColGap", family="table-column")
    colG.addElement(style.TableColumnProperties(columnwidth=COL_GAP_CM))
    doc.automaticstyles.addElement(colA)
    doc.automaticstyles.addElement(colW)
    doc.automaticstyles.addElement(colG)

    order = ["Barrang","Bilin","Naatiyn"]
    sheet_keys = [k for k in order if k in rooms] + [k for k in rooms if k not in order]

    for key in sheet_keys:
        data = rooms[key]
        table = Table(name=key)

        # Define columns: A, then (W, Gap)*5 -> B..K
        table.addElement(TableColumn(stylename=colA))
        for _ in range(5):
            table.addElement(TableColumn(stylename=colW))
            table.addElement(TableColumn(stylename=colG))

        # Row 1: merge A..I, exact title line, Verdana 17
        tr = TableRow()
        tc = TableCell(valuetype="string", numbercolumnsspanned=9, stylename=title_cell)
        tc.addElement(P(text=data["title"]))
        tr.addElement(tc)
        for _ in range(8):
            tr.addElement(CoveredTableCell())
        # add two blanks for J,K (not merged)
        tr.addElement(TableCell(valuetype="string", stylename=body_cell))
        tr.addElement(TableCell(valuetype="string", stylename=body_cell))
        table.addElement(tr)

        # Row 2: headers. A2="Name"; then merged pairs (B+C), (D+E), ...
        headers = data.get("headers") or (["Name"] + DAYS)
        tr = TableRow()
        # A2
        tc = TableCell(valuetype="string", stylename=body_cell); tc.addElement(P(text=headers[0])); tr.addElement(tc)
        # Days with merge across each weekday + gap
        for label in headers[1:6]:
            tc = TableCell(valuetype="string", numbercolumnsspanned=2, stylename=body_cell)
            tc.addElement(P(text=label))
            tr.addElement(tc)
            tr.addElement(CoveredTableCell())
        table.addElement(tr)

        # Data rows: write values into weekday columns, leave gap columns blank
        for row, is_child in zip(data["rows"], data["child_flags"]):
            tr = TableRow(stylename=(row15 if is_child else None))
            # A: Name(Age) or "Totals"
            tc = TableCell(valuetype="string", stylename=body_cell); tc.addElement(P(text=str(row[0]))); tr.addElement(tc)
            # B..K: for each weekday write value into weekday col, then blank gap
            for val in row[1:6]:
                t1 = TableCell(valuetype="string", stylename=body_cell); t1.addElement(P(text=str(val))); tr.addElement(t1)
                tgap = TableCell(valuetype="string", stylename=body_cell); tgap.addElement(P(text="")); tr.addElement(tgap)
            table.addElement(tr)

        doc.spreadsheet.addElement(table)

    # Exact filename, no auto-suffix
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
