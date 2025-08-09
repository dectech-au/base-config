#!/usr/bin/env python3
# Parse Hastings weekly PDF by reading the table grid (boxes) via pdfplumber,
# then write a styled ODS via odfpy. No text-column guessing; per-cell read.
# Deps: pdfplumber, odfpy

import sys, re
from pathlib import Path
from typing import List, Tuple, Dict, Any

import pdfplumber
from odf.opendocument import OpenDocumentSpreadsheet
from odf.table import Table, TableRow, TableCell, CoveredTableCell, TableColumn
from odf.text import P
from odf import style

DAYS = ["Mon","Tue","Wed","Thu","Fri"]
FIX_RE = re.compile(r"\bfixed(?:\s+daily)?\b", re.IGNORECASE)
AGE_RE = re.compile(r"(\d+)\s*yrs(?:\s+(\d+)\s*mths)?", re.IGNORECASE)

# ---------- ODS styling ----------
COL_A_CM   = "7.303cm"   # ~320 px
COL_W_CM   = "2.622cm"   # ~111 px
COL_GAP_CM = "0.741cm"   # ~27 px

ROW1_HEIGHT_PT = "29.25pt"  # ~39 px
ROW_BODY_PT    = "14pt"     # header + data

def make_ods_styles(doc):
    doc.fontfacedecls.addElement(style.FontFace(name="Verdana"))
    doc.fontfacedecls.addElement(style.FontFace(name="Calibri"))

    title_cell = style.Style(name="CellTitle", family="table-cell")
    title_cell.addElement(style.TextProperties(fontname="Verdana", fontsize="17pt"))
    title_cell.addElement(style.ParagraphProperties(textalign="center"))

    header_bgborder = style.Style(name="HeaderBGBorder", family="table-cell")
    header_bgborder.addElement(style.TableCellProperties(backgroundcolor="#ededed", border="0.50pt solid #000"))
    header_bgborder.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    body_border = style.Style(name="BodyBorder", family="table-cell")
    body_border.addElement(style.TableCellProperties(border="0.50pt solid #000"))
    body_border.addElement(style.TextProperties(fontname="Calibri", fontsize="10pt"))

    rowTop  = style.Style(name="RowTop",  family="table-row")
    rowTop.addElement(style.TableRowProperties(rowheight=ROW1_HEIGHT_PT, useoptimalrowheight="false"))
    rowBody = style.Style(name="RowBody", family="table-row")
    rowBody.addElement(style.TableRowProperties(rowheight=ROW_BODY_PT, useoptimalrowheight="false"))

    colA = style.Style(name="ColA", family="table-column")
    colA.addElement(style.TableColumnProperties(columnwidth=COL_A_CM))
    colW = style.Style(name="ColW", family="table-column")
    colW.addElement(style.TableColumnProperties(columnwidth=COL_W_CM))
    colG = style.Style(name="ColGap", family="table-column")
    colG.addElement(style.TableColumnProperties(columnwidth=COL_GAP_CM))

    for s in (title_cell, header_bgborder, body_border, rowTop, rowBody, colA, colW, colG):
        doc.automaticstyles.addElement(s)

    return title_cell, header_bgborder, body_border, rowTop, rowBody, colA, colW, colG

# ---------- PDF grid helpers ----------

def v_h_lines(page, min_v_len=100, min_h_len=200):
    """Return significant vertical and horizontal lines."""
    v = []
    h = []
    for ln in page.lines:
        x0, y0, x1, y1 = ln["x0"], ln["y0"], ln["x1"], ln["y1"]
        if abs(x0 - x1) < 0.5 and abs(y1 - y0) >= min_v_len:
            v.append((x0, y0, x1, y1))
        if abs(y0 - y1) < 0.5 and abs(x1 - x0) >= min_h_len:
            h.append((x0, y0, x1, y1))
    # unique-ish x and y by rounding
    vx = sorted(sorted({round(x0,1) for (x0,_,_,_) in v}))
    hy = sorted(sorted({round(y0,1) for (_,y0,_,_) in h}))
    return vx, hy

def text_in_bbox(page, bbox) -> str:
    with page.crop(bbox):
        txt = page.extract_text() or ""
    return " ".join(txt.split())

def words_in_bbox(page, bbox):
    with page.crop(bbox):
        return page.extract_words()

