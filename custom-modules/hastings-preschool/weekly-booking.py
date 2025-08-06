#!/usr/bin/env python3
"""
pdf2xlsx – dumb one‑to‑one converter
====================================
Take **any** PDF you hand it, grab the first table on each page with
`pdfplumber`, and dump the rows into an Excel workbook. No fancy cleaning, no
merging; just a straight lift‑and‑shift so we can confirm the tool‑chain works
(end‑to‑end) before adding smarts later.

Usage
-----
```bash
python3 pdf2xlsx.py schedule.pdf               # writes schedule.xlsx
```
(Or launch via your KF6 context‑menu once that calls the same file.)

Dependencies (NixOS names)
--------------------------
* `python311Packages.pdfplumber`
* `python311Packages.openpyxl`

We’ll layer on column tweaks and data cleaning once this basic flow is proven.
"""
from __future__ import annotations

import sys
from pathlib import Path

import pdfplumber
from openpyxl import Workbook


def pdf_to_xlsx(pdf_path: Path) -> Path:
    """Extract the first table from each page and write to `*.xlsx`."""
    out_path = pdf_path.with_suffix(".xlsx")
    wb = Workbook()
    wb.remove(wb.active)  # start with a clean workbook

    with pdfplumber.open(str(pdf_path)) as pdf:
        for page_num, page in enumerate(pdf.pages, start=1):
            tables = page.extract_tables()
            if not tables:
                continue  # no table on this page
            ws = wb.create_sheet(f"Page{page_num}")
            for r_idx, row in enumerate(tables[0], start=1):
                for c_idx, cell in enumerate(row, start=1):
                    ws.cell(r_idx, c_idx, cell)

    wb.save(out_path)
    return out_path


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: pdf2xlsx.py schedule.pdf", file=sys.stderr)
        sys.exit(1)

    pdf_path = Path(sys.argv[1]).expanduser()
    if not pdf_path.exists() or pdf_path.suffix.lower() != ".pdf":
        print("Error: provide a valid .pdf file", file=sys.stderr)
        sys.exit(1)

    out = pdf_to_xlsx(pdf_path)
    print(f"✓ Wrote {out}")


if __name__ == "__main__":
    main()
