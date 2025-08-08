#!/usr/bin/env python3
# okular_txt_to_ods.py
# Convert Okular "Export as Plain Text" -> output.ods (one sheet per room)
# Deps: python3 + odfpy

import sys, re
from pathlib import Path
from typing import List, Dict, Any, Tuple

from odf.opendocument import OpenDocumentSpreadsheet
from odf.table import Table, TableRow, TableCell, CoveredTableCell, TableColumn
from odf.text import P
from odf import style

# ---------- regex & helpers ----------

DAYS       = ["Mon","Tue","Wed","Thu","Fri"]  # weekend removed
ROOM_LINE  = re.compile(r"(.+ Room, .+ - .+)$")
DATE_RE    = re.compile(r"\d{2}/\d{2}/\d{4}")
FIX_RE     = re.compile(r"\bfixed(?:\s+daily)?\b", re.IGNORECASE)

def find_room_title(line: str) -> str | None:
    m = ROOM_LINE.search(line)
    return m.group(1).strip() if m else None

def is_weekday_header(line: str) -> bool:
    return all(d in line for d in DAYS)

def date_positions(line: str) -> List[int]:
    return [m.start() for m in DATE_RE.finditer(line)]

def dayname_positions(line: str) -> List[int] | None:
    pos, cur = [], 0
    for name in DAYS:
        idx = line.find(name, cur)
        if idx == -1: return None
        pos.append(idx)
        cur = idx + 1
    return pos

def is_age_or_contact(line: str) -> bool:
    s = line.strip()
    return bool(re.search(r"\b\d+\s+yrs", s)) or bool(re.search(r"\b[MPHW]\s*:\s*\S", s)) or s == ""

def parse_age(line: str) -> str | None:
    m = re.search(r"(\d+)\s*yrs(?:\s+(\d+)\s*mths)?", line)
    if not m: return None
    yy = int(m.group(1)); mm = m.group(2)
    return f"{yy}y{int(mm)}m" if mm else f"{yy}y"

def two_token_name(seg: str) -> str:
    toks = seg.strip().split()
    return " ".join(toks[:2]) if toks else ""

# ---------- section calibration by “Fixed Daily” positions ----------

def cluster_positions(positions: List[int], tol: int = 3) -> List[Tuple[int,int]]:
    """
    Greedy cluster of sorted positions. Returns list of (center, count),
    where center is rounded mean of the cluster.
    """
    if not positions: return []
    positions.sort()
    clusters: List[List[int]] = [[positions[0]]]
    for p in positions[1:]:
        if p - clusters[-1][-1] <= tol:
            clusters[-1].append(p)
        else:
            clusters.append([p])
    result: List[Tuple[int,int]] = []
    for cl in clusters:
        center = int(round(sum(cl) / len(cl)))
        result.append((center, len(cl)))
    return result

def calibrate_anchors_by_fixed(lines: List[str], start: int, stop_pred) -> Tuple[List[int], int]:
    """
    From `start`, scan down until stop_pred(line) is True.
    Wait until we see the first FIX_RE, then record ALL FIX_RE start indices until stop.
    Return (anchors[5], stop_index).
    If fewer than 5 anchors found, return empty list; caller can fallback.
    """
    i = start
    n = len(lines)
    started = False
    positions: List[int] = []
    while i < n and not stop_pred(lines[i]):
        line = lines[i]
        matches = list(FIX_RE.finditer(line))
        if matches:
            started = True
            positions.extend(m.start() for m in matches)
        i += 1
    # Choose top-5 most frequent clusters (then left->right)
    centers = cluster_positions(positions, tol=3)
    if len(centers) >= 5:
        # pick by frequency then sort by center
        top = sorted(centers, key=lambda x: (-x[1], x[0]))[:5]
        anchors = sorted(c for c, _ in top)
    else:
        anchors = []
    return anchors, i  # i is at the stop line index

# ---------- parsing into room -> rows ----------

