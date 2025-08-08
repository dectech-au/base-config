#!/usr/bin/env python3
# okular_txt_to_ods.py
# Convert Okular "Export as Plain Text" to an ODS with one sheet per room.
# Deps: python3 + odfpy

import sys, re
from pathlib import Path
from typing import List, Dict, Any

from odf.opendocument import OpenDocumentSpreadsheet
from odf.table import Table, TableRow, TableCell, CoveredTableCell, TableColumn
from odf.text import P
from odf import style

# ---------- parsing helpers ----------

DAYS       = ["Mon","Tue","Wed","Thu","Fri"]  # weekend removed
ROOM_LINE  = re.compile(r"(.+ Room, .+ - .+)$")
DATE_RE    = re.compile(r"\d{2}/\d{2}/\d{4}")
FIX_RE     = re.compile(r"\bfixed(?:\s+daily)?\b", re.IGNORECASE)

def find_room_line(line: str):
    m = ROOM_LINE.search(line)
    return m.group(1).strip() if m else None

def date_positions(line: str) -> List[int]:
    """Start indices of dd/mm/yyyy on a header row."""
    return [m.start() for m in DATE_RE.finditer(line)]

def dayname_positions(line: str) -> List[int] | None:
    """Start indices of 'Mon Tue Wed Thu Fri' in a header row, left-to-right."""
    pos = []
    cur = 0
    for name in DAYS:
        idx = line.find(name, cur)
        if idx == -1:
            return None
        pos.append(idx)
        cur = idx + 1
    return pos

def looks_like_weekday_header(line: str) -> bool:
    return all(t in line for t in DAYS)

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
    return " ".join(toks[:2]) if toks else ""

def room_key_from_title(title_line: str) -> str:
    return title_line.split(" Room,", 1)[0].strip()

FIX_RE = re.compile(r"\bfixed(?:\s+daily)?\b", re.IGNORECASE)

def _nearest_day(pos_first5, idx):
    return min(range(5), key=lambda k: abs(idx - pos_first5[k]))

