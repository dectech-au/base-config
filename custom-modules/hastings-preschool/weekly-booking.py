#!/usr/bin/env python3
#/etc/nixos/custom-modules/hastings-preschool/weekly-booking.py
"""
pdf2spreadsheet.py — Hastings Preschool weekly roster converter
===============================================================

Improvements in this pass
-------------------------
* **No hard‑coded filenames** — if you invoke the script with *one* path that
  ends in “.pdf” it will write `<same‑basename>.xlsx` in the same directory.
* **Works from a file manager** — if your desktop entry passes `%f` or `%u`,
  that argument is handled. Launching the entry without a file pops up a
  Zenity chooser so non‑terminal users aren’t left hanging.
* **Overwrites cleanly** — any existing spreadsheet of the same name is
  replaced; no stale data ever survive.

Dependencies (NixOS package names)
----------------------------------
* `python311Packages.pdfplumber`
* `python311Packages.openpyxl`
* `zenity` (for the optional GUI file picker; harmless headless)

Usage patterns
--------------
```bash
# 1. Explicit CLI
weekly-booking.py /path/to/Week8-Bookings.pdf          # writes Week8-Bookings.xlsx

# 2. From your .desktop entry — right‑click a PDF → “Convert Weekly Bookings”
Exec=/home/tim/.local/bin/weekly-booking.py %f           # %f supplies the PDF
```

Code
----
```python
import sys
import re
import pathlib
import subprocess
import shutil
from typing import Iterator, List, Tuple

import pdfplumber
from openpyxl import Workbook
from openpyxl.utils import get_column_letter

ILLEGAL = re.compile(r"[\x00-\x1F\x7F-\x9F]")
DAYS    = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def clean(text: str) -> str:
    """Strip control chars and whitespace."""
    return "" if text is None else ILLEGAL.sub("", text).strip()


# ───────────────────────── PDF PARSING ──────────────────────────

def extract_pages(pdf_path: pathlib.Path) -> Iterator[Tuple[str, List[str], List[List[str]]]]:
    """Yield (title, day_headers, rows) for each page in the PDF."""
    with pdfplumber.open(str(pdf_path)) as pdf:
        for page in pdf.pages:
            lines = [l.strip() for l in page.extract_text().splitlines() if l.strip()]
            title = clean(lines[0])
            table = page.extract_tables()[0]
            header_row = table[0]
            day_headers = [clean(c.replace("\n", " ")) for c in header_row[2:]]
            yield title, day_headers, table[1:]


# ───────────────────────── XLSX WRITER ──────────────────────────

def build_workbook(pages) -> Workbook:
    wb = Workbook()
    ws = wb.active
    r = 1  # 1‑based Excel row index

    for title, day_headers, rows in pages:
        # Title row merged across B–M
        ws.cell(r, 2, title)
        ws.merge_cells(start_row=r, start_column=2, end_row=r, end_column=13)
        r += 1

        # Header: blank, Name, Mon, '', Tue, '' …
        header = [None, "Name"]
        for h in day_headers:
            header.extend([h, None])
        header += [None] * (14 - len(header))  # pad to 14 cols
        ws.append(header)
        r += 1

        for raw in rows:
            name_field = clean(raw[0])
            is_totals  = name_field.lower().startswith("totals")
            row = [None, "Totals" if is_totals else name_field]
            for idx in range(len(DAYS)):
                cell_raw = clean(raw[2 + idx] if 2 + idx < len(raw) else "")
                value = cell_raw if is_totals else ("Fixed" if cell_raw.lower().startswith("fixed") else "")
                row.extend([value, None])
            row += [None] * (14 - len(row))
            ws.append(row)
            r += 1

        r += 1  # spacer row

    # Make it print nicely
    for col in range(2, 14):  # B–M
        ws.column_dimensions[get_column_letter(col)].width = 14
    return wb


# ───────────────────────── UX HELPERS ───────────────────────────

def pick_pdf_with_zenity() -> pathlib.Path:
    """Graphical file chooser fallback."""
    if shutil.which("zenity") is None:
        print("Error: no PDF path provided and zenity not available", file=sys.stderr)
        sys.exit(1)
    result = subprocess.run([
        "zenity", "--file-selection", "--title=Select weekly schedule PDF", "--file-filter=PDF files | *.pdf"
    ], capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(0)  # user cancelled
    return pathlib.Path(result.stdout.strip())


# ──────────────────────────── MAIN ──────────────────────────────

def main():
    # Accept 0 or 1 CLI argument.
    if len(sys.argv) > 2:
        print("Usage: weekly-booking.py [schedule.pdf]", file=sys.stderr)
        sys.exit(1)

    pdf_path = pathlib.Path(sys.argv[1]) if len(sys.argv) == 2 else pick_pdf_with_zenity()
    if not pdf_path.exists() or pdf_path.suffix.lower() != ".pdf":
        print(f"Error: {pdf_path} is not a PDF", file=sys.stderr)
        sys.exit(1)

    out_path = pdf_path.with_suffix(".xlsx")
    wb = build_workbook(extract_pages(pdf_path))
    wb.save(out_path)
    print(f"✓ Wrote {out_path}")


if __name__ == "__main__":
    main()
```
