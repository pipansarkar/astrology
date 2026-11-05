"""Builds assets/cities.tsv from GeoNames dumps (CC BY 4.0, geonames.org).

Download into an empty folder:
  https://download.geonames.org/export/dump/{cities15000.zip,IN.zip,admin1CodesASCII.txt,countryInfo.txt}
Then:
  python3 -I tool/build_cities.py <download-folder> assets/cities.tsv

Output columns (tab-separated, sorted by population descending):
  name  region  country  latitude  longitude  timezone  population
Includes every Indian populated place with population >= 1000 (plus all
district/state headquarters) and world cities with population >= 15000.
"""
import csv
import io
import sys
import zipfile
from pathlib import Path

src, out = Path(sys.argv[1]), Path(sys.argv[2])

admin1 = {}
with open(src / "admin1CodesASCII.txt", encoding="utf-8") as f:
    for row in csv.reader(f, delimiter="\t"):
        admin1[row[0]] = row[1]

countries = {}
with open(src / "countryInfo.txt", encoding="utf-8") as f:
    for line in f:
        if line.startswith("#"):
            continue
        row = line.rstrip("\n").split("\t")
        countries[row[0]] = row[4]


def rows(zip_name, member):
    with zipfile.ZipFile(src / zip_name) as z:
        with z.open(member) as raw:
            yield from csv.reader(
                io.TextIOWrapper(raw, encoding="utf-8"), delimiter="\t",
                quoting=csv.QUOTE_NONE)


places = {}


def add(r):
    gid, name, lat, lon = r[0], r[1], float(r[4]), float(r[5])
    cc, a1, pop, tz = r[8], r[10], int(r[14] or 0), r[17]
    if not tz or "\t" in name:
        return
    places[gid] = (
        name,
        admin1.get(f"{cc}.{a1}", ""),
        countries.get(cc, cc),
        f"{lat:.4f}",
        f"{lon:.4f}",
        tz,
        pop,
    )


for r in rows("IN.zip", "IN.txt"):
    if r[6] != "P":  # populated places only
        continue
    if int(r[14] or 0) >= 1000 or r[7] in ("PPLA", "PPLA2", "PPLC"):
        add(r)

for r in rows("cities15000.zip", "cities15000.txt"):
    if r[0] not in places:
        add(r)

ordered = sorted(places.values(), key=lambda p: -p[6])
with open(out, "w", encoding="utf-8", newline="") as f:
    for p in ordered:
        f.write("\t".join(map(str, p)) + "\n")

india = sum(1 for p in ordered if p[2] == "India")
print(f"{len(ordered)} places ({india} in India) -> {out}")
