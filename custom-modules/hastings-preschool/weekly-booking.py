#!/usr/bin/env python3
"""
Hastings Preschool – weekly roster converter
===========================================
Convert the centre’s PDF schedule to a matching `.xlsx`. Works from CLI or a
KF6 service‑menu entry.

* Supply any `*.pdf`; the script writes `<same‑basename>.xlsx` next to it.
* If launched with no args (double‑click or menu with no selection) it pops up
  a Zenity chooser.

Dependencies: `pdfplumber`, `openpyxl`, `zenity` (GUI only).
"""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterator, List, Tuple

import pdfplumber
from openpyxl import Workbook
from openpyxl.utils import get_column_letter

ILLEGAL = re.compile(r"[\x00-\x1F\x7F-\x9F]")
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def clean(text: str | None) -> str:
    """Return *text* without control chars or surrounding spaces."""
    return "" if text is None else ILLEGAL.sub("", text).strip()


# ───────────────────── PDF PARSING ─────────────────────────────

def extract_pages(pdf_path: Path) -> Iterator[Tuple[str, List[str], List[List[str]]]]:
    """Yield (title, day_headers, rows) for each page in *pdf_path*."""
    with pdfplumber.open(str(pdf_path)) as pdf:
        for page in pdf.pages:
            lines = [l.strip() for l in page.extract_text().splitlines() if l.strip()]
            if not lines:
                continue
            title = clean(lines[0])
            table = page.extract_tables()[0]
            header_row = table[0]
            day_headers = [clean(c.replace("\n", " ")) for c in header_row[2:]]
            yield title, day_headers, table[1:]


# ───────────────────── XLSX WRITER ─────────────────────────────

def build_workbook(pages: Iterator[Tuple[str, List[str], List[List[str]]]]) -> Workbook:
    wb = Workbook()
    ws = wb.active
    row_idx = 1

    for title, day_headers, rows in pages:
        ws.cell(row_idx, 2, title)
        ws.merge_cells(start_row=row_idx, start_column=2, end_row=row_idx, end_column=13)
        row_idx += 1

        header = [None, "Name"]
        for h in day_headers:
            header.extend([h, None])
        header.extend([None] * (14 - len(header)))
        ws.append(header)
        row_idx += 1

        for raw in rows:
            name = clean(raw[0])
            is_totals = name.lower().startswith("totals")
            out = [None, "Totals" if is_totals else name]
            for idx in range(len(DAYS)):
                cell_raw = clean(raw[2 + idx] if 2 + idx < len(raw) else "")
                value = cell_raw if is_totals else ("Fixed" if cell_raw.lower().startswith("fixed") else "")
                out.extend([value, None])
            out.extend([None] * (14 - len(out)))
            ws.append(out)
            row_idx += 1

        row_idx += 1  # spacer

    for col in range(2, 14):
        ws.column_dimensions[get_column_letter(col)].width = 14
    return wb


# ───────────────────── UX HELPERS ──────────────────────────────

def zenity_pick_pdf() -> Path:
    if shutil.which("zenity") is None:
        print("Error: no PDF supplied and zenity not installed", file=sys.stderr)
        sys.exit(1)
    proc = subprocess.run([
        "zenity", "--file-selection", "--title=Select weekly schedule PDF",
        "--file-filter=PDF files | *.pdf"
    ], capture_output=True, text=True)
    if proc.returncode != 0:
        sys.exit(0)  # user cancelled
    return Path(proc.stdout.strip())


# ───────────────────────── MAIN ────────────────────────────────

def main() -> None:
    if len(sys.argv) > 2:
        print("Usage: weekly-booking.py [schedule.pdf]", file=sys.stderr)
        sys.exit(1)

    pdf_path = Path(sys.argv[1]) if len(sys.argv) == 2 else zenity_pick_pdf()
    if not pdf_path.exists() or pdf_path.suffix.lower() != ".pdf":
        print(f"Error: {pdf_path} is not a valid PDF", file=sys.stderr)
        sys.exit(1)

    out_path = pdf_path.with_suffix(".xlsx")
    wb = build_workbook(extract_pages(pdf_path))
    wb.save(out_path)
    print(f"✓ Wrote {out_path}")


if __name__ == "__main__":
    main()
