import json
from pathlib import Path

cache = json.load(open('data/wargame_cache.json', encoding='utf-8'))
db_slugs = {p['slug'] for p in cache['platforms']}

lines = open('src/sim_core/systems/unit_tactical_trials_system.gd', encoding='utf-8').readlines()
trial_keys = []
for line in lines:
    s = line.strip()
    if s.startswith('"') and s.endswith('{') and ':' in s:
        key = s.split(':')[0].strip().strip('"')
        trial_keys.append(key)

print(f"DB count: {len(db_slugs)}")
print(f"Trials count: {len(trial_keys)}")
print("In Trials but NOT in DB:", set(trial_keys) - db_slugs)
print("In DB but NOT in Trials:", db_slugs - set(trial_keys))