def find_sections(page) -> List[Tuple[float,float,str]]:
    """
    Find table sections on a page: (top_y, bottom_y, room_title).
    Use 'Name Guardian' as top; 'Totals' as bottom; title comes from nearest 'Room,' above.
    """
    words = page.extract_words(extra_attrs=["x0","x1","top","bottom"])
    tops = []
    for w in words:
        if w["text"] == "Name":
            # look for Guardian within same band
            same = [u for u in words if abs(u["top"] - w["top"]) < 3 and u["text"].lower().startswith("guardian")]
            if same:
                tops.append(w["top"])
    tops = sorted(set(round(t,1) for t in tops))
    sections = []
    for i, top in enumerate(tops):
        # bottom: next "Totals" below this top or next top-1
        bottom_cand = None
        totals = [w for w in words if w["text"].lower().startswith("totals") and w["top"] > top]
        if totals:
            bottom_cand = min(t["top"] for t in totals if t["top"] > top)
        if bottom_cand is None:
            # fallback to next section top
            for t in tops:
                if t > top:
                    bottom_cand = t - 5
                    break
        if bottom_cand is None:
            bottom_cand = page.height - 10

        # room title: nearest line with "Room," above top
        title = ""
        lines_txt = (page.extract_text() or "").splitlines()
        for line in lines_txt:
            if "Room," in line:
                # choose the last title before this top by comparing y via search in words
                title = line.strip()
        sections.append((top-4, bottom_cand+6, title))
    return sections

def build_grid_in_section(page, vx, hy, sec_top, sec_bot) -> Tuple[List[float], List[float]]:
    """Pick the grid lines that fall inside the section."""
    ys = [y for y in hy if sec_top-2 <= y <= sec_bot+2]
    # need at least few rows
    xs = vx[:]  # columns are global on page; we'll filter by actual text headers below
    return xs, ys

def header_labels_from_top_rows(page, xs, ys, sec_top) -> Tuple[int,List[int],List[str]]:
    """
    Look in first 2-3 row bands to find which column indices correspond to Mon..Fri.
    Returns: (name_col_index, day_col_indices[5], labels[5])
    """
    labels = []
    idxs = []
    name_idx = 0
    # scan across columns: look at cell text in first data band between ys[0]..ys[1], and next
    max_cols = len(xs)-1
    if len(ys) < 3 or max_cols < 2:
        return 0, [], []
    band = (ys[0], ys[1])
    # Find columns with day names (Mon..Sun); ignore empty
    candidates = {}
    for c in range(max_cols):
        bbox = (xs[c]+0.5, band[0]+0.5, xs[c+1]-0.5, band[1]-0.5)
        t = text_in_bbox(page, bbox)
        if any(d in t for d in ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]) or re.search(r"\d{2}/\d{2}/\d{4}", t):
            candidates[c] = t
    # Heuristic: the first candidate to the right of the biggest empty stretch is Mon.
    # Simpler: locate exact day-name cells in band or next band.
    def find_day_in_rows(day):
        for r in range(2):  # try first two bands
            if r+1 >= len(ys): break
            y0, y1 = ys[r], ys[r+1]
            for c in range(max_cols):
                t = text_in_bbox(page, (xs[c]+0.5, y0+0.5, xs[c+1]-0.5, y1-0.5))
                if day in t:
                    return c, t
        return None

    hits = []
    for d in DAYS:
        f = find_day_in_rows(d)
        if f: hits.append((d, f[0], f[1]))
    if len(hits) >= 3:
        hits.sort(key=lambda x: x[1])
        cols = [h[1] for h in hits]
        # densify to 5 by stepping
        # assume equal spacing; pick 5 consecutive starting from leftmost seen
        start = cols[0]
        step = min(b-a for a,b in zip(cols, cols[1:])) if len(cols)>1 else 1
        days_cols = [start + i*step for i in range(5)]
        days_cols = [c for c in days_cols if c < max_cols]
        # Name column is left of first day col
        name_idx = max(0, days_cols[0]-1)
        # labels: read day name + maybe date from next band
        labels = []
        for i, c in enumerate(days_cols):
            # merge two header bands if necessary
            y0, y1 = ys[0], ys[2] if len(ys) > 2 else ys[1]
            labels.append(text_in_bbox(page, (xs[c]+0.5, y0+0.5, xs[c+1]-0.5, y1-0.5)).replace("  ", " ").strip() or DAYS[i])
        return name_idx, days_cols[:5], labels[:5]
    # fallback naive: try to find 5 columns with dates on second band
    days_cols = []
    band2 = (ys[1], ys[2]) if len(ys)>2 else band
    for c in range(max_cols):
        t = text_in_bbox(page, (xs[c]+0.5, band2[0]+0.5, xs[c+1]-0.5, band2[1]-0.5))
        if re.search(r"\d{2}/\d{2}/\d{4}", t):
            days_cols.append(c)
    days_cols = days_cols[:5]
    if days_cols:
        name_idx = max(0, days_cols[0]-1)
        labels = [DAYS[i] + " " + text_in_bbox(page, (xs[c]+0.5, band2[0]+0.5, xs[c+1]-0.5, band2[1]-0.5)).strip() for i,c in enumerate(days_cols)]
    return name_idx, days_cols, labels

