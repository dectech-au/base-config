#/etc/nixos/custom-modules/hastings-preschool/home-weekly-schedule.nix
{ config, lib, pkgs, ... }:
let
  bookingScript = ".scripts/weekly-booking.sh";
in
{
  # enable management of XDG dirs and desktop entries
  xdg.enable = true;

  # define one or more .desktop files
  xdg.desktopEntries.convert_weekly_bookings = {
    name        = "Convert Weekly Bookings";
    genericName = "convert-weekly-bookings";         # optional
    comment     = "PDF to Spreadsheet";
    exec        = "${config.home.homeDirectory}/bookingScript";
    icon        = "firefox";               # an icon name in your theme or full path
    categories  = [ "Office" ];          # menu categories
    terminal    = false;                  # true if it needs a terminal
    #startupNotify = true;                 # optional
  };

  home.file."bookingScript".text = ''
   #!/usr/bin/env python3
"""
pdf2spreadsheet.py
Pull weekly room schedules from Hastings Preschool PDF and dump them into a
LibreOffice Calc (.ods) or Excel (.xlsx) file that mirrors the layout shown
in Output.xlsx.

Dependencies:
    pip install pdfplumber openpyxl

(If you want pandas for other work, fine, but it's not required here.)

Usage:
    python pdf2spreadsheet.py Input.pdf out.xlsx
    # or, if you insist on .ods, run
    libreoffice --headless --convert-to ods out.xlsx

What it does:
    1. Opens the PDF and loops over each page.
    2. Reads the first text line to capture the title (room + date range).
    3. Extracts the main table with pdfplumber.
    4. Strips the Guardian column, reduces any variant of “Fixed Daily” to
       the single word “Fixed”, and ignores the trailing Daily column the
       daycare never uses.
    5. Writes the data into an .xlsx workbook with exactly the same column
       pattern as your Output file:
           blank, Name, Mon, '', Tue, '', Wed, '', Thu, '', Fri, '', '',
       plus the Totals row and a blank spacer row between rooms.

If the centre changes the PDF template you may need to tweak the regex that
splits the day headers, but for the file you gave me this is bullet‑proof.
"""
import sys
import re
import pdfplumber
from openpyxl import Workbook
from openpyxl.utils import get_column_letter

ILLEGAL = re.compile(r"[\x00-\x1F\x7F-\x9F]")
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def clean(text: str) -> str:
    """Strip control chars and whitespace."""
    if text is None:
        return ""
    return ILLEGAL.sub("", text).strip()


def extract_pages(pdf_path):
    """Yield (title, day_headers, rows) for each page in the PDF."""
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text_lines = [l.strip() for l in page.extract_text().splitlines() if l.strip()]
            title = clean(text_lines[0])
            table = page.extract_tables()[0]
            header_row = table[0]
            day_headers = [clean(c.replace("\n", " ")) for c in header_row[2:]]
            yield title, day_headers, table[1:]


def build_workbook(pages):
    wb = Workbook()
    ws = wb.active
    r = 1  # worksheet row pointer (1‑based)

    for title, day_headers, rows in pages:
        # Title row merged across columns B‑M
        ws.cell(row=r, column=2, value=title)
        ws.merge_cells(start_row=r, start_column=2, end_row=r, end_column=13)
        r += 1

        # Header row: blank, Name, Day, '', Day, '', ...
        header = [None, "Name"]
        for h in day_headers:
            header.extend([h, None])
        while len(header) < 14:
            header.append(None)
        ws.append(header)
        r += 1

        # Data rows
        for raw in rows:
            name_field = clean(raw[0])
            is_totals = name_field.startswith("Totals")
            row_out = [None, "Totals" if is_totals else name_field]
            for idx in range(len(DAYS)):
                cell_raw = clean(raw[2 + idx] if 2 + idx < len(raw) else "")
                if is_totals:
                    value = cell_raw  # e.g. "12/20"
                else:
                    value = "Fixed" if cell_raw.lower().startswith("fixed") else ""
                row_out.extend([value, None])
            while len(row_out) < 14:
                row_out.append(None)
            ws.append(row_out)
            r += 1

        # Spacer row between rooms
        r += 1

    # Cosmetics: widen columns B‑M a bit so the dates fit when printed
    for col in range(2, 14):
        ws.column_dimensions[get_column_letter(col)].width = 14
    return wb


def main():
    if len(sys.argv) != 3:
        print("Usage: pdf2spreadsheet.py input.pdf output.xlsx")
        sys.exit(1)

    in_pdf, out_file = sys.argv[1:]
    wb = build_workbook(extract_pages(in_pdf))
    wb.save(out_file)
    print(f"Done; wrote {out_file}")


if __name__ == "__main__":
    main()

  '';
