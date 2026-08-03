# Batal Al-Droob Catalog Asset Packs

The 640 original PDF catalogs are delivered as Apple-hosted, on-demand Background Assets. They are deliberately excluded from the main app bundle because their uncompressed size exceeds the App Store's 4 GB iOS app limit.

Generate the deterministic delivery index and pack manifests:

```sh
python3 scripts/generate_catalog_asset_packs.py
```

Package one archive for validation or upload:

```sh
python3 scripts/generate_catalog_asset_packs.py \
  --package batal.catalog.y60.001 \
  --output-directory /tmp/BatalCatalogAssetPacks
```

Package all 40 archives with the supported release of Xcode:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
python3 scripts/generate_catalog_asset_packs.py \
  --package-all \
  --output-directory CatalogAssetPacks/archives
```

You can set `BA_PACKAGE` to an explicit packaging-tool path instead. Confirm that
the selected Xcode is a production release; App Store Connect does not allow
asset packs produced by a beta packaging tool to be submitted for review.

The command must run on the complete local archive. Generated `.aar` archives are release artifacts and must not be committed. Upload them independently to the Batal Al-Droob app record in App Store Connect, then validate them through TestFlight before App Review.

App Store Connect currently accepts at most ten asset packs in one review
submission. The 40 packs therefore require four review submissions. Keeping the
packs granular avoids forcing a customer to download several gigabytes to open
one small catalog.

Security and access rules:

- The iOS app requests a pack only after the related catalog entitlement is available.
- Apple hosts and validates the downloadable archives; no storage credentials are embedded in the app.
- The bundled JSON database remains available offline without downloading PDF assets.
- Do not publish the PDFs through unauthenticated public URLs.
