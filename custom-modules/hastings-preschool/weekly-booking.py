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
    header_written = False  # track if the column header has been written

    with pdfplumber.open(str(pdf_path)) as pdf:
        for table in extract_tables(pdf):
            for row in table:
                # Identify the column‑header row by its second cell being "Name".
                # Keep the very first one; drop repeats that appear on continuation pages.
                second_cell = clean_cell(row[1]) if len(row) > 1 else ""
                is_column_header = second_cell.lower() == "name"

                if is_column_header:
                    if header_written:
                        continue  # skip duplicate header row
                    header_written = True

                # Write the row to the sheet
                for col_idx, cell in enumerate(row, start=1):
                    ws.cell(current_row, col_idx, clean_cell(cell))
                current_row += 1

    wb.save(out_path)
    return out_path
