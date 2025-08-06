#!/usr/bin/env python3
"""
pdf2xlsx – single‑sheet converter
=================================
Flatten the Hastings Preschool roster PDF into **one Excel sheet**.

Behaviour changes
-----------------
* All PDF pages append into the *same* worksheet ("Roster"), so printing is
  easy.
* The first row of each subsequent page is skipped because it repeats the
  column headers that page 1 already has.
* Control characters that break XML are stripped as before.

This is still a dumb lift‑and‑shift; we’re just concatenating tables instead
of making a sheet per page. Once this runs end‑to‑end we can add smarter
room‑detection.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterator, List

import pdfplumber
from openpyxl import Workbook

_illegal = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")


# ──────────────────────── HELPERS ─────────────────────────────

def extract_tables(pdf: pdfplumber.pdf.PDF) -> Iterator[List[List[str]]]:
    for page in pdf.pages:
        tables = page.extract_tables()
        if tables:
            yield tables[0]


def clean_cell(cell) -> str:
    return _illegal.sub("", "" if cell is None else str(cell))


# ──────────────────────── MAIN LOGIC ─────────────────────────

def pdf_to_single_sheet(pdf_path: Path) -> Path:
    out_path = pdf_path.with_suffix(".xlsx")

    wb = Workbook()
    ws = wb.active
    ws.title = "Roster"

    current_row = 1
    first_table = True

    with pdfplumber.open(str(pdf_path)) as pdf:
        for table in extract_tables(pdf):
            start_index = 0 if first_table else 1  # skip repeated header
            for row in table[start_index:]:
                for col_idx, cell in enumerate(row, start=1):
                    ws.cell(current_row, col_idx, clean_cell(cell))
                current_row += 1
            first_table = False

    wb.save(out_path)
    return out_path


def main():
    if len(sys.argv) != 2:
        print("Usage: pdf2xlsx.py <schedule.pdf>", file=sys.stderr)
        sys.exit(1)

    pdf_path = Path(sys.argv[1]).expanduser()
    if not (pdf_path.exists() and pdf_path.suffix.lower() == ".pdf"):
        print("Error: provide a valid .pdf file", file=sys.stderr)
        sys.exit(1)

    out_file = pdf_to_single_sheet(pdf_path)
    print(f"✓ Wrote {out_file}")


if __name__ == "__main__":
    main()
