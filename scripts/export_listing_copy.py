"""Export plain-text fields for direct copy/paste into App Store Connect."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
folder = ROOT / 'appstore/metadata'
metadata = json.loads((folder/'en-AU.json').read_text())
out = folder/'paste-ready-en-AU'
out.mkdir(exist_ok=True)
fields = {'name':'name.txt','subtitle':'subtitle.txt','promotionalText':'promotional-text.txt',
          'description':'description.txt','keywords':'keywords.txt','reviewNotes':'review-notes.txt',
          'copyright':'copyright.txt'}
for field, name in fields.items():
    (out/name).write_text(metadata[field]+'\n')
(out/'urls.txt').write_text('\n'.join(f'{key}: {metadata[key]}' for key in ['supportURL','marketingURL','privacyPolicyURL'])+'\n')
print('Exported eight paste-ready text files')
