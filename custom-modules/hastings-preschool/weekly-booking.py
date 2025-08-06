#!/usr/bin/env python3
"""
pdf2xlsx – dumb one‑to‑one converter
====================================
Grab the *first* table on every page of a PDF and dump it into an Excel
workbook—one sheet per page. No formatting, no data cleanup beyond stripping
XML‑illegal control characters that would make openpyxl puke.

Usage
-----
```bash
python3 pdf2xlsx.py schedule.pdf       # writes schedule.xlsx next to the PDF
```
(Your KDE service‑menu passes the PDF path in `%f`, quoted.)

Dependencies (NixOS names)
--------------------------
* `python311Packages.pdfplumber`
* `python311Packages.openpyxl`  (tests disabled in your Nix expr → no torch)
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterator, List

import pdfplumber
from openpyxl import Workbook

# Regex that nukes control chars disallowed in XML 1.0
_illegal = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")


# ──────────────────────── CORE LOGIC ───────────────────────────

def extract_tables(pdf: pdfplumber.pdf.PDF) -> Iterator[List[List[str]]]:
    """Yield the first table from each page of *pdf* (if present)."""
    for page in pdf.pages:
        tbls = page.extract_tables()
        if tbls:
            yield tbls[0]


def dump_to_sheet(ws, table: List[List[str]]):
    """Write *table* (a list of rows) to *ws*, sanitising cell content."""
    for r_idx, row in enumerate(table, start=1):
        for c_idx, cell in enumerate(row, start=1):
            val = "" if cell is None else _illegal.sub("", str(cell))
            ws.cell(r_idx, c_idx, val)


def pdf_to_xlsx(pdf_path: Path) -> Path:
    out_path = pdf_path.with_suffix(".xlsx")
    wb = Workbook()
    wb.remove(wb.active)  # start fresh

    with pdfplumber.open(str(pdf_path)) as pdf:
        for page_num, table in enumerate(extract_tables(pdf), start=1):
            ws = wb.create_sheet(f"Page{page_num}")
            dump_to_sheet(ws, table)

    wb.save(out_path)
    return out_path


# ─────────────────────────── CLI ───────────────────────────────

def main():
    if len(sys.argv) != 2:
        print("Usage: pdf2xlsx.py <schedule.pdf>", file=sys.stderr)
        sys.exit(1)

    pdf_path = Path(sys.argv[1]).expanduser()
    if not (pdf_path.exists() and pdf_path.suffix.lower() == ".pdf"):
        print("Error: provide a valid .pdf file", file=sys.stderr)
        sys.exit(1)

    out_file = pdf_to_xlsx(pdf_path)
    print(f"✓ Wrote {out_file}")


if __name__ == "__main__":
    main()
