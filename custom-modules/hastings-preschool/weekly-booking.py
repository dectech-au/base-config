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
    """Yield the first table per page using lattice mode, fallback to stream."""
    for page in pdf.pages:
        # Try lattice (line‑based) detection first – works with bordered grids
        tables = page.extract_tables({
            "vertical_strategy": "lines",
            "horizontal_strategy": "lines",
        })
        if not tables:
            # Fallback to default stream mode
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
    header_written = False  # we only want one column‑header row

    with pdfplumber.open(str(pdf_path)) as pdf:
        for table in extract_tables(pdf):
            for row in table:
                # Skip empty or whitespace‑only rows (PDF junk lines)
                if not any(cell and str(cell).strip() for cell in row):
                    continue

                # Detect the real column header: second cell == "Name" (case‑insensitive)
                second = clean_cell(row[1]) if len(row) >= 2 else ""
                is_col_header = second.lower() == "name"
                if is_col_header and header_written:
                    continue  # duplicate header on continuation page
                if is_col_header:
                    header_written = True

                # Write row data
                for col_idx, cell in enumerate(row, start=1):
                    ws.cell(current_row, col_idx, clean_cell(cell))
                current_row += 1

    # If we somehow never wrote anything, raise an error for easier debugging
    if current_row == 1:
        raise RuntimeError("No tables found in PDF – check file format")

    wb.save(out_path)
    return out_path
