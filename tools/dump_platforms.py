import json

d = json.load(open('data/wargame_cache.json', encoding='utf-8'))
print("Platform sample keys:", list(d['platforms'][0].keys()))
for i, p in enumerate(d['platforms']):
    print(f"[{i+1:02d}] slug={p.get('slug')} domain={p.get('domain')} name={p.get('display_name', p.get('full_name', p.get('title')))}")