def detect_fixed(window_lines, pos_first5):
    """
    For each 'Fixed' / 'Fixed Daily' match, map the **center** of the token
    to the nearest date-start column (Mon..Fri). This prevents left-edge bleed
    into Monday when the word starts a bit early.
    """
    flags = [False]*5
    for s in window_lines:
        for m in FIX_RE.finditer(s):
            center = m.start() + (len(m.group(0)) // 2)
            j = _nearest_day(pos_first5, center)
            flags[j] = True
    return ["Fixed" if x else "" for x in flags]

def parse_okular_text(lines: List[str]) -> Dict[str, Dict[str, Any]]:
    rooms: Dict[str, Dict[str, Any]] = {}
    current = None
    pos_all: List[int] | None = None      # current page-section's Mon..Fri starts
    days_start: int | None = None         # left edge of day columns (Mon start)
    wrote_headers_for_room: Dict[str, bool] = {}  # only write once per sheet

    i, n = 0, len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        # New room title
        title = find_room_line(line)
        if title:
            key = room_key_from_title(title)
            rooms[key] = {"title": title, "rows": [], "headers": None}
            wrote_headers_for_room[key] = False
            current = key
            pos_all = None
            days_start = None
            i += 1
            continue

        if not current:
            i += 1; continue

        # (Re)calibrate anchors when we hit ANY header block in this page section.
        # Prefer date positions; if missing, fall back to weekday names.
        positions = date_positions(line)
        if not positions or len(positions) < 5:
            if looks_like_weekday_header(line):
                positions = dayname_positions(line)
        if positions and len(positions) >= 5:
            pos_all = positions[:5]
            days_start = pos_all[0]
            # stash printable headers ONCE per room (use the first date row we saw)
            if not rooms[current]["headers"]:
                # If this line had dates, build "Mon dd/mm/yyyy" headers; otherwise just day names.
                if DATE_RE.search(line):
                    hdrs = ["Name"] + [f"{DAYS[idx]} {line[positions[idx]:positions[idx+1] if idx+1 < len(line) else None].strip()}"
                                       for idx in range(5)]
                else:
                    hdrs = ["Name"] + DAYS
                rooms[current]["headers"] = hdrs
            i += 1
            continue  # don't treat header lines as data

        # Skip the "Name  Guardian" line
        if "Name" in line and "Guardian" in line:
            i += 1; continue

        # Totals row -> record and close this room section
        if line.strip().lower().startswith("totals"):
            pairs = re.findall(r"(\d+)\s*/\s*(\d+)", line)
            vals = [f"{a}/{b}" for (a,b) in pairs[:5]]
            while len(vals) < 5: vals.append("")
            rooms[current]["rows"].append(["Totals"] + vals)
            i += 1
            # after totals, keep scanning; if another title appears, we’ll start a new sheet
            continue

        # We need anchors before we can parse a child row
        if not (pos_all and days_start is not None):
            i += 1; continue

        # Child row (left segment -> name)
        name = two_token_name(line[:days_start])
        if not name:
            i += 1; continue

        # Build a small window (this + next 2 lines) to catch wraps and the age/contact line
        window = [line]
        if i + 1 < n: window.append(lines[i+1])
        if i + 2 < n: window.append(lines[i+2])

        # Age (from the immediate next line if present)
        age = parse_age(window[1]) if len(window) > 1 else None
        name_age = f"{name} ({age})" if age else name

        # Detect "Fixed" per weekday using nearest date-start
        day_vals = detect_fixed(window, pos_all[:5])
        rooms[current]["rows"].append([name_age] + day_vals)

        # Advance 1, then swallow trailing age/contact lines
        i += 1
        while i < n and is_age_or_contact(lines[i]):
            i += 1

    return rooms

# ---------- ODS writer ----------

# widths tuned for Calc’s pixel mapping
COL_A_CM   = "7.303cm"  # ~320 px
COL_W_CM   = "2.622cm"  # ~111 px
COL_GAP_CM = "0.741cm"  # ~27 px

ROW1_HEIGHT_PT = "29.25pt"  # ~39 px (title row)
ROW_BODY_PT    = "14pt"     # header + all data rows

def write_ods(rooms: Dict[str, Dict[str, Any]], out_path: Path):
    doc = OpenDocumentSpreadsheet()

    # Fonts
    doc.fontfacedecls.addElement(style.FontFace(name="Verdana"))
    doc.fontfacedecls.addElement(style.FontFace(name="Calibri"))

    # Cell styles
    title_cell = style.Style(name="CellTitle", family="table-cell")
    title_cell.addElement(style.TextProperties(fontname="Verdana", fontsize="17pt"))
    title_cell.addElement(style.ParagraphProperties(textalign="center"))

    body_cell = style.Style(name="CellBody", family="table-cell")
    body_cell.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    header_bgborder = style.Style(name="HeaderBGBorder", family="table-cell")
    header_bgborder.addElement(style.TableCellProperties(backgroundcolor="#ededed", border="0.50pt solid #000"))
    header_bgborder.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    body_border = style.Style(name="BodyBorder", family="table-cell")
    body_border.addElement(style.TableCellProperties(border="0.50pt solid #000"))
    body_border.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    doc.automaticstyles.addElement(title_cell)
    doc.automaticstyles.addElement(body_cell)
    doc.automaticstyles.addElement(header_bgborder)
    doc.automaticstyles.addElement(body_border)

    # Row styles
    rowTop  = style.Style(name="RowTop",  family="table-row")
    rowTop.addElement(style.TableRowProperties(rowheight=ROW1_HEIGHT_PT, useoptimalrowheight="false"))
    rowBody = style.Style(name="RowBody", family="table-row")
    rowBody.addElement(style.TableRowProperties(rowheight=ROW_BODY_PT, useoptimalrowheight="false"))
    doc.automaticstyles.addElement(rowTop)
    doc.automaticstyles.addElement(rowBody)

    # Column styles
    colA = style.Style(name="ColA", family="table-column")
    colA.addElement(style.TableColumnProperties(columnwidth=COL_A_CM))
    colW = style.Style(name="ColW", family="table-column")
    colW.addElement(style.TableColumnProperties(columnwidth=COL_W_CM))
    colG = style.Style(name="ColGap", family="table-column")
    colG.addElement(style.TableColumnProperties(columnwidth=COL_GAP_CM))
    doc.automaticstyles.addElement(colA); doc.automaticstyles.addElement(colW); doc.automaticstyles.addElement(colG)

    order = ["Barrang","Bilin","Naatiyn"]
    sheet_keys = [k for k in order if k in rooms] + [k for k in rooms if k not in order]

    for key in sheet_keys:
        data = rooms[key]
        table = Table(name=key)

        # Define columns: A, then (weekday,gap)*5 => A..K
        table.addElement(TableColumn(stylename=colA))
        for _ in range(5):
            table.addElement(TableColumn(stylename=colW))
            table.addElement(TableColumn(stylename=colG))

        # Row 1 — merged title A..K
        tr = TableRow(stylename=rowTop)
        tc = TableCell(valuetype="string", numbercolumnsspanned=11, stylename=title_cell)
        tc.addElement(P(text=data["title"]))
        tr.addElement(tc)
        for _ in range(10): tr.addElement(CoveredTableCell())
        table.addElement(tr)

        # Row 2 — headers: A2 and each weekday merged pair (B+C, D+E, F+G, H+I, J+K)
        tr = TableRow(stylename=rowBody)
        headers = data.get("headers") or (["Name"] + DAYS)

        # A2
        t = TableCell(valuetype="string", stylename=header_bgborder); t.addElement(P(text=headers[0])); tr.addElement(t)
        # Weekdays (style BOTH the anchor and covered cell so the merge is fully boxed)
        for label in headers[1:6]:
            t = TableCell(valuetype="string", numbercolumnsspanned=2, stylename=header_bgborder)
            t.addElement(P(text=label))
            tr.addElement(t)
            tr.addElement(CoveredTableCell(stylename=header_bgborder))
        table.addElement(tr)

        # Rows 3..Totals — every cell A..K bordered; children get "Fixed"; totals show n/d
        for row in data["rows"]:
            tr = TableRow(stylename=rowBody)
            is_totals = (row and row[0] == "Totals")

            # Column A (name or Totals)
            tA = TableCell(valuetype="string", stylename=body_border); tA.addElement(P(text=str(row[0]))); tr.addElement(tA)

            if not is_totals:
                for val in row[1:6]:
                    t1 = TableCell(valuetype="string", stylename=body_border); t1.addElement(P(text=val)); tr.addElement(t1)
                    tr.addElement(TableCell(valuetype="string", stylename=body_border))  # gap (bordered)
            else:
                for frac in row[1:6]:
                    t1 = TableCell(valuetype="string", stylename=body_border); t1.addElement(P(text=str(frac))); tr.addElement(t1)
                    tr.addElement(TableCell(valuetype="string", stylename=body_border))

            table.addElement(tr)

        doc.spreadsheet.addElement(table)

    # exact name (no ".ods" twice)
    doc.save(str(out_path), addsuffix=False)

# ---------- CLI ----------

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
