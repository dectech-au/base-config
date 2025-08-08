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
FIX_RE    = re.compile(r"\bfixed(?:\s+daily)?\b", re.IGNORECASE)

# Column widths tuned to your Calc pixel readout
COL_A_CM   = "7.303cm"  # ~320 px
COL_W_CM   = "2.622cm"  # ~111 px (weekday)
COL_GAP_CM = "0.741cm"  # ~27 px  (gap)

# Row 1 height only (others default)
ROW1_HEIGHT_PT  = "29.25pt"  # ~39 px

def find_room_line(line: str):
    m = ROOM_LINE.search(line)
    return m.group(1).strip() if m else None

def date_positions(line: str) -> List[int]:
    return [m.start() for m in DATE_RE.finditer(line)]

def looks_like_weekday_header(line: str) -> bool:
    return all(t in line for t in ["Mon","Tue","Wed","Thu","Fri"])

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
    locked_after_totals: Dict[str, bool] = {}
    saw_header_for_room: Dict[str, bool] = {}

    i, n = 0, len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        title = find_room_line(line)
        if title:
            key = room_key_from_title(title)
            rooms[key] = {"title": title, "rows": [], "headers": None}
            locked_after_totals[key] = False
            saw_header_for_room[key] = False
            current = key
            pos_all = None
            days_start = None
            i += 1
            continue

        if not current or locked_after_totals[current]:
            i += 1
            continue

        # Establish date anchors + header labels
        if pos_all is None:
            positions = date_positions(line)
            if positions and len(positions) >= 5:
                pos_all = positions
                days_start = positions[0]
                headers = ["Name"]
                for idx, day in enumerate(DAYS):
                    s = positions[idx]
                    e = positions[idx + 1] if idx + 1 < len(positions) else len(line)
                    headers.append(f"{day} {line[s:e].strip()}")
                rooms[current]["headers"] = headers
                saw_header_for_room[current] = True
                i += 1
                continue

        if not (pos_all and days_start is not None):
            i += 1
            continue

        # Skip continuation weekday/date headers after the first header for this room
        if saw_header_for_room.get(current, False) and (looks_like_weekday_header(line) or date_positions(line)):
            i += 1
            continue

        if "Name" in line and "Guardian" in line:
            i += 1
            continue
        if is_age_or_contact(line):
            i += 1
            continue

        # Totals row ends the room
        if line.strip().lower().startswith("totals"):
            pairs = re.findall(r"(\d+)\s*/\s*(\d+)", line)
            vals = [f"{a}/{b}" for (a,b) in pairs[:5]]
            while len(vals) < 5: vals.append("")
            rooms[current]["rows"].append(["Totals"] + vals)
            locked_after_totals[current] = True
            i += 1
            continue

        # Child row
        name = two_token_name(line[:days_start])
        if not name:
            i += 1
            continue
        age = parse_age(lines[i+1]) if i + 1 < n else None
        name_age = f"{name} ({age})" if age else name

        # Slice per weekday, scan this + next 3 lines for "Fixed Daily"
        look = [line]
        for k in (1,2,3):
            if i + k < n:
                look.append(lines[i+k])
        maxlen = max(len(L) for L in look)
        fri_end = pos_all[5] if len(pos_all) > 5 else maxlen
        starts = pos_all[:5]
        ends   = [pos_all[1], pos_all[2], pos_all[3], pos_all[4], fri_end]

        day_vals = []
        for s, e in zip(starts, ends):
            cell_text = " ".join(L[s:e] for L in look)
            day_vals.append("Fixed" if FIX_RE.search(cell_text) else "")

        rooms[current]["rows"].append([name_age] + day_vals)

        # Advance past following age/contact lines
        i += 1
        while i < n and is_age_or_contact(lines[i]):
            i += 1
        continue

    return rooms