def parse_section(page, xs, ys, labels, name_idx, days_cols) -> Tuple[List[List[str]], List[str]]:
    """
    Return (rows, totals). rows: [ [name(age), Mon..Fri 'Fixed'/''] ... , ['Totals', n/d ...] ]
    """
    rows = []
    max_cols = len(xs)-1
    # data rows start after header bands (assume first 2 bands are header)
    start_row = 2 if len(ys) > 2 else 1
    # find the Totals band by looking for a cell starting with Totals in the name column
    totals_row_idx = None
    for r in range(start_row, len(ys)-1):
        y0, y1 = ys[r], ys[r+1]
        tname = text_in_bbox(page, (xs[name_idx]+0.5, y0+0.5, xs[name_idx+1]-0.5, y1-0.5))
        if tname.strip().lower().startswith("totals"):
            totals_row_idx = r
            break
    if totals_row_idx is None:
        totals_row_idx = len(ys)-2

    # normal child rows
    for r in range(start_row, totals_row_idx):
        y0, y1 = ys[r], ys[r+1]
        cell_text = text_in_bbox(page, (xs[name_idx]+0.5, y0+0.5, xs[name_idx+1]-0.5, y1-0.5))
        if not cell_text.strip():
            continue
        # name is first two tokens; age from any "yrs" line in the same cell
        toks = cell_text.strip().split()
        name = " ".join(toks[:2]) if len(toks)>=2 else toks[0]
        m = AGE_RE.search(cell_text)
        age = None
        if m:
            yy = int(m.group(1)); mm = m.group(2)
            age = f"{yy}y{int(mm)}m" if mm else f"{yy}y"
        name_age = f"{name} ({age})" if age else name

        day_vals = []
        for c in days_cols:
            if c >= max_cols: continue
            t = text_in_bbox(page, (xs[c]+0.5, y0+0.5, xs[c+1]-0.5, y1-0.5))
            day_vals.append("Fixed" if FIX_RE.search(t) else "")
        # ensure five day cells
        day_vals = (day_vals + [""]*5)[:5]
        rows.append([name_age] + day_vals)

    # totals row
    totals = [""]*5
    r = totals_row_idx
    y0, y1 = ys[r], ys[r+1]
    # read fractions in the day columns
    for j, c in enumerate(days_cols[:5]):
        t = text_in_bbox(page, (xs[c]+0.5, y0+0.5, xs[c+1]-0.5, y1-0.5))
        m = re.search(r"(\d+)\s*/\s*(\d+)", t)
        totals[j] = f"{m.group(1)}/{m.group(2)}" if m else ""
    return rows, totals

# ---------- High level PDF -> logical sheets ----------

