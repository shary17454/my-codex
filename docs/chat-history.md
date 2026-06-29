# Nissan Patrol Y60 EPC Catalog - Chat Work Log

This file documents the work performed in the Codex session for the Nissan Patrol Y60 EPC catalog project.

## Scope Requested

The requested target was a professional bilingual Arabic/English catalog for Nissan Patrol Y60 covering:

- Production years 1988-1997.
- Markets including Japan, GCC/General Asia, Australia, Europe, Africa/South Africa, and export where data is available.
- Body styles including wagon, hardtop/SWB, pickup, cab chassis/A-chassis, high roof, van variants, and related market-specific trims.
- Engines including TB42, TB42S, TB42E, TD42, TD42T, RD28, RD28T, RB30 and related regional variants where verified.
- Full EPC-style data: plates, diagrams, part numbers, descriptions, quantities, applicability, supersessions/replacements when present, and verification notes.

The user also requested older pre-1988 Patrol catalogs with the same level of detail. These were separated from Y60 because pre-1988 data visible in the current PartSouq index corresponds mainly to Patrol 160, not Y60.

## Data Source

Primary source used during the session:

- PartSouq Nissan genuine catalog pages.

Important rule followed:

- No fabricated part numbers.
- Unknown or blocked data is marked as `Verification Required`.
- Cloudflare blocks prevented full automated extraction of all missing references.

## Main Generated Outputs

### Updated 10 yearly PDFs plus independent WGY reference

ZIP package:

```text
output/pdf/Y60_1988-1997_updated_10_plus_WGY60348567.zip
```

Contents:

- `Y60 1988.pdf`
- `Y60 1989.pdf`
- `Y60 1990.pdf`
- `Y60 1991.pdf`
- `Y60 1992.pdf`
- `Y60 1993.pdf`
- `Y60 1994.pdf`
- `Y60 1995.pdf`
- `Y60 1996.pdf`
- `Y60 1997.pdf`
- `WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.reportlab.pdf`

Approximate ZIP size: 117 MB.

### Single combined PDF

Combined chronological PDF:

```text
output/pdf/Y60_1988-1997_all_11_catalogs_combined.pdf
```

Details:

- 11 sections.
- Ordered from 1988 through 1997.
- Final section is the independent `WGY60348567` detailed EPC catalog.
- Section divider pages were added before each section.
- Total pages: 5281.

Manifest:

```text
output/pdf/Y60_1988-1997_all_11_catalogs_combined_manifest.json
```

### Updated yearly PDFs with available missing supplements

Directory:

```text
output/pdf/yearly_with_available_missing/
```

Files:

- `Y60 1988.pdf`
- `Y60 1989.pdf`
- `Y60 1990.pdf`
- `Y60 1991.pdf`
- `Y60 1992.pdf`
- `Y60 1993.pdf`
- `Y60 1994.pdf`
- `Y60 1995.pdf`
- `Y60 1996.pdf`
- `Y60 1997.pdf`

Merge manifest:

```text
output/pdf/yearly_with_available_missing/merge_available_missing_manifest.json
```

## Fully/Partially Extracted References

### WGY60348567

Reference:

```text
WGY60348567 - General/Asia LHD WAGON TB42S SGL
```

Output:

```text
output/pdf/full_y60/WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.reportlab.pdf
```

Extracted data:

```text
sources/partsouq/full_y60/WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.json
```

Summary:

- 170 catalog plates.
- 3081 part rows.
- 248 PDF pages.
- 1 item requiring verification.

Arabic rendering issues were fixed by:

- Replacing corrupted Arabic strings in the PDF generator.
- Adding Arabic reshaping and bidi support.
- Improving Arabic labels and common part-name translations.

### Australia RHD / WAGON / RB30S / STD

Extract ID:

```text
b3d7b114a89a
```

JSON:

```text
sources/partsouq/full_y60/b3d7b114a89a_Australia_RHD_WAGON_RB30S_STD.json
```

PDF:

```text
output/pdf/available_missing_y60/b3d7b114a89a_Australia_RHD_WAGON_RB30S_STD.pdf
```

Summary:

- 226 catalog plates extracted.
- 4741 part rows extracted.
- 3 items marked `Verification Required`.
- Applied to yearly PDFs 1988-1991.

### Australia RHD / HARDTOP / TD42 / DX

Extract ID:

```text
d074a6710cf6
```

JSON:

```text
sources/partsouq/full_y60/d074a6710cf6_Australia_RHD_HARDTOP_TD42_DX.json
```

PDF:

```text
output/pdf/available_missing_y60/d074a6710cf6_Australia_RHD_HARDTOP_TD42_DX.pdf
```

Summary:

- 249 catalog plate references discovered.
- 20 catalog plates extracted before Cloudflare resumed blocking.
- 600 part rows extracted.
- 20 items marked `Verification Required`.
- Applied to yearly PDFs 1988-1993.

## Coverage Reports

Y60 detailed coverage report:

```text
output/reports/y60_detail_coverage_summary.json
output/reports/y60_detail_coverage_all.csv
output/reports/y60_detail_coverage_missing.csv
output/reports/y60_detail_coverage_extracted.csv
```

At the time of reporting:

- Y60 rows applicable to 1988-1997: 264.
- Detailed extracted rows after additional extraction: 10.
- Missing detailed rows: 254.
- Extracted source count: 11.

Pre-1988 Patrol 160 report:

```text
output/reports/pre1988_patrol_160_coverage_summary.json
output/reports/pre1988_patrol_160_coverage_all.csv
output/reports/pre1988_patrol_160_missing.csv
```

Pre-1988 visible scope:

- Model code: `160`.
- Catalog rows: 59.
- Markets: Australia RHD, Europe LHD, Europe RHD.
- Engines: L28, P40, SD33, SD33T.
- Body styles: hardtop, wagon, pickup, A-chassis, van, high roof wagon.
- All 59 still require full EPC extraction.

## Scripts Added or Updated

Key scripts created/updated during the session:

```text
scripts/build_wgy60348567_pdf_reportlab.py
scripts/merge_wgy60348567_into_yearly_pdfs.py
scripts/combine_all_11_catalogs_pdf.py
scripts/audit_y60_detail_coverage.py
scripts/audit_pre1988_patrol_coverage.py
scripts/build_available_missing_reportlab_pdfs.py
scripts/merge_available_missing_into_yearly_pdfs.py
scripts/cdp_extract_y60_batch.py
scripts/cdp_extract_y60_incremental.py
scripts/cdp_extract_current_vehicle.py
```

## Cloudflare / PartSouq Limitation

PartSouq repeatedly triggered Cloudflare protection during extraction:

- `Just a moment...`
- Arabic security verification page.
- `Sorry, you have been blocked`.

Because of that, only verified extracted data was merged. Blocked pages were not guessed or generated.

Recommended continuation workflow:

1. Open PartSouq in a clean Edge profile or normal browser session.
2. Avoid rapid navigation.
3. Extract in small batches.
4. Save after each batch.
5. Rebuild PDFs only after a meaningful batch is complete.

## GitHub Preparation Notes

Git LFS is required for large generated artifacts:

- PDF files.
- ZIP files.

The local repository includes:

```text
.gitattributes
.gitignore
```

`.gitattributes` tracks PDFs and archives through Git LFS.

`.gitignore` excludes temporary browser profiles and local Codex/session state:

- `tmp/`
- `.codex/`
- `.agents/`

This avoids committing browser cookies, caches, and temporary extraction state that should not be pushed to GitHub.

## Privacy Note

The session included a WhatsApp phone number. It is intentionally not included in this project log because it is personal contact information and is not needed for the technical repository.
