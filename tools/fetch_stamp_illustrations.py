"""Fetch unmodified public-domain educational illustrations and retain provenance."""
import html
import json
import re
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
out = root / 'assets/images/stamp_making'
out.mkdir(parents=True, exist_ok=True)
files = [
    ('design', 'Franklin 1870 die proof2-1c.jpg'),
    ('proof', 'Washington Die Proof2 1861-10c.jpg'),
    ('perforation', 'Women perforating sheets of stamps in the Stamp Division at the Bureau of Engraving & Printing 3c37142v.jpg'),
    ('finished', 'Abraham Lincoln 1890 Issue-4c.jpg'),
]
records = []
def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'JejakPOS educational asset research/1.0'})
    return urllib.request.urlopen(req, timeout=40).read()
for name, title in files:
    url = 'https://commons.wikimedia.org/wiki/File:' + urllib.parse.quote(title.replace(' ', '_'))
    page = get(url).decode()
    match = re.search(r'class="fullImageLink"[^>]*>\s*<a href="([^"]+)"', page)
    if not match:
        raise RuntimeError('No original image: ' + title)
    original = html.unescape(match.group(1)).split('?')[0]
    print(name, original, flush=True)
    try:
        data = get(original)
    except urllib.error.HTTPError:
        preview = re.search(r'href="(https://thumb.wikimedia.org/[^"]+)"', page)
        if not preview:
            raise
        original = html.unescape(preview.group(1))
        print('preview', original, flush=True)
        data = get(original)
    (out / (name + '.jpg')).write_bytes(data)
    records.append({'asset': name + '.jpg', 'source': url, 'original': original, 'license': 'Public domain (see source file page)'})
    print(name, original)
# The LOC blog embeds its historical printing photograph directly.
url = 'https://blogs.loc.gov/picturethis/2019/05/frances-benjamin-johnston-puts-her-stamp-on-documenting-work-at-the-bureau-of-engraving-and-printing/'
page = get(url).decode()
imgs = re.findall(r'<img[^>]+>', page)
for tag in imgs:
    if 'SheetsOffPresses' in tag:
        original = html.unescape(re.search(r'src="([^"]+)"', tag).group(1))
        if original.startswith('//'):
            original = 'https:' + original
        (out / 'printing.jpg').write_bytes(get(original))
        records.append({'asset': 'printing.jpg', 'source': url, 'original': original, 'author': 'Frances Benjamin Johnston, 1889–1890; Library of Congress', 'license': 'Public domain, historical US photograph published in 1895'})
        print('printing', original)
        break
else:
    raise RuntimeError('Printing photo not found')
(out / 'credits.json').write_text(json.dumps(records, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