def parse_okular_text(lines: List[str]) -> Dict[str, Dict[str, Any]]:
    rooms: Dict[str, Dict[str, Any]] = {}
    i, n = 0, len(lines)
    current: str | None = None

    while i < n:
        line = lines[i].rstrip("\n")

        # Room title opens a new sheet
        title = find_room_title(line)
        if title:
            key = title.split(" Room,", 1)[0].strip()
            rooms[key] = {"title": title, "rows": [], "headers": None}
            current = key
            i += 1
            continue

        if not current:
            i += 1; continue

        # A header starts a SECTION
        header_pos = date_positions(line)
        header_kind = "dates" if header_pos and len(header_pos) >= 5 else None
        if not header_kind and is_weekday_header(line):
            header_pos = dayname_positions(line)
            header_kind = "names" if header_pos and len(header_pos) >= 5 else None

        if header_kind:
            # For the very first header we see for this room, build printable headers
            if rooms[current]["headers"] is None:
                if header_kind == "dates":
                    hdrs = ["Name"] + [f"{DAYS[idx]} {line[header_pos[idx]: header_pos[idx+1] if idx+1 < len(line) else None].strip()}"
                                       for idx in range(5)]
                else:
                    hdrs = ["Name"] + DAYS
                rooms[current]["headers"] = hdrs

            # Determine section stop: next header/room/totals/EOF
            def is_section_stop(L: str) -> bool:
                return (find_room_title(L) is not None
                        or L.strip().lower().startswith("totals")
                        or is_weekday_header(L)
                        or (bool(DATE_RE.search(L)) and len(date_positions(L)) >= 5))

            # Calibrate anchors for THIS section using “Fixed Daily” positions
            anchors, stop_idx = calibrate_anchors_by_fixed(lines, i+1, is_section_stop)

            # If calibration failed (rare), fallback to the header’s own column starts
            if not anchors:
                anchors = header_pos[:5]

            # days_start for name slicing (left of Monday column)
            days_start = min(anchors) if anchors else header_pos[0]

            # Now parse the section content line-by-line until stop_idx
            j = i + 1
            while j < stop_idx:
                L = lines[j].rstrip("\n")

                # Totals inside this section
                if L.strip().lower().startswith("totals"):
                    pairs = re.findall(r"(\d+)\s*/\s*(\d+)", L)
                    vals = [f"{a}/{b}" for (a,b) in pairs[:5]]
                    while len(vals) < 5: vals.append("")
                    rooms[current]["rows"].append(["Totals"] + vals)
                    j += 1
                    continue

                # Skip the 'Name  Guardian' line
                if "Name" in L and "Guardian" in L:
                    j += 1; continue

                # Child row?
                name = two_token_name(L[:days_start])
                if not name:
                    j += 1; continue

                # Build a small lookahead window (this + next two) for wrapped text
                window = [L]
                if j + 1 < stop_idx: window.append(lines[j+1])
                if j + 2 < stop_idx: window.append(lines[j+2])

                # Age from the immediate next line if present
                age = parse_age(window[1]) if len(window) > 1 else None
                name_age = f"{name} ({age})" if age else name

                # Decide Fixed per weekday using **match center** mapped to nearest anchor
                flags = [False]*5
                for W in window:
                    for m in FIX_RE.finditer(W):
                        center = m.start() + (len(m.group(0)) // 2)
                        # nearest anchor
                        idx = min(range(5), key=lambda k: abs(center - anchors[k]))
                        flags[idx] = True
                row = [name_age] + ["Fixed" if f else "" for f in flags]
                rooms[current]["rows"].append(row)

                # Move to next candidate line; swallow trailing age/contact lines
                j += 1
                while j < stop_idx and is_age_or_contact(lines[j]):
                    j += 1

            # Continue from the stop line (which is the next header/totals/room or EOF)
            i = stop_idx
            continue

        # Any other line outside a section: skip
        i += 1

    return rooms

# ---------- ODS writer ----------

# widths tuned to your Calc pixels
COL_A_CM   = "7.303cm"  # ~320 px
COL_W_CM   = "2.622cm"  # ~111 px
COL_GAP_CM = "0.741cm"  # ~27 px

ROW1_HEIGHT_PT = "29.25pt"  # ~39 px (title)
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

    header_bgborder = style.Style(name="HeaderBGBorder", family="table-cell")
    header_bgborder.addElement(style.TableCellProperties(backgroundcolor="#ededed", border="0.50pt solid #000"))
    header_bgborder.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    body_border = style.Style(name="BodyBorder", family="table-cell")
    body_border.addElement(style.TableCellProperties(border="0.50pt solid #000"))
    body_border.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    doc.automaticstyles.addElement(title_cell)
    doc.automaticstyles.addElement(header_bgborder)
    doc.automaticstyles.addElement(body_border)

    # Row styles
    rowTop  = style.Style(name="RowTop",  family="table-row")
    rowTop.addElement(style.TableRowProperties(rowheight=ROW1_HEIGHT_PT, useoptimalrowheight="false"))
    rowBody = style.Style(name="RowBody", family="table-row")
    rowBody.addElement(style.TableRowProperties(rowheight=ROW_BODY_PT, useoptimalrowheight="false"))
    doc.automaticstyles.addElement(rowTop); doc.automaticstyles.addElement(rowBody)

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

        # Columns: A + (weekday,gap)*5 => A..K
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
        # merged weekday pairs (style anchor + covered so borders fully enclose)
        for label in headers[1:6]:
            t = TableCell(valuetype="string", numbercolumnsspanned=2, stylename=header_bgborder)
            t.addElement(P(text=label))
            tr.addElement(t)
            tr.addElement(CoveredTableCell(stylename=header_bgborder))
        table.addElement(tr)

        # Rows 3..Totals — border every cell A..K
        for row in data["rows"]:
            tr = TableRow(stylename=rowBody)
            is_totals = (row and row[0] == "Totals")

            # A
            tA = TableCell(valuetype="string", stylename=body_border); tA.addElement(P(text=str(row[0]))); tr.addElement(tA)

            if not is_totals:
                for val in row[1:6]:
                    t1 = TableCell(valuetype="string", stylename=body_border); t1.addElement(P(text=val)); tr.addElement(t1)
                    tr.addElement(TableCell(valuetype="string", stylename=body_border))  # gap
            else:
                for frac in row[1:6]:
                    t1 = TableCell(valuetype="string", stylename=body_border); t1.addElement(P(text=str(frac))); tr.addElement(t1)
                    tr.addElement(TableCell(valuetype="string", stylename=body_border))
            table.addElement(tr)

        doc.spreadsheet.addElement(table)

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
