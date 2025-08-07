#/etc/nixos/custom-modules/hastings-preschool/okular2csv.nix
{ config, pkgs, ... }:
{
  home.file.".local/bin/text2ods" = {
    executable = true;
    text = ''
      #!/usr/bin/env python3
      import sys, re, csv
      from pathlib import Path
      
      DAYS = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
      
      def find_day_slices(day_line:str):
          idx=[]
          for d in DAYS:
              p=day_line.find(d)
              if p==-1: return []
              idx.append(p)
          idx.sort()
          out=[]
          for i,s in enumerate(idx):
              e = idx[i+1] if i+1<len(idx) else len(day_line)
              out.append((s,e))
          return out
      
      def is_room_line(line:str):
          m=re.search(r"([A-Za-z/\- ]+ Room),", line)
          return m.group(1).strip() if m else None
      
      def is_age_or_contact(line:str):
          s=line.strip()
          return (" yrs" in s) or re.search(r"\b[MPHW]\s*:\s*\S", s) or s==""
      
      def parse_text(lines):
          recs=[]
          room=None
          guardian_start=None
          days_slices=[]
          days_start=None
      
          i=0
          n=len(lines)
          while i<n:
              line=lines[i].rstrip("\n")
      
              maybe_room=is_room_line(line)
              if maybe_room:
                  room=maybe_room
                  guardian_start=None; days_slices=[]; days_start=None
                  i+=1; continue
      
              if not days_slices and any(d in line for d in DAYS):
                  sl=find_day_slices(line)
                  if sl:
                      days_slices=sl; days_start=sl[0][0]
                      i+=1; continue
      
              if days_slices and guardian_start is None and ("Name" in line and "Guardian" in line):
                  guardian_start=line.find("Guardian")
                  i+=1; continue
      
              if days_slices and re.search(r"\d{2}/\d{2}/\d{4}", line):
                  i+=1; continue
      
              if not room or not days_slices or guardian_start is None:
                  i+=1; continue
      
              if line.strip().startswith("Totals"):
                  vals=[ line[s:e].strip() for (s,e) in days_slices ]
                  recs.append([room,"Totals",""]+vals)
                  i+=1; continue
      
              name=line[:guardian_start].strip()
              guardian=line[guardian_start:days_start].strip()
              if name and guardian and name!="Name" and guardian!="Guardian":
                  look=[line]
                  if i+1<n: look.append(lines[i+1])
                  if i+2<n: look.append(lines[i+2])
                  day_vals=[]
                  for (s,e) in days_slices:
                      cell_has_fixed=any("Fixed" in L[s:e] for L in look)
                      day_vals.append("Fixed" if cell_has_fixed else "")
                  recs.append([room,name,guardian]+day_vals)
                  i+=1
                  while i<n and is_age_or_contact(lines[i]):
                      i+=1
                  continue
      
              i+=1
      
          headers=["Room","Name","Guardian"]+DAYS
          return headers,recs
      
      def main():
          if len(sys.argv) not in (2,3):
              print("Usage: okular2csv.py input.txt [output.csv]", file=sys.stderr); sys.exit(1)
          inp=Path(sys.argv[1])
          if not inp.exists(): print(f"No such file: {inp}", file=sys.stderr); sys.exit(1)
          out=Path(sys.argv[2]) if len(sys.argv)==3 else inp.with_suffix(".csv")
          lines=inp.read_text(encoding="utf-8").splitlines()
          headers,recs=parse_text(lines)
          with out.open("w", newline="", encoding="utf-8") as f:
              w=csv.writer(f)
              w.writerow(headers)
              w.writerows(recs)
          print(f"✓ Wrote {out}")
      
      if __name__=="__main__":
          main()
    '';
  };
}
