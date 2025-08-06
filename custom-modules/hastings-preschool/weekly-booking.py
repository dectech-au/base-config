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
import re
_illegal = re.compile(r"[