def write_ods(rooms: Dict[str, Dict[str, Any]], out_path: Path):
    doc = OpenDocumentSpreadsheet()

    # Fonts
    doc.fontfacedecls.addElement(style.FontFace(name="Verdana"))
    doc.fontfacedecls.addElement(style.FontFace(name="Calibri"))

    # Styles
    title_cell = style.Style(name="CellTitle", family="table-cell")
    title_cell.addElement(style.TextProperties(fontname="Verdana", fontsize="17pt"))
    title_cell.addElement(style.ParagraphProperties(textalign="center"))

    body_cell = style.Style(name="CellBody", family="table-cell")
    body_cell.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    header_bg_border = style.Style(name="HeaderBGBorder", family="table-cell")
    header_bg_border.addElement(style.TableCellProperties(backgroundcolor="#ededed", border="0.50pt solid #000"))
    header_bg_border.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    body_border = style.Style(name="BodyBorder", family="table-cell")
    body_border.addElement(style.TableCellProperties(border="0.50pt solid #000"))
    body_border.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    doc.automaticstyles.addElement(title_cell)
    doc.automaticstyles.addElement(body_cell)
    doc.automaticstyles.addElement(header_bg_border)
    doc.automaticstyles.addElement(body_border)

    # Row 1 height only
    rowTop = style.Style(name="RowTop", family="table-row")
    rowTop.addElement(style.TableRowProperties(rowheight=ROW1_HEIGHT_PT, useoptimalrowheight="false"))
    doc.automaticstyles.addElement(rowTop)

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

        # Columns: A, then (weekday,gap)*5 => A..K
        table.addElement(TableColumn(stylename=colA))
        for _ in range(5):
            table.addElement(TableColumn(stylename=colW))
            table.addElement(TableColumn(stylename=colG))

        # Row 1: merge A..K, centered Verdana 17, fixed height
        tr = TableRow(stylename=rowTop)
        tc = TableCell(valuetype="string", numbercolumnsspanned=11, stylename=title_cell)
        tc.addElement(P(text=data["title"]))
        tr.addElement(tc)
        for _ in range(10):
            tr.addElement(CoveredTableCell())
        table.addElement(tr)

        # Row 2: headers with bg + border on A2 and each merged weekday pair
        tr = TableRow()
        headers = data.get("headers") or (["Name"] + DAYS)
        # A2
        t = TableCell(valuetype="string", stylename=header_bg_border); t.addElement(P(text=headers[0])); tr.addElement(t)
        # B..K merged (weekday + gap)
        for label in headers[1:6]:
            t = TableCell(valuetype="string", numbercolumnsspanned=2, stylename=header_bg_border)
            t.addElement(P(text=label))
            tr.addElement(t)
            tr.addElement(CoveredTableCell())
        table.addElement(tr)

        # Data rows: border EVERY cell A..K from row 3 until "Totals"
        for row in data["rows"]:
            tr = TableRow()
            is_totals = (row and row[0] == "Totals")

            # A column
            tA = TableCell(valuetype="string", stylename=body_border); tA.addElement(P(text=str(row[0]))); tr.addElement(tA)

            # For each weekday write either "Fixed" (children) or the raw fraction (totals); gap cells blank
            if not is_totals:
                for val in row[1:6]:
                    t1 = TableCell(valuetype="string", stylename=body_border)
                    t1.addElement(P(text=("Fixed" if val == "Fixed" else "")))
                    tr.addElement(t1)
                    tr.addElement(TableCell(valuetype="string", stylename=body_border))  # gap, still bordered
            else:
                for frac in row[1:6]:
                    t1 = TableCell(valuetype="string", stylename=body_border)
                    t1.addElement(P(text=str(frac)))
                    tr.addElement(t1)
                    tr.addElement(TableCell(valuetype="string", stylename=body_border))  # gap, still bordered

            table.addElement(tr)

            if is_totals:
                # stop after totals row for this sheet
                pass

        doc.spreadsheet.addElement(table)

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
