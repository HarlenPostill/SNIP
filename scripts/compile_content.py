"""Compile original editorial rows and verify every cut mechanically."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
rows = list(csv.DictReader((ROOT / "work/puzzles.tsv").open(), delimiter="\t"))
result = []
seen = set()
for row in rows:
    source, cut = row["source"], row["cut"]
    assert source not in seen, f"Duplicate source {source}"
    seen.add(source)
    ranges = [(i, i + len(cut)) for i in range(1, len(source) - len(cut)) if source[i:i + len(cut)] == cut]
    assert len(ranges) == 1, f"Ambiguous or missing cut in {source}"
    a, b = ranges[0]
    keep = source[:a] + source[b:]
    assert len(keep) >= 3 and len(cut) >= 3
    result.append(dict(id=source.lower(), source=source, cut=cut, keep=keep,
                       cutClue=row["cutClue"], keepClue=row["keepClue"],
                       difficulty=int(row["difficulty"]), collection=row["collection"]))
dailies = [p for p in result if p["collection"] == "daily"]
# Preserve 90 distinct daily source words in 30 sets, each sorted into a gentle ramp.
assert len(dailies) >= 90
dailies = dailies[:90]
for i in range(0, 90, 3):
    dailies[i:i+3] = sorted(dailies[i:i+3], key=lambda p: p["difficulty"])
practice = [p for p in result if p["collection"] != "daily"]
output = ROOT / "sol-word-test/Puzzles.json"
output.write_text(json.dumps(dailies + practice, ensure_ascii=False, indent=2) + "\n")
print(f"Validated {len(dailies)} daily + {len(practice)} practice puzzles; {len(dailies)//3}-day cycle.")
