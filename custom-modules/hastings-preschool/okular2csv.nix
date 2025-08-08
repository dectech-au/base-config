#/etc/nixos/custom-modules/hastings-preschool/okular2csv.nix
{ config, pkgs, ... }:
{
  home.file.".local/bin/okular2ods.py" = {
    executable = true;
    text = ''
#!/usr/bin/env python3
import sys, re, csv
from pathlib import Path

DAYS = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

def is_room_line(line: str):
    m = re.search(r"([A-Za-z/\- ]+ Room),", line)
    return m.group(1).strip() if m else None

def find_date_positions(line: str):
    # positions of dd/mm/yyyy; we use these as day column anchors
    return [m.start() for m in re.finditer(r"\d{2}/\d{2}/\d{4}", line)]

def is_age_or_contact(line: str):
    s = line.strip()
    return bool(re.search(r"\b\d+\s+yrs", s)) or bool(re.search(r"\b[MPHW]\s*:\s*\S", s)) or s == ""

def split_name_guardian(seg: str):
    # Prefer a double-space split; fallback to "first two tokens = child"
    m2 = list(re.finditer(r"\s{2,}", seg))
    for r in m2:
        left = seg[:r.start()].rstrip()
        right = seg[r.end():].strip()
        if left and right and not right.startswith("Fix"):
            return left, right
    toks = seg.split()
    if len(toks) >= 3:
        return " ".join(toks[:2]), " ".join(toks[2:])
    return None, None

def parse_lines(lines):
    recs = []
    room = None
    days_pos = None
    days_start = None

    i = 0
    n = len(lines)
    while i < n:
        line = lines[i].rstrip("\n")

        r = is_room_line(line)
        if r:
            room = r
            days_pos = None
            days_start = None
            i += 1
            continue

        if room:
            pos = find_date_positions(line)
            if pos and len(pos) >= 3:
                days_pos = pos
                days_start = pos[0]
                i += 1
                continue

        if not (room and days_pos is not None):
            i += 1
            continue

        if "Name" in line and "Guardian" in line:
            i += 1
            continue

        if line.strip().startswith("Totals"):
            ends = days_pos[1:] + [len(line)]
            vals = [line[s:e].strip() for s, e in zip(days_pos, ends)]
            recs.append([room, "Totals", ""] + vals[:7])
            i += 1
            continue

        if is_age_or_contact(line):
            i += 1
            continue

        # Candidate data row
        seg = line[:days_start]
        name, guardian = split_name_guardian(seg)
        if name and guardian:
            guardian = re.sub(r"\s*Fix(?:ed.*)?$", "", guardian).rstrip()

            look = [line]
            if i + 1 < n: look.append(lines[i + 1])
            if i + 2 < n: look.append(lines[i + 2])

            ends = days_pos[1:] + [max(len(L) for L in look)]
            day_vals = [
                ("Fixed" if any("Fixed" in L[s:e] for L in look) else "")
                for s, e in zip(days_pos, ends)
            ]
            recs.append([room, name, guardian] + day_vals[:7])

            i += 1
            while i < n and is_age_or_contact(lines[i]):
                i += 1
            continue

        i += 1

    return recs

def main():
    if len(sys.argv) not in (2, 3):
        print("Usage: okular2csv.py input.txt [output.csv]", file=sys.stderr)
        sys.exit(1)
    inp = Path(sys.argv[1]).expanduser()
    if not inp.exists():
        print(f"No such file: {inp}", file=sys.stderr)
        sys.exit(1)
    out = Path(sys.argv[2]).expanduser() if len(sys.argv) == 3 else inp.with_suffix(".csv")

    lines = inp.read_text(encoding="utf-8", errors="replace").splitlines()
    recs = parse_lines(lines)

    headers = ["Room", "Name", "Guardian"] + DAYS
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(headers)
        w.writerows(recs)

    print(f"✓ Wrote {out}")

if __name__ == "__main__":
    main()

    '';
  };
}
