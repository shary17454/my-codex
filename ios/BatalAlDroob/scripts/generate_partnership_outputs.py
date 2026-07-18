#!/usr/bin/env python3
from pathlib import Path
import json, csv, re

BASE = Path(__file__).resolve().parents[1] / 'Partnerships'
DATA = BASE / 'suppliers.json'

def slug(s):
    return re.sub(r'[^a-z0-9-]+', '-', s.lower()).strip('-')

def val(v):
    if v is None:
        return ''
    if isinstance(v, list):
        return '; '.join(map(str, v))
    if isinstance(v, dict):
        return json.dumps(v, ensure_ascii=False)
    return str(v)

def main():
    payload = json.loads(DATA.read_text(encoding='utf-8'))
    suppliers = payload['suppliers']
    fields = payload['schema']['fields']
    required = ['id','company_name','country','official_website','importance_score','verification_status','outreach']
    for s in suppliers:
        missing = [f for f in required if f not in s]
        if missing:
            raise SystemExit(f"{s.get('id','unknown')} missing {missing}")
        if not isinstance(s.get('importance_score'), int):
            raise SystemExit(f"{s['id']} importance_score must be int")

    with (BASE / 'suppliers.csv').open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for s in suppliers:
            writer.writerow({field: val(s.get(field)) for field in fields})

    lines = ['# Nissan Patrol Supplier Directory', '', 'This directory is for Batal Al-Droob partnership research. It must not be treated as an approved partner list until written permission is recorded.', '', '| Score | Company | Country | Type | OEM | Aftermarket | Shipping | Outreach |', '|---:|---|---|---|---|---|---|---|']
    for s in sorted(suppliers, key=lambda x: x['importance_score'], reverse=True):
        lines.append(f"| {s['importance_score']} | [{s['company_name']}](stores/{s['id']}.md) | {s['country']} | {val(s['parts_types'])} | {val(s['sells_oem'])} | {val(s['sells_aftermarket'])} | {val(s['ships_to'])} | {s['outreach']['status']} |")
    (BASE / 'suppliers.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')

    counts = {
        'total': len(suppliers),
        'outreach_attempts': sum(
            1
            for s in suppliers
            for event in s['outreach'].get('history', [])
            if 'sent' in event.lower()
        ),
        'contacted_suppliers': sum(1 for s in suppliers if s['outreach'].get('last_sent_at')),
        'awaiting_reply': sum(
            1
            for s in suppliers
            if s['outreach']['status'] in {
                'sent_awaiting_reply',
                'follow_up_sent_awaiting_reply',
                'awaiting_written_link_permission',
            }
        ),
        'contact_form_required': sum(
            1 for s in suppliers if 'contact_form_required' in s['outreach']['status']
        ),
        'delivery_failed': sum(
            1
            for s in suppliers
            if 'bounced' in s['outreach']['status']
            or any(
                'delivery failed' in event.lower() or 'bounced' in event.lower()
                for event in s['outreach'].get('history', [])
            )
        ),
        'not_contacted': sum(1 for s in suppliers if not s['outreach'].get('last_sent_at')),
        'approved': sum(1 for s in suppliers if s['negotiation_status'] == 'approved'),
        'rejected': sum(
            1
            for s in suppliers
            if s['negotiation_status'] == 'rejected'
            or 'declined' in s['negotiation_status']
        ),
        'needs_info': sum(1 for s in suppliers if s['negotiation_status'] == 'needs_more_information'),
        'with_review_flags': sum(1 for s in suppliers if s.get('review_flags')),
        'api_known': sum(1 for s in suppliers if s['api_available'] is True),
        'affiliate_known': sum(1 for s in suppliers if s['affiliate_program'] is True),
        'actual_partners': sum(1 for s in suppliers if s['negotiation_status'] == 'approved'),
    }
    dash = ['# Partnership Outreach Dashboard', '', '| Metric | Count |', '|---|---:|']
    labels = {
        'total': 'Stores discovered', 'outreach_attempts': 'Outbound messages/attempts recorded',
        'contacted_suppliers': 'Suppliers with an outbound attempt', 'awaiting_reply': 'Awaiting a reply or written permission',
        'contact_form_required': 'Official contact form required', 'delivery_failed': 'Known delivery failures',
        'not_contacted': 'No successful email attempt yet', 'approved': 'Approved',
        'rejected': 'Rejected', 'needs_info': 'Requested more information', 'with_review_flags': 'Suppliers requiring manual verification', 'api_known': 'Known API available',
        'affiliate_known': 'Known affiliate available', 'actual_partners': 'Actual partners'
    }
    for k in labels:
        dash.append(f"| {labels[k]} | {counts[k]} |")
    dash.extend(['', '## Current Rules', '', '- Do not send outreach without human review.', '- Do not claim partnership without written approval.', '- Do not copy prices, stock, diagrams, or protected catalog data.', '- Prefer user-initiated links to supplier pages/search results after permission/legal review.'])
    (BASE / 'dashboard.md').write_text('\n'.join(dash) + '\n', encoding='utf-8')

    for s in suppliers:
        md = [f"# {s['company_name']}", '', f"- ID: `{s['id']}`", f"- Country: {s['country']}", f"- Region: {s['region']}", f"- Website: {s['official_website']}", f"- Email: {val(s['contact_email']) or 'Unknown'}", f"- Contact form: {val(s['contact_form']) or 'Unknown'}", f"- Contact person: {val(s['contact_person']) or 'Unknown'}", f"- Phone: {val(s['phone']) or 'Unknown'}", f"- LinkedIn: {val(s['linkedin']) or 'Unknown'}", f"- X: {val(s['x']) or 'Unknown'}", f"- Facebook: {val(s['facebook']) or 'Unknown'}", f"- Instagram: {val(s['instagram']) or 'Unknown'}", '', '## Parts Fit', '', f"- Parts types: {val(s['parts_types'])}", f"- OEM: {val(s['sells_oem'])}", f"- Aftermarket: {val(s['sells_aftermarket'])}", f"- International shipping: {val(s['supports_international_shipping'])}", f"- Ships to: {val(s['ships_to'])}", f"- Site languages: {val(s['site_languages'])}", '', '## Partnership Signals', '', f"- Affiliate program: {val(s['affiliate_program'])}", f"- API available: {val(s['api_available'])}", f"- Partnership program: {val(s['partnership_program'])}", f"- External link allowed: {val(s['external_link_allowed'])}", f"- Developer program: {val(s['developer_program'])}", '', '## Legal Notes', '', s['legal_notes'], '', f"Link terms: {s['link_terms']}", '', '## Priority', '', f"- Score: {s['importance_score']}/100", f"- Reason: {s['importance_reason']}", '', '## Outreach', '', f"- Status: {s['outreach']['status']}", f"- Last sent: {val(s['outreach']['last_sent_at']) or 'Not sent'}", f"- Next follow-up: {val(s['outreach']['next_follow_up_at']) or 'Not scheduled'}", f"- Negotiation status: {s['negotiation_status']}", '', '### History']
        hist = s['outreach'].get('history') or []
        md.extend([f"- {h}" for h in hist] or ['- No outreach recorded.'])
        md.extend(['', '## Review Flags'])
        flags = s.get('review_flags') or []
        md.extend([f"- {flag}" for flag in flags] or ['- No specific review flags.'])
        md.extend(['', '## Recommended Next Action', '', s.get('recommended_next_action', 'Review manually before outreach.')])
        md.extend(['', '## Sources'])
        md.extend([f"- {u}" for u in s['source_urls']])
        md.extend(['', f"Last updated: {s['last_updated']}"])
        (BASE / 'stores' / f"{s['id']}.md").write_text('\n'.join(md) + '\n', encoding='utf-8')

if __name__ == '__main__':
    main()
