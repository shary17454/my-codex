#!/usr/bin/env python3
from pathlib import Path
import csv
import json
import re
import sys

BASE = Path(__file__).resolve().parents[1] / 'Partnerships'
DATA = BASE / 'suppliers.json'

errors = []
warnings = []

def fail(msg):
    errors.append(msg)

def warn(msg):
    warnings.append(msg)

payload = json.loads(DATA.read_text(encoding='utf-8'))
suppliers = payload['suppliers']
fields = payload['schema']['fields']
ids = set()
for supplier in suppliers:
    sid = supplier.get('id', '<missing>')
    if sid in ids:
        fail(f'duplicate supplier id: {sid}')
    ids.add(sid)
    for field in fields:
        if field not in supplier:
            fail(f'{sid}: missing field {field}')
    if supplier.get('negotiation_status') == 'approved':
        fail(f'{sid}: marked approved without stored written approval')
    if supplier.get('external_link_allowed') is True:
        fail(f'{sid}: external_link_allowed cannot be true before permission')
    if supplier.get('api_available') is True:
        warn(f'{sid}: API marked true, verify supporting proof')
    if supplier.get('affiliate_program') is True:
        warn(f'{sid}: affiliate marked true, verify supporting proof')
    email = supplier.get('contact_email')
    if email and not re.match(r'^[^@\s]+@[^@\s]+\.[^@\s]+$', email):
        warn(f'{sid}: suspicious email {email}')
    if not email and not supplier.get('contact_form'):
        warn(f'{sid}: no direct outreach channel')
    store_file = BASE / 'stores' / f'{sid}.md'
    if not store_file.exists():
        fail(f'{sid}: missing store file')

with (BASE / 'suppliers.csv').open(encoding='utf-8') as csv_file:
    rows = list(csv.DictReader(csv_file))
if len(rows) != len(suppliers):
    fail(f'suppliers.csv row count {len(rows)} does not match suppliers.json {len(suppliers)}')

for template in (BASE / 'templates').glob('*.md'):
    text = template.read_text(encoding='utf-8')
    if template.name != 'linkedin.md' and 'Subject:' not in text:
        fail(f'{template.name}: missing subject')
    lower = text.lower()
    mentions_prices = 'price' in lower or 'pricing' in lower
    mentions_inventory = 'stock' in lower or 'inventory' in lower
    mentions_protected = 'protected' in lower or 'catalog' in lower or 'images' in lower
    if not (mentions_prices and mentions_inventory and mentions_protected):
        warn(f'{template.name}: does not fully state no copying of prices/inventory/protected content')
    if template.name != 'linkedin.md' and 'prefer not to participate' not in text and 'do not want to receive' not in text:
        warn(f'{template.name}: missing explicit opt-out language')
    if 'trusted' in text.lower():
        warn(f'{template.name}: avoid trust wording before approval')

print('Partnership validation')
print(f'Suppliers: {len(suppliers)}')
print(f'Errors: {len(errors)}')
for error in errors:
    print(f'ERROR: {error}')
print(f'Warnings: {len(warnings)}')
for warning in warnings:
    print(f'WARNING: {warning}')
if errors:
    sys.exit(1)