def pdf_to_sheets(pdf_path: Path) -> Dict[str, Dict[str, Any]]:
    sheets: Dict[str, Dict[str, Any]] = {}
    with pdfplumber.open(str(pdf_path)) as pdf:
        for page in pdf.pages:
            vx, hy = v_h_lines(page)
            if len(vx) < 3 or len(hy) < 3:
                continue
            for (sec_top, sec_bot, title) in find_sections(page):
                xs, ys = build_grid_in_section(page, vx, hy, sec_top, sec_bot)
                if len(xs) < 3 or len(ys) < 4:
                    continue
                name_idx, day_cols, labels = header_labels_from_top_rows(page, xs, ys, sec_top)
                if len(day_cols) < 5:
                    continue
                # Normalize header labels to Mon..Fri + date (strip Sat/Sun if present later)
                labels = [lbl if lbl else d for lbl, d in zip(labels[:5], DAYS)]
                # Determine room key from title
                room = title.split(" Room,", 1)[0].strip() if " Room," in title else "Room"
                sheet = sheets.setdefault(room, {"title": title or room, "headers": None, "rows": []})
                if sheet["headers"] is None:
                    sheet["headers"] = ["Name"] + labels[:5]

                rows, totals = parse_section(page, xs, ys, labels, name_idx, day_cols)
                # append rows and a totals line (ensure only one totals per room at the end)
                sheet["rows"].extend(rows)
                if totals and any(totals):
                    sheet["rows"].append(["Totals"] + totals)
    return sheets

# ---------- ODS writer ----------

def write_ods_from_sheets(sheets: Dict[str, Dict[str, Any]], out_path: Path):
    doc = OpenDocumentSpreadsheet()
    title_cell, header_bgborder, body_border, rowTop, rowBody, colA, colW, colG = make_ods_styles(doc)

    # Order sheets
    order = ["Barrang","Bilin","Naatiyn"]
    sheet_keys = [k for k in order if k in sheets] + [k for k in sheets if k not in order]

    for key in sheet_keys:
        data = sheets[key]
        table = Table(name=key)

        # columns A + (weekday,gap)*5 => A..K
        table.addElement(TableColumn(stylename=colA))
        for _ in range(5):
            table.addElement(TableColumn(stylename=colW))
            table.addElement(TableColumn(stylename=colG))

        # Row 1 — title merged A..K
        tr = TableRow(stylename=rowTop)
        tc = TableCell(valuetype="string", numbercolumnsspanned=11, stylename=title_cell)
        tc.addElement(P(text=data["title"]))
        tr.addElement(tc)
        for _ in range(10): tr.addElement(CoveredTableCell())
        table.addElement(tr)

        # Row 2 — headers (A2 + B:C, D:E, F:G, H:I, J:K) grey + border
        tr = TableRow(stylename=rowBody)
        headers = data.get("headers") or (["Name"] + DAYS)
        # A2
        t = TableCell(valuetype="string", stylename=header_bgborder); t.addElement(P(text=headers[0])); tr.addElement(t)
        # merged weekday pairs
        for label in headers[1:6]:
            t = TableCell(valuetype="string", numbercolumnsspanned=2, stylename=header_bgborder)
            t.addElement(P(text=label))
            tr.addElement(t)
            tr.addElement(CoveredTableCell(stylename=header_bgborder))
        table.addElement(tr)

        # Data rows
        for row in data["rows"]:
            tr = TableRow(stylename=rowBody)
            is_totals = row and row[0] == "Totals"
            # A
            tA = TableCell(valuetype="string", stylename=body_border); tA.addElement(P(text=str(row[0]))); tr.addElement(tA)
            # Mon..Fri + gaps (bordered)
            for val in row[1:6]:
                t1 = TableCell(valuetype="string", stylename=body_border); t1.addElement(P(text=str(val))); tr.addElement(t1)
                tr.addElement(TableCell(valuetype="string", stylename=body_border))
            table.addElement(tr)

        doc.spreadsheet.addElement(table)

    doc.save(str(out_path), addsuffix=False)

# ---------- CLI ----------

def main():
    if len(sys.argv) not in (2,3):
        print("Usage: pdf_to_ods_boxes.py input.pdf [output.ods]", file=sys.stderr)
        sys.exit(1)
    pdf_path = Path(sys.argv[1]).expanduser()
    if not pdf_path.exists():
        print(f"No such file: {pdf_path}", file=sys.stderr); sys.exit(1)
    out = Path(sys.argv[2]).expanduser() if len(sys.argv)==3 else pdf_path.with_name("output.ods")

    sheets = pdf_to_sheets(pdf_path)
    if not sheets:
        print("No sheets parsed — the table grid may not have been detected.", file=sys.stderr)
        sys.exit(2)
    write_ods_from_sheets(sheets, out)
    print(f"OK: wrote {out}")

if __name__ == "__main__":
    main()
