#!/usr/bin/env python3
# okular_txt_to_ods.py
# Parse Okular "Export as Plain Text" and produce output.ods with one sheet per room.
# No third-party Python deps. Requires: ssconvert (from gnumeric) on PATH.

import sys, re, csv, tempfile, subprocess
from pathlib import Path

DAYS = ["Mon","Tue","Wed","Thu","Fri"]  # drop Sat/Sun entirely

ROOM_RE = re.compile(r"([A-Za-z/\- ]+ Room),")
DATE_RE = re.compile(r"\d{2}/\d{2}/\d{4}")

def is_room_line(line: str):
    m = ROOM_RE.search(line)
    return m.group(1).strip() if m else None

def find_date_positions(line: str):
    # absolute positions of dd/mm/yyyy tokens -> day column anchors
    return [m.start() for m in DATE_RE.finditer(line)]

def is_age_or_contact(line: str):
    s = line.strip()
    return bool(re.search(r"\b\d+\s+yrs", s)) or bool(re.search(r"\b[MPHW]\s*:\s*\S", s)) or s == ""

def parse_age(line: str) -> str | None:
    m = re.search(r"(\d+)\s*yrs(?:\s+(\d+)\s*mths)?", line)
    if not m: return None
    y = int(m.group(1))
    mm = m.group(2)
    if mm: return f"{y}y{int(mm)}m"
    return f"{y}y"

def split_name_guardian(seg: str):
    # Prefer double-space split; fallback heuristic
    m2 = list(re.finditer(r"\s{2,}", seg))
    for r in m2:
        left = seg[:r.start()].rstrip()
        right = seg[r.end():].strip()
        if left and right and not right.lower().startswith("guardian"):
            return left, right
    toks = seg.split()
    if len(toks) >= 3:
        return " ".join(toks[:2]), " ".join(toks[2:])
    return None, None

def normalize_room_key(room_header: str) -> str:
    # "Barrang Room" -> "Barrang"; "Bilin Room" -> "Bilin"; handle slashes/spaces
    base = room_header.replace(" Room","").strip()
    base = base.split(",")[0].strip()
    return re.sub(r"[^A-Za-z0-9]+", "_", base)

def parse_okular_text(lines: list[str]):
    """
    Returns: dict(room_key -> {"title": room_title, "rows": [ [Name(Age), Mon..Fri], ..., ["Totals", ..] ]})
    """
    rooms = {}
    current_room = None
    days_pos = None
    days_start = None

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        # Room header?
        room_title = is_room_line(line)
        if room_title:
            key = normalize_room_key(room_title)
            rooms[key] = {"title": room_title, "rows": []}
            current_room = key
            days_pos = None
            days_start = None
            i += 1
            continue

        if current_room:
            # detect the date row -> gives stable column anchors
            pos = find_date_positions(line)
            if pos and len(pos) >= 5:
                days_pos = pos[:5]  # Mon..Fri only
                days_start = days_pos[0]
                i += 1
                continue

        if not (current_room and days_pos):
            i += 1
            continue

        # Skip duplicated "Name  Guardian" header rows
        if "Name" in line and "Guardian" in line:
            i += 1
            continue

        # Totals row
        if line.strip().lower().startswith("totals"):
            # Build slices for each weekday using this line only
            ends = days_pos[1:] + [len(line)]
            vals = [line[s:e].strip() for s, e in zip(days_pos, ends)]
            # keep "12/20" as-is per column order Mon..Fri
            rows = rooms[current_room]["rows"]
            rows.append(["Totals"] + vals)
            i += 1
            continue

        # Skip standalone age/contact lines in the main loop; we’ll read age explicitly
        if is_age_or_contact(line):
            i += 1
            continue

        # Candidate data row: Name + Guardian + maybe some "Fixed Daily" flags inline
        # We need the guardian split boundary: find "Guardian" in the most recent header line above.
        # Heuristic: the "Guardian" text was on a previous header row; but here we use the day start as split end.
        # Choose a mid split based on multiple spaces before days start.
        seg = line[:days_start]
        name, guardian = split_name_guardian(seg)
        if not (name and guardian):
            i += 1
            continue

        # Pull age from the very next line (Okular dump format)
        age = None
        if i + 1 < n:
            age = parse_age(lines[i+1])
        name_age = f"{name} ({age})" if age else name

        # Collect day flags from this line and the next two lines
        look = [line]
        if i + 1 < n: look.append(lines[i+1])
        if i + 2 < n: look.append(lines[i+2])
        ends = days_pos[1:] + [max(len(L) for L in look)]
        day_vals = [
            ("Fixed" if any("Fixed" in L[s:e] for L in look) else "")
            for s, e in zip(days_pos, ends)
        ]

        rooms[current_room]["rows"].append([name_age] + day_vals)

        # advance past this row and swallow following age/contact lines
        i += 1
        while i < n and is_age_or_contact(lines[i]):
            i += 1
        continue

        # default
        i += 1

    return rooms

def write_room_csvs(rooms: dict, outdir: Path) -> list[Path]:
    paths = []
    for key, data in rooms.items():
        csv_path = outdir / f"{key}.csv"
        with csv_path.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            # Header: Name(Age), Mon..Fri
            w.writerow(["Name"] + DAYS)
            for row in data["rows"]:
                if row and row[0] == "Totals":
                    # Totals row: keep one cell label and 5 day fractions
                    w.writerow(["Totals"] + row[1:6])
                else:
                    # Normal row: [Name(Age)] + 5 day cells
                    w.writerow([row[0]] + row[1:6])
        paths.append(csv_path)
    return paths

def merge_to_ods(csv_paths: list[Path], sheet_order: list[str], out_ods: Path):
    # Use ssconvert --merge-to to build a multi-sheet ODS.
    # Name the sheets by CSV basenames (so order them by desired sheet_order).
    ordered = []
    name_map = {p.stem: p for p in csv_paths}
    for name in sheet_order:
        if name in name_map:
            ordered.append(str(name_map[name]))
    if not ordered:
        ordered = [str(p) for p in csv_paths]

    cmd = ["ssconvert", "--merge-to", str(out_ods)] + ordered
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def main():
    if len(sys.argv) not in (2,3):
        print("Usage: okular_txt_to_ods.py input.txt [output.ods]", file=sys.stderr)
        sys.exit(1)
    inp = Path(sys.argv[1]).expanduser()
    if not inp.exists():
        print(f"No such file: {inp}", file=sys.stderr); sys.exit(1)
    out = Path(sys.argv[2]).expanduser() if len(sys.argv)==3 else inp.with_name("output.ods")

    lines = inp.read_text(encoding="utf-8", errors="replace").splitlines()
    rooms = parse_okular_text(lines)
    if not rooms:
        print("No rooms parsed. Is this an Okular plain-text export?", file=sys.stderr)
        sys.exit(2)

    with tempfile.TemporaryDirectory() as tmpd:
        csvs = write_room_csvs(rooms, Path(tmpd))
        # Prefer Barrang/Bilin/Naatiyn order if present
        preferred = ["Barrang", "Bilin", "Naatiyn"]
        merge_to_ods(csvs, preferred, out)

    print(f"✓ Wrote {out}")

if __name__ == "__main__":
    main()
