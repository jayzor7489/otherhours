"""Builds Resources/cities.tsv and Resources/regions.tsv from GeoNames (CC BY 4.0).

    python3 -I scripts/make_cities.py

Output columns, tab separated, no header, most populous first:
name, ascii name, country code, time zone, population, admin1 (region) code.
regions.tsv: "CC.code", name, ascii name, from admin1CodesASCII.txt.
"""
import io
import os
import sys
import tempfile
import urllib.request
import zipfile

URL = "https://download.geonames.org/export/dump/cities15000.zip"
REGIONS_URL = "https://download.geonames.org/export/dump/admin1CodesASCII.txt"
RESOURCES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Resources")
OUT = os.path.join(RESOURCES, "cities.tsv")
REGIONS_OUT = os.path.join(RESOURCES, "regions.tsv")

with tempfile.TemporaryDirectory() as tmp:
    archive = os.path.join(tmp, "cities15000.zip")
    urllib.request.urlretrieve(URL, archive)
    with zipfile.ZipFile(archive) as zf:
        raw = zf.read("cities15000.txt").decode("utf-8")
    regions_file = os.path.join(tmp, "admin1.txt")
    urllib.request.urlretrieve(REGIONS_URL, regions_file)
    with open(regions_file, encoding="utf-8") as f:
        regions = [line.rstrip("\n").split("\t")[:3] for line in f if line.count("\t") >= 2]

rows = []
for line in io.StringIO(raw):
    f = line.rstrip("\n").split("\t")
    if len(f) < 18 or not f[17]:
        continue
    name, ascii_name, country, admin1, population, zone = f[1], f[2], f[8], f[10], f[14], f[17]
    rows.append((name, ascii_name, country, zone, int(population or 0), admin1))

rows.sort(key=lambda r: -r[4])
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as out:
    for r in rows:
        out.write("\t".join([r[0], r[1], r[2], r[3], str(r[4]), r[5]]) + "\n")
with open(REGIONS_OUT, "w", encoding="utf-8") as out:
    for r in regions:
        out.write("\t".join(r) + "\n")
print(f"wrote {len(rows)} cities to {os.path.normpath(OUT)}", file=sys.stderr)
print(f"wrote {len(regions)} regions to {os.path.normpath(REGIONS_OUT)}", file=sys.stderr)
