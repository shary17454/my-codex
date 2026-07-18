# Batal Al-Droob Supplier Partnership Workspace

This workspace tracks Nissan Patrol parts suppliers for lawful partnership outreach.

## Rules

- Do not claim any company is a partner until written approval is stored in that company's store file.
- Do not copy prices, stock status, catalog diagrams, protected catalog data, or supplier trademarks into the app.
- Use supplier links only after permission/legal review, or keep the supplier as an internal candidate.
- Every outreach email or contact-form message must be reviewed by a human before sending.
- Record every sent message, reply, permission, restriction, and follow-up date.

## Files

- `suppliers.json`: source of truth.
- `suppliers.csv`: spreadsheet-friendly export.
- `suppliers.md`: readable ranked directory.
- `dashboard.md`: outreach metrics.
- `stores/`: one file per supplier.
- `templates/`: reviewed outreach templates by supplier type.

## Regenerate derived files

```bash
python3 ios/BatalAlDroob/scripts/generate_partnership_outputs.py
```
